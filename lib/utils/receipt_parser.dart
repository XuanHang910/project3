import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ParsedReceiptResult {
  final String? merchant;
  final double? amount;
  final DateTime? date;

  ParsedReceiptResult({this.merchant, this.amount, this.date});
}

class ReceiptParser {
  static ParsedReceiptResult parse(RecognizedText recognizedText) {
    String? merchant;
    double? amount;
    DateTime? date;

    // Lọc và làm sạch các dòng text nhận diện được
    final lines = recognizedText.blocks
        .expand((block) => block.lines)
        .map((line) => line.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (lines.isEmpty) return ParsedReceiptResult();

    // 1. Parse Merchant: Thường là dòng đầu tiên không chứa số và đủ dài (tên cửa hàng, siêu thị)
    for (var line in lines) {
      if (!line.contains(RegExp(r'\d')) && line.length > 3) {
        merchant = line;
        break;
      }
    }
    merchant ??= 'Cửa hàng không xác định';

    // 2. Parse Date: Bắt các định dạng ngày phổ biến (dd/MM/yyyy, dd-MM-yyyy, yyyy-MM-dd)
    final dateRegExp = RegExp(r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{4})\b|\b(\d{4})[/-](\d{1,2})[/-](\d{1,2})\b');
    for (var line in lines) {
      final match = dateRegExp.firstMatch(line);
      if (match != null) {
        try {
          if (match.group(1) != null) { // dd/MM/yyyy
            final day = int.parse(match.group(1)!);
            final month = int.parse(match.group(2)!);
            final year = int.parse(match.group(3)!);
            date = DateTime(year, month, day);
          } else if (match.group(4) != null) { // yyyy-MM-dd
            final year = int.parse(match.group(4)!);
            final month = int.parse(match.group(5)!);
            final day = int.parse(match.group(6)!);
            date = DateTime(year, month, day);
          }
          break;
        } catch (_) {}
      }
    }

    // 3. Parse Amount: Nâng cấp heuristic để tìm số tiền chính xác hơn
    // Các từ khóa chỉ tổng tiền ở Việt Nam và Quốc tế
    final amountKeywords = ['tổng', 'cộng', 'thanh toán', 'total', 'tiền mặt', 'phải trả', 'khách đưa'];
    final valueRegExp = RegExp(r'([\d.,]+)\s*(đ|vnd|vnđ|d)?', caseSensitive: false);

    for (int i = 0; i < lines.length; i++) {
      final lowerLine = lines[i].toLowerCase();
      // Nếu dòng chứa từ khóa tổng tiền
      if (amountKeywords.any((kw) => lowerLine.contains(kw))) {
        // Tìm số trong cùng dòng đó (lấy số cuối cùng xuất hiện trong dòng)
        final match = valueRegExp.allMatches(lowerLine).lastOrNull;
        if (match != null && match.group(1) != null) {
          amount = _parseAmountString(match.group(1)!);
          if (amount != null && amount! > 0) break;
        }
        
        // Hoặc tìm số ở ngay dòng tiếp theo (do layout hóa đơn đôi khi ngắt dòng)
        if (i + 1 < lines.length) {
          final nextLineMatch = valueRegExp.allMatches(lines[i + 1].toLowerCase()).lastOrNull;
          if (nextLineMatch != null && nextLineMatch.group(1) != null) {
            final tempAmt = _parseAmountString(nextLineMatch.group(1)!);
            if (tempAmt != null && tempAmt > 0) {
              amount = tempAmt;
              break;
            }
          }
        }
      }
    }

    // Fallback: Nếu không tìm thấy từ khóa, lấy số tiền lớn nhất có vẻ hợp lý trong toàn hóa đơn
    if (amount == null || amount == 0) {
      double maxAmount = 0;
      for (var line in lines) {
        final matches = valueRegExp.allMatches(line.toLowerCase());
        for (var match in matches) {
          if (match.group(1) != null) {
            final val = _parseAmountString(match.group(1)!);
            // Lọc các số vô lý (ví dụ mã vạch dài thòng) > 1 tỷ
            if (val != null && val > maxAmount && val < 1000000000) {
              maxAmount = val;
            }
          }
        }
      }
      if (maxAmount > 0) amount = maxAmount;
    }

    return ParsedReceiptResult(
      merchant: merchant,
      amount: amount,
      date: date ?? DateTime.now(),
    );
  }

  static double? _parseAmountString(String str) {
    try {
      // Xóa tất cả các ký tự không phải số, dấu phẩy hoặc chấm
      String clean = str.replaceAll(RegExp(r'[^\d.,]'), '');
      if (clean.isEmpty) return null;
      
      // Xử lý chuẩn hóa dấu phân cách hàng nghìn (Việt Nam dùng chấm, Mỹ dùng phẩy)
      if (clean.contains('.') && clean.contains(',')) {
        final lastDot = clean.lastIndexOf('.');
        final lastComma = clean.lastIndexOf(',');
        if (lastDot > lastComma) { // 1,000.50
           clean = clean.replaceAll(',', '');
        } else { // 1.000,50
           clean = clean.replaceAll('.', '').replaceAll(',', '.');
        }
      } else if (clean.contains(',')) {
        final parts = clean.split(',');
        if (parts.last.length == 3) {
           clean = clean.replaceAll(',', ''); // Dấu phẩy là ngăn cách hàng nghìn: 100,000
        } else {
           clean = clean.replaceAll(',', '.'); // Dấu phẩy là số thập phân: 100,5
        }
      } else {
         final parts = clean.split('.');
         if (parts.length > 1 && parts.last.length == 3) {
            clean = clean.replaceAll('.', ''); // Dấu chấm là ngăn cách hàng nghìn: 100.000
         }
      }
      return double.tryParse(clean);
    } catch (_) {
      return null;
    }
  }
}
