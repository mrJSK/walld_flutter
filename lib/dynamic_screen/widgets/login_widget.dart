// lib/dynamic_screen/widgets/login_widget.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:walld_flutter/core/wallpaper_service.dart';

import '../../workspace/workspace_controller.dart';
import '../../workspace/workspace_shell.dart';

class LoginWidget extends StatefulWidget {
  const LoginWidget({super.key});

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> signIn() async {
  if (!(_formKey.currentState?.validate() ?? false)) return;

  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    debugPrint('[LOGIN] ✅ Signed in as ${cred.user?.uid}');

    if (!mounted) return;

    // Navigate to WorkspaceShell after successful login
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => WorkspaceShell(
          workspaceController: WorkspaceController(),
        ),
      ),
    );
  } on FirebaseAuthException catch (e) {
    debugPrint('[LOGIN] ❌ error: ${e.code} ${e.message}');
    setState(() {
      _errorMessage = _getErrorMessage(e.code);
    });
  } catch (e) {
    debugPrint('[LOGIN] ❌ unknown error: $e');
    setState(() {
      _errorMessage = 'Unexpected error. Please try again.';
    });
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}


  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found. Please register first.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Invalid email format.';
      case 'user-disabled':
        return 'Account disabled. Contact admin.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return 'Login failed. Please try again.';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  return AnimatedBuilder(
    animation: WallpaperService.instance,
    builder: (context, _) {
      final ws = WallpaperService.instance;

      // Glass color derived from global glass opacity
      final Color bgColor = const Color(0xFF11111C)
          .withOpacity((ws.globalGlassOpacity * 3).clamp(0.05, 0.45));

      return LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          final maxH = constraints.maxHeight;
          final shortest = math.min(maxW, maxH);

          // When the box is short, compress everything a bit
          final double compress =
              shortest < 360 ? 0.85 : (shortest < 420 ? 0.92 : 1.0);

          final double unit = (shortest / 11.0).clamp(10.0, 32.0) * compress;
          final double radius = (unit * 0.9).clamp(12.0, 24.0);
          final double margin = (unit * 0.22).clamp(6.0, 14.0);
          final EdgeInsets padding =
              EdgeInsets.all((unit * 0.65 * compress).clamp(8.0, 20.0));

          final double titleFont = (unit * 1.1).clamp(18.0, 26.0);
          final double subtitleFont = (unit * 0.72).clamp(11.0, 16.0);
          final double fieldFont = (unit * 0.80).clamp(12.0, 18.0);
          final double smallFont = (unit * 0.70).clamp(10.0, 14.0);
          final double gap = (unit * 0.40 * compress).clamp(4.0, 12.0);
          final double fieldVerticalPad =
              (unit * 0.30 * compress).clamp(4.0, 8.0);
          final double fieldRadius = (unit * 0.55).clamp(8.0, 14.0);

          // ✅ Wrap in Material + SingleChildScrollView
          return Material(
            type: MaterialType.transparency,
            child: Container(
              margin: EdgeInsets.all(margin),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: const Color(0x22FFFFFF)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              padding: padding,
              child: SingleChildScrollView(  // ✅ Make scrollable
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo
                      const Icon(
                        Icons.image_outlined,
                        color: Colors.cyanAccent,
                        size: 48,
                      ),
                      SizedBox(height: gap),

                      // Title
                      Text(
                        'Wall-D',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: titleFont,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: gap * 0.5),

                      // Subtitle
                      Text(
                        'Sign in with your work account',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: subtitleFont,
                        ),
                      ),
                      SizedBox(height: gap * 1.5),

                      // Email field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: Colors.white, fontSize: fieldFont),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                          labelStyle: const TextStyle(color: Colors.white70),
                          floatingLabelStyle: const TextStyle(color: Colors.cyanAccent),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.04),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(fieldRadius),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(fieldRadius),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(fieldRadius),
                            borderSide: const BorderSide(
                              color: Colors.cyanAccent,
                              width: 2,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: unit * 0.5,
                            vertical: fieldVerticalPad,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email required';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: gap),

                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        style: TextStyle(color: Colors.white, fontSize: fieldFont),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                          labelStyle: const TextStyle(color: Colors.white70),
                          floatingLabelStyle: const TextStyle(color: Colors.cyanAccent),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.04),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(fieldRadius),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(fieldRadius),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(fieldRadius),
                            borderSide: const BorderSide(
                              color: Colors.cyanAccent,
                              width: 2,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: unit * 0.5,
                            vertical: fieldVerticalPad,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password required';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: gap),

                      // Error message (optional)
                      if (_errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(unit * 0.35),
                          decoration: BoxDecoration(
                            color: Colors.red.shade900,
                            borderRadius: BorderRadius.circular(fieldRadius),
                            border: Border.all(color: Colors.red.shade700),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.redAccent,
                                size: 16,
                              ),
                              SizedBox(width: unit * 0.3),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: smallFont,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: gap),
                      ],

                      // Sign in button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyanAccent,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(fieldRadius),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: fieldVerticalPad + 1,
                            ),
                            elevation: 8,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: unit,
                                  width: unit,
                                  child: const CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: fieldFont,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: gap),

                      Text(
                        "You'll see your dashboard after login",
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: smallFont,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

}
