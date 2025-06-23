import 'package:chat/model/user_data_model.dart';
import 'package:chat/screens/auth/login_screen.dart';
import 'package:chat/screens/chat/chat_list_room.dart';
import 'package:chat/screens/chat/chat_screen.dart';
import 'package:chat/services%20/auth_service.dart';
import 'package:chat/services%20/websocket_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/liquid_theme.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProxyProvider<AuthService, SocketService>(
          create: (_) => SocketService(),
          update: (_, auth, socket) {
            socket?.updateAuth(auth.isAuthenticated);
            return socket ?? SocketService();
          },
        ),
      ],
      child: LiquidChatApp(),
    ),
  );
}

class LiquidChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LiquidChat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'System',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: LiquidAuthWrapper(),
      routes: {
        '/login': (context) => LiquidLoginScreen(),
        '/chat-list': (context) => LiquidChatListScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/chat') {
          final User otherUser = settings.arguments as User;
          return MaterialPageRoute(
            builder: (context) => LiquidChatScreen(otherUser: otherUser),
          );
        }
        return null;
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class LiquidAuthWrapper extends StatefulWidget {
  @override
  State<LiquidAuthWrapper> createState() => _LiquidAuthWrapperState();
}

class _LiquidAuthWrapperState extends State<LiquidAuthWrapper> {
  bool _isCheckingAuth = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Wait for auth service to initialize
    while (!authService.isInitialized) {
      await Future.delayed(Duration(milliseconds: 100));
    }
    
    final isAuthenticated = await authService.checkAuthStatus();
    
    if (mounted) {
      setState(() {
        _isAuthenticated = isAuthenticated;
        _isCheckingAuth = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        if (_isCheckingAuth || !authService.isInitialized) {
          return _buildLoadingScreen();
        }

        // Listen to auth state changes
        if (authService.isAuthenticated != _isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _isAuthenticated = authService.isAuthenticated;
            });
          });
        }

        return _isAuthenticated ? LiquidChatListScreen() : LiquidLoginScreen();
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LiquidTheme.oceanGradient,
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LiquidTheme.sunsetGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: LiquidTheme.primaryBlue.withOpacity(0.3),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                
                SizedBox(height: 24),
                
                // App Title
                Text(
                  'LiquidChat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                SizedBox(height: 12),
                
                // Loading indicator
                SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Status text
                Text(
                  'Initializing...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Error handling wrapper
class LiquidErrorHandler extends StatelessWidget {
  final Widget child;
  final String? error;
  final VoidCallback? onRetry;

  const LiquidErrorHandler({
    Key? key,
    required this.child,
    this.error,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LiquidTheme.oceanGradient,
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 80,
                      color: Colors.red[300],
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Connection Error',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      error!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (onRetry != null) ...[
                      SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: onRetry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text('Retry'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    return child;
  }
}