import 'package:chat/components/liquide_component.dart';
import 'package:chat/services%20/auth_service.dart';
import 'package:chat/services%20/websocket_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/message_model.dart';
import '../../model/user_data_model.dart';
import '../../theme/liquid_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LiquidChatScreen extends StatefulWidget {
  final User otherUser;

  LiquidChatScreen({required this.otherUser});

  @override
  _LiquidChatScreenState createState() => _LiquidChatScreenState();
}

class _LiquidChatScreenState extends State<LiquidChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isTyping = false;
  DateTime? _lastTypingTime;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupSocketListeners();
    
    // Auto-scroll when keyboard appears
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        Future.delayed(Duration(milliseconds: 300), () {
          _scrollToBottom();
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _setupSocketListeners() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    
    socketService.onNewMessage = (message) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUserId = authService.currentUser?.id;
      
      if ((message.senderId == currentUserId && 
           message.receiverId == widget.otherUser.id) ||
          (message.senderId == widget.otherUser.id && 
           message.receiverId == currentUserId)) {
        if (mounted) {
          setState(() {
            final exists = _messages.any((m) => m.id == message.id);
            if (!exists) {
              _messages.add(message);
              _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
            }
          });
          _scrollToBottom();
        }
      }
    };
  }

  Future<void> _loadMessages() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final messages = await authService.getMessages(widget.otherUser.id);
      
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && mounted) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.sendMessage(widget.otherUser.id, text);
    
    _messageController.clear();
    _handleTyping(false);
    _scrollToBottom();
  }

  void _handleTyping(bool isTyping) {
    final socketService = Provider.of<SocketService>(context, listen: false);
    final now = DateTime.now();
    
    if (isTyping && (_lastTypingTime == null || 
        now.difference(_lastTypingTime!).inSeconds > 2)) {
      socketService.sendTypingStatus(widget.otherUser.id, true);
      _lastTypingTime = now;
      _isTyping = true;
    } else if (!isTyping && _isTyping) {
      socketService.sendTypingStatus(widget.otherUser.id, false);
      _isTyping = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final socketService = Provider.of<SocketService>(context);
    final currentUserId = authService.currentUser?.id;
    final isOtherUserTyping = socketService.isUserTyping(widget.otherUser.id);
    
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LiquidTheme.oceanGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              _buildAppBar(socketService, isOtherUserTyping),
              
              // Messages Area
              Expanded(
                child: _isLoading 
                    ? _buildLoadingIndicator() 
                    : _buildMessagesList(currentUserId, isOtherUserTyping),
              ),
              
              // Input Area
              _buildInputArea(socketService),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(SocketService socketService, bool isOtherUserTyping) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          
          SizedBox(width: 16),
          
          // User Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LiquidTheme.sunsetGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: LiquidTheme.primaryBlue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.otherUser.name.isNotEmpty ? widget.otherUser.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          SizedBox(width: 12),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUser.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 200),
                  child: isOtherUserTyping
                      ? Text(
                          'typing...',
                          key: Key('typing'),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      : Text(
                          socketService.isConnected ? 'Online' : 'Offline',
                          key: Key('status'),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                ),
              ],
            ),
          ),
          
          // Connection Status
          if (!socketService.isConnected)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Reconnecting...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ),
        ],
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
            'Loading messages...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(int? currentUserId, bool isOtherUserTyping) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(20),
      itemCount: _messages.length + (isOtherUserTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _messages.length) {
          final message = _messages[index];
          final isOutgoing = message.senderId == currentUserId;
          
          return OptimizedChatBubble(
            message: message.text,
            isOutgoing: isOutgoing,
            timestamp: message.timestamp,
          );
        } else {
          // Typing indicator
          return OptimizedTypingIndicator();
        }
      },
    );
  }

  Widget _buildInputArea(SocketService socketService) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          // Text Input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
                textInputAction: TextInputAction.send,
                onChanged: (text) {
                  _handleTyping(text.isNotEmpty);
                },
                onSubmitted: (_) => _sendMessage(),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          
          SizedBox(width: 12),
          
          // Send Button
          GestureDetector(
            onTap: socketService.isConnected ? _sendMessage : null,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: socketService.isConnected 
                    ? LiquidTheme.sunsetGradient
                    : LinearGradient(colors: [Colors.grey, Colors.grey]),
                shape: BoxShape.circle,
                boxShadow: socketService.isConnected ? [
                  BoxShadow(
                    color: LiquidTheme.primaryBlue.withOpacity(0.4),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ] : [],
              ),
              child: Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Optimized Chat Bubble without heavy animations
class OptimizedChatBubble extends StatelessWidget {
  final String message;
  final bool isOutgoing;
  final DateTime timestamp;

  const OptimizedChatBubble({
    Key? key,
    required this.message,
    required this.isOutgoing,
    required this.timestamp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        left: isOutgoing ? 50 : 0,
        right: isOutgoing ? 0 : 50,
        bottom: 8,
      ),
      child: Column(
        crossAxisAlignment: isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isOutgoing
                  ? LinearGradient(
                      colors: [
                        LiquidTheme.primaryBlue,
                        LiquidTheme.primaryBlue.withOpacity(0.8),
                      ],
                    )
                  : null,
              color: isOutgoing ? null : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(isOutgoing ? 20 : 5),
                bottomRight: Radius.circular(isOutgoing ? 5 : 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              message,
              style: TextStyle(
                color: isOutgoing ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
          ),
          SizedBox(height: 4),
          Text(
            '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// Optimized Typing Indicator
class OptimizedTypingIndicator extends StatefulWidget {
  @override
  State<OptimizedTypingIndicator> createState() => _OptimizedTypingIndicatorState();
}

class _OptimizedTypingIndicatorState extends State<OptimizedTypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 50, bottom: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(5),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'typing',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              String dots = '';
              int dotCount = ((_controller.value * 3) % 3).floor() + 1;
              for (int i = 0; i < dotCount; i++) {
                dots += '.';
              }
              return Text(
                dots,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}