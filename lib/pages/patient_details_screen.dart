  import 'package:flutter/material.dart';
  import 'package:flutter_application_1/pages/dashboard.dart';
  import 'package:cloud_firestore/cloud_firestore.dart'; // Added import
import 'package:firebase_auth/firebase_auth.dart';

  const Color primaryColor = Color(0xFFA8D5BA); // Soft Sage
  const Color accentColor = Color(0xFFFF6F61);  // Warm Coral
  const Color bgColor = Color(0xFFFAF3EC);      // Light Beige
  const Color textColor = Color(0xFF333333);    // Deep Charcoal

  // ✅ Moved outside of the widget class
 class PatientDetails {
  final int age;
  final double weight;
  final double height;
  final String? medicalCondition;
  final String? cancerType;
  final String? treatmentPlan;
  final String? eatingNormally;
  final String? dietPreference;
  final String? foodType;
  final String? dietType;
  final String? indianCuisine;

  PatientDetails({
    required this.age,
    required this.weight,
    required this.height,
    this.medicalCondition,
    this.cancerType,
    this.treatmentPlan,
    this.eatingNormally,
    this.dietPreference,
    this.foodType,
    this.dietType,
    this.indianCuisine,
  });

  Map<String, dynamic> toMap() {
    return {
      'age': age.toString(),
      'weight': weight.toString(),
      'height': height.toString(),
      'medicalCondition': medicalCondition,
      'cancerType': cancerType,
      'treatmentPlan': treatmentPlan,
      'eatingNormally': eatingNormally,
      'dietPreference': dietPreference,
      'foodType': foodType,
      'dietType': dietType,
      'indianCuisine': indianCuisine,
    };
  }
}

  class PatientDetailsScreen extends StatefulWidget {
  final String userId; // Add userId parameter
  
  const PatientDetailsScreen({super.key, required this.userId}); // Update constructor

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

  class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController _ageController = TextEditingController();
    final TextEditingController _weightController = TextEditingController();
    final TextEditingController _heightController = TextEditingController();  

    String? _medicalCondition;
    String? _cancerType;
    String? _treatmentPlan;
    String? _eatingNormally;
    String? _dietPreference;
    String? _foodType;
    String? _dietType;
    String? _indianCuisine;

    final List<String> _cancerTypes = [
      "Head / neck", "Breast", "Gastric", "Colorectal", "Liver", "Pancreas",
      "Gynaecologic", "Kidney", "Urinary bladder", "Esophageal", "Lung",
      "Sarcoma", "Lymphoma", "Leukemia", "Brain", "Others"
    ];

    @override
    void dispose() {
      _ageController.dispose();
      _weightController.dispose();
      _heightController.dispose();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: primaryColor),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "OncoTrack",
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Patient Details",
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField("Age", _ageController),
                  _buildTextField("Weight (kg)", _weightController),
                  _buildTextField("Height (cm)", _heightController),

                  _buildDropdown<String>(
                    title: "Medical Condition",
                    value: _medicalCondition,
                    items: ["Diabetes", "Hypertension", "Cardiac condition","None"],
                    onChanged: (val) => setState(() => _medicalCondition = val),
                  ),

                  _buildDropdown<String>(
                    title: "Type of Cancer",
                    value: _cancerType,
                    items: _cancerTypes,
                    onChanged: (val) => setState(() => _cancerType = val),
                  ),

                  _buildRadioGroup(
                    title: "Are you planned for:",
                    options: ["Surgery", "Chemotherapy", "Immunotherapy", "Radiation"],
                    groupValue: _treatmentPlan,
                    onChanged: (val) => setState(() => _treatmentPlan = val),
                  ),

                  _buildRadioGroup(
                    title: "Are you able to eat normally?",
                    options: ["Yes", "No"],
                    groupValue: _eatingNormally,
                    onChanged: (val) => setState(() => _eatingNormally = val),
                  ),

                  _buildRadioGroup(
                    title: "Preferred Diet",
                    options: ["Vegetarian", "Vegan", "Jain", "Vegetarian with eggs", "Non Vegetarian"],
                    groupValue: _dietPreference,
                    onChanged: (val) => setState(() => _dietPreference = val),
                  ),

                  _buildRadioGroup(
                    title: "Preferred Type of Food",
                    options: ["Regular", "Liquids", "Mashed", "Tube feeds"],
                    groupValue: _foodType,
                    onChanged: (val) => setState(() => _foodType = val),
                  ),

                  _buildRadioGroup(
                    title: "Preferred Type of Diet",
                    options: ["Indian", "Western", "Middle Eastern", "Oriental"],
                    groupValue: _dietType,
                    onChanged: (val) => setState(() => _dietType = val),
                  ),

                  if (_dietType == "Indian")
                    _buildRadioGroup(
                      title: "Preferred Indian Cuisine",
                      options: ["North Indian", "South Indian", "Eastern"],
                      groupValue: _indianCuisine,
                      onChanged: (val) => setState(() => _indianCuisine = val),
                    ),

                  const SizedBox(height: 24),
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
                      onPressed: _submitForm,
                      child: const Text("Submit"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    InputDecoration _styledInputDecoration(String label) {
      return InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );
    }

    Widget _buildTextField(String label, TextEditingController controller) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: textColor),
          decoration: _styledInputDecoration(label),
          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
        ),
      );
    }

    Widget _buildDropdown<T>({
      required String title,
      required T? value,
      required List<T> items,
      required ValueChanged<T?> onChanged,
    }) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: DropdownButtonFormField<T>(
          value: value,
          decoration: _styledInputDecoration(title),
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item.toString()))).toList(),
          onChanged: onChanged,
          validator: (val) => val == null ? 'Please select $title' : null,
        ),
      );
    }

    Widget _buildRadioGroup({
      required String title,
      required List<String> options,
      required String? groupValue,
      required ValueChanged<String?> onChanged,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: textColor)),
          Column(
            children: options.map((option) {
              return RadioListTile<String>(
                activeColor: primaryColor,
                title: Text(option),
                value: option,
                groupValue: groupValue,
                onChanged: onChanged,
                contentPadding: const EdgeInsets.symmetric(horizontal: 0),
              );
            }).toList(),
          ),
        ],
      );
    }
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final details = PatientDetails(
          age: int.parse(_ageController.text),
          weight: double.parse(_weightController.text),
          height: double.parse(_heightController.text),
          medicalCondition: _medicalCondition,
          cancerType: _cancerType,
          treatmentPlan: _treatmentPlan,
          eatingNormally: _eatingNormally,
          dietPreference: _dietPreference,
          foodType: _foodType,
          dietType: _dietType,
          indianCuisine: _indianCuisine,
        );

        // Save to Firestore
        await _firestore.collection('patients')
          .doc(widget.userId)
          .update(details.toMap());

        // Navigate to dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeDashboard(
              
              userID: widget.userId, // Pass userId to dashboard
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving data: ${e.toString()}')),
        );
      }
    }
  }

  }

