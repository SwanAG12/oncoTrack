import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color primaryColor = Color(0xFFA8D5BA); // Soft Sage
const Color bgColor = Color(0xFFFAF3EC); // Light Beige
const Color textColor = Color(0xFF333333); // Deep Charcoal

class MealSuggestionsPage extends StatefulWidget {
  final String userId;
  const MealSuggestionsPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<MealSuggestionsPage> createState() => _MealSuggestionsPageState();
}

class _MealSuggestionsPageState extends State<MealSuggestionsPage> {
  late Future<List<MealSuggestion>> _mealSuggestions;

  @override
  void initState() {
    super.initState();
    _mealSuggestions = _loadMealSuggestions();
  }

  Future<Map<String, dynamic>?> _getPatientDetails(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('patients').doc(userId).get();
      if (snapshot.exists) {
        return snapshot.data();
      }
    } catch (e) {
      debugPrint("Error fetching patient details: $e");
    }
    return null;
  }

  Future<List<MealSuggestion>> _fetchMealSuggestionsFromSupabase(Map<String, dynamic> details) async {
    final supabase = Supabase.instance.client;

    final rawCondition = (details['medicalCondition'] ?? '').toString().trim().toLowerCase();
    final medicalCondition = rawCondition == 'diabetic' ? 'Diabetic' : 'Normal';

    final dietPreference = (details['dietPreference'] ?? '').toString().trim();
    final foodType = (details['foodType'] ?? '').toString().trim();
    final preferredFoodTexture = (details['preferredFoodTexture'] ?? '').toString().trim();

    debugPrint("🔍 Querying Supabase with:");
    debugPrint("  medicalCondition: '$medicalCondition'");
    debugPrint("  dietPreference: '$dietPreference'");
    debugPrint("  foodType: '$foodType'");
    debugPrint("  preferredFoodTexture: '$preferredFoodTexture'");

    final response = await supabase
        .from('meal_suggestions')
        .select()
        .eq('medicalCondition', medicalCondition)
        .eq('dietPreference', dietPreference)
        .eq('foodType', foodType)
        .eq('preferredFoodTexture', preferredFoodTexture);

    debugPrint("✅ Supabase returned ${response.length} rows");
    return response.map((e) => MealSuggestion.fromMap(e)).toList();
  }

  Future<List<MealSuggestion>> _loadMealSuggestions() async {
    final details = await _getPatientDetails(widget.userId);
    if (details == null) throw Exception('No patient details found.');
    return await _fetchMealSuggestionsFromSupabase(details);
  }

  Map<String, List<MapEntry<String, String>>> _groupSuggestionsByDay(List<MealSuggestion> suggestions) {
    final Map<String, List<MapEntry<String, String>>> dayMap = {
      'Sunday': [],
      'Monday': [],
      'Tuesday': [],
      'Wednesday': [],
      'Thursday': [],
      'Friday': [],
      'Saturday': [],
    };

    for (final suggestion in suggestions) {
      suggestion.meals.forEach((day, meal) {
        if (meal.trim().isNotEmpty) {
          dayMap[day]?.add(MapEntry(suggestion.time, meal));
        }
      });
    }

    return dayMap;
  }

  Widget _buildDayCard(String day, List<MapEntry<String, String>> meals) {
    if (meals.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                ...meals.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("• ", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              text: '${entry.key}: ',
                              style: const TextStyle(color: textColor, fontWeight: FontWeight.w600),
                              children: [
                                TextSpan(
                                  text: entry.value,
                                  style: const TextStyle(fontWeight: FontWeight.normal),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
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
  backgroundColor: bgColor,
  elevation: 0,
  automaticallyImplyLeading: false,
  leading: IconButton(
    icon: const Icon(Icons.arrow_back, color: primaryColor),
    onPressed: () => Navigator.of(context).pop(),
  ),
  centerTitle: true,
  title: const Text(
    "OncoTrack",
    style: TextStyle(
      color: primaryColor,
      fontWeight: FontWeight.bold,
      fontSize: 22,
    ),
  ),
  bottom: PreferredSize(
    preferredSize: const Size.fromHeight(50),
    child: Column(
      children: const [
        Text(
          "Meal Suggestions",
          style: TextStyle(
            color: primaryColor,
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
        ),
        SizedBox(height: 2),
        Text(
          "Made by a certified dietician",
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        SizedBox(height: 8),
      ],
    ),
  ),
),


      body: SafeArea(
        child: FutureBuilder<List<MealSuggestion>>(
          future: _mealSuggestions,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No meal suggestions found."));
            }

            final suggestionsByDay = _groupSuggestionsByDay(snapshot.data!);

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: suggestionsByDay.length,
              itemBuilder: (context, index) {
                final day = suggestionsByDay.keys.elementAt(index);
                final meals = suggestionsByDay[day]!;
                return _buildDayCard(day, meals);
              },
            );
          },
        ),
      ),
    );
  }
}

class MealSuggestion {
  final String time;
  final Map<String, String> meals;

  MealSuggestion({
    required this.time,
    required this.meals,
  });

  factory MealSuggestion.fromMap(Map<String, dynamic> map) {
    return MealSuggestion(
      time: map['time'] ?? '',
      meals: {
        'Sunday': map['Sunday'] ?? '',
        'Monday': map['Monday'] ?? '',
        'Tuesday': map['Tuesday'] ?? '',
        'Wednesday': map['Wednesday'] ?? '',
        'Thursday': map['Thursday'] ?? '',
        'Friday': map['Friday'] ?? '',
        'Saturday': map['Saturday'] ?? '',
      },
    );
  }
}
