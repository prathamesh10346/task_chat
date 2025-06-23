import 'package:chat/components/liquide_component.dart';
import 'package:chat/services%20/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../theme/liquid_theme.dart';

class LiquidLoginScreen extends StatefulWidget {
  @override
  _LiquidLoginScreenState createState() => _LiquidLoginScreenState();
}

class _LiquidLoginScreenState extends State<LiquidLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (success) {
        Navigator.pushReplacementNamed(context, '/chat-list');
      } else {
        setState(() {
          _errorMessage = 'Invalid username or password';
        });
      }
    }
  }

  void _fillDemoCredentials(String username, String password) {
    _usernameController.text = username;
    _passwordController.text = password;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LiquidTheme.oceanGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                          MediaQuery.of(context).padding.top - 
                          MediaQuery.of(context).padding.bottom - 48,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Title
                    Text(
                      'LiquidChat',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ).animate().fadeIn(duration: 800.ms).scale(
                      begin: Offset(0.8, 0.8),
                      curve: Curves.easeOutBack,
                    ),

                    SizedBox(height: 16),

                    Text(
                      'Fluid conversations, seamless connections',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 200.ms, duration: 600.ms),

                    SizedBox(height: 60),

                    // Login Form
                    LiquidGlassContainer(
                      borderRadius: 25,
                      opacity: 0.2,
                      child: Column(
                        children: [
                          // Username Field
                          _buildTextField(
                            controller: _usernameController,
                            label: 'Username',
                            icon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter username';
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 20),

                          // Password Field
                          _buildTextField(
                            controller: _passwordController,
                            label: 'Password',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter password';
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 30),

                          // Error Message
                          AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            height: _errorMessage != null ? null : 0,
                            child: _errorMessage != null
                                ? Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(12),
                                    margin: EdgeInsets.only(bottom: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(color: Colors.red[300]),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : SizedBox.shrink(),
                          ),

                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            child: LiquidButton(
                              text: 'Sign In',
                              isLoading: _isLoading,
                              onPressed: _isLoading ? null : _login,
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms, duration: 600.ms),

                    SizedBox(height: 40),

                    // Demo Credentials
                    LiquidGlassContainer(
                      borderRadius: 20,
                      opacity: 0.15,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Demo Credentials:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 12),
                          _buildCredentialRow('User 1', 'user1', 'password1'),
                          SizedBox(height: 8),
                          _buildCredentialRow('User 2', 'user2', 'password2'),
                          SizedBox(height: 8),
                          _buildCredentialRow('User 3', 'user3', 'password3'),
                        ],
                      ),
                    ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.8)),
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
      ),
      validator: validator,
      textInputAction: isPassword ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: (_) {
        if (!isPassword) {
          FocusScope.of(context).nextFocus();
        } else {
          _login();
        }
      },
    );
  }

  Widget _buildCredentialRow(String label, String username, String password) {
    return InkWell(
      onTap: () => _fillDemoCredentials(username, password),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$label:',
                style: TextStyle(color: Colors.white.withOpacity(0.9)),
              ),
            ),
            Text(
              '$username / $password',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.touch_app,
              size: 16,
              color: Colors.white.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}