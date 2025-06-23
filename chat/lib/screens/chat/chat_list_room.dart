import 'package:chat/components/liquide_component.dart';
import 'package:chat/services%20/auth_service.dart';
import 'package:chat/services%20/websocket_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../model/user_data_model.dart';
import '../../theme/liquid_theme.dart';

class LiquidChatListScreen extends StatefulWidget {
  @override
  _LiquidChatListScreenState createState() => _LiquidChatListScreenState();
}

class _LiquidChatListScreenState extends State<LiquidChatListScreen> {
  List<User> _users = [];
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    
    socketService.onUserStatusChanged = (userId, isOnline) {
      if (mounted) {
        setState(() {
          final userIndex = _users.indexWhere((u) => u.id == userId);
          if (userIndex != -1) {
            _users[userIndex].isOnline = isOnline;
          }
        });
      }
    };
  }

  Future<void> _loadUsers() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final users = await authService.getUsers();
      
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _loadUsers();
  }

  Future<void> _logout() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      // Handle logout error
      print('Logout error: $e');
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              child: Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final socketService = Provider.of<SocketService>(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LiquidTheme.oceanGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              _buildAppBar(authService, socketService),
              
              // Current User Card
              _buildCurrentUserCard(authService),
              
              // Users List
              Expanded(
                child: _isLoading ? _buildLoadingIndicator() : _buildUsersList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(AuthService authService, SocketService socketService) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          Text(
            'LiquidChat',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          Spacer(),
          
          // Connection Status
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: socketService.isConnected ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (socketService.isConnected ? Colors.green : Colors.red)
                      .withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  socketService.isConnected ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(width: 12),
          
          // Logout Button
          GestureDetector(
            onTap: _showLogoutConfirmation,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.logout,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentUserCard(AuthService authService) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: LiquidGlassContainer(
        borderRadius: 20,
        opacity: 0.3,
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LiquidTheme.sunsetGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: LiquidTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  authService.currentUser?.name.isNotEmpty == true 
                      ? authService.currentUser!.name[0].toUpperCase() 
                      : '?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    authService.currentUser?.name ?? 'User',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
          SizedBox(height: 16),
          Text(
            'Loading users...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.white.withOpacity(0.5),
            ),
            SizedBox(height: 16),
            Text(
              'No users available',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 18,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      backgroundColor: Colors.white.withOpacity(0.9),
      color: LiquidTheme.primaryBlue,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return _buildUserTile(user);
        },
      ),
    );
  }

  Widget _buildUserTile(User user) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/chat',
              arguments: user,
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: LiquidGlassContainer(
            borderRadius: 20,
            opacity: 0.2,
            child: Row(
              children: [
                // Avatar with online indicator
                Stack(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: user.isOnline 
                            ? LiquidTheme.sunsetGradient
                            : LinearGradient(colors: [Colors.grey, Colors.grey[400]!]),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (user.isOnline ? LiquidTheme.primaryBlue : Colors.grey)
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    // Online indicator
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: user.isOnline ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(width: 16),
                
                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: user.isOnline ? Colors.green : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            user.isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Arrow
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.5),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}