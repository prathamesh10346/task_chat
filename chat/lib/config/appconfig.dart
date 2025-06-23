import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;

class AppConfig {
  // 🚀 Replace this with your Render URL after deployment
  static const String _renderUrl =
      'https://flutter-chat-backend-3073.onrender.com';

  static String get baseUrl {
    // For production/testing on real devices, use Render URL
    if (kReleaseMode || const bool.fromEnvironment('USE_PRODUCTION')) {
      return _renderUrl;
    }

    // For local development
    if (kIsWeb) {
      return 'http://localhost:3000';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000'; // Android emulator
    } else if (Platform.isIOS) {
      return 'http://localhost:3000'; // iOS simulator
    } else {
      return 'http://localhost:3000';
    }
  }

  // Easy way to force production URL for testing
}
