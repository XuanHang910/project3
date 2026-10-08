# 🧾 OCR Expense Tracker & Receipt Parser (Mini-Project 3)

A personal finance management application built with **Flutter 3.x** and **Google ML Kit**. This app allows users to scan physical supermarket receipts, automatically extract the highest monetary total using an on-device OCR regex heuristic engine, and visualize spending categories using custom-drawn canvas charts.

---

## ✨ Features

1. **📷 Camera Capture & Crop Overlay:**
   - Real-time camera viewfinder with tap-to-focus and flash toggle.
   - 4-corner crop overlay mask to guide users in framing the receipt perfectly.
   
2. **🧠 On-Device Text Recognition (OCR) & Regex Heuristics:**
   - Integrates `google_mlkit_text_recognition` for sub-100ms, completely offline text extraction.
   - Built-in `ReceiptParser` using heuristics and regex to identify Vietnamese currency formats (e.g., `150,000 VND`, `150.000 đ`, `150k`) and extract the largest value as the **Total Amount**.
   - Interactive Scan Review screen to manually verify and assign categories.

3. **💾 Local Database & Caching:**
   - Persists all transactions using `sqflite`.
   - Categories included: Food, Study, Travel, Gear, Entertainment.
   - Caches receipt thumbnail images to the application document directory using `path_provider`.

4. **📊 Custom Canvas Visualizations (`CustomPainter`):**
   - **Donut Chart:** Animated pie chart indicating spending distribution across categories.
   - **Weekly Bar Chart:** Auto-scaling bar chart showing spending across the last 7 days.
   - Fully custom-drawn using `Canvas` API (0 third-party charting libraries used) with 1.2s smooth animations.

---

## 🏗️ Architecture & Project Structure

The project follows a modular and clean architecture for scalability:

```text
lib/
 ├── main.dart                  # App entry point, Material 3 Theme setup
 ├── screens/                   
 │   ├── dashboard_screen.dart  # Home screen with charts and recent transactions
 │   ├── camera_scanner_screen.dart # Camera UI and ML Kit integration
 │   └── scan_review_screen.dart    # Review OCR results and save transaction
 ├── widgets/                   
 │   ├── donut_chart.dart       # CustomPainter for Animated Donut Chart
 │   └── weekly_bar_chart.dart  # CustomPainter for Animated Bar Chart
 ├── utils/                     
 │   └── receipt_parser.dart    # Core regex logic to clean and extract currency
 └── models/
     └── transaction.dart       # Data model (if separated)
```

---

## 🚀 Setup Instructions

### Prerequisites
- Flutter SDK `^3.x.x`
- Dart SDK `^3.x.x`
- Android Studio / VS Code with Flutter extensions.
- An Android physical device (API 21+) or Emulator.

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/XuanHang910/project3.git
   cd project3
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the application:**
   ```bash
   flutter run
   ```
   *(Note: For the Camera functionality to work properly, it is highly recommended to run this on a physical device).*

### Build Release APK

To generate a standalone APK for deployment/submission:
```bash
flutter build apk --release
```
The resulting APK will be located at:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 🛠️ Built With

* **[Flutter](https://flutter.dev/)** - UI Toolkit
* **[sqflite](https://pub.dev/packages/sqflite)** - SQLite plugin for Flutter
* **[camera](https://pub.dev/packages/camera)** - For on-device camera control
* **[google_mlkit_text_recognition](https://pub.dev/packages/google_mlkit_text_recognition)** - On-device ML OCR
* **[path_provider](https://pub.dev/packages/path_provider)** - Finding local paths for image storage

---
**Course:** Cross-Platform Mobile App Development (VKU)
