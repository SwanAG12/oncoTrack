import 'package:flutter/material.dart';
import 'package:flutter_application_1/Auth/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/pages/patient_details_screen.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

const Color primaryColor = Color(0xFFA8D5BA);
const Color accentColor = Color(0xFFFF6F61);
const Color bgColor = Color(0xFFFAF3EC);
const Color textColor = Color(0xFF333333);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _completePhone = '';

  String? _verificationId;
  bool otpSent = false;
  bool isLoading = false;
  bool isPhoneMode = true; // Show phone screen first

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    if (_completePhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }
    setState(() => isLoading = true);

    try {
      await _authService.signInWithPhoneNumber(
        _completePhone,
        (verificationId, resendToken) {
          setState(() {
            _verificationId = verificationId;
            otpSent = true;
          });
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OTP Error: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _verifyOTP() async {
    if (_verificationId == null || _otpController.text.isEmpty) return;
    setState(() => isLoading = true);

    try {
      final user = await _authService.verifyOTP(_verificationId!, _otpController.text);
      if (user != null) {
        await _firestore.collection('patients').doc(user.uid).set({
          'name': _nameController.text.trim(),
          'phone': _completePhone,
          'createdAt': FieldValue.serverTimestamp(),
          'userType': 'patient',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PatientDetailsScreen(userId: user.uid),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid OTP')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _registerWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      final user = await _authService.createUserWithEmailandPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null) {
        await _firestore.collection('patients').doc(user.uid).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'userType': 'patient',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PatientDetailsScreen(userId: user.uid),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration Error: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    const Text(
                      'OncoTrack',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Name
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: textColor),
                      decoration: _cleanInputDecoration('Full Name', Icons.person),
                      validator: (value) => value!.isEmpty ? 'Enter your name' : null,
                    ),
                    const SizedBox(height: 20),

                    // Phone mode
                    if (isPhoneMode) ...[
                      IntlPhoneField(
                        controller: _phoneController,
                        initialCountryCode: 'IN',
                        decoration: _cleanInputDecoration('Phone Number', Icons.phone),
                        style: const TextStyle(color: textColor),
                        onChanged: (phone) {
                          _completePhone = phone.completeNumber;
                        },
                        onSaved: (phone) {
                          _completePhone = phone?.completeNumber ?? '';
                        },
                        validator: (value) => value == null || value.number.isEmpty ? 'Enter your phone number' : null,
                      ),
                      const SizedBox(height: 20),
                      if (otpSent)
                        TextFormField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: textColor),
                          decoration: _cleanInputDecoration('Enter OTP', Icons.lock),
                        ),
                    ] else ...[
                      // Email mode
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _cleanInputDecoration('Email', Icons.email),
                        validator: (value) => value!.isEmpty ? 'Enter your email' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: _cleanInputDecoration('Password', Icons.lock),
                        validator: (value) => value!.length < 6 ? 'Minimum 6 characters' : null,
                      ),
                    ],

                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: isLoading
                            ? null
                            : isPhoneMode
                                ? (otpSent ? _verifyOTP : _sendOTP)
                                : _registerWithEmail,
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(isPhoneMode ? (otpSent ? 'Verify OTP' : 'Send OTP') : 'Register'),
                      ),
                    ),

                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          isPhoneMode = !isPhoneMode;
                          otpSent = false;
                        });
                      },
                      child: Text(
                        isPhoneMode
                            ? 'Register using Email instead'
                            : 'Register using Phone instead',
                        style: const TextStyle(color: accentColor),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Back to Login',
                        style: TextStyle(color: accentColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _cleanInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: Colors.grey[700]),
      filled: true,
      fillColor: bgColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
