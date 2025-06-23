import 'package:chat/config/appconfig.dart';
import 'package:chat/model/message_model.dart';
import 'package:chat/model/user_data_model.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
    static final String baseUrl = "https://flutter-chat-backend-3073.onrender.com";
  static const String tokenKey = 'auth_token';

  final Dio _dio = Dio();
  String? _token;

  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isInitialized = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isInitialized => _isInitialized;

  AuthService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);

    // Add token interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_token != null) {
            options.headers['Cookie'] = 'auth_token=$_token';
          }
          handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            // Token expired or invalid
            await _clearToken();
            _isAuthenticated = false;
            _currentUser = null;
            // Don't call notifyListeners here during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              notifyListeners();
            });
          }
          handler.next(e);
        },
      ),
    );

    // Add logging interceptor
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        logPrint: (obj) => print(obj),
      ),
    );

    _initialize();
  }

  Future<void> _initialize() async {
    await _loadToken();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(tokenKey);
      if (_token != null) {
        print('✅ Token loaded from storage');
      }
    } catch (e) {
      print('❌ Error loading token: $e');
    }
  }

  Future<void> _saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(tokenKey, token);
      _token = token;
      print('✅ Token saved to storage');
    } catch (e) {
      print('❌ Error saving token: $e');
    }
  }

  Future<void> _clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(tokenKey);
      _token = null;
      print('✅ Token cleared from storage');
    } catch (e) {
      print('❌ Error clearing token: $e');
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      print('🔐 Attempting login for: $username');
      final response = await _dio.post(
        '/api/login',
        data: {'username': username, 'password': password},
      );

      print('📥 Login response: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final userData = response.data['user'];

        // Extract token from Set-Cookie header
        String? token;
        final cookies = response.headers['set-cookie'];
        if (cookies != null) {
          for (String cookie in cookies) {
            if (cookie.startsWith('auth_token=')) {
              token = cookie.split('auth_token=')[1].split(';')[0];
              break;
            }
          }
        }

        if (token != null) {
          await _saveToken(token);

          _currentUser = User(
            id: userData['id'],
            username: userData['username'],
            name: userData['name'],
          );
          _isAuthenticated = true;
          notifyListeners();
          print('✅ Login successful');
          return true;
        }
      }
      print('❌ Login failed: Invalid response');
      return false;
    } catch (e) {
      print('❌ Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      print('🚪 Logging out...');
      await _dio.post('/api/logout');
    } catch (e) {
      print('❌ Logout error: $e');
    } finally {
      await _clearToken();
      _currentUser = null;
      _isAuthenticated = false;
      notifyListeners();
      print('✅ Logout completed');
    }
  }

  Future<bool> checkAuthStatus() async {
    if (!_isInitialized) {
      return false;
    }

    try {
      print('🔍 Checking auth status...');
      if (_token == null) {
        print('❌ No token available');
        _isAuthenticated = false;
        return false;
      }

      final response = await _dio.get('/api/me');
      print('📥 Auth check response: ${response.data}');

      _currentUser = User(
        id: response.data['id'],
        username: response.data['username'],
        name: response.data['name'],
      );
      _isAuthenticated = true;
      
      // Use post frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      
      print('✅ Auth check successful');
      return true;
    } catch (e) {
      print('❌ Auth check error: $e');
      await _clearToken();
      _isAuthenticated = false;
      _currentUser = null;
      
      // Use post frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      
      return false;
    }
  }

  Future<List<User>> getUsers() async {
    try {
      print('👥 Fetching users...');
      final response = await _dio.get('/api/users');
      final users = (response.data as List)
          .map((user) => User.fromJson(user))
          .toList();
      print('✅ Fetched ${users.length} users');
      return users;
    } catch (e) {
      print('❌ Get users error: $e');
      return [];
    }
  }

  Future<List<Message>> getMessages(int otherUserId) async {
    try {
      print('💬 Fetching messages with user $otherUserId...');
      final response = await _dio.get('/api/messages/$otherUserId');
      final messages = (response.data as List)
          .map((msg) => Message.fromJson(msg))
          .toList();
      print('✅ Fetched ${messages.length} messages');
      return messages;
    } catch (e) {
      print('❌ Get messages error: $e');
      return [];
    }
  }

  Dio get dio => _dio;
}