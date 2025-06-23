import 'package:chat/model/message_model.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';

class SocketService extends ChangeNotifier {
  static final String baseUrl =
      "https://flutter-chat-backend-3073.onrender.com";

  IO.Socket? _socket;
  bool _isConnected = false;
  Map<int, bool> _typingUsers = {};
  bool _isAuthenticated = false;
  bool _isConnecting = false;

  bool get isConnected => _isConnected;
  Map<int, bool> get typingUsers => Map.unmodifiable(_typingUsers);

  // Callbacks for UI updates
  Function(Message)? onNewMessage;
  Function(int userId, bool isOnline)? onUserStatusChanged;

  void updateAuth(bool isAuthenticated) {
    if (kDebugMode) {
      print('SocketService: Auth status changed to $isAuthenticated');
    }

    _isAuthenticated = isAuthenticated;

    if (isAuthenticated && _socket == null && !_isConnecting) {
      _connectWithDelay();
    } else if (!isAuthenticated && _socket != null) {
      disconnect();
    }
  }

  // Add a small delay to ensure auth token is saved
  void _connectWithDelay() {
    Future.delayed(Duration(milliseconds: 500), () {
      if (_isAuthenticated && !_isConnecting) {
        connect();
      }
    });
  }

  void connect() async {
    if (_socket != null || _isConnecting) {
      if (kDebugMode) {
        print('Socket already connected or connecting');
      }
      return;
    }

    _isConnecting = true;

    try {
      // Get the token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        if (kDebugMode) {
          print('No auth token available for socket connection');
        }
        _isConnecting = false;
        return;
      }

      if (kDebugMode) {
        print('Connecting socket with token...');
      }

      _socket = IO.io(
        baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .setExtraHeaders({'Cookie': 'auth_token=$token'})
            .setTimeout(10000)
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(1000)
            .build(),
      );

      _setupSocketEvents();
      _socket!.connect();
    } catch (e) {
      if (kDebugMode) {
        print('Error setting up socket connection: $e');
      }
      _isConnecting = false;
    }
  }

  void _setupSocketEvents() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      if (kDebugMode) {
        print('✅ Socket connected successfully');
      }
      _isConnected = true;
      _isConnecting = false;
      notifyListeners();
    });

    _socket!.onDisconnect((_) {
      if (kDebugMode) {
        print('❌ Socket disconnected');
      }
      _isConnected = false;
      _isConnecting = false;
      notifyListeners();
    });

    _socket!.onConnectError((error) {
      if (kDebugMode) {
        print('❌ Socket connection error: $error');
      }
      _isConnected = false;
      _isConnecting = false;
      notifyListeners();
    });

    _socket!.onError((error) {
      if (kDebugMode) {
        print('❌ Socket error: $error');
      }
    });

    _socket!.on('new_message', (data) {
      if (kDebugMode) {
        print('📨 New message received: $data');
      }
      try {
        final message = Message.fromJson(data);
        onNewMessage?.call(message);
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing new message: $e');
        }
      }
    });

    _socket!.on('message_sent', (data) {
      if (kDebugMode) {
        print('✉️ Message sent confirmation: $data');
      }
      try {
        final message = Message.fromJson(data);
        onNewMessage?.call(message);
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing sent message: $e');
        }
      }
    });

    _socket!.on('user_status', (data) {
      if (kDebugMode) {
        print('👤 User status update: $data');
      }
      try {
        final userId = data['userId'] as int;
        final isOnline = data['online'] as bool;
        onUserStatusChanged?.call(userId, isOnline);
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing user status: $e');
        }
      }
    });

    _socket!.on('user_typing', (data) {
      if (kDebugMode) {
        print('⌨️ User typing: $data');
      }
      try {
        final userId = data['userId'] as int;
        final isTyping = data['isTyping'] as bool;

        _updateTypingStatus(userId, isTyping);
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing typing status: $e');
        }
      }
    });
  }

  void _updateTypingStatus(int userId, bool isTyping) {
    final wasTyping = _typingUsers[userId] ?? false;
    _typingUsers[userId] = isTyping;

    // Only notify listeners if typing status actually changed
    if (wasTyping != isTyping) {
      notifyListeners();
    }

    // Remove typing indicator after 3 seconds
    if (isTyping) {
      Future.delayed(Duration(seconds: 3), () {
        if (_typingUsers[userId] == true) {
          _typingUsers[userId] = false;
          notifyListeners();
        }
      });
    }
  }

  void disconnect() {
    if (kDebugMode) {
      print('Disconnecting socket...');
    }

    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _isConnecting = false;
    _typingUsers.clear();
    notifyListeners();
  }

  void sendMessage(int receiverId, String text) {
    if (_socket != null && _isConnected) {
      if (kDebugMode) {
        print('📤 Sending message to $receiverId: $text');
      }
      _socket!.emit('send_message', {
        'receiverId': receiverId,
        'text': text.trim(),
      });
    } else {
      if (kDebugMode) {
        print('❌ Cannot send message: socket not connected');
      }
    }
  }

  void sendTypingStatus(int receiverId, bool isTyping) {
    if (_socket != null && _isConnected) {
      _socket!.emit('typing', {'receiverId': receiverId, 'isTyping': isTyping});
    }
  }

  bool isUserTyping(int userId) {
    return _typingUsers[userId] ?? false;
  }

  // Force reconnection
  void reconnect() {
    if (_isAuthenticated && !_isConnecting) {
      disconnect();
      Future.delayed(Duration(milliseconds: 1000), () {
        connect();
      });
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
