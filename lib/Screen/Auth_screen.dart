import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'SignUp_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  // Check if user already logged in (auto-redirect)
  Future<void> _checkAuthState() async {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null && mounted) {
        setState(() => _currentUser = user);
        _loadUserScreen(user.uid); // Determine screen based on designation
      }
    });
  }

  // Load user designation → determine screen access (per plan)
  Future<void> _loadUserScreen(String userId) async {
    try {
      const tenantId = 'default_tenant';
      final userDoc = await FirebaseFirestore.instance
          .collection('tenants/$tenantId/users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final designation = userDoc['designation'];
        final screenAccess = await _getScreenAccess(designation);
        
        if (screenAccess.length == 1) {
          // Single screen → auto-redirect
          _navigateToScreen(screenAccess.first);
        } else {
          // Multiple screens → show selector
          _showScreenSelector(screenAccess);
        }
      }
    } catch (e) {
      print('Screen load error: $e');
    }
  }

  Future<List<String>> _getScreenAccess(String designation) async {
    const tenantId = 'default_tenant';
    final metadataDoc = await FirebaseFirestore.instance
        .collection('tenants/$tenantId/metadata')
        .doc('designations.json')
        .get();

    if (metadataDoc.exists) {
      final data = metadataDoc.data() as Map<String, dynamic>;
      final designationData = data['designations'][designation];
      return List<String>.from(designationData?['screen_access'] ?? []);
    }
    return ['employee']; // Default fallback
  }

  void _showScreenSelector(List<String> screens) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Select Screen', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: screens.map((screen) => ListTile(
            leading: Icon(_getScreenIcon(screen), color: Colors.cyan),
            title: Text(_getScreenTitle(screen), style: const TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _navigateToScreen(screen);
            },
          )).toList(),
        ),
      ),
    );
  }

  String _getScreenTitle(String screen) {
    switch (screen) {
      case 'developer': return 'Developer Screen';
      case 'admin': return 'Admin Screen';
      case 'manager': return 'Manager Screen';
      default: return 'Employee Screen';
    }
  }

  IconData _getScreenIcon(String screen) {
    switch (screen) {
      case 'developer': return Icons.code;
      case 'admin': return Icons.admin_panel_settings;
      case 'manager': return Icons.supervisor_account;
      default: return Icons.task_alt;
    }
  }

  void _navigateToScreen(String screen) {
    // TODO: Navigate to actual screens (Phase 4)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Welcome to $screen Screen!'), backgroundColor: Colors.green),
    );
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Firebase Auth + Session Management (JWT 1hr expiry per plan)
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Auto-load user screen on success
      print('✅ Login successful - Loading screen...');
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found': return 'No account found. Please register first.';
      case 'wrong-password': return 'Incorrect password.';
      case 'invalid-email': return 'Invalid email format.';
      case 'user-disabled': return 'Account disabled. Contact admin.';
      case 'too-many-requests': return 'Too many attempts. Try again later.';
      default: return 'Login failed. Please try again.';
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    setState(() => _currentUser = null);
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen if checking auth state
    if (_isLoading && _currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.cyan)),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0A0A), Color(0xFF1A1A2E)],
          ),
        ),
        child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Wall-D Branding (per plan)
                  const Icon(
                    Icons.wallpaper,
                    size: 100,
                    color: Colors.cyan,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Wall-D',
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enterprise Workflow Command Center',
                    style: TextStyle(fontSize: 20, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 48),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Work Email',
                      prefixIcon: const Icon(Icons.email_outlined, color: Colors.cyan),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey[800]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.cyan, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Email required';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Enter valid work email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.cyan),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey[800]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.cyan, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Password required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Error Message
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[900],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[700]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[300], size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text(_errorMessage!, style: TextStyle(color: Colors.red[200]))),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),

                  // Sign In Button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan[600],
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 8,
                        shadowColor: Colors.cyan,
                      ),
                      child: _isLoading
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Text('Signing In...', style: TextStyle(fontSize: 18)),
                              ],
                            )
                          : const Text(
                              'Sign In',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Divider + Sign Up
                  Row(
                    children: [
                      Expanded(child: Container(height: 1, color: Colors.grey[800])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('New User?', style: TextStyle(color: Colors.grey[500])),
                      ),
                      Expanded(child: Container(height: 1, color: Colors.grey[800])),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Sign Up Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignUpScreen()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange[400],
                        side: BorderSide(color: Colors.orange[400]!, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        'Register (Manager Approval Required)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
