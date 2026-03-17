# RentToys Flutter Frontend

Production-grade mobile app for toy rental platform with beautiful, premium login screen.

## 🎯 Features

- ✅ Beautiful light-theme login UI (premium style)
- ✅ JWT authentication with token persistence
- ✅ Form validation with real-time feedback
- ✅ Smooth animations and transitions
- ✅ Provider-based state management
- ✅ Dio HTTP client with interceptors
- ✅ Error handling with user-friendly messages
- ✅ LocalStorage via SharedPreferences

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── config/
│   └── api_config.dart       # Base URL & Dio configuration
├── screens/
│   └── login_screen.dart     # Login UI (premium design)
├── services/
│   └── auth_service.dart     # API calls (Dio client)
└── providers/
    └── auth_provider.dart    # State management (Provider)
```

## 🚀 Getting Started

### Prerequisites
- Flutter 3.0+
- Dart 3.0+
- Active backend server (see Backend Setup)

### Installation

```bash
# Navigate to FE folder
cd FE

# Get dependencies
flutter pub get

# Run the app
flutter run
```

## 🔧 Configuration

### Backend API URL

Update `lib/config/api_config.dart`:

```dart
static const String _baseUrlAndroid = 'http://YOUR_BACKEND_IP:5000/api';
static const String _baseUrlIOS = 'http://YOUR_BACKEND_IP:5000/api';
```

**For Android Emulator (local backend):**
```
http://10.0.2.2:5000/api
```

**For iOS Simulator (local backend):**
```
http://127.0.0.1:5000/api
```

**For Physical Device:**
```
http://YOUR_COMPUTER_IP:5000/api  # e.g., 192.168.1.100:5000/api
```

## 📱 Backend Integration

### API Endpoints Used

**Login Endpoint:**
- Method: `POST`
- Path: `/api/auth/login`
- Body:
  ```json
  {
    "email": "user@example.com",
    "password": "password123"
  }
  ```

**Success Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "_id": "userId",
      "name": "User Name",
      "email": "user@example.com",
      "phone": "+1234567890"
    },
    "token": "eyJhbGc..."
  }
}
```

**Error Response:**
```json
{
  "success": false,
  "message": "Invalid credentials",
  "data": {}
}
```

## 🎨 Design System

### Colors
- **Primary:** `#FF6600` (Premium Orange)
- **Secondary:** `#FF8A00` (Light Orange)
- **Background:** `#FFFFFF` (Clean White)
- **Surface:** `#F8F9FB` (Light Gray)
- **Text:** `#1A1A1A` (Dark Gray)

### Typography
- **Header:** 28px, Bold (700)
- **Labels:** 12px, Semi-bold (600)
- **Body:** 14px, Medium (500)

## 🔐 Authentication Flow

1. User enters email & password
2. Form validation (client-side)
3. HTTP POST to `/api/auth/login`
4. Backend validates credentials
5. Token + User data returned
6. Token stored in SharedPreferences
7. User state updated via Provider
8. Navigate to home screen (TODO)

## 📦 Dependencies

- **provider:** State management
- **dio:** HTTP client with interceptors
- **shared_preferences:** Local storage
- **flutter_animate:** Smooth animations
- **google_fonts:** Premium typography

## ⚙️ State Management (Provider)

### AuthProvider Usage

```dart
// Read state
final authProvider = Provider.of<AuthProvider>(context, listen: false);

// Check if logged in
if (authProvider.isLoggedIn) { ... }

// Get token
String token = authProvider.token ?? '';

// Get user info
String name = authProvider.user?.name ?? '';

// Login
bool success = await authProvider.login(
  email: 'user@example.com',
  password: 'password123',
);

// Logout
await authProvider.logout();

// Error message
String? error = authProvider.errorMessage;
```

## 🧪 Testing the App

### Test Login Credentials

Use credentials from your backend database:

```
Email: test@example.com
Password: password123
```

### Debug Tips

1. Check backend logs for API errors
2. Enable Dio logging in `api_config.dart`
3. Verify network connection
4. Check SharedPreferences data with devtools

## 🚀 Next Steps

1. ✅ Replace placeholder logo with actual logo
2. ✅ Create register screen
3. ✅ Create home screen
4. ✅ Add navigation between screens
5. ✅ Implement refresh token logic
6. ✅ Add more authentication states (forgot password, etc.)

## 📝 Notes

- Tokens are stored in SharedPreferences (not secure for production - consider using flutter_secure_storage)
- Email validation uses regex pattern
- Password minimum length: 6 characters
- All API errors are mapped to user-friendly messages
- Loading state prevents multiple submissions

## 🔗 Backend Setup

Ensure your Node.js backend is running:

```bash
cd ../BE
npm install
npm start
# Backend runs on http://localhost:5000
```

Backend must have:
- MongoDB connection configured
- JWT_SECRET in .env
- All auth routes implemented

---

**Built with ❤️ for production use**
