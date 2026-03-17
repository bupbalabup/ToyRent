# Flutter Frontend - Setup & Installation Guide

## 🔄 Quick Start (5 minutes)

### 1. Prerequisites
```bash
# Check Flutter installation
flutter --version

# Check Dart
dart --version

# Ensure device/emulator is running
flutter devices
```

### 2. Install Dependencies
```bash
cd FE
flutter pub get
```

### 3. Configure Backend URL

Edit **lib/config/api_config.dart**:

```dart
// For Android Emulator (local backend)
static const String _baseUrlAndroid = 'http://10.0.2.2:5000/api';

// For iOS Simulator
static const String _baseUrlIOS = 'http://127.0.0.1:5000/api';

// For Physical Device
static const String _baseUrlAndroid = 'http://192.168.1.100:5000/api';
```

### 4. Run the App
```bash
# Clean build
flutter clean
flutter pub get

# Run
flutter run

# Or with specific device
flutter run -d emulator-5554  # Android
flutter run -d iphone         # iOS
```

---

## 📲 Device-Specific Configuration

### Android Emulator
```
Base URL: http://10.0.2.2:5000/api
Reason: Special alias to access host machine from emulator
```

### iOS Simulator
```
Base URL: http://127.0.0.1:5000/api
Reason: Direct localhost access
```

### Physical Device (Wi-Fi)
```
1. Find your computer's IP:
   - Windows: ipconfig | findstr IPv4
   - Mac/Linux: ifconfig | grep inet

2. Update config:
   static const String _baseUrlAndroid = 'http://192.168.1.100:5000/api';

3. Ensure device is on same network as backend
4. Backend must be accessible: ping 192.168.1.100
```

---

## 🧪 Test the Login

### Test Credentials
Use any user from your MongoDB database. Example:
```
Email: test@example.com
Password: password123
```

Or create a test user via the register endpoint first.

### Expected Flow
1. ✅ Enter email & password
2. ✅ Button becomes enabled
3. ✅ Click "Sign In"
4. ✅ Shows loading spinner
5. ✅ On success: Navigate to home (TODO: implement)
6. ✅ On error: Shows error message

### Common Errors & Fixes

| Error | Cause | Solution |
|-------|-------|----------|
| Connection refused | Backend not running | `npm start` in BE folder |
| Connection timeout | Wrong IP/port | Check `api_config.dart` |
| Invalid credentials | Wrong email/password | Use correct test credentials |
| CORS error | Backend CORS not configured | Add CORS middleware in Express |
| JSON parsing error | Backend response format | Check backend returns correct structure |

---

## 📁 Project Structure

```
FE/
├── lib/
│   ├── main.dart                 ← App entry point
│   ├── config/
│   │   ├── api_config.dart       ← Backend URL & Dio setup
│   │   ├── theme.dart            ← Global theme & styles
│   │   └── constants.dart        ← App-wide constants
│   ├── screens/
│   │   └── login_screen.dart     ← Beautiful login UI
│   ├── services/
│   │   └── auth_service.dart     ← API calls (Dio)
│   ├── providers/
│   │   └── auth_provider.dart    ← State management (Provider)
│   └── utils/
│       ├── helpers.dart          ← Validation & UI helpers
│       └── extensions.dart       ← Dart extensions
├── pubspec.yaml                  ← Dependencies
├── README.md                      ← Overview
└── SETUP.md                       ← This file
```

---

## 🔧 Key Files Reference

### lib/config/api_config.dart
- Configure backend URL
- Setup Dio interceptors
- Handle logging

### lib/services/auth_service.dart
- Login API call
- Error handling
- Response parsing

### lib/providers/auth_provider.dart
- Store user data
- Manage login state
- Save token to SharedPreferences

### lib/screens/login_screen.dart
- Beautiful UI
- Form validation
- Error display
- Loading animation

---

## 🚀 Production Checklist

- [ ] ✅ Update backend URL for production
- [ ] ✅ Use flutter_secure_storage for token (not SharedPreferences)
- [ ] ✅ Implement refresh token logic
- [ ] ✅ Add certificate pinning for HTTPS
- [ ] ✅ Implement proper error logging
- [ ] ✅ Test on physical device
- [ ] ✅ Build release APK/IPA
- [ ] ✅ Implement home screen
- [ ] ✅ Add deep linking
- [ ] ✅ Setup analytics

---

## 🐛 Debugging Tips

### Enable Dio Logging
```dart
// In lib/config/api_config.dart
// Interceptors already enabled - watch console for logs
```

### Print Response
```dart
// In lib/services/auth_service.dart
print('Response: ${response.data}');
```

### Check SharedPreferences
```bash
# In Flutter console
flutter run
# Then type: i (hot restart)
```

### Network Debugging
```bash
# Check if backend is reachable
curl http://192.168.1.100:5000/api/auth/login \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"password"}'
```

---

## 📚 Useful Flutter Commands

```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade

# Format code
dart format lib/

# Analyze code
dart analyze

# Build APK
flutter build apk

# Build iOS
flutter build ios

# Run tests
flutter test
```

---

## 🔗 Dependencies Overview

| Package | Purpose | Version |
|---------|---------|---------|
| provider | State management | ^6.1.0 |
| dio | HTTP client | ^5.4.0 |
| shared_preferences | Local storage | ^2.2.2 |
| flutter_animate | Smooth animations | ^4.5.0 |
| google_fonts | Premium fonts | ^6.1.0 |

---

## ✅ Next Steps

1. **Register Screen** - Create `screens/register_screen.dart`
2. **Home Screen** - Create `screens/home_screen.dart`
3. **Navigation** - Setup routing between screens
4. **Security** - Replace SharedPreferences with flutter_secure_storage
5. **Error Handling** - Create `services/error_handler.dart`
6. **Tokens** - Implement refresh token logic

---

## 📞 Support

If you encounter issues:

1. Check backend is running: `http://localhost:5000`
2. Verify credentials in database
3. Check network connectivity
4. Review console logs in Flutter
5. Enable Dio logging for API debugging

---

**Last Updated:** March 22, 2026
