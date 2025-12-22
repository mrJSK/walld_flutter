// lib/dynamic_screen/widgets/login_widget.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // DashboardPanel listens to authStateChanges and will react.
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        final shortest = math.min(maxW, maxH);
        // When the box is short, compress everything a bit
        final double compress =
            shortest < 360 ? 0.85 : shortest < 420 ? 0.92 : 1.0;

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
        final double fieldHorizontalPad =
            (unit * 0.75).clamp(10.0, 18.0);
        final double fieldRadius = (unit * 0.70).clamp(10.0, 20.0);



        return Container(
          margin: EdgeInsets.all(margin),
          decoration: BoxDecoration(
            color: const Color(0x6611111C),
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
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min, // allows tight packing
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Branding
                Icon(
                  Icons.wallpaper,
                  size: unit * 1.7 * compress,
                  color: Colors.cyanAccent,
                ),
                SizedBox(height: gap * 0.5),
                Text(
                  'Wall‑D',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleFont,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: gap * 0.3),
                Text(
                  'Sign in with your work account',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: subtitleFont,
                  ),
                ),
                SizedBox(height: gap),

                // Email field
      TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        style: TextStyle(fontSize: fieldFont),
        decoration: InputDecoration(
          labelText: 'Work Email',
          prefixIcon: const Icon(
            Icons.email_outlined,
            color: Colors.cyan,
            size: 18,
          ),
          filled: true,
          fillColor: Colors.grey[900],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(fieldRadius),
            borderSide:
                BorderSide(color: Colors.grey[800] ?? Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(fieldRadius),
            borderSide: const BorderSide(
              color: Colors.cyan,
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: fieldHorizontalPad,
            vertical: fieldVerticalPad,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Email required';
          }
          final regex =
              RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
          if (!regex.hasMatch(value)) {
            return 'Enter valid work email';
          }
          return null;
        },
      ),
      SizedBox(height: gap),

      // Password field
      TextFormField(
        controller: _passwordController,
        obscureText: true,
        style: TextStyle(fontSize: fieldFont),
        decoration: InputDecoration(
          labelText: 'Password',
          prefixIcon: const Icon(
            Icons.lock_outline,
            color: Colors.cyan,
            size: 18,
          ),
          filled: true,
          fillColor: Colors.grey[900],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(fieldRadius),
            borderSide:
                BorderSide(color: Colors.grey[800] ?? Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(fieldRadius),
            borderSide: const BorderSide(
              color: Colors.cyan,
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: fieldHorizontalPad,
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
            color: Colors.red[900],
            borderRadius: BorderRadius.circular(fieldRadius),
            border: Border.all(
              color: Colors.red[700] ?? Colors.red,
            ),
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

      // Sign in button (flexible height via padding)
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _signIn,
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
        'You\'ll see your dashboard after login',
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

        );
      },
    );
  }
}
