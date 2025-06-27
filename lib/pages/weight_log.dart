import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

const Color primaryColor = Color(0xFFA8D5BA);
const Color accentColor = Color(0xFFFF6F61);
const Color bgColor = Color(0xFFFAF3EC);
const Color textColor = Color(0xFF333333);
final GlobalKey weightChartKey = GlobalKey();

class WeightLogPage extends StatefulWidget {
  const WeightLogPage({super.key});

  @override
  State<WeightLogPage> createState() => _WeightLogPageState();
}

class _WeightLogPageState extends State<WeightLogPage> {
  final TextEditingController _weightController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  DateTime? _selectedDate;

  List<Map<String, dynamic>> weightEntries = [];
  bool showWarning = false;

  @override
  void initState() {
    super.initState();
    _loadWeightEntries();
  }

  Future<void> _loadWeightEntries() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot = await _firestore
        .collection('patients')
        .doc(user.uid)
        .collection('weight_logs')
        .orderBy('date', descending: true)
        .get();

    final entries = snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();

    if (!mounted) return;
    setState(() {
      weightEntries = entries.cast<Map<String, dynamic>>();
    });

    _checkForWeightLossWarning();
  }

  Future<void> _submitWeight() async {
  final user = _auth.currentUser;
  if (user == null || _weightController.text.isEmpty) return;

  final weight = double.tryParse(_weightController.text);
  if (weight == null || weight <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please enter a valid weight greater than 0.'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
    return;
  }

  final dateToSave = _selectedDate ?? DateTime.now();
  final formattedDay = DateFormat('yyyy-MM-dd').format(dateToSave);

  final weightLogRef = _firestore
      .collection('patients')
      .doc(user.uid)
      .collection('weight_logs');

  final existing = await weightLogRef
      .where('date', isGreaterThanOrEqualTo: DateTime(dateToSave.year, dateToSave.month, dateToSave.day))
      .where('date', isLessThan: DateTime(dateToSave.year, dateToSave.month, dateToSave.day + 1))
      .get();

  if (existing.docs.isNotEmpty) {
    for (final doc in existing.docs) {
      await doc.reference.delete();
    }
  }

  await weightLogRef.add({'weight': weight, 'date': dateToSave});

  _weightController.clear();
  _selectedDate = null;
  _loadWeightEntries();
}


  Future<void> _deleteEntry(String id) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('patients')
        .doc(user.uid)
        .collection('weight_logs')
        .doc(id)
        .delete();

    _loadWeightEntries();
  }

  void _checkForWeightLossWarning() {
    final now = DateTime.now();

    final currentMonthEntries = weightEntries.where((entry) {
      final entryDate = (entry['date'] as Timestamp).toDate();
      return entryDate.year == now.year && entryDate.month == now.month;
    }).toList();

    if (currentMonthEntries.length < 2) {
      if (!mounted) return;
      setState(() => showWarning = false);
      return;
    }

    final weights = currentMonthEntries.map((e) => e['weight'] as double).toList();
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    final minWeight = weights.reduce((a, b) => a < b ? a : b);

    if ((maxWeight - minWeight) >= 5) {
      if (!mounted) return;
      setState(() => showWarning = true);
    } else {
      setState(() => showWarning = false);
    }
  }

  Widget _buildWeightChart() {
    final now = DateTime.now();

    final monthlyEntries = weightEntries.where((entry) {
      final entryDate = (entry['date'] as Timestamp).toDate();
      return entryDate.year == now.year && entryDate.month == now.month;
    }).toList();

    monthlyEntries.sort((a, b) {
      final dateA = (a['date'] as Timestamp).toDate();
      final dateB = (b['date'] as Timestamp).toDate();
      return dateA.compareTo(dateB);
    });

    final spots = monthlyEntries.map((entry) {
      final date = (entry['date'] as Timestamp).toDate();
      final weight = entry['weight'] as double;
      return FlSpot(date.day.toDouble(), weight);
    }).toList();

    if (spots.isEmpty) {
      return const Center(child: Text("No weight data for this month."));
    }

    return RepaintBoundary(
      key: weightChartKey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LineChart(
          LineChartData(
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 5,
                  getTitlesWidget: (value, _) =>
                      Text(value.toInt().toString()),
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, _) =>
                      Text(value.toStringAsFixed(1)),
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Colors.teal,
                barWidth: 3,
                dotData: FlDotData(show: true),
              ),
            ],
            gridData: FlGridData(show: true),
            borderData: FlBorderData(show: true),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Weight Log'),
        backgroundColor: const Color(0xFFA3B18A),
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showWarning)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You have lost more than 5kg in the last month. Please consult your doctor.',
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              const Text(
                "Log Your Weight",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter your weight (kg)',
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 18, horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _submitWeight,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    _selectedDate != null
                        ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                        : 'Pick a date',
                    style: const TextStyle(color: textColor),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        if (!mounted) return;
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                    child: const Text('Change Date'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Monthly Progress',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor),
              ),
              const SizedBox(height: 12),
              SizedBox(height: 200, child: _buildWeightChart()),
              const SizedBox(height: 4),
              const Center(
                child: Text(
                  "Day of the month (left to right), Weight in kg (down to up)",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Previous Entries',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: weightEntries.length,
                itemBuilder: (context, index) {
                  final entry = weightEntries[index];
                  final date = (entry['date'] as Timestamp).toDate();
                  final formattedDate =
                      DateFormat('MMM dd, yyyy').format(date);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${entry['weight']} kg',
                                style: const TextStyle(
                                    fontSize: 16, color: textColor)),
                            Text(formattedDate,
                                style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteEntry(entry['id']),
                        )
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
