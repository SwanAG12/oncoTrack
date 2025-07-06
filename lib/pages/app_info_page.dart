import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/auth/login_page.dart';
import 'package:flutter_application_1/pages/patient_details_screen.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFE6E4D9),
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
        backgroundColor: const Color(0xFFA3B18A),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              "Edit your details",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 12),

            _settingsTile(
              icon: Icons.person_outline,
              title: "Edit Profile",
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Edit Profile coming soon")),
                );
              },
            ),
            const SizedBox(height: 12),

            _settingsTile(
              icon: Icons.medical_services_outlined,
              title: "Edit Medical Info",
              onTap: () {
                if (userId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PatientDetailsScreen(userId: userId),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("User not logged in.")),
                  );
                }
              },
            ),

            const SizedBox(height: 24),
            const Divider(thickness: 1.2),
            const SizedBox(height: 12),

            _settingsTile(
              icon: Icons.info_outline,
              title: "App Info",
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text("About App"),
                    content: const Text(
                      "OncoTrack v1.0.0 (Build 1)\n\nCreated with ❤️ to help cancer patients track their nutrition and recovery progress.",
                      style: TextStyle(fontSize: 14),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("OK"),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            _settingsTile(
              icon: Icons.policy_outlined,
              title: "Medical Disclaimer",
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text("Medical Disclaimer"),
                    content: const Text(
                      "This app is intended for informational and nutritional guidance only. "
                      "It does not replace professional medical advice, diagnosis, or treatment. "
                      "Always consult your doctor or healthcare provider before making any health decisions.",
                      style: TextStyle(fontSize: 13),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("OK"),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            _settingsTile(
              icon: Icons.logout,
              title: "Logout",
              onTap: () => _logout(context),
              color: Colors.redAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      shadowColor: Colors.black26,
      color: const Color(0xFFF4F1EA),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Icon(icon, color: color ?? Colors.black87),
        title: Text(title, style: TextStyle(color: color ?? Colors.black87)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
