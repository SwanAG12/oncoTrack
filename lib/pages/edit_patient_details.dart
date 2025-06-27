import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditDetailsPage extends StatefulWidget {
  final String userId;
  const EditDetailsPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<EditDetailsPage> createState() => _EditDetailsPageState();
}

class _EditDetailsPageState extends State<EditDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for editable fields
  final TextEditingController _medicalConditionController = TextEditingController();
  final TextEditingController _dietPreferenceController = TextEditingController();
  final TextEditingController _foodTypeController = TextEditingController();
  final TextEditingController _preferredFoodTextureController = TextEditingController();
  final TextEditingController _treatmentPlanController = TextEditingController();

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatientDetails();
  }

  Future<void> _loadPatientDetails() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('patients').doc(widget.userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        _medicalConditionController.text = data['medicalCondition'] ?? '';
        _dietPreferenceController.text = data['dietPreference'] ?? '';
        _foodTypeController.text = data['foodType'] ?? '';
        _preferredFoodTextureController.text = data['preferredFoodTexture'] ?? '';
        _treatmentPlanController.text = data['treatmentPlan'] ?? '';
      }
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Error loading patient details: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load details.")),
      );
    }
  }

  Future<void> _updatePatientDetails() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('patients').doc(widget.userId).update({
          'medicalCondition': _medicalConditionController.text.trim(),
          'dietPreference': _dietPreferenceController.text.trim(),
          'foodType': _foodTypeController.text.trim(),
          'preferredFoodTexture': _preferredFoodTextureController.text.trim(),
          'treatmentPlan': _treatmentPlanController.text.trim(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Details updated successfully.")),
        );
      } catch (e) {
        debugPrint("❌ Error updating details: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update details.")),
        );
      }
    }
  }

  @override
  void dispose() {
    _medicalConditionController.dispose();
    _dietPreferenceController.dispose();
    _foodTypeController.dispose();
    _preferredFoodTextureController.dispose();
    _treatmentPlanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: const Color(0xFFA3B18A),
      ),
      backgroundColor: const Color(0xFFE6E4D9),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildField("Medical Condition", _medicalConditionController),
              _buildField("Diet Preference", _dietPreferenceController),
              _buildField("Food Type", _foodTypeController),
              _buildField("Preferred Food Texture", _preferredFoodTextureController),
              _buildField("Treatment Plan", _treatmentPlanController),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA3B18A),
                ),
                onPressed: _updatePatientDetails,
                child: const Text("Save Changes"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (value) =>
            (value == null || value.trim().isEmpty) ? 'Please enter $label' : null,
      ),
    );
  }
}
