<p align="center">
  <img src="assets/naqdilogo.jpg" alt="Naqdi Logo" width="120" height="120">
</p>

<h1 align="center">Naqdi - نقدي</h1>

<p align="center">
  <strong>A Modern Point of Sale & Invoice Management Application</strong>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#screenshots">Screenshots</a> •
  <a href="#installation">Installation</a> •
  <a href="#tech-stack">Tech Stack</a> •
  <a href="#license">License</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Android-green.svg" alt="Platform">
  <img src="https://img.shields.io/badge/Flutter-3.1.0+-blue.svg" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.1.0+-blue.svg" alt="Dart">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License">
</p>

---

## 📱 About

Naqdi is a comprehensive Point of Sale (POS) and invoice management solution designed for businesses of all sizes. Built with Flutter, it offers a seamless experience for managing sales, inventory, customers, and billing operations.

---

## ✨ Features

### 🛒 Sales Management
- Create and manage sales transactions
- Generate professional invoices
- Sales history and reporting

### 📦 Inventory Management
- Track product stock levels
- Product categorization
- Low stock alerts

### 👥 Customer Management
- Customer database management
- Purchase history tracking
- Customer analytics

### 💳 Billing & Payments
- QR code scanning for quick billing
- Multiple payment methods
- Receipt generation and printing

### 🏪 Shop Management
- Multi-shop support
- Shop details configuration
- Business settings

### 📊 Reports & Analytics
- Sales reports
- Revenue tracking
- Business insights

### ⚙️ Settings & Configuration
- User management
- Backup and restore
- Printer configuration
- App customization

### 🎁 Donation Tracking
- Track charitable donations
- Donation receipts
- Reporting

---

## 🛠 Tech Stack

<p align="center">
  <!-- Flutter -->
  <a href="https://flutter.dev" target="_blank">
    <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  </a>
  <!-- Dart -->
  <a href="https://dart.dev" target="_blank">
    <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  </a>
  <!-- BLoC -->
  <a href="https://bloclibrary.dev" target="_blank">
    <img src="https://img.shields.io/badge/BLoC-1DA7E0?style=for-the-badge&logo=flutter&logoColor=white" alt="BLoC">
  </a>
  <!-- Hive -->
  <a href="https://docs.hivedb.dev" target="_blank">
    <img src="https://img.shields.io/badge/Hive-FFD700?style=for-the-badge&logo=hive&logoColor=black" alt="Hive">
  </a>
</p>

<p align="center">
  <!-- Go Router -->
  <a href="https://pub.dev/packages/go_router" target="_blank">
    <img src="https://img.shields.io/badge/Go_Router-00B4D8?style=for-the-badge&logo=router&logoColor=white" alt="Go Router">
  </a>
  <!-- PDF -->
  <a href="https://pub.dev/packages/pdf" target="_blank">
    <img src="https://img.shields.io/badge/PDF-EF476F?style=for-the-badge&logo=adobe&logoColor=white" alt="PDF">
  </a>
  <!-- QR Code -->
  <a href="https://pub.dev/packages/pretty_qr_code" target="_blank">
    <img src="https://img.shields.io/badge/QR_Code-06D6A0?style=for-the-badge&logo=qrcode&logoColor=white" alt="QR Code">
  </a>
  <!-- Material Design -->
  <a href="https://material.io" target="_blank">
    <img src="https://img.shields.io/badge/Material_Design-757575?style=for-the-badge&logo=material-design&logoColor=white" alt="Material Design">
  </a>
</p>

### Architecture & State Management
- **BLoC Pattern** - Predictable state management
- **Clean Architecture** - Scalable and maintainable code structure
- **Dependency Injection** - Using GetIt

### Key Dependencies
| Package | Purpose |
|---------|---------|
| `flutter_bloc` | State management |
| `go_router` | Declarative routing |
| `hive_flutter` | Local NoSQL database |
| `pdf` & `printing` | PDF generation and printing |
| `mobile_scanner` | QR/Barcode scanning |
| `pretty_qr_code` | QR code generation |
| `share_plus` | File sharing |
| `image_picker` | Image selection |
| `google_fonts` | Custom typography |
| `intl` | Internationalization |
| `fpdart` | Functional programming |

---

## 📲 Installation

### Prerequisites
- Flutter SDK 3.1.0 or higher
- Dart SDK 3.1.0 or higher
- Android Studio / VS Code

### Clone & Run

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/naqdi.git

# Navigate to the project directory
cd naqdi

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Build APK

```bash
# Build split APKs (recommended for smaller size)
flutter build apk --split-per-abi

# Or build a single universal APK
flutter build apk --release
```

The APKs will be available in `build/app/outputs/flutter-apk/`

---

## 📸 Screenshots

> Coming soon...

---

## 📁 Project Structure

```
lib/
├── config/
│   └── routes/           # App routing configuration
├── core/
│   ├── data/             # Core data layer
│   ├── error/            # Error handling
│   ├── presentation/     # Shared UI components
│   ├── theme/            # App theming
│   ├── usecase/          # Use case base classes
│   ├── utils/            # Utilities and helpers
│   └── widgets/          # Reusable widgets
├── features/
│   ├── auth/             # Authentication module
│   ├── billing/          # Billing & payments
│   ├── customers/        # Customer management
│   ├── donation/         # Donation tracking
│   ├── inventory/        # Inventory management
│   ├── product/          # Product management
│   ├── sales/            # Sales operations
│   ├── settings/         # App settings
│   ├── setup/            # Initial setup
│   ├── shop/             # Shop management
│   └── suppliers/        # Supplier management
└── main.dart             # App entry point
```

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📞 Support

If you encounter any issues or have questions, please open an issue on GitHub.

---

<p align="center">
  Made with ❤️ using Flutter
</p>
