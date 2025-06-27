import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Auth/register_screen.dart';
import 'package:flutter_application_1/pages/dashboard.dart';
import 'package:flutter_application_1/Auth/auth_service.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

const Color primaryColor = Color(0xFFA8D5BA);
const Color accentColor = Color(0xFFFF6F61);
const Color bgColor = Color(0xFFFAF3EC);
const Color textColor = Color(0xFF333333);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  String _completePhone = '';


  bool isEmailLogin = false; // Default to phone login
  bool isLoading = false;
  String? _verificationId;
  bool otpSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
  final phone = _completePhone.trim();
  if (phone.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter a valid phone number')),
    );
    return;
  }

  setState(() => isLoading = true);

  try {
    await _authService.signInWithPhoneNumber(phone, (verificationId, resendToken) {
      setState(() {
        _verificationId = verificationId;
        otpSent = true;
      });
    });
  } on FirebaseAuthException catch (e) {
    String message;
    if (e.code == 'invalid-phone-number') {
      message = 'The phone number entered is invalid. Please use the correct format.';
    } else if (e.code == 'too-many-requests') {
      message =
          'Too many requests from this device. Please try again later or use a different device.';
    } else {
      message = 'Failed to send OTP. ${e.message}';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unexpected error: $e')),
    );
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeDashboard(userID: user.uid),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid OTP')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _emailLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      final user = await _authService.loginWithEmailandPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeDashboard(userID: user.uid),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login Error: $e')));
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
                    const SizedBox(height: 20),

                    // Toggle between phone and email login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Use ", style: TextStyle(color: textColor)),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isEmailLogin = !isEmailLogin;
                              otpSent = false; // Reset OTP state
                            });
                          },
                          child: Text(
                            isEmailLogin ? "Phone Number" : "Email",
                            style: const TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Phone/OTP Login
                    if (!isEmailLogin) ...[
                      if (!isEmailLogin) ...[
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
  ),
  const SizedBox(height: 20),
  if (otpSent)
    TextFormField(
      controller: _otpController,
      decoration: _cleanInputDecoration('OTP', Icons.lock),
      keyboardType: TextInputType.number,
    ),
  const SizedBox(height: 20),
],

                      const SizedBox(height: 20),
                      if (otpSent)
                        TextFormField(
                          controller: _otpController,
                          decoration: _cleanInputDecoration('OTP', Icons.lock),
                          keyboardType: TextInputType.number,
                        ),
                      const SizedBox(height: 20),
                    ],

                    // Email/Password Login
                    if (isEmailLogin) ...[
                      TextFormField(
                        controller: _emailController,
                        decoration: _cleanInputDecoration('Email', Icons.email),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Enter your email' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        decoration: _cleanInputDecoration('Password', Icons.lock),
                        obscureText: true,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Enter your password' : null,
                      ),
                      const SizedBox(height: 20),
                    ],

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
                            : isEmailLogin
                                ? _emailLogin
                                : otpSent
                                    ? _verifyOTP
                                    : _sendOTP,
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(isEmailLogin ? 'Login' : (otpSent ? 'Verify OTP' : 'Send OTP')),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? ", style: TextStyle(color: textColor)),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                          ),
                          child: const Text(
                            'Register',
                            style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
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
