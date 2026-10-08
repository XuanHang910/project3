import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../utils/receipt_parser.dart';
import 'scan_review_screen.dart';

class CameraScannerScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  
  const CameraScannerScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  State<CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends State<CameraScannerScreen> {
  CameraController? _controller;
  bool _isFlashOn = false;
  bool _isProcessing = false;
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (widget.cameras.isEmpty) return;
    _controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.high,
      enableAudio: false,
    );
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    _isFlashOn = !_isFlashOn;
    await _controller!.setFlashMode(
      _isFlashOn ? FlashMode.torch : FlashMode.off,
    );
    setState(() {});
  }

  Future<void> _takePictureAndProcess() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile image = await _controller!.takePicture();
      
      final inputImage = InputImage.fromFilePath(image.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      final parsedResult = ReceiptParser.parse(recognizedText);

      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ScanReviewScreen(
            imagePath: image.path,
            parsedResult: parsedResult,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi quét hóa đơn: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Colors.white)));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Live Camera
          GestureDetector(
            onTapDown: (details) async {
              if (_controller == null || !_controller!.value.isInitialized) return;
              final RenderBox box = context.findRenderObject() as RenderBox;
              final Offset localPoint = box.globalToLocal(details.globalPosition);
              final double x = localPoint.dx / box.size.width;
              final double y = localPoint.dy / box.size.height;
              try {
                await _controller!.setFocusPoint(Offset(x, y));
              } catch (e) {}
            },
            child: CameraPreview(_controller!),
          ),
          
          // Crop Mask Overlay
          ColorFiltered(
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.srcOut),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    height: 400,
                    width: 300,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 4 White Corners
          CustomPaint(
            painter: CropCornersPainter(),
            child: Container(),
          ),

          // Top Toolbar
          Positioned(
            top: 50,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            top: 50,
            right: 16,
            child: IconButton(
              icon: Icon(
                _isFlashOn ? Icons.flash_on : Icons.flash_off,
                color: _isFlashOn ? Colors.yellow : Colors.white,
                size: 28,
              ),
              onPressed: _toggleFlash,
            ),
          ),

          // Capture Button
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : GestureDetector(
                      onTap: _takePictureAndProcess,
                      child: Container(
                        height: 72,
                        width: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class CropCornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
      
    final rectWidth = 300.0;
    final rectHeight = 400.0;
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: rectWidth,
      height: rectHeight,
    );
    
    final l = 30.0; // length of corner line
    
    // Top Left
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(l, 0), paint);
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(0, l), paint);
    // Top Right
    canvas.drawLine(rect.topRight, rect.topRight + Offset(-l, 0), paint);
    canvas.drawLine(rect.topRight, rect.topRight + Offset(0, l), paint);
    // Bottom Left
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + Offset(l, 0), paint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + Offset(0, -l), paint);
    // Bottom Right
    canvas.drawLine(rect.bottomRight, rect.bottomRight + Offset(-l, 0), paint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + Offset(0, -l), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
