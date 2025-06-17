import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddFoodPage extends StatefulWidget {
  final String mealType;
  final String userId;
  final DateTime selectedDate;

  const AddFoodPage({
    Key? key,
    required this.mealType,
    required this.userId,
    required this.selectedDate,
  }) : super(key: key);

  @override
  _AddFoodPageState createState() => _AddFoodPageState();
}

class _AddFoodPageState extends State<AddFoodPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _foods = [];
  List<Map<String, dynamic>> _filteredFoods = [];
  TextEditingController _searchController = TextEditingController();
  TextEditingController _amountController = TextEditingController(text: '1');
  Map<String, dynamic>? _selectedFood;

  @override
  void initState() {
    super.initState();
    _amountController.text = '1'; // Default to 1 serving
    _loadFoods();
  }

  Future<void> _loadFoods() async {
  try {
    final response = await supabase
        .from('food_database')
        .select('*')
        .order('Name', ascending: true);

    print('Fetched foods: $response'); // ✅ DEBUG PRINT

    setState(() {
      _foods = List<Map<String, dynamic>>.from(response);
      _filteredFoods = _foods;
    });
  } catch (e) {
    print('Error loading foods: $e'); // ✅ DEBUG PRINT
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error loading foods: $e')),
    );
  }
}

  void _searchFoods(String query) {
    setState(() {
      _filteredFoods = _foods.where((food) {
        final name = food['Name'].toString().toLowerCase();
        return name.contains(query.toLowerCase());
      }).toList();
    });
  }

  Future<void> _addFoodToDiary() async {
    if (_selectedFood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a food first')),
      );
      return;
    }

    final servings = double.tryParse(_amountController.text) ?? 1.0;

    try {
      await supabase.from('food_diary').insert({
        'user_id': widget.userId,
        'meal_type': widget.mealType.toLowerCase(),
        'date': widget.selectedDate.toIso8601String(),
        'food_id': _selectedFood!['id'],
        'amount': servings,
        'Name': _selectedFood!['Name'],
        'Group': _selectedFood!['Group'],
        'Serving': _selectedFood!['Serving'],
        'Energy': (_selectedFood!['Energy'] ?? 0) * servings,
        'Protein': (_selectedFood!['Protein'] ?? 0) * servings,
        'Fat': (_selectedFood!['Fat'] ?? 0) * servings,
        'Carbs': (_selectedFood!['Carbs'] ?? 0) * servings,
        'Fiber': (_selectedFood!['Fiber'] ?? 0) * servings,
        'Sugar': (_selectedFood!['Sugar'] ?? 0) * servings,
        'Sodium': (_selectedFood!['Sodium'] ?? 0) * servings,
      });

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding food: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Food to ${widget.mealType}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _addFoodToDiary,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search foods',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _searchFoods,
            ),
            const SizedBox(height: 16),
            if (_selectedFood != null) ...[
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedFood!['Name'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Serving Size: ${_selectedFood!['Serving'] ?? '1 serving'}',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Energy: ${_selectedFood!['Energy'] ?? 0} kcal'),
                          Text('Protein: ${_selectedFood!['Protein'] ?? 0}g'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Carbs: ${_selectedFood!['Carbs'] ?? 0}g'),
                          Text('Fat: ${_selectedFood!['Fat'] ?? 0}g'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Number of servings',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixText: 'x ${_selectedFood!['Serving'] ?? "serving"}',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: ListView.builder(
                itemCount: _filteredFoods.length,
                itemBuilder: (context, index) {
                  final food = _filteredFoods[index];
                  return ListTile(
                    title: Text(food['Name'] ?? ''),
                    subtitle: Text(
                      '${food['Energy'] ?? 0} kcal | Serving: ${food['Serving'] ?? "serving"}\n'
                      'P:${food['Protein'] ?? 0}g C:${food['Carbs'] ?? 0}g F:${food['Fat'] ?? 0}g',
                    ),
                    trailing: _selectedFood?['id'] == food['id']
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedFood = food;
                        _amountController.text = '1';
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}
