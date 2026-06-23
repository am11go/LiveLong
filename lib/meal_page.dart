import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MealPage extends StatefulWidget {
  const MealPage({Key? key}) : super(key: key);

  @override
  _MealPageState createState() => _MealPageState();
}

// Категория продукта
class _FoodCategory {
  final String name;
  const _FoodCategory(this.name);
}

// Продукт (КБЖУ на 100г) + категория
class _CategorizedFoodProduct {
  final String name;
  final String category;
  final double caloriesPer100;
  final double proteinPer100;
  final double fatPer100;
  final double carbsPer100;

  const _CategorizedFoodProduct(
    this.name, {
    required this.category,
    required this.caloriesPer100,
    required this.proteinPer100,
    required this.fatPer100,
    required this.carbsPer100,
  });
}

class _MealPageState extends State<MealPage> {
  final List<_FoodCategory> _foodCategories = [
    const _FoodCategory('Фрукты'),
    const _FoodCategory('Овощи'),
    const _FoodCategory('Крупы/каши'),
    const _FoodCategory('Мясо/птица'),
    const _FoodCategory('Рыба/морепродукты'),
    const _FoodCategory('Молочные'),
    const _FoodCategory('Яйца'),
    const _FoodCategory('Хлеб/выпечка'),
    const _FoodCategory('Масла'),
    const _FoodCategory('Напитки/йогурты'),
    const _FoodCategory('Бобовые'),
    const _FoodCategory('Орехи/семена'),
    const _FoodCategory('Сладкое (умеренно)'),
  ];

  final List<_CategorizedFoodProduct> _foodDb = [
    // Фрукты
    const _CategorizedFoodProduct('Яблоко', category: 'Фрукты', caloriesPer100: 52, proteinPer100: 0.3, fatPer100: 0.2, carbsPer100: 14.0),
    const _CategorizedFoodProduct('Банан', category: 'Фрукты', caloriesPer100: 89, proteinPer100: 1.1, fatPer100: 0.3, carbsPer100: 22.8),
    const _CategorizedFoodProduct('Апельсин', category: 'Фрукты', caloriesPer100: 47, proteinPer100: 0.9, fatPer100: 0.1, carbsPer100: 12.0),
    const _CategorizedFoodProduct('Груша', category: 'Фрукты', caloriesPer100: 57, proteinPer100: 0.4, fatPer100: 0.2, carbsPer100: 15.0),
    const _CategorizedFoodProduct('Киви', category: 'Фрукты', caloriesPer100: 61, proteinPer100: 1.1, fatPer100: 0.5, carbsPer100: 14.7),
    const _CategorizedFoodProduct('Клубника', category: 'Фрукты', caloriesPer100: 32, proteinPer100: 0.7, fatPer100: 0.3, carbsPer100: 7.7),
    const _CategorizedFoodProduct('Виноград', category: 'Фрукты', caloriesPer100: 69, proteinPer100: 0.7, fatPer100: 0.2, carbsPer100: 18.1),
    const _CategorizedFoodProduct('Персик', category: 'Фрукты', caloriesPer100: 39, proteinPer100: 0.9, fatPer100: 0.3, carbsPer100: 9.5),
    const _CategorizedFoodProduct('Манго', category: 'Фрукты', caloriesPer100: 60, proteinPer100: 0.8, fatPer100: 0.4, carbsPer100: 14.0),

    // Овощи
    const _CategorizedFoodProduct('Салат (листья)', category: 'Овощи', caloriesPer100: 15, proteinPer100: 1.4, fatPer100: 0.2, carbsPer100: 2.9),
    const _CategorizedFoodProduct('Огурец', category: 'Овощи', caloriesPer100: 15, proteinPer100: 0.7, fatPer100: 0.1, carbsPer100: 3.6),
    const _CategorizedFoodProduct('Помидор', category: 'Овощи', caloriesPer100: 18, proteinPer100: 0.9, fatPer100: 0.2, carbsPer100: 3.9),
    const _CategorizedFoodProduct('Морковь', category: 'Овощи', caloriesPer100: 35, proteinPer100: 0.8, fatPer100: 0.2, carbsPer100: 7.0),
    const _CategorizedFoodProduct('Болгарский перец', category: 'Овощи', caloriesPer100: 31, proteinPer100: 1.3, fatPer100: 0.3, carbsPer100: 5.3),
    const _CategorizedFoodProduct('Брокколи', category: 'Овощи', caloriesPer100: 34, proteinPer100: 2.8, fatPer100: 0.4, carbsPer100: 6.6),
    const _CategorizedFoodProduct('Цветная капуста', category: 'Овощи', caloriesPer100: 25, proteinPer100: 1.9, fatPer100: 0.3, carbsPer100: 5.0),
    const _CategorizedFoodProduct('Кабачок', category: 'Овощи', caloriesPer100: 17, proteinPer100: 1.2, fatPer100: 0.3, carbsPer100: 3.1),
    const _CategorizedFoodProduct('Баклажан', category: 'Овощи', caloriesPer100: 24, proteinPer100: 1.0, fatPer100: 0.2, carbsPer100: 5.9),

    // Крупы/каши
    const _CategorizedFoodProduct('Рис отварной', category: 'Крупы/каши', caloriesPer100: 130, proteinPer100: 2.4, fatPer100: 0.3, carbsPer100: 28.0),
    const _CategorizedFoodProduct('Гречка отварная', category: 'Крупы/каши', caloriesPer100: 110, proteinPer100: 3.4, fatPer100: 1.1, carbsPer100: 19.9),
    const _CategorizedFoodProduct('Овсянка', category: 'Крупы/каши', caloriesPer100: 366, proteinPer100: 13.1, fatPer100: 6.9, carbsPer100: 61.0),
    const _CategorizedFoodProduct('Пшено отварное', category: 'Крупы/каши', caloriesPer100: 105, proteinPer100: 3.0, fatPer100: 1.0, carbsPer100: 21.6),
    const _CategorizedFoodProduct('Перловка отварная', category: 'Крупы/каши', caloriesPer100: 123, proteinPer100: 3.5, fatPer100: 0.4, carbsPer100: 25.0),
    const _CategorizedFoodProduct('Киноа отварная', category: 'Крупы/каши', caloriesPer100: 120, proteinPer100: 4.4, fatPer100: 1.9, carbsPer100: 21.3),

    // Мясо/птица
    const _CategorizedFoodProduct('Куриная грудка (готовая)', category: 'Мясо/птица', caloriesPer100: 165, proteinPer100: 31.0, fatPer100: 3.6, carbsPer100: 0.0),
    const _CategorizedFoodProduct('Куриное филе (сырое)', category: 'Мясо/птица', caloriesPer100: 119, proteinPer100: 22.0, fatPer100: 2.6, carbsPer100: 0.0),
    const _CategorizedFoodProduct('Индейка (филе)', category: 'Мясо/птица', caloriesPer100: 135, proteinPer100: 29.0, fatPer100: 1.6, carbsPer100: 0.0),
    const _CategorizedFoodProduct('Говядина постная', category: 'Мясо/птица', caloriesPer100: 250, proteinPer100: 26.0, fatPer100: 15.0, carbsPer100: 0.0),
    const _CategorizedFoodProduct('Свинина постная', category: 'Мясо/птица', caloriesPer100: 242, proteinPer100: 27.0, fatPer100: 14.0, carbsPer100: 0.0),

    // Рыба/морепродукты
    const _CategorizedFoodProduct('Лосось', category: 'Рыба/морепродукты', caloriesPer100: 208, proteinPer100: 20.0, fatPer100: 13.0, carbsPer100: 0.0),
    const _CategorizedFoodProduct('Тунец', category: 'Рыба/морепродукты', caloriesPer100: 132, proteinPer100: 29.0, fatPer100: 1.0, carbsPer100: 0.0),
    const _CategorizedFoodProduct('Креветки', category: 'Рыба/морепродукты', caloriesPer100: 99, proteinPer100: 24.0, fatPer100: 1.0, carbsPer100: 0.2),
    const _CategorizedFoodProduct('Минтай', category: 'Рыба/морепродукты', caloriesPer100: 72, proteinPer100: 15.0, fatPer100: 1.0, carbsPer100: 0.0),

    // Молочные
    const _CategorizedFoodProduct('Творог 5%', category: 'Молочные', caloriesPer100: 121, proteinPer100: 17.2, fatPer100: 5.0, carbsPer100: 2.0),
    const _CategorizedFoodProduct('Йогурт натуральный', category: 'Молочные', caloriesPer100: 59, proteinPer100: 10.0, fatPer100: 0.4, carbsPer100: 3.5),
    const _CategorizedFoodProduct('Молоко 2.5%', category: 'Молочные', caloriesPer100: 52, proteinPer100: 2.8, fatPer100: 2.5, carbsPer100: 4.7),
    const _CategorizedFoodProduct('Сыр твердый', category: 'Молочные', caloriesPer100: 350, proteinPer100: 25.0, fatPer100: 28.0, carbsPer100: 0.5),

    // Яйца
    const _CategorizedFoodProduct('Яйцо куриное', category: 'Яйца', caloriesPer100: 143, proteinPer100: 12.6, fatPer100: 9.5, carbsPer100: 0.7),

    // Хлеб/выпечка
    const _CategorizedFoodProduct('Хлеб пшеничный', category: 'Хлеб/выпечка', caloriesPer100: 247, proteinPer100: 8.5, fatPer100: 3.3, carbsPer100: 41.4),
    const _CategorizedFoodProduct('Хлеб цельнозерновой', category: 'Хлеб/выпечка', caloriesPer100: 220, proteinPer100: 8.0, fatPer100: 3.0, carbsPer100: 40.0),
    const _CategorizedFoodProduct('Овсяное печенье', category: 'Хлеб/выпечка', caloriesPer100: 390, proteinPer100: 6.0, fatPer100: 14.0, carbsPer100: 60.0),

    // Масла
    const _CategorizedFoodProduct('Оливковое масло', category: 'Масла', caloriesPer100: 884, proteinPer100: 0.0, fatPer100: 100.0, carbsPer100: 0.0),
    const _CategorizedFoodProduct('Масло сливочное', category: 'Масла', caloriesPer100: 748, proteinPer100: 0.5, fatPer100: 81.0, carbsPer100: 0.1),

    // Напитки/йогурты
    const _CategorizedFoodProduct('Кефир 1%', category: 'Напитки/йогурты', caloriesPer100: 40, proteinPer100: 3.0, fatPer100: 1.0, carbsPer100: 4.0),
    const _CategorizedFoodProduct('Смузи фруктовый', category: 'Напитки/йогурты', caloriesPer100: 70, proteinPer100: 2.0, fatPer100: 1.0, carbsPer100: 14.0),

    // Бобовые
    const _CategorizedFoodProduct('Чечевица отварная', category: 'Бобовые', caloriesPer100: 116, proteinPer100: 9.0, fatPer100: 0.4, carbsPer100: 20.1),
    const _CategorizedFoodProduct('Нут отварной', category: 'Бобовые', caloriesPer100: 164, proteinPer100: 8.9, fatPer100: 2.6, carbsPer100: 27.4),
    const _CategorizedFoodProduct('Фасоль отварная', category: 'Бобовые', caloriesPer100: 127, proteinPer100: 9.7, fatPer100: 0.5, carbsPer100: 22.0),

    // Орехи/семена
    const _CategorizedFoodProduct('Миндаль', category: 'Орехи/семена', caloriesPer100: 579, proteinPer100: 21.2, fatPer100: 49.9, carbsPer100: 21.6),
    const _CategorizedFoodProduct('Грецкий орех', category: 'Орехи/семена', caloriesPer100: 654, proteinPer100: 15.2, fatPer100: 65.2, carbsPer100: 13.7),
    const _CategorizedFoodProduct('Семена чиа', category: 'Орехи/семена', caloriesPer100: 486, proteinPer100: 16.5, fatPer100: 30.7, carbsPer100: 42.1),

    // Сладкое (умеренно)
    const _CategorizedFoodProduct('Шоколад темный', category: 'Сладкое (умеренно)', caloriesPer100: 550, proteinPer100: 7.0, fatPer100: 31.0, carbsPer100: 51.0),
    const _CategorizedFoodProduct('Мёд', category: 'Сладкое (умеренно)', caloriesPer100: 304, proteinPer100: 0.3, fatPer100: 0.0, carbsPer100: 82.4),
    const _CategorizedFoodProduct('Джем', category: 'Сладкое (умеренно)', caloriesPer100: 250, proteinPer100: 0.3, fatPer100: 0.1, carbsPer100: 63.0),
  ];

  List<_CategorizedFoodProduct> _productsByCategory(String category) {
    return _foodDb.where((p) => p.category == category).toList();
  }

  double _totalCalories = 0.0;
  double _totalProtein = 0.0;
  double _totalFat = 0.0;
  double _totalCarbs = 0.0;

  List<Map<String, dynamic>> _meals = [];
  String? _userId;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.uid;
      });
      _loadNormAndMeals();
    }
  }

  Future<void> _loadNormAndMeals() async {
    if (_userId == null) return;

    // Здесь у вас ранее была логика нормы через BzhuCalculator.
    // Чтобы не ломать текущую задачу UI-логики, держим только загрузку приёмов.
    _loadMeals();
  }

  void _loadMeals() {
    if (_userId == null) return;

    FirebaseFirestore.instance
        .collection('Users')
        .doc(_userId)
        .collection('Meals')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      double calories = 0;
      double protein = 0;
      double fat = 0;
      double carbs = 0;

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      List<Map<String, dynamic>> meals = [];

      for (var doc in snapshot.docs) {
        var data = doc.data();
        var timestamp = data['timestamp'];
        if (timestamp != null) {
          DateTime mealDate = (timestamp as Timestamp).toDate();
          if (mealDate.isAfter(todayStart) ||
              (mealDate.year == todayStart.year &&
                  mealDate.month == todayStart.month &&
                  mealDate.day == todayStart.day)) {
            data['docId'] = doc.id;
            meals.add(data);
            calories += (data['calories'] ?? 0).toDouble();
            protein += (data['protein'] ?? 0).toDouble();
            fat += (data['fat'] ?? 0).toDouble();
            carbs += (data['carbs'] ?? 0).toDouble();
          }
        }
      }

      setState(() {
        _meals = meals;
        _totalCalories = calories;
        _totalProtein = protein;
        _totalFat = fat;
        _totalCarbs = carbs;
      });
    });
  }

  Future<void> _addMeal(String name, double calories, double protein, double fat, double carbs, String mealType) async {
    if (_userId == null) return;

    await FirebaseFirestore.instance
        .collection('Users')
        .doc(_userId)
        .collection('Meals')
        .add({
      'name': name,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
      'mealType': mealType,
      'timestamp': DateTime.now(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Прием пищи добавлен! ($calories ккал)'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteMeal(String docId) async {
    if (_userId == null) return;

    await FirebaseFirestore.instance
        .collection('Users')
        .doc(_userId)
        .collection('Meals')
        .doc(docId)
        .delete();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Прием пищи удален'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showAddMealDialogPickFromDb() {
    // Убрано переключение режимов: оставляем только добавление из базы.
    final initialCategory = _foodCategories.first.name;
    final initialProducts = _productsByCategory(initialCategory);
    final initialProduct =
        initialProducts.isNotEmpty ? initialProducts.first : null;

    _showAddMealDialogFromDb(initialCategory, initialProduct);
  }


  void _showAddMealDialogWithManualInputs() {
    // Ручной ввод уже реализован через _showAddMealDialogWithCategory.
    _showAddMealDialogWithCategory(
      productName: '',
      calories: 0,
      protein: 0,
      fat: 0,
      carbs: 0,
    );
  }


  void _showAddMealDialogFromDb(String initialCategory, _CategorizedFoodProduct? preselectedProduct) {
    final TextEditingController weightController = TextEditingController(text: '100');

    String selectedMealType = 'Завтрак';
    String selectedCategory = initialCategory;

    _CategorizedFoodProduct? selectedProduct = preselectedProduct;

    double parsedWeight() {
      final w = double.tryParse(weightController.text.replaceAll(',', '.')) ?? 0;
      return w.clamp(0, 5000);
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final products = _productsByCategory(selectedCategory);

          if (products.isEmpty) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.restaurant_menu, color: Colors.deepOrange),
                  SizedBox(width: 10),
                  Text('Добавить'),
                ],
              ),
              content: Text('В выбранной категории нет продуктов.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('Ок')),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showAddMealDialogWithManualInputs();
                  },
                  child: const Text('Ручной ввод'),
                ),
              ],
            );
          }

          if (selectedProduct == null || selectedProduct!.category != selectedCategory) {
            selectedProduct = products.first;
          }

          final factor = parsedWeight() / 100.0;
          final calories = selectedProduct!.caloriesPer100 * factor;
          final p = selectedProduct!.proteinPer100 * factor;
          final f = selectedProduct!.fatPer100 * factor;
          final c = selectedProduct!.carbsPer100 * factor;

          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.restaurant_menu, color: Colors.deepOrange),
                SizedBox(width: 10),
                Text('Добавить из базы'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Категория продукта',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _foodCategories
                        .map((c0) => DropdownMenuItem<String>(value: c0.name, child: Text(c0.name)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        selectedCategory = value;
                        final list = _productsByCategory(selectedCategory);
                        selectedProduct = list.isNotEmpty ? list.first : null;
                      });
                    },
                  ),
                  SizedBox(height: 16),

                  DropdownButtonFormField<_CategorizedFoodProduct>(
                    value: selectedProduct,
                    decoration: InputDecoration(
                      labelText: 'Продукт',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    items: products
                        .map((p0) => DropdownMenuItem<_CategorizedFoodProduct>(value: p0, child: Text(p0.name)))
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedProduct = value;
                      });
                    },
                  ),
                  SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: selectedMealType,
                    decoration: InputDecoration(
                      labelText: 'Тип приема пищи',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: ['Завтрак', 'Обед', 'Ужин', 'Перекус']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        selectedMealType = value;
                      });
                    },
                  ),
                  SizedBox(height: 16),

                  TextField(
                    controller: weightController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Вес (г)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.scale),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^[0-9]*[\.,]?[0-9]*')),
                    ],
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  SizedBox(height: 16),

                  Text(
                    'Итоговый КБЖУ',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                  ),
                  SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildDialogMiniChip('Ккал', calories, Colors.deepOrange),
                      _buildDialogMiniChip('Б', p, Colors.red),
                      _buildDialogMiniChip('Ж', f, Colors.yellow.shade700),
                      _buildDialogMiniChip('У', c, Colors.green),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showAddMealDialogWithManualInputs();
                },
                child: const Text('Ручной ввод'),
              ),
              ElevatedButton(
                onPressed: () {
                  final w = parsedWeight();
                  if (w <= 0) return;
                  final factor = w / 100.0;

                  final cal = selectedProduct!.caloriesPer100 * factor;
                  final pp = selectedProduct!.proteinPer100 * factor;
                  final ff = selectedProduct!.fatPer100 * factor;
                  final cc = selectedProduct!.carbsPer100 * factor;

                  _addMeal(selectedProduct!.name, cal, pp, ff, cc, selectedMealType);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                child: Text('Добавить', style: TextStyle(color: Colors.white)),
              ),
              TextButton(onPressed: () => Navigator.pop(context), child: Text('Отмена')),
            ],
          );
        },
      ),
    );
  }

  void _showAddMealDialogWithCategory({
    required String productName,
    required double calories,
    required double protein,
    required double fat,
    required double carbs,
  }) {
    String selectedMealType = 'Завтрак';
    String selectedCategory = _foodCategories.first.name;
    _CategorizedFoodProduct? selectedProduct;

    final byName = _foodDb.where((p) => p.name.toLowerCase() == productName.toLowerCase()).toList();
    if (byName.isNotEmpty) {
      selectedProduct = byName.first;
      selectedCategory = selectedProduct!.category;
    }

    final TextEditingController nameController =
        TextEditingController(text: selectedProduct?.name ?? productName);
    final TextEditingController proteinController =
        TextEditingController(text: (selectedProduct?.proteinPer100 ?? protein).toString());
    final TextEditingController fatController =
        TextEditingController(text: (selectedProduct?.fatPer100 ?? fat).toString());
    final TextEditingController carbsController =
        TextEditingController(text: (selectedProduct?.carbsPer100 ?? carbs).toString());

    double calculatedCalories = calories;

    double calculateCalories(double p, double f, double c) => (p * 4) + (f * 9) + (c * 4);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final p = double.tryParse(proteinController.text) ?? 0;
          final f = double.tryParse(fatController.text) ?? 0;
          final c = double.tryParse(carbsController.text) ?? 0;
          calculatedCalories = calculateCalories(p, f, c);

          final products = _productsByCategory(selectedCategory);

          if (selectedProduct != null && selectedProduct!.category != selectedCategory) {
            selectedProduct = products.isNotEmpty ? products.first : null;
            if (selectedProduct != null) {
              nameController.text = selectedProduct!.name;
              proteinController.text = selectedProduct!.proteinPer100.toString();
              fatController.text = selectedProduct!.fatPer100.toString();
              carbsController.text = selectedProduct!.carbsPer100.toString();
            }
          }

          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.restaurant_menu, color: Colors.deepOrange),
                SizedBox(width: 10),
                Text('Ручной ввод'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Категория продукта',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _foodCategories
                        .map((c0) => DropdownMenuItem(value: c0.name, child: Text(c0.name)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        selectedCategory = value;
                        final list = _productsByCategory(selectedCategory);
                        selectedProduct = list.isNotEmpty ? list.first : null;
                        if (selectedProduct != null) {
                          nameController.text = selectedProduct!.name;
                          proteinController.text = selectedProduct!.proteinPer100.toString();
                          fatController.text = selectedProduct!.fatPer100.toString();
                          carbsController.text = selectedProduct!.carbsPer100.toString();
                        }
                      });
                    },
                  ),
                  SizedBox(height: 16),

                  // Убрано раскрывающееся меню выбора продукта при ручном вводе.
                  // Теперь значения КБЖУ задаются вручную (поля ниже).
                  SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: selectedMealType,
                    decoration: InputDecoration(
                      labelText: 'Тип приема пищи',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: ['Завтрак', 'Обед', 'Ужин', 'Перекус']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        selectedMealType = value;
                      });
                    },
                  ),
                  SizedBox(height: 16),

                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Название блюда',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.edit),
                    ),
                    inputFormatters: [LengthLimitingTextInputFormatter(50)],
                  ),
                  SizedBox(height: 20),

                  Text('БЖУ на 100г', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                  SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: proteinController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Белки',
                            border: OutlineInputBorder(),
                          ),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                          onChanged: (_) => setDialogState(() {}),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: fatController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Жиры',
                            border: OutlineInputBorder(),
                          ),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                          onChanged: (_) => setDialogState(() {}),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: carbsController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Углеводы',
                            border: OutlineInputBorder(),
                          ),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                          onChanged: (_) => setDialogState(() {}),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.deepOrange.shade50, Colors.orange.shade50]),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.deepOrange.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.local_fire_department, color: Colors.deepOrange),
                                SizedBox(width: 8),
                                Text('Калории ', style: TextStyle(fontWeight: FontWeight.w500)),
                              ],
                            ),
                            Text(
                              '${calculatedCalories.toStringAsFixed(0)} ккал',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('Отмена')),
              ElevatedButton(
                onPressed: () {
                  final p = double.tryParse(proteinController.text) ?? 0;
                  final f = double.tryParse(fatController.text) ?? 0;
                  final cc = double.tryParse(carbsController.text) ?? 0;
                  final calcCalories = calculateCalories(p, f, cc);

                  _addMeal(
                    nameController.text.isEmpty ? 'Прием пищи' : nameController.text,
                    calcCalories,
                    p,
                    f,
                    cc,
                    selectedMealType,
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text('Добавить', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDialogMiniChip(String label, double value, Color color) {
    final text = label == 'Ккал' ? '${value.toStringAsFixed(0)} ккал' : '$label: ${value.toStringAsFixed(1)}г';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildNutrientCircle(String label, double value, double max, Color color) {
    final progress = (value / max).clamp(0.0, 1.0);
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 76,
              width: 76,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 7,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            Text(
              '${value.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }


  Widget _buildMiniChip(String label, double value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
      child: Text('$label: ${value.toStringAsFixed(1)}г',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
    );
  }

  IconData _getMealIcon(String? mealType) {
    switch (mealType) {
      case 'Завтрак':
        return Icons.free_breakfast;
      case 'Обед':
        return Icons.lunch_dining;
      case 'Ужин':
        return Icons.dinner_dining;
      case 'Перекус':
        return Icons.cookie;
      default:
        return Icons.restaurant;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text('Питание', style: TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: Colors.deepOrange,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMealDialogPickFromDb,
        backgroundColor: Colors.deepOrange,

        icon: Icon(Icons.add, color: Colors.white),
        label: Text('Добавить', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadMeals();
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 14),
              SizedBox(height: 24),
              Container(

                margin: EdgeInsets.symmetric(horizontal: 16),
                padding: EdgeInsets.all(24),

                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.deepOrange, Colors.orange], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepOrange.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.today, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Дневная норма', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildNutrientCircle('Калории', _totalCalories, 2000, Colors.white),
                        _buildNutrientCircle('Белки', _totalProtein, 50, Colors.white),
                        _buildNutrientCircle('Жиры', _totalFat, 60, Colors.white),
                        _buildNutrientCircle('Углеводы', _totalCarbs, 250, Colors.white),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Приемы пищи сегодня', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.deepOrange.shade50, borderRadius: BorderRadius.circular(20)),
                      child: Text('${_meals.length} приемов',
                          style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.w500, fontSize: 12)),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 10),

              if (_meals.isEmpty)
                Container(
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.restaurant_menu, size: 64, color: Colors.grey.shade300),
                      SizedBox(height: 16),
                      Text('Нет приемов пищи', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500)),
                      SizedBox(height: 8),
                      Text('Нажмите + чтобы добавить первый прием пищи!',
                          style: TextStyle(color: Colors.grey.shade400), textAlign: TextAlign.center),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _meals.length,
                  itemBuilder: (context, index) {
                    var meal = _meals[index];
                    DateTime timestamp = (meal['timestamp'] as Timestamp).toDate();

                    return Dismissible(
                      key: Key(meal['docId'].toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Удалить прием пищи?'),
                            content: Text('Вы уверены, что хотите удалить "${meal['name']}"?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Отмена')),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                child: Text('Удалить'),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) {
                        _deleteMeal(meal['docId'].toString());
                      },
                      child: Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.deepOrange.shade100, shape: BoxShape.circle),
                            child: Icon(_getMealIcon(meal['mealType'] as String?), color: Colors.deepOrange, size: 24),
                          ),
                          title: Text(meal['name'] ?? 'Без названия',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          subtitle: Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.deepOrange.shade50, borderRadius: BorderRadius.circular(10)),
                                      child: Text(meal['mealType'] ?? '', style: TextStyle(fontSize: 11, color: Colors.deepOrange)),
                                    ),
                                    SizedBox(width: 8),
                                    Text(_formatDate(timestamp), style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                                SizedBox(height: 6),
                                Row(
                                  children: [
                                    _buildMiniChip('Б', (meal['protein'] ?? 0).toDouble(), Colors.red),
                                    SizedBox(width: 4),
                                    _buildMiniChip('Ж', (meal['fat'] ?? 0).toDouble(), Colors.yellow.shade700),
                                    SizedBox(width: 4),
                                    _buildMiniChip('У', (meal['carbs'] ?? 0).toDouble(), Colors.green),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${(meal['calories'] ?? 0).toDouble().toStringAsFixed(0)}',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.deepOrange),
                              ),
                              Text('ккал', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

              SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

