import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  
  // Form fields from plan
  String? _selectedDesignation;
  String? _selectedDepartment;
  String? _selectedManager;
  
  bool _isLoading = false;
  String? _errorMessage;
  List<String> _designations = [];
  List<String> _departments = [];
  List<String> _managers = [];
  DocumentSnapshot? _tenantDoc;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    try {
      // Get tenant ID from Firebase Auth (default tenant for now)
      const tenantId = 'default_tenant'; // Replace with dynamic tenant selection
      
      // Load designations (from metadata/designations)
      final designationsSnap = await FirebaseFirestore.instance
          .collection('tenants/$tenantId/metadata')
          .doc('designations.json')
          .get();
      
      if (designationsSnap.exists) {
        final data = designationsSnap.data() as Map<String, dynamic>;
        setState(() {
          _designations = data['designations'].keys.toList();
        });
      }

      // Load departments (from organizations filter type=department)
      final deptsSnap = await FirebaseFirestore.instance
          .collection('tenants/$tenantId/organizations')
          .where('type', isEqualTo: 'department')
          .limit(20)
          .get();
      
      setState(() {
        _departments = deptsSnap.docs.map((doc) => doc['name'] as String).toList();
      });

      // Load managers (users with manager role)
      final managersSnap = await FirebaseFirestore.instance
          .collection('tenants/$tenantId/users')
          .where('roles', arrayContains: 'manager')
          .limit(20)
          .get();
      
      setState(() {
        _managers = managersSnap.docs.map((doc) => doc['profile_data']['fullName'] as String).toList();
      });
    } catch (e) {
      print('Metadata load error: $e');
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // STEP 1: Create Firebase Auth user
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // STEP 2: Create pending user document (requires manager approval)
      await FirebaseFirestore.instance
          .collection('tenants/default_tenant/users')
          .doc(userCredential.user!.uid)
          .set({
        'profile_data': {
          'fullName': _fullNameController.text.trim(),
          'email': _emailController.text.trim(),
        },
        'designation': _selectedDesignation,
        'department': _selectedDepartment,
        'proposed_manager': _selectedManager,
        'status': 'pending_approval', // Key field from plan
        'created_at': FieldValue.serverTimestamp(),
        'approval_required': true,
      }, SetOptions(merge: true));

      // STEP 3: Notify manager (Cloud Function trigger)
      await FirebaseFirestore.instance
          .collection('tenants/default_tenant/notifications')
          .add({
        'type': 'pending_registration',
        'user_id': userCredential.user!.uid,
        'title': 'New User Registration - Pending Approval',
        'message': '$_fullNameController has registered as $_selectedDesignation',
        'action': 'approve_user',
        'data': {
          'userId': userCredential.user!.uid,
          'fullName': _fullNameController.text.trim(),
          'designation': _selectedDesignation,
        },
        'created_at': FieldValue.serverTimestamp(),
      });

      // Success message - user must wait for manager approval
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Registration submitted! Waiting for manager approval...\nCheck your email for status updates.',
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.green[900],
            duration: const Duration(seconds: 6),
          ),
        );
        Navigator.pop(context); // Back to login
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Registration failed. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use': return 'Email already registered.';
      case 'weak-password': return 'Password too weak (min 12 chars).';
      case 'invalid-email': return 'Invalid email format.';
      default: return 'Registration failed: ${code}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Branding
                  const Icon(Icons.person_add, size: 80, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text(
                    'Wall-D Registration',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Submit for Manager Approval',
                    style: TextStyle(fontSize: 18, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 48),

                  // Full Name
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline, color: Colors.orange),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Full name required';
                      if (value.length < 3) return 'Name too short';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Work Email',
                      prefixIcon: Icon(Icons.email_outlined, color: Colors.orange),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Email required';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Enter valid work email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password (12+ chars per security plan)
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password (12+ chars)',
                      prefixIcon: Icon(Icons.lock_outline, color: Colors.orange),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Password required';
                      if (value.length < 12) return 'Password must be 12+ characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Designation Dropdown (from metadata)
                  DropdownButtonFormField<String>(
                    value: _selectedDesignation,
                    decoration: InputDecoration(
                      labelText: 'Designation',
                      prefixIcon: Icon(Icons.badge_outlined, color: Colors.orange),
                    ),
                    items: _designations.map((String designation) {
                      return DropdownMenuItem(value: designation, child: Text(designation));
                    }).toList(),
                    onChanged: _designations.isEmpty ? null : (value) {
                      setState(() => _selectedDesignation = value);
                    },
                    validator: (value) => value == null ? 'Select designation' : null,
                  ),
                  const SizedBox(height: 20),

                  // Department Autocomplete
                  DropdownButtonFormField<String>(
                    value: _selectedDepartment,
                    decoration: const InputDecoration(
                      labelText: 'Department',
                      prefixIcon: Icon(Icons.business_outlined, color: Colors.orange),
                    ),
                    items: _departments.map((String dept) {
                      return DropdownMenuItem(value: dept, child: Text(dept));
                    }).toList(),
                    onChanged: _departments.isEmpty ? null : (value) {
                      setState(() => _selectedDepartment = value);
                    },
                    validator: (value) => value == null ? 'Select department' : null,
                  ),
                  const SizedBox(height: 20),

                  // Manager Picker
                  DropdownButtonFormField<String>(
                    value: _selectedManager,
                    decoration: const InputDecoration(
                      labelText: 'Reporting Manager (optional)',
                      prefixIcon: Icon(Icons.supervisor_account, color: Colors.orange),
                    ),
                    items: _managers.map((String manager) {
                      return DropdownMenuItem(value: manager, child: Text(manager));
                    }).toList(),
                    onChanged: _managers.isEmpty ? null : (value) {
                      setState(() => _selectedManager = value);
                    },
                  ),
                  const SizedBox(height: 32),

                  // Error Message
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[900],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_errorMessage!, style: TextStyle(color: Colors.red[100])),
                    ),

                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                            )
                          : const Text(
                              'Submit for Approval',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Back to Login', style: TextStyle(color: Colors.grey[400])),
                  ),
                ],
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
    _fullNameController.dispose();
    super.dispose();
  }
}
