import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/patient_details_screen.dart';

class TermsAgreementScreen extends StatelessWidget {
  final String userId;

  const TermsAgreementScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF3EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFA8D5BA),
        centerTitle: true,
        title: const Text("Agreement"),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 15, color: Colors.black),
                    children: [
                      TextSpan(
                        text:
                            'By continuing, you agree to the following Terms of Use and Disclaimer:\n\n',
                      ),
                      TextSpan(
                        text: '1. Usage & Intent:\n',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text:
                            'OncoTrack is designed to assist with dietary monitoring for cancer patients. It is NOT a replacement for professional medical advice.\n\n',
                      ),
                      TextSpan(
                        text: '2. Medical Disclaimer:\n',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text:
                            'Always consult your oncologist, dietitian, or healthcare provider before making any decisions based on this app. Data, calculations, and suggestions are based on general guidelines and should be tailored to individual medical needs.\n\n',
                      ),
                      TextSpan(
                        text: '3. Data Privacy:\n',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text:
                            'Your personal and medical data is stored securely and used only for app functionality. No data is sold or shared with third parties.\n\n',
                      ),
                      TextSpan(
                        text: '4. No Guarantees:\n',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text:
                            'While the app aims to help patients reach their nutritional goals, results may vary. We do not guarantee weight change, recovery rate, or treatment outcomes.\n\n',
                      ),
                      TextSpan(
                        text: '5. User Responsibility:\n',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text:
                            'You are responsible for the accuracy of the information you provide and for seeking medical help when required.\n\n',
                      ),
                      TextSpan(
                        text: '6. Modifications:\n',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text:
                            'The app may update its features and terms. Continued use after updates constitutes acceptance.\n\n',
                      ),
                      TextSpan(
                        text:
                            'By using this app, you accept these terms and acknowledge the above disclaimer.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PatientDetailsScreen(userId: userId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("I Agree"),
            ),
          ],
        ),
      ),
    );
  }
}
