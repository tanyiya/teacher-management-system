import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../app_theme.dart';
import '../services/auth_service.dart';

class TeacherRegistrationScreen extends StatefulWidget {
  const TeacherRegistrationScreen({super.key});

  @override
  State<TeacherRegistrationScreen> createState() =>
      _TeacherRegistrationScreenState();
}

class _TeacherRegistrationScreenState extends State<TeacherRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _nameController = TextEditingController();
  final _icController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedGender;
  String? _selectedMaritalStatus;
  DateTime? _selectedDob;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _icController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedGender == null ||
        _selectedMaritalStatus == null ||
        _selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all dropdowns and date of birth.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Create Auth Account
      final cred = await _authService.registerUser(
        email: _emailController.text,
        password: _passwordController.text,
      );
      final uid = cred.user?.uid;
      if (uid == null) throw Exception('No user ID returned');

      final normalizedEmail = _emailController.text.trim().toLowerCase();
      final username = normalizedEmail.contains('@')
          ? normalizedEmail.split('@').first
          : normalizedEmail;

      // 2. Create Firestore Document for auth metadata
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'fullName': _nameController.text.trim(),
        'icNumber': _icController.text.trim(),
        'gender': _selectedGender,
        'dateOfBirth': Timestamp.fromDate(_selectedDob!),
        'email': normalizedEmail,
        'phoneNumber': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'maritalStatus': _selectedMaritalStatus,
        'emergencyContact': _emergencyNameController.text.trim(),
        'emergencyNumber': _emergencyPhoneController.text.trim(),
        'role': 'Teacher',
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Also create the teacher profile so the teacher appears in
      //    collections and screens that read from `teachers`.
      await FirebaseFirestore.instance.collection('teachers').doc(uid).set({
        'username': username,
        'fullName': _nameController.text.trim(),
        'icNumber': _icController.text.trim(),
        'gender': _selectedGender,
        'dob': _selectedDob!.toIso8601String(),
        'email': normalizedEmail,
        'phoneNumber': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'maritalStatus': _selectedMaritalStatus,
        'emergencyContactName': _emergencyNameController.text.trim(),
        'emergencyContactNumber': _emergencyPhoneController.text.trim(),
        'role': 'teacher',
        'status': 'pending',
        'verificationStatus': 'pending',
        'currentScore': 100,
        'yearlyKpi': 0,
        'documents': {},
      });

      // 4. Sign out immediately
      await _authService.signOut();

      // 4. Navigate to success
      if (mounted) context.go('/register-success');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Registration failed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasBase,
      appBar: AppBar(
        title: const Text('Teacher Registration'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.subtleGrayBoundary),
                  boxShadow: AppTheme.iosBoxShadow,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Personal Information',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          icon: LucideIcons.user,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _icController,
                          label: 'IC Number',
                          icon: LucideIcons.creditCard,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Gender',
                                  prefixIcon: Icon(LucideIcons.users),
                                ),
                                value: _selectedGender,
                                items: const [
                                  DropdownMenuItem(
                                      value: 'Male', child: Text('Male')),
                                  DropdownMenuItem(
                                      value: 'Female', child: Text('Female')),
                                ],
                                onChanged: (v) =>
                                    setState(() => _selectedGender = v),
                                validator: (v) => v == null ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDob ?? DateTime(2000),
                                    firstDate: DateTime(1940),
                                    lastDate: DateTime.now(),
                                  );
                                  if (date != null)
                                    setState(() => _selectedDob = date);
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Date of Birth',
                                    prefixIcon: Icon(LucideIcons.calendar),
                                  ),
                                  child: Text(
                                    _selectedDob == null
                                        ? 'Select Date'
                                        : '${_selectedDob!.year}-${_selectedDob!.month.toString().padLeft(2, '0')}-${_selectedDob!.day.toString().padLeft(2, '0')}',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Contact Information',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: LucideIcons.mail,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) =>
                              !v!.contains('@') ? 'Invalid email' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          icon: LucideIcons.phone,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _addressController,
                          label: 'Address',
                          icon: LucideIcons.mapPin,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Additional Information',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Marital Status',
                            prefixIcon: Icon(LucideIcons.heart),
                          ),
                          value: _selectedMaritalStatus,
                          items: const [
                            DropdownMenuItem(
                                value: 'Single', child: Text('Single')),
                            DropdownMenuItem(
                                value: 'Married', child: Text('Married')),
                            DropdownMenuItem(
                                value: 'Divorced', child: Text('Divorced')),
                            DropdownMenuItem(
                                value: 'Widowed', child: Text('Widowed')),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedMaritalStatus = v),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Emergency Contact',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _emergencyNameController,
                          label: 'Emergency Contact Name',
                          icon: LucideIcons.user,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _emergencyPhoneController,
                          label: 'Emergency Contact Number',
                          icon: LucideIcons.phone,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Account Credentials',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _buildPasswordField(
                          controller: _passwordController,
                          label: 'Password',
                          obscure: _obscurePassword,
                          onToggle: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          validator: (v) =>
                              v!.length < 8 ? 'Min 8 characters' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildPasswordField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          obscure: _obscureConfirmPassword,
                          onToggle: () => setState(() =>
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword),
                          validator: (v) => v != _passwordController.text
                              ? 'Passwords do not match'
                              : null,
                        ),
                        const SizedBox(height: 32),
                        FilledButton(
                          onPressed: _isLoading ? null : _submit,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Register',
                                  style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
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
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: maxLines == 1
            ? Icon(icon)
            : Padding(
                padding: const EdgeInsets.only(bottom: 48), child: Icon(icon)),
      ),
      validator: validator ?? (v) => v!.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(LucideIcons.lock),
        suffixIcon: IconButton(
          icon: Icon(obscure ? LucideIcons.eye : LucideIcons.eyeOff),
          onPressed: onToggle,
        ),
      ),
      validator: validator,
    );
  }
}
