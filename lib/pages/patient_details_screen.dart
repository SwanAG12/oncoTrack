import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color primaryColor = Color(0xFFA8D5BA);
const Color accentColor = Color(0xFFFF6F61);
const Color bgColor = Color(0xFFFAF3EC);
const Color textColor = Color(0xFF333333);

class PatientDetails {
  final int age;
  final double weight;
  final double height;
  final String medicalCondition;
  final String cancerType;
  final String treatmentPlan;
  final String eatingNormally;
  final String dietPreference;
  final String foodType;
  final String dietType;
  final String indianCuisine;
  final String preferredFoodTexture;

  PatientDetails({
    required this.age,
    required this.weight,
    required this.height,
    required this.medicalCondition,
    required this.cancerType,
    required this.treatmentPlan,
    required this.eatingNormally,
    required this.dietPreference,
    required this.foodType,
    required this.dietType,
    required this.indianCuisine,
    required this.preferredFoodTexture,
  });

  Map<String, dynamic> toMap() => {
        'age': age,
        'weight': weight,
        'height': height,
        'medicalCondition': medicalCondition,
        'cancerType': cancerType,
        'treatmentPlan': treatmentPlan,
        'eatingNormally': eatingNormally,
        'dietPreference': dietPreference,
        'foodType': foodType,
        'dietType': dietType,
        'indianCuisine': indianCuisine,
        'preferredFoodTexture': preferredFoodTexture,
      };
}

class PatientDetailsScreen extends StatefulWidget {
  final String userId;

  const PatientDetailsScreen({super.key, required this.userId});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;

  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  String? _medicalCondition;
  String? _cancerType;
  String? _treatmentPlan;
  String? _eatingNormally;
  String? _dietPreference;
  String? _foodType;
  String? _dietType;
  String? _indianCuisine;
  String? _preferredFoodTexture;

  final List<String> _cancerTypes = [
    "Head / neck", "Breast", "Gastric", "Colorectal", "Liver", "Pancreas",
    "Gynaecologic", "Kidney", "Urinary bladder", "Esophageal", "Lung",
    "Sarcoma", "Lymphoma", "Leukemia", "Brain", "Others"
  ];

  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    _loadExistingDetails();
  }

  Future<void> _loadExistingDetails() async {
    final doc = await _firestore.collection('patients').doc(widget.userId).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    setState(() {
      _ageController.text = data['age']?.toString() ?? '';
      _weightController.text = data['weight']?.toString() ?? '';
      _heightController.text = data['height']?.toString() ?? '';
      _medicalCondition = data['medicalCondition'];
      _cancerType = data['cancerType'];
      _treatmentPlan = data['treatmentPlan'];
      _eatingNormally = data['eatingNormally'];
      _dietPreference = data['dietPreference'];
      _foodType = data['foodType'];
      _dietType = data['dietType'];
      _indianCuisine = data['indianCuisine'];
      _preferredFoodTexture = data['preferredFoodTexture'];
    });
  }

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  InputDecoration _styledInputDecoration(String label) {
    return InputDecoration(
      hintText: "$label *",
      hintStyle: const TextStyle(color: Colors.grey),
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
        validator: (value) {
          if (value == null || value.isEmpty) return 'Required';
          final number = double.tryParse(value);
          if (number == null) return 'Enter a valid number';
          if (label == "Age" && (number < 1 || number > 99)) return 'Age must be between 1 and 99';
          if (label == "Weight (kg)" && (number <= 0 || number > 250)) return 'Weight must be between 1 and 250';
          if (label == "Height (cm)" && (number <= 0 || number > 300)) return 'Enter a valid height (up to 300 cm)';
          return null;
        },
      ),
    );
  }

  Widget _buildDropdown({
    required String title,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: _styledInputDecoration(title),
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
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
    final bool showError = _showErrors && groupValue == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        RichText(
          text: TextSpan(
            text: title,
            style: const TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16),
            children: const [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        ...options.map((option) => RadioListTile<String>(
              title: Text(option),
              value: option,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: primaryColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 0),
            )),
        if (showError)
          const Padding(
            padding: EdgeInsets.only(left: 12, top: 4),
            child: Text("This field is required", style: TextStyle(color: Colors.red, fontSize: 12)),
          ),
      ],
    );
  }

  void _submitForm() async {
    setState(() => _showErrors = true);
    if (_formKey.currentState!.validate() &&
        _treatmentPlan != null &&
        _eatingNormally != null &&
        _dietPreference != null &&
        _foodType != null &&
        _dietType != null &&
        _preferredFoodTexture != null &&
        (_dietType != "Indian" || _indianCuisine != null)) {
      try {
        final details = PatientDetails(
          age: int.parse(_ageController.text),
          weight: double.parse(_weightController.text),
          height: double.parse(_heightController.text),
          medicalCondition: _medicalCondition!,
          cancerType: _cancerType!,
          treatmentPlan: _treatmentPlan!,
          eatingNormally: _eatingNormally!,
          dietPreference: _dietPreference!,
          foodType: _foodType!,
          dietType: _dietType!,
          indianCuisine: _indianCuisine ?? "",
          preferredFoodTexture: _preferredFoodTexture!,
        );

        await _firestore.collection('patients')
            .doc(widget.userId)
            .set(details.toMap(), SetOptions(merge: true));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeDashboard(userID: widget.userId)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: bgColor,
        foregroundColor: primaryColor,
        toolbarHeight: 80,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("OncoTrack", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 22)),
            SizedBox(height: 4),
            Text("Patient Details", style: TextStyle(color: primaryColor, fontSize: 14)),
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
                _buildDropdown(
                  title: "Medical Condition",
                  value: _medicalCondition,
                  items: ["Diabetic", "Hypertension", "Cardiac condition", "None"],
                  onChanged: (val) => setState(() => _medicalCondition = val),
                ),
                _buildDropdown(
                  title: "Type of Cancer",
                  value: _cancerType,
                  items: _cancerTypes,
                  onChanged: (val) => setState(() => _cancerType = val),
                ),
                _buildRadioGroup(
                  title: "Are you planned for",
                  options: ["Surgery", "Chemotherapy", "Immunotherapy", "Radiation"],
                  groupValue: _treatmentPlan,
                  onChanged: (val) => setState(() => _treatmentPlan = val),
                ),
                _buildRadioGroup(
                  title: "Are you able to eat normally",
                  options: ["Yes", "No"],
                  groupValue: _eatingNormally,
                  onChanged: (val) => setState(() => _eatingNormally = val),
                ),
                _buildRadioGroup(
                  title: "Preferred Diet",
                  options: ["Vegetarian", "Non-Vegetarian"],
                  groupValue: _dietPreference,
                  onChanged: (val) => setState(() {
                    _dietPreference = val;
                    _foodType = null;
                  }),
                ),
                if (_dietPreference == "Vegetarian")
                  _buildRadioGroup(
                    title: "Vegetarian Preferences",
                    options: ["Gluten Free", "Lactose Free", "Vegan", "With Egg"],
                    groupValue: _foodType,
                    onChanged: (val) => setState(() => _foodType = val),
                  ),
                if (_dietPreference == "Non-Vegetarian")
                  _buildRadioGroup(
                    title: "Non-Vegetarian Preferences",
                    options: ["Gluten Free", "Lactose Free"],
                    groupValue: _foodType,
                    onChanged: (val) => setState(() => _foodType = val),
                  ),
                _buildRadioGroup(
                  title: "Preferred Type of Food",
                  options: ["Full", "Liquid/Semi solid", "Soft"],
                  groupValue: _preferredFoodTexture,
                  onChanged: (val) => setState(() => _preferredFoodTexture = val),
                ),
                _buildRadioGroup(
                  title: "Preferred Type of Diet",
                  options: ["Indian", "Western", "Middle Eastern", "Oriental"],
                  groupValue: _dietType,
                  onChanged: (val) => setState(() {
                    _dietType = val;
                    _indianCuisine = null;
                  }),
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
}
