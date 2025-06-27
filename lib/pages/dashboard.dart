
  import 'dart:math';
  import 'package:flutter/material.dart';
  import 'package:intl/intl.dart';
  import 'package:flutter_application_1/pages/add_food.dart';
  import 'package:supabase_flutter/supabase_flutter.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:flutter_application_1/pages/progress_tracker.dart';
  import 'package:flutter_application_1/pages/weight_log.dart';
  import 'package:flutter_application_1/pages/settings_page.dart';
  import 'package:flutter_application_1/pages/meal_suggestions.dart';
  class HomeDashboard extends StatefulWidget {
    final String userID;

    const HomeDashboard({Key? key, required this.userID}) : super(key: key);

    @override
    _HomeDashboardState createState() => _HomeDashboardState();
  }

  class _HomeDashboardState extends State<HomeDashboard> {
    final SupabaseClient supabase = Supabase.instance.client;
    Map<String, dynamic>? patientDetails;
    DateTime selectedDate = DateTime.now();
    int totalCalories = 0;
    int totalProtein = 0;

    int? requiredCalories;
    int? requiredProtein;
    int? requiredCarbs;
    int? requiredFat;
    int? requiredFiber;
    int? requiredSugar;

    final List<Map<String, dynamic>> dailyItems = [];

    @override
    void initState() {
      super.initState();
      _loadPatientData();
    }

    Future<void> _loadPatientData() async {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('patients')
            .doc(widget.userID)
            .get();

        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            patientDetails = data;
            _calculateRequirements();
            setState(() {});
            _loadFoodItems();
          }
        } else {
          throw Exception("No patient data found");
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading patient data: $e")),
        );
      }
    }

    void _calculateRequirements() {
      try {
        double heightDouble = double.tryParse(patientDetails?['height']?.toString() ?? '0') ?? 0;
        double weightDouble = double.tryParse(patientDetails?['weight']?.toString() ?? '0') ?? 0;
        int height = heightDouble.round();
        int weight = weightDouble.round();

        if (weight <= 0) weight = 1;
        if (height <= 0) height = 1;

        if (weight > 50) {
          requiredCalories = (30 * weight).clamp(1200, 4000);
          requiredProtein = (weight * 1.5).clamp(50, 200).toInt();
          requiredCarbs = (((requiredCalories ?? 2000) - (requiredProtein ?? 100) * 4) / 8).toInt();
          requiredFat = (((requiredCalories ?? 2000) - (requiredProtein ?? 100) * 4) / 18).toInt();
          requiredFiber = (14 * (requiredCalories ?? 2000) / 1000).clamp(14, 100).toInt();
          requiredSugar = 36;
        } else {
          requiredCalories = (35 * weight).clamp(1200, 4000);
          requiredProtein = (weight * 1.5).clamp(50, 200).toInt();
          requiredCarbs = (((requiredCalories ?? 2000) - (requiredProtein ?? 100) * 4) / 8).toInt();
          requiredFat = (((requiredCalories ?? 2000) - (requiredProtein ?? 100) * 4) / 18).toInt();
          requiredFiber = (14 * (requiredCalories ?? 2000) / 1000).clamp(14, 100).toInt();
          requiredSugar = 30;
        }
      } catch (_) {
        requiredCalories = 2000;
        requiredProtein = 100;
      }
    }

    Future<void> _loadFoodItems() async {
      try {
        final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
        final response = await supabase
            .from('food_diary')
            .select('*, food_database(*)')
            .eq('user_id', widget.userID)
            .eq('date', dateStr);

        setState(() {
          _calculateRequirements();
          dailyItems.clear();
          totalCalories = 0;
          totalProtein = 0;

          for (var entry in response) {
            final food = entry['food_database'] as Map<String, dynamic>?;
            if (food == null) continue;
            final amount = (entry['amount'] as num).toDouble();
            final multiplier = amount;

            final displayItem = {
              'id': entry['id'],
              'name': food['Name'],
              'amount': amount,
              'calories': ((food['Energy'] ?? 0.0) * multiplier).round(),
              'carbs': ((food['Carbs'] ?? 0.0) * multiplier).round(),
              'protein': ((food['Protein'] ?? 0.0) * multiplier).round(),
              'fats': ((food['Fat'] ?? 0.0) * multiplier).round(),
            };

            dailyItems.add(displayItem);
            totalCalories += displayItem['calories'] as int;
            totalProtein += displayItem['protein'] as int;
          }
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading food items: $e')),
        );
      }
    }

    void _nextDay() {
      setState(() {
        selectedDate = selectedDate.add(const Duration(days: 1));
        _loadFoodItems();
      });
    }

    void _previousDay() {
      setState(() {
        selectedDate = selectedDate.subtract(const Duration(days: 1));
        _loadFoodItems();
      });
    }

    void _addFoodItem(String mealType) async {
      final added = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => AddFoodPage(
            mealType: mealType,
            userId: widget.userID,
            selectedDate: selectedDate,
          ),
        ),
      );
      


      if (added == true) {
        _loadFoodItems();
      }
    }

    Future<void> _removeFoodItem(String mealType, Map<String, dynamic> item) async {
      try {
        await supabase.from('food_diary').delete().eq('id', item['id']);
        setState(() {
          dailyItems.remove(item);
          totalCalories = max(0, totalCalories - item['calories'] as int);
          totalProtein = max(0, totalProtein - item['protein'] as int);
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting item: $e')),
        );
      }
    }
    Future<void> _copyYesterdayMeals() async {
  try {
    final yesterday = selectedDate.subtract(const Duration(days: 1));
    final today = selectedDate;
    final yestStr = DateFormat('yyyy-MM-dd').format(yesterday);
    final todayStr = DateFormat('yyyy-MM-dd').format(today);

    final response = await supabase
        .from('food_diary')
        .select()
        .eq('user_id', widget.userID)
        .eq('date', yestStr);

    for (var entry in response) {
      await supabase.from('food_diary').insert({
        'user_id': widget.userID,
        'date': todayStr,
        'food_id': entry['food_id'],
        'amount': entry['amount'],
        'meal_type': entry['meal_type'], // ✅ Add this line
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Copied yesterday's meals.")),
    );

    _loadFoodItems();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error copying meals: $e')),
    );
  }
}



    Widget _dailyIntakeSection() {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
        color: const Color(0xFFF4F1EA),
        margin: const EdgeInsets.symmetric(vertical: 20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Today's Intake", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22)),
              const SizedBox(height: 16),
              if (dailyItems.isEmpty)
                const Center(child: Text("No food items added yet.", style: TextStyle(color: Colors.grey)))
              else
                ...dailyItems.map((item) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                      ),
                      child: ListTile(
                        title: Text("${item['name']} (${item['amount']}g)"),
                        subtitle: Text("${item['calories']} kcal, ${item['protein']}g protein"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _removeFoodItem("Daily", item),
                        ),
                      ),
                    )),
              const SizedBox(height: 12),
Center(
  child: ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: Color(0xFF344E41), // Darker green
      foregroundColor: Colors.white,
    ),
    onPressed: _copyYesterdayMeals,
    icon: Icon(Icons.refresh),
    label: Text("Same as Yesterday"),
  ),
),
const SizedBox(height: 8),
Center(
  child: ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: Color(0xFF588157),
      foregroundColor: Colors.white,
    ),
    onPressed: () => _addFoodItem("Daily"),
    icon: Icon(Icons.add),
    label: Text("Add Food Item"),
  ),
),

            ],
          ),
        ),
      );
    }

    Widget _circularProgress(String label, int value, int? goal, Color color) {
      final int safeGoal = goal ?? 1;
      final double percent = min(max(value / safeGoal, 0.0), 1.0);
      return Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: percent,
                  color: color,
                  backgroundColor: const Color(0xFFDADBC6),
                  strokeWidth: 10,
                ),
              ),
              Column(
                children: [
                  Text("$value", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text("/ $safeGoal", style: const TextStyle(color: Colors.black87)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
        ],
      );
    }

    Widget _modernButton(IconData icon, String label, VoidCallback onPressed) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF4F1EA),
          foregroundColor: Colors.black87,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          elevation: 2,
          shadowColor: Colors.black26,
        ),
      );
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: const Color(0xFFE6E4D9),
        appBar: AppBar(
          title: const Text("Nutrition Dashboard"),
          centerTitle: true,
          backgroundColor: const Color(0xFFA3B18A),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: _previousDay),
                  Text(
                    DateFormat('EEE, MMM d, yyyy').format(selectedDate),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  IconButton(icon: const Icon(Icons.arrow_forward_ios), onPressed: _nextDay),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _circularProgress("Calories", totalCalories, requiredCalories, Colors.teal),
                  _circularProgress("Protein", totalProtein, requiredProtein, Colors.teal),
                ],
              ),
              const SizedBox(height: 20),
              _dailyIntakeSection(),
              const SizedBox(height: 20),
              const Divider(thickness: 1.5),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _modernButton(Icons.show_chart, "Progress", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProgressTrackerPage(
                          userId: widget.userID,
                          requiredCalories: requiredCalories ?? 2000,
                          requiredProtein: requiredProtein ?? 100,
                          requiredCarbs: requiredCarbs ?? 125,
                          requiredFat: requiredFat ?? 56,
                          requiredFiber: requiredFiber ?? 28,
                          requiredSugar: requiredSugar ?? 30,
                        ),
                      ),
                    );
                  }),
                  _modernButton(Icons.restaurant_menu, "Meal Plans", () {
                    Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => MealSuggestionsPage(userId: widget.userID)),
  );


                  }),
                  _modernButton(Icons.monitor_weight, "Weight Log", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const WeightLogPage()),
                    );
                  }),
                  _modernButton(Icons.settings, "Settings", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsPage()),
                    );
                  }),
                ],
              )
            ],
          ),
        ),
      );
    }
  }

