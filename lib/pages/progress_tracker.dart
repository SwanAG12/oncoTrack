import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProgressTrackerPage extends StatelessWidget {
  final String userId;
  final int requiredCalories;
  final int requiredProtein;
  final int requiredCarbs;
  final int requiredFat;
  final int requiredFiber;
  final int requiredSugar;

  const ProgressTrackerPage({
    Key? key,
    required this.userId,
    required this.requiredCalories,
    required this.requiredProtein,
    required this.requiredCarbs,
    required this.requiredFat,
    required this.requiredFiber,
    required this.requiredSugar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFE6E4D9),
        appBar: AppBar(
          title: const Text("Progress Tracker"),
          centerTitle: true,
          backgroundColor: const Color(0xFFA3B18A),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Daily"),
              Tab(text: "Weekly"),
              Tab(text: "Monthly"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            DailyTracker(
              userId: userId,
              requiredCalories: requiredCalories,
              requiredProtein: requiredProtein,
              requiredCarbs: requiredCarbs,
              requiredFat: requiredFat,
              requiredFiber: requiredFiber,
              requiredSugar: requiredSugar,
            ),
            WeeklyTracker(
              userId: userId,
              requiredCalories: requiredCalories,
              requiredProtein: requiredProtein,
              requiredCarbs: requiredCarbs,
              requiredFat: requiredFat,
              requiredFiber: requiredFiber,
              requiredSugar: requiredSugar,
            ),
            MonthlyTracker(
              userId: userId,
              requiredCalories: requiredCalories,
              requiredProtein: requiredProtein,
            ),
          ],
        ),
      ),
    );
  }
}

// === DAILY TRACKER (unchanged from your latest) ===
class DailyTracker extends StatefulWidget {
  final String userId;
  final int requiredCalories;
  final int requiredProtein;
  final int requiredCarbs;
  final int requiredFat;
  final int requiredFiber;
  final int requiredSugar;

  const DailyTracker({
    Key? key,
    required this.userId,
    required this.requiredCalories,
    required this.requiredProtein,
    required this.requiredCarbs,
    required this.requiredFat,
    required this.requiredFiber,
    required this.requiredSugar,
  }) : super(key: key);

  @override
  _DailyTrackerState createState() => _DailyTrackerState();
}

class _DailyTrackerState extends State<DailyTracker> {
  final supabase = Supabase.instance.client;
  double todayCalories = 0;
  double todayProtein = 0;
  double todayCarbs = 0;
  double todayFats = 0;
  double todayFiber = 0;
  double todaySugar = 0;

  @override
  void initState() {
    super.initState();
    _loadDailyData();
  }

  Future<void> _loadDailyData() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final response = await supabase
        .from('food_diary')
        .select('Energy, Protein, Carbs, Fat, Fiber, Sugar')
        .eq('user_id', widget.userId)
        .eq('date', today);

    double cal = 0;
    double prot = 0;
    double carbs = 0;
    double fats = 0;
    double fiber = 0;
    double sugar = 0;

    for (var entry in response) {
      cal += (entry['Energy'] ?? 0).toDouble();
      prot += (entry['Protein'] ?? 0).toDouble();
      carbs += (entry['Carbs'] ?? 0).toDouble();
      fats += (entry['Fat'] ?? 0).toDouble();
      fiber += (entry['Fiber'] ?? 0).toDouble();
      sugar += (entry['Sugar'] ?? 0).toDouble();
    }
    if (!mounted) return;

    setState(() {
      todayCalories = cal;
      todayProtein = prot;
      todayCarbs = carbs;
      todayFats = fats;
      todayFiber = fiber;
      todaySugar = sugar;
    });
  }

  Widget _lineStat(String label, double value, double goal, Color color) {
    final double percent = (value / goal).clamp(0.0, 1.0);
    return Column(
      children: [
        LinearProgressIndicator(
          value: percent,
          backgroundColor: const Color(0xFFDADBC6),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            Text("${value.toStringAsFixed(1)}", style: TextStyle(color: color, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _lineStat("Calories", todayCalories, widget.requiredCalories.toDouble(), const Color(0xFF8E8D8A)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _lineStat("Protein", todayProtein, widget.requiredProtein.toDouble(), const Color(0xFFA3B18A)),
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Divider(thickness: 1.5),
          const SizedBox(height: 10),
          _lineStat("Carbohydrates", todayCarbs, widget.requiredCarbs.toDouble(), const Color(0xFFB7B7A4)),
          _lineStat("Fats", todayFats, widget.requiredFat.toDouble(), const Color(0xFF9A8C98)),
          _lineStat("Fiber", todayFiber, widget.requiredFiber.toDouble(), const Color(0xFFB5B5B5)),
          _lineStat("Sugar", todaySugar, widget.requiredSugar.toDouble(), const Color(0xFFDADBC6)),
        ],
      ),
    );
  }
}

// === WEEKLY TRACKER (FIXED) ===
class WeeklyTracker extends StatefulWidget {
  final String userId;
  final int requiredCalories;
  final int requiredProtein;
  final int requiredCarbs;
  final int requiredFat;
  final int requiredFiber;
  final int requiredSugar;

  const WeeklyTracker({
    Key? key,
    required this.userId,
    required this.requiredCalories,
    required this.requiredProtein,
    required this.requiredCarbs,
    required this.requiredFat,
    required this.requiredFiber,
    required this.requiredSugar,
  }) : super(key: key);

  @override
  _WeeklyTrackerState createState() => _WeeklyTrackerState();
}

class _WeeklyTrackerState extends State<WeeklyTracker> {
  final supabase = Supabase.instance.client;

  double avgCalories = 0;
  double avgProtein = 0;
  double avgCarbs = 0;
  double avgFats = 0;
  double avgFiber = 0;
  double avgSugar = 0;

  @override
  void initState() {
    super.initState();
    _loadWeeklyData();
  }

  Future<void> _loadWeeklyData() async {
    final today = DateTime.now();
    final start = today.subtract(const Duration(days: 6));
    int validDays = 0;

    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFats = 0;
    double totalFiber = 0;
    double totalSugar = 0;

    for (int i = 0; i < 7; i++) {
      final date = start.add(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      final response = await supabase
          .from('food_diary')
          .select('Energy, Protein, Carbs, Fat, Fiber, Sugar')
          .eq('user_id', widget.userId)
          .eq('date', dateStr);

      if (response.isNotEmpty) {
        validDays++;
        for (var entry in response) {
          totalCalories += (entry['Energy'] ?? 0).toDouble();
          totalProtein += (entry['Protein'] ?? 0).toDouble();
          totalCarbs += (entry['Carbs'] ?? 0).toDouble();
          totalFats += (entry['Fat'] ?? 0).toDouble();
          totalFiber += (entry['Fiber'] ?? 0).toDouble();
          totalSugar += (entry['Sugar'] ?? 0).toDouble();
        }
      }
    }

    if (validDays > 0) {
      setState(() {
        avgCalories = totalCalories / validDays;
        avgProtein = totalProtein / validDays;
        avgCarbs = totalCarbs / validDays;
        avgFats = totalFats / validDays;
        avgFiber = totalFiber / validDays;
        avgSugar = totalSugar / validDays;
      });
    }
  }

  Widget _lineStat(String label, double value, double goal, Color color) {
    final double percent = (value / goal).clamp(0.0, 1.0);
    return Column(
      children: [
        LinearProgressIndicator(
          value: percent,
          backgroundColor: const Color(0xFFDADBC6),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            Text("${value.toStringAsFixed(1)}", style: TextStyle(color: color, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text("Weekly Averages", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _lineStat("Calories", avgCalories, widget.requiredCalories.toDouble(), const Color(0xFF8E8D8A)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _lineStat("Protein", avgProtein, widget.requiredProtein.toDouble(), const Color(0xFFA3B18A)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(thickness: 1.5),
          const SizedBox(height: 10),
          _lineStat("Carbohydrates", avgCarbs, widget.requiredCarbs.toDouble(), const Color(0xFFB7B7A4)),
          _lineStat("Fats", avgFats, widget.requiredFat.toDouble(), const Color(0xFF9A8C98)),
          _lineStat("Fiber", avgFiber, widget.requiredFiber.toDouble(), const Color(0xFFB5B5B5)),
          _lineStat("Sugar", avgSugar, widget.requiredSugar.toDouble(), const Color(0xFFDADBC6)),
        ],
      ),
    );
  }
}


class MonthlyTracker extends StatefulWidget {
  final String userId;
  final int requiredCalories;
  final int requiredProtein;

  const MonthlyTracker({
    Key? key,
    required this.userId,
    required this.requiredCalories,
    required this.requiredProtein,
  }) : super(key: key);

  @override
  _MonthlyTrackerState createState() => _MonthlyTrackerState();
}

class _MonthlyTrackerState extends State<MonthlyTracker> {
  final supabase = Supabase.instance.client;
  Map<DateTime, double> completionMap = {};

  @override
  void initState() {
    super.initState();
    _loadMonthlyData();
  }

  Future<void> _loadMonthlyData() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    final dateFormat = DateFormat('yyyy-MM-dd');

    final response = await supabase
        .from('food_diary')
        .select('date, Energy, Protein')
        .eq('user_id', widget.userId)
        .gte('date', dateFormat.format(startOfMonth))
        .lte('date', dateFormat.format(endOfMonth));

    Map<DateTime, List<Map<String, dynamic>>> grouped = {};

    for (var entry in response) {
      DateTime rawDate = dateFormat.parse(entry['date']);
      DateTime normalizedDate = DateTime(rawDate.year, rawDate.month, rawDate.day);

      grouped.putIfAbsent(normalizedDate, () => []).add(entry);
    }

    Map<DateTime, double> newCompletionMap = {};
    grouped.forEach((date, entries) {
      double cal = 0;
      double prot = 0;
      for (var entry in entries) {
        cal += (entry['Energy'] ?? 0).toDouble();
        prot += (entry['Protein'] ?? 0).toDouble();
      }

      if (widget.requiredCalories > 0 && widget.requiredProtein > 0) {
        double percent = (((cal / widget.requiredCalories) + (prot / widget.requiredProtein)) / 2) * 100;
        newCompletionMap[date] = percent;
      }
    });

    if (mounted) {
      setState(() {
        completionMap = newCompletionMap;
      });
    }
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

@override
Widget build(BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // Center align all children
            children: [
              TableCalendar(
                focusedDay: DateTime.now(),
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                calendarFormat: CalendarFormat.month,
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Month',
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final matchedDate = completionMap.keys.firstWhere(
                      (d) => d.year == day.year && d.month == day.month && d.day == day.day,
                      orElse: () => DateTime(2000),
                    );

                    final percent = completionMap[matchedDate] ?? 0;

                    Color color;
                    if (percent >= 90) {
                      color = Colors.green;
                    } else if (percent >= 75) {
                      color = Colors.yellow;
                    } else if (percent > 0) {
                      color = Colors.red;
                    } else {
                      color = Colors.transparent;
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: Text('${day.day}')),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Legend",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildLegendItem(Colors.green, "Hit 90%+ of calorie & protein goal"),
                  _buildLegendItem(Colors.yellow, "Hit 75%+ of calorie & protein goal"),
                  _buildLegendItem(Colors.red, "Below 75% of your goals"),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(thickness: 1.5),
              const SizedBox(height: 12),
              const Text(
                "Even 1% is forward.",
                style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    },
  );
}


}
