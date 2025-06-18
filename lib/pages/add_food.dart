import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

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
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> allFoods = [];
  List<Map<String, dynamic>> filteredFoods = [];
  List<Map<String, dynamic>> favoriteFoods = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _amountController = TextEditingController(text: '1');
  Map<String, dynamic>? _selectedFood;

  @override
  void initState() {
    super.initState();
    _loadFoods();
    _loadFavorites();
  }

  Future<void> _loadFoods() async {
    try {
      final response = await supabase.from('food_database').select().order('Name');
      setState(() {
        allFoods = List<Map<String, dynamic>>.from(response);
        filteredFoods = allFoods;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading foods: $e')),
      );
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14));
      final response = await supabase
          .from('food_diary')
          .select('food_id, Name, Energy, Protein, Carbs, Fat, Serving')
          .eq('user_id', widget.userId)
          .gte('date', twoWeeksAgo.toIso8601String());

      final Map<int, Map<String, dynamic>> foodCountMap = {};

      for (var item in response) {
        final foodId = item['food_id'];
        if (!foodCountMap.containsKey(foodId)) {
          foodCountMap[foodId] = {
            ...item,
            'count': 1,
          };
        } else {
          foodCountMap[foodId]!['count'] += 1;
        }
      }

      final favs = foodCountMap.values.where((food) => food['count'] >= 5).toList();

      setState(() {
        favoriteFoods = favs;
      });
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  void _filterFoods(String query) {
    setState(() {
      filteredFoods = allFoods.where((food) {
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
  void dispose() {
    _searchController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6E4D9),
      appBar: AppBar(
        title: Text('Add Food to ${widget.mealType}'),
        centerTitle: true,
        backgroundColor: const Color(0xFFA3B18A),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
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
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search foods...',
                filled: true,
                fillColor: const Color(0xFFF4F1EA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _filterFoods,
            ),
            const SizedBox(height: 20),
            if (_selectedFood != null) ...[
              Card(
                color: const Color(0xFFF4F1EA),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  filled: true,
                  fillColor: const Color(0xFFF4F1EA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixText: 'x ${_selectedFood!['Serving'] ?? "serving"}',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
            ],
            if (favoriteFoods.isNotEmpty) ...[
              const Text('Favourites', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: favoriteFoods.length,
                  itemBuilder: (context, index) {
                    final food = favoriteFoods[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFood = food;
                          _amountController.text = '1';
                        });
                      },
                      child: Container(
                        width: 140,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F1EA),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(food['Name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('${food['Energy']} kcal'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
            Expanded(
              child: filteredFoods.isEmpty
                  ? const Center(child: Text('No foods found'))
                  : ListView.builder(
                      itemCount: filteredFoods.length,
                      itemBuilder: (context, index) {
                        final food = filteredFoods[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F1EA),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            title: Text(
                              food['Name'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${food['Energy']} kcal | Serving: ${food['Serving']} \n'
'P:${food['Protein']}g C:${food['Carbs']}g F:${food['Fat']}g',

                              style: const TextStyle(color: Colors.black54),
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
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}


