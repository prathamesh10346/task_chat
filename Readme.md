
This project implements a real-time chat application using Flutter for the frontend and Node.js for the backend, demonstrating:

WebSocket real-time communication
HTTP-only Cookie authentication
Secure session management without storing tokens in Flutter

🚀 Features Implemented
✅ WebSocket Implementation

Real-time messaging between users
Connection status indicators (Online/Offline)
Automatic reconnection on connection loss
Typing indicators
User online/offline status

✅ HTTP-only Cookie Authentication

Secure login with username/password
HTTP-only cookies for session management
No tokens stored in Flutter app
Automatic cookie handling for API requests
Secure logout with session cleanup

🛠️ Technology Stack
Frontend (Flutter)

socket_io_client: WebSocket communication
dio: HTTP requests with automatic cookie handling
provider: State management
shared_preferences: Local storage for non-sensitive data

Backend (Node.js)

Express.js: Web server framework
Socket.IO: WebSocket server
JWT: Token generation for HTTP-only cookies
bcryptjs: Password hashing
cookie-parser: Cookie handling

📱 Installation & Setup
Prerequisites

Flutter SDK (>=3.0.0)
Node.js (>=16.0.0)
Dart SDK
Android Studio / VS Code

Backend Setup
bashcd backend
npm install
npm start
# Server runs on http://localhost:3000
Flutter Setup
bashcd flutter_app
flutter pub get
flutter run
🔐 Demo Credentials

User 1: username: user1, password: password1
User 2: username: user2, password: password2
User 3: username: user3, password: password3
User 4: username: user4, password: password4
