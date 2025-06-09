# Go Cloud Frontend

A modern and responsive Flutter application for attendance management with QR code scanning, admin dashboard, and complete authentication system. Fully compatible with web, mobile, and desktop platforms.

## 📱 App Overview

This Flutter application provides a comprehensive user interface for attendance tracking through QR code scanning, admin management, and user authentication with multiplatform support and responsive design.

### 🚀 Key Features

- **🔐 Complete Authentication**: Login/Register with JWT tokens and name/surname registration
- **📱 QR Code Scanning**: Real-time QR scanning with camera and gallery support
- **👥 Attendance Management**: Full attendance tracking with present/absent/late status
- **🔧 Admin Dashboard**: QR code generation for events with save/share functionality
- **📱 Responsive Design**: Optimized layouts for mobile, tablet and desktop
- **🌐 Web Compatibility**: Fully functional on web browsers
- **🔄 Auto-Refresh Token**: Automatic management of expired token renewal
- **💾 Secure Storage**: Use of Flutter Secure Storage for tokens
- **🎨 Modern UI**: Elegant design with gradients, cards and animations

## 🏗️ Architecture

### 📁 Project Structure

```
lib/
├── main.dart                    # Application entry point
├── models/                      # Data models with JSON serialization
│   ├── attendance.dart          # Attendance tracking model (English)
│   ├── attendance.g.dart        # Auto-generated code
│   ├── auth_response.dart       # Authentication response model
│   ├── auth_response.g.dart     # Auto-generated code
│   ├── auth_log.dart           # Authentication logs model
│   ├── user.dart               # User model
│   └── user.g.dart             # Auto-generated code
├── screens/                     # UI screens
│   ├── dashboard_screen.dart    # Main dashboard (responsive)
│   ├── login_screen.dart       # Login screen (email/password only)
│   ├── register_screen.dart    # Registration screen (with name/surname)
│   ├── qr_scanner_screen.dart  # QR code scanner with camera/gallery
│   ├── admin_qr_page.dart      # Admin QR generation with save/share
│   ├── admin_logs_screen.dart  # Admin authentication logs
│   ├── settings_screen.dart    # User settings
│   └── user_detail_screen.dart # User details
├── services/                    # Business logic
│   ├── auth_service.dart       # Authentication and token management
│   ├── user_service.dart       # User CRUD operations
│   ├── attendance_service.dart # Attendance tracking logic
│   └── log_service.dart        # Authentication logs service
├── utils/                       # Utilities and configurations
│   ├── constants.dart          # App constants
│   └── token_manager.dart      # Legacy token management
└── widgets/                     # Reusable widgets
    ├── custom_text_field.dart  # Custom input field
    ├── responsive_layout.dart  # Responsive layout system
    ├── dashboard/              # Dashboard widgets
    └── qr_scanner/             # QR scanner widgets
```

## 🔧 Backend Configuration

### 🌍 API Endpoints

- **Base URL**: `http://34.140.122.146:3000` (Gateway)
- **Login**: `POST /auth/login`
- **Registration**: `POST /auth/register` (with name/surname)
- **Refresh Token**: `POST /auth/refresh`
- **QR Generation**: `POST /admin/qr/generate` (Admin only)
- **Attendance**: Various endpoints with Bearer authorization
- **User Operations**: Various endpoints with authorization

### 🔐 Authentication System

#### Token Management
- **Access Token**: JWT for API authorization (short duration)
- **Refresh Token**: For renewing access tokens (long duration)
- **Auto-Refresh**: Automatic renewal on 401 Unauthorized
- **Secure Storage**: All tokens saved securely

#### Authentication Flow
1. **Login**: User enters email/password
2. **Registration**: User enters email/password/name/surname
3. **JWT Decode**: Extract user_id and claims from token
4. **Storage**: Secure saving of access_token, refresh_token, user_id
5. **Navigation**: Automatic redirect to dashboard with user_id
6. **Auto-Refresh**: Transparent token renewal management

### 📱 QR Code System

#### QR Generation (Admin)
- **Event Management**: Create QR codes for specific events
- **JWT Integration**: QR codes contain JWT tokens for attendance
- **Expiry Control**: Configurable QR code expiration (hours)
- **Save & Share**: Save to gallery and share QR codes

#### QR Scanning
- **Camera Scanning**: Real-time QR code detection
- **Gallery Import**: Scan QR codes from saved images
- **Attendance Tracking**: Automatic attendance recording
- **Status Management**: Present, Absent, Late status tracking

## 🎨 Responsive Design

### 📱 Mobile Layout
- **ListView**: Touch-optimized vertical lists
- **AppBar**: Standard mobile navigation
- **Card Layout**: Clean and modern design
- **QR Scanner**: Full-screen camera interface

### 🖥️ Desktop Layout  
- **GridView**: Grid layout for large screens
- **Centered Cards**: Cards centered with max-width
- **Gradient Backgrounds**: Elegant gradient backgrounds
- **Admin Dashboard**: Enhanced admin controls

### 🔄 Breakpoint System
- **Mobile**: < 600px width
- **Desktop**: ≥ 600px width
- **Auto-Switch**: Automatic layout switching based on screen size

## 🚀 Setup and Installation

### ✅ Prerequisites
- Flutter SDK ≥ 3.0.0
- Dart ≥ 3.0.0
- Git (for dependency management)
- Android Studio (for mobile development)
- VS Code with Flutter extension (recommended)

### 📦 Dependencies Installation

```powershell
# Navigate to project directory
cd "go-cloud-front-end"

# Install dependencies
flutter pub get

# Generate JSON serialization files
flutter packages pub run build_runner build --delete-conflicting-outputs

# Generate mocks for testing  
flutter packages pub run build_runner build
```

### 🔧 Main Dependencies

```yaml
dependencies:
  flutter: sdk: flutter
  http: ^1.1.0                    # HTTP requests
  flutter_secure_storage: ^9.0.0  # Secure token storage  
  provider: ^6.1.0               # State management
  json_annotation: ^4.9.0        # JSON serialization
  jwt_decoder: ^2.0.1            # JWT token decoding
  qr_code_scanner: ^1.0.1        # QR code camera scanning
  qr_flutter: ^4.1.0             # QR code generation
  qr_code_tools: ^0.2.0          # QR code tools for gallery
  image_picker: ^1.0.4           # Gallery image picking
  permission_handler: ^11.0.1    # Device permissions
  share_plus: ^7.2.1             # System sharing
  path_provider: ^2.1.1          # File system paths
  image_gallery_saver: ^2.0.3    # Save images to gallery
  url_launcher: ^6.2.2           # URL launching

dev_dependencies:
  build_runner: ^2.4.0           # Code generation
  json_serializable: ^6.7.0      # JSON serialization  
  mockito: ^5.4.0               # Testing mocks
  flutter_test: sdk: flutter     # Flutter testing framework
```

## 🌐 Build and Deploy

### 📱 Mobile Build
```powershell
# Android
flutter build apk --release

# iOS  
flutter build ios --release
```

### 🌐 Web Build
```powershell
# Production web build
flutter build web --release

# Local development server
flutter run -d chrome
```

### 🖥️ Desktop Build
```powershell
# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux  
flutter build linux --release
```

## 🧪 Testing

### 🔬 Automated Testing
```powershell
# Run all tests
flutter test

# Test with coverage
flutter test --coverage

# Specific tests
flutter test test/auth_service_test.dart
flutter test test/attendance_service_integration_test.dart
flutter test test/qr_scanner_test.dart
```

### 📋 Test Coverage
- ✅ **AuthService**: Login, register, token refresh, storage
- ✅ **UserService**: CRUD operations with HTTP mocks
- ✅ **AttendanceService**: Attendance tracking with English enums
- ✅ **QR Scanner**: QR code scanning functionality
- ✅ **Widget Tests**: Main UI components

## 🔐 Security

### 🛡️ Implemented Best Practices
- **Secure Storage**: Encrypted token storage
- **JWT Validation**: Automatic token expiry verification
- **Auto-Logout**: Automatic logout on persistent errors
- **HTTPS Communication**: All communications encrypted (when deployed)
- **Input Validation**: Email and password validation
- **Permission Management**: Proper Android/iOS permissions for camera and gallery
- **QR Code Security**: JWT-based QR codes with expiration

## 🎯 Key Features

### 🔑 Authentication
- [x] Login with email/password
- [x] Registration with name/surname fields
- [x] Secure logout
- [x] Persistent session management
- [x] Auto-refresh tokens
- [x] JWT token validation

### 📱 QR Code Management
- [x] Real-time QR scanning with camera
- [x] QR scanning from gallery images
- [x] Admin QR code generation
- [x] Save QR codes to device gallery
- [x] Share QR codes via system dialog
- [x] Event-based QR generation with expiry

### 👤 User Management
- [x] Responsive user list (mobile/desktop)
- [x] User details view
- [x] Current user profile
- [x] Navigation with user_id
- [x] Admin authentication logs

### 📊 Attendance System
- [x] Attendance tracking (Present/Absent/Late)
- [x] QR-based attendance marking
- [x] Attendance form with reason/motivation
- [x] Status management in English
- [x] Integration with backend API

### 🎨 User Experience
- [x] Modern design with Material Design
- [x] Responsive mobile/desktop layouts
- [x] Loading states and visual feedback
- [x] User-friendly error handling
- [x] Intuitive navigation
- [x] Gradient backgrounds and modern UI

## 📚 Useful Resources

### 🔗 Reference Links
- [Flutter Documentation](https://docs.flutter.dev/)
- [Flutter Web Support](https://docs.flutter.dev/platform-integration/web)
- [QR Code Scanner Package](https://pub.dev/packages/qr_code_scanner)
- [QR Flutter Package](https://pub.dev/packages/qr_flutter)
- [JWT.io](https://jwt.io/) - JWT Debugger
- [Material Design](https://material.io/design) - Design Guidelines

### 🆘 Troubleshooting
- **Git PATH Issues**: Use `flutter pub get` instead of `dart pub get`
- **Build Errors**: Clean cache with `flutter clean && flutter pub get`
- **Web Issues**: Verify `flutter config --enable-web` is active
- **Token Issues**: Check JWT format and claims in debugger
- **QR Scanner Issues**: Ensure camera permissions are granted
- **Gallery Issues**: Check photo/storage permissions on device
- **Android Build**: Ensure Android SDK and tools are properly installed

### 🔧 Common Commands
```powershell
# Clean and rebuild
flutter clean
flutter pub get
flutter packages pub run build_runner build --delete-conflicting-outputs

# Check for issues
flutter doctor

# Run on specific device
flutter run -d chrome  # Web
flutter run -d windows # Desktop
flutter run             # Connected mobile device
```

## 👨‍💻 Development

### 🔄 Development Workflow
1. **Feature Branch**: Create branch for new features
2. **Code Generation**: Regenerate code with build_runner
3. **Testing**: Run tests before commit
4. **Build**: Verify build for all target platforms
5. **English Standards**: All code, comments, and models in English

### 📝 Code Conventions
- **Naming**: camelCase for variables, PascalCase for classes
- **Language**: All code and comments in English
- **Comments**: Document public methods
- **Error Handling**: Always handle HTTP exceptions
- **State Management**: Use Provider for global state
- **Model Fields**: Use English field names (reason vs motivazione)

### 🌍 Internationalization
- **Codebase Language**: All code standardized to English
- **Enum Values**: AttendanceStatus uses English values (present, absent, late)
- **Field Names**: All model fields in English for API compatibility
- **Comments**: All documentation and comments in English

---

**🚀 Production-ready app with complete QR attendance system, admin dashboard, and modern responsive design!**
