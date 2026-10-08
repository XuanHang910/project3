import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'screens/dashboard_screen.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized before accessing native plugins
  WidgetsFlutterBinding.ensureInitialized();
  
  // Get list of available cameras on the device
  List<CameraDescription> cameras = [];
  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint('Không thể khởi tạo camera: $e');
  }

  runApp(ExpenseTrackerApp(cameras: cameras));
}

class ExpenseTrackerApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const ExpenseTrackerApp({Key? key, required this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OCR Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA), // Nền xám khói nhẹ
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 4,
        ),
      ),
      home: DashboardScreen(cameras: cameras),
    );
  }
}

