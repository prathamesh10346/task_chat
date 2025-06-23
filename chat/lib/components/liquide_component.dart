import 'package:flutter/material.dart';
import '../theme/liquid_theme.dart';

class LiquidButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final EdgeInsets padding;
  final double borderRadius;

  const LiquidButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    this.borderRadius = 25,
  }) : super(key: key);

  @override
  State<LiquidButton> createState() => _LiquidButtonState();
}

class _LiquidButtonState extends State<LiquidButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onPressed != null ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: widget.onPressed != null ? () => setState(() => _isPressed = false) : null,
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        padding: widget.padding,
        decoration: BoxDecoration(
          gradient: _isPressed
              ? LinearGradient(
                  colors: [
                    LiquidTheme.primaryBlue.withOpacity(0.8),
                    LiquidTheme.primaryPink.withOpacity(0.8),
                  ],
                )
              : LiquidTheme.sunsetGradient,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: [
            BoxShadow(
              color: LiquidTheme.primaryBlue.withOpacity(_isPressed ? 0.2 : 0.3),
              blurRadius: _isPressed ? 8 : 12,
              offset: Offset(0, _isPressed ? 2 : 4),
            ),
          ],
        ),
        child: widget.isLoading
            ? Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              )
            : Center(
                child: Text(
                  widget.text,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
      ),
    );
  }
}

class LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets? margin;
  final EdgeInsets padding;
  final double borderRadius;
  final double opacity;

  const LiquidGlassContainer({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.margin,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 20,
    this.opacity = 0.2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class LiquidChatBubble extends StatelessWidget {
  final String message;
  final bool isOutgoing;
  final DateTime timestamp;

  const LiquidChatBubble({
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
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            decoration: BoxDecoration(
              gradient: isOutgoing
                  ? LinearGradient(
                      colors: [
                        LiquidTheme.primaryBlue,
                        LiquidTheme.primaryBlue.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
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
                  blurRadius: 4,
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
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LiquidTypingIndicator extends StatefulWidget {
  @override
  State<LiquidTypingIndicator> createState() => _LiquidTypingIndicatorState();
}

class _LiquidTypingIndicatorState extends State<LiquidTypingIndicator>
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
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
                dots.padRight(3),
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

class LiquidLoadingShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LiquidLoadingShimmer({
    Key? key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: Colors.white.withOpacity(0.1),
      ),
    );
  }
}

// Optimized input decoration for text fields
class LiquidInputDecoration {
  static InputDecoration getDecoration({
    required String labelText,
    required IconData prefixIcon,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
      prefixIcon: Icon(prefixIcon, color: Colors.white.withOpacity(0.8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.white, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.red.withOpacity(0.5)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.red, width: 2),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
    );
  }
}

// Simple connection status indicator
class LiquidConnectionStatus extends StatelessWidget {
  final bool isConnected;
  final String connectedText;
  final String disconnectedText;

  const LiquidConnectionStatus({
    Key? key,
    required this.isConnected,
    this.connectedText = 'Online',
    this.disconnectedText = 'Offline',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isConnected ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isConnected ? Colors.green : Colors.red).withOpacity(0.3),
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
            isConnected ? connectedText : disconnectedText,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// User avatar with online indicator
class LiquidUserAvatar extends StatelessWidget {
  final String name;
  final bool isOnline;
  final double size;
  final bool showOnlineIndicator;

  const LiquidUserAvatar({
    Key? key,
    required this.name,
    this.isOnline = false,
    this.size = 50,
    this.showOnlineIndicator = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: isOnline 
                ? LiquidTheme.sunsetGradient
                : LinearGradient(colors: [Colors.grey, Colors.grey[400]!]),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isOnline ? LiquidTheme.primaryBlue : Colors.grey)
                    .withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        
        // Online indicator
        if (showOnlineIndicator)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.32,
              height: size * 0.32,
              decoration: BoxDecoration(
                color: isOnline ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}