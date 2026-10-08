import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../database/database_helper.dart';
import '../models/transaction_model.dart';
import '../models/expense_category.dart';
import '../widgets/donut_chart.dart';
import '../widgets/weekly_bar_chart.dart';
import 'camera_scanner_screen.dart';

class DashboardScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const DashboardScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<DashboardData> _fetchDashboardData() async {
    final db = DatabaseHelper.instance;
    final stats = await db.getCategoryStats();
    final allTransactions = await db.getAllTransactions();
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sevenDaysAgo = today.subtract(const Duration(days: 6));
    
    final recentTransactions = await db.getTransactionsByDateRange(
      sevenDaysAgo, 
      DateTime(today.year, today.month, today.day, 23, 59, 59),
    );

    List<double> weeklyData = List.filled(7, 0.0);
    List<String> labels = List.filled(7, '');
    
    for (int i = 0; i < 7; i++) {
      final day = sevenDaysAgo.add(Duration(days: i));
      labels[i] = _getWeekdayLabel(day.weekday);
      
      final dailySum = recentTransactions
          .where((t) => t.date.year == day.year && t.date.month == day.month && t.date.day == day.day)
          .fold(0.0, (sum, t) => sum + t.amount);
      weeklyData[i] = dailySum;
    }

    final monthlyTotal = allTransactions
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .fold(0.0, (sum, t) => sum + t.amount);

    return DashboardData(
      categoryStats: stats,
      weeklyData: weeklyData,
      weeklyLabels: labels,
      recentTransactions: allTransactions.take(10).toList(),
      monthlyTotal: monthlyTotal,
    );
  }

  String _getWeekdayLabel(int weekday) {
    switch (weekday) {
      case 1: return 'T2';
      case 2: return 'T3';
      case 3: return 'T4';
      case 4: return 'T5';
      case 5: return 'T6';
      case 6: return 'T7';
      case 7: return 'CN';
      default: return '';
    }
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    ) + ' đ';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardData>(
      future: _fetchDashboardData(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Xin chào!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal)),
                Text('Tháng ${DateTime.now().month}/${DateTime.now().year}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              if (data != null)
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '-${_formatCurrency(data.monthlyTotal)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
            ],
          ),
          body: snapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : snapshot.hasError
                  ? Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'))
                  : RefreshIndicator(
                      onRefresh: () async { setState(() {}); },
                      child: ListView(
                        padding: const EdgeInsets.all(16.0),
                        children: [
                          // Donut Chart Card
                          Card(
                            color: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  const Text('Cơ cấu chi tiêu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  const SizedBox(height: 16),
                                  AnimatedDonutChart(data: data!.categoryStats),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Weekly Bar Chart Card
                          Card(
                            color: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  const Text('Chi tiêu 7 ngày qua', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  const SizedBox(height: 16),
                                  WeeklyBarChart(
                                    weeklyData: data.weeklyData,
                                    labels: data.weeklyLabels,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          const Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 8),
                            child: Text('Giao dịch gần đây', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                          ),
                          if (data.recentTransactions.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Text('Chưa có giao dịch nào', style: TextStyle(color: Colors.grey)),
                              ),
                            )
                          else
                            ...data.recentTransactions.map((tx) => Card(
                              color: Colors.white,
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: tx.category.color.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(tx.category.icon, color: tx.category.color),
                                ),
                                title: Text(tx.merchant, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text('${tx.date.day.toString().padLeft(2, '0')}/${tx.date.month.toString().padLeft(2, '0')}/${tx.date.year}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                ),
                                trailing: Text(
                                  '-${_formatCurrency(tx.amount)}',
                                  style: const TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                            )),
                            const SizedBox(height: 80), // Padding for FAB
                        ],
                      ),
                    ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CameraScannerScreen(cameras: widget.cameras),
                ),
              );
              setState(() {});
            },
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.document_scanner),
            label: const Text('Quét hóa đơn', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }
}

class DashboardData {
  final Map<ExpenseCategory, double> categoryStats;
  final List<double> weeklyData;
  final List<String> weeklyLabels;
  final List<TransactionModel> recentTransactions;
  final double monthlyTotal;

  DashboardData({
    required this.categoryStats,
    required this.weeklyData,
    required this.weeklyLabels,
    required this.recentTransactions,
    required this.monthlyTotal,
  });
}
