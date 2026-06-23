import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminDbWorkView extends StatefulWidget {
  const AdminDbWorkView({super.key});

  @override
  State<AdminDbWorkView> createState() => _AdminDbWorkViewState();
}

class _AdminDbWorkViewState extends State<AdminDbWorkView> {
  int _subIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Material(
            color: Theme.of(context).cardColor,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => setState(() => _subIndex = 0),
                        icon: const Icon(Icons.people),
                        label: Text(
                          'Пользователи',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _subIndex == 0 ? Colors.deepOrange : null,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => setState(() => _subIndex = 1),
                        icon: const Icon(Icons.storage),
                        label: Text(
                          'Продукты',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _subIndex == 1 ? Colors.deepOrange : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _subIndex == 0 ? const UsersCrudView() : const ProductsCrudView(),
          ),
        ],
      ),
    );
  }
}

class UsersCrudView extends StatefulWidget {
  const UsersCrudView({super.key});

  @override
  State<UsersCrudView> createState() => _UsersCrudViewState();
}

class _UsersCrudViewState extends State<UsersCrudView> {
  String _sortBy = 'name';
  bool _ascending = true;
  final List<Map<String, dynamic>> _usersList = [];

  void _sortUsers(List<Map<String, dynamic>> list) {
    list.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'name':
          comparison = (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString());
          break;
        case 'email':
          comparison = (a['email'] ?? '').toString().compareTo((b['email'] ?? '').toString());
          break;
        case 'age':
          comparison = ((a['age'] ?? 0)).compareTo((b['age'] ?? 0));
          break;
        default:
          comparison = 0;
      }
      return _ascending ? comparison : -comparison;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text(
                'Пользователи',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              DropdownButton<String>(
                value: _sortBy,
                items: const [
                  DropdownMenuItem(value: 'name', child: Text('По имени')),
                  DropdownMenuItem(value: 'email', child: Text('По email')),
                  DropdownMenuItem(value: 'age', child: Text('По возрасту')),
                ],
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                  });
                },
              ),
              IconButton(
                icon: Icon(_ascending ? Icons.arrow_upward : Icons.arrow_downward),
                onPressed: () {
                  setState(() {
                    _ascending = !_ascending;
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('Users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Ошибка: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Center(child: Text('Нет пользователей'));
              }

              _usersList.clear();
              for (final doc in docs) {
                final data = doc.data() as Map<String, dynamic>;
                data['id'] = doc.id;
                _usersList.add(data);
              }

              _sortUsers(_usersList);

              return ListView.builder(
                itemCount: _usersList.length,
                itemBuilder: (context, index) {
                  final userData = _usersList[index];
                  final userId = userData['id'];

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.deepOrange,
                        child: Text(
                          userData['name']?.toString().substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(userData['name'] ?? 'Без имени'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userData['email'] ?? 'Нет email'),
                          Text('Возраст: ${userData['age'] ?? 'N/A'} | Пол: ${userData['gender'] ?? 'N/A'}'),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit),
                                SizedBox(width: 8),
                                Text('Редактировать'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Удалить', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditUserDialog(context, userId, userData);
                          } else if (value == 'delete') {
                            _showDeleteConfirmation(context, userId, userData['name']);
                          }
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showEditUserDialog(BuildContext context, String userId, Map<String, dynamic> userData) {
    final nameController = TextEditingController(text: userData['name']?.toString());
    final emailController = TextEditingController(text: userData['email']?.toString());
    final ageController = TextEditingController(text: userData['age']?.toString());
    final heightController = TextEditingController(text: userData['height']?.toString());
    final weightController = TextEditingController(text: userData['weight']?.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактирование пользователя'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Имя')),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
              TextField(
                controller: ageController,
                decoration: const InputDecoration(labelText: 'Возраст'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: heightController,
                decoration: const InputDecoration(labelText: 'Рост'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: weightController,
                decoration: const InputDecoration(labelText: 'Вес'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('Users').doc(userId).update({
                'name': nameController.text,
                'email': emailController.text,
                'age': int.tryParse(ageController.text),
                'height': int.tryParse(heightController.text),
                'weight': int.tryParse(weightController.text),
              });

              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Пользователь обновлен')));
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String userId, dynamic userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление пользователя'),
        content: Text('Вы уверены, что хотите удалить пользователя ${userName ?? ''}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('Users').doc(userId).delete();
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Пользователь удален')));
              } catch (e) {
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка удаления: $e')));
              }
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}

class ProductsCrudView extends StatefulWidget {
  const ProductsCrudView({super.key});

  @override
  State<ProductsCrudView> createState() => _ProductsCrudViewState();
}

class _ProductsCrudViewState extends State<ProductsCrudView> {
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();

  // Nutrition per 100g/ml
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fatController = TextEditingController();
  final _carbsController = TextEditingController();

  // Optional: for UI compatibility with old schema
  final _descController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _descController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _carbsController.dispose();
    super.dispose();
  }

  Future<void> _addProduct() async {
    final name = _nameController.text.trim();
    final category = _categoryController.text.trim();

    if (name.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введите название продукта')));
      return;
    }
    if (category.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введите вид продукта / категорию')));
      return;
    }

    final calories = double.tryParse(_caloriesController.text.trim().replaceAll(',', '.'));
    final protein = double.tryParse(_proteinController.text.trim().replaceAll(',', '.'));
    final fat = double.tryParse(_fatController.text.trim().replaceAll(',', '.'));
    final carbs = double.tryParse(_carbsController.text.trim().replaceAll(',', '.'));

    if (calories == null || protein == null || fat == null || carbs == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введите КБЖУ и калории числами')));
      return;
    }

    await FirebaseFirestore.instance.collection('Products').add({
      'name': name,
      'category': category,

      // Nutrition per 100g/ml
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carbs': carbs,

      // legacy / optional
      'description': _descController.text.trim(),

      'timestamp': FieldValue.serverTimestamp(),
    });

    if (!context.mounted) return;
    _nameController.clear();
    _categoryController.clear();
    _descController.clear();
    _caloriesController.clear();
    _proteinController.clear();
    _fatController.clear();
    _carbsController.clear();

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Продукт добавлен')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Продукты',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Название'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    tooltip: 'Добавить продукт',
                    icon: const Icon(Icons.add_circle, color: Colors.deepOrange),
                    onPressed: _addProduct,
                  )
                ],
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _categoryController,
                      decoration: const InputDecoration(labelText: 'Вид продукта / категория'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _descController,
                      decoration: const InputDecoration(labelText: 'Описание (опционально)'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _caloriesController,
                      decoration: const InputDecoration(labelText: 'Калории (на 100г/мл)'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _proteinController,
                      decoration: const InputDecoration(labelText: 'Белки (Б) на 100г/мл'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _fatController,
                      decoration: const InputDecoration(labelText: 'Жиры (Ж) на 100г/мл'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _carbsController,
                      decoration: const InputDecoration(labelText: 'Углеводы (У) на 100г/мл'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Products')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Ошибка: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Center(child: Text('Нет продуктов'));
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;

                  final productId = doc.id;
                  final name = data['name']?.toString() ?? 'Без названия';
                  final description = data['description']?.toString() ?? '';
                  final calories = data['calories'];
                  final protein = data['protein'];
                  final fat = data['fat'];
                  final carbs = data['carbs'];

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.deepOrange,
                        child: Text(
                          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'P',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(name),
                      subtitle: Text(
                        'Ккал: ${calories ?? 'N/A'}\n'
                        'Б: ${protein ?? 'N/A'}  '
                        'Ж: ${fat ?? 'N/A'}\n'
                        'У: ${carbs ?? 'N/A'}'
                        '${description.isNotEmpty ? '\n$description' : ''}',
                      ),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit),
                                SizedBox(width: 8),
                                Text('Редактировать'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Удалить', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditProductDialog(context, productId, data);
                          } else if (value == 'delete') {
                            _showDeleteProductDialog(context, productId, name);
                          }
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showEditProductDialog(BuildContext context, String productId, Map<String, dynamic> data) {
    final nameController = TextEditingController(text: data['name']?.toString());
    final categoryController = TextEditingController(text: data['category']?.toString());
    final descController = TextEditingController(text: data['description']?.toString());

    final caloriesController = TextEditingController(text: data['calories']?.toString());
    final proteinController = TextEditingController(text: data['protein']?.toString());
    final fatController = TextEditingController(text: data['fat']?.toString());
    final carbsController = TextEditingController(text: data['carbs']?.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактирование продукта'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Название'),
              ),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Вид продукта / категория'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Описание'),
              ),
              TextField(
                controller: caloriesController,
                decoration: const InputDecoration(labelText: 'Калории (на 100г/мл)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              TextField(
                controller: proteinController,
                decoration: const InputDecoration(labelText: 'Белки (Б) на 100г/мл'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              TextField(
                controller: fatController,
                decoration: const InputDecoration(labelText: 'Жиры (Ж) на 100г/мл'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              TextField(
                controller: carbsController,
                decoration: const InputDecoration(labelText: 'Углеводы (У) на 100г/мл'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Название не может быть пустым')),
                );
                return;
              }

              final category = categoryController.text.trim();
              if (category.isEmpty) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Категория не может быть пустой')),
                );
                return;
              }

              final calories = double.tryParse(caloriesController.text.trim().replaceAll(',', '.'));
              final protein = double.tryParse(proteinController.text.trim().replaceAll(',', '.'));
              final fat = double.tryParse(fatController.text.trim().replaceAll(',', '.'));
              final carbs = double.tryParse(carbsController.text.trim().replaceAll(',', '.'));

              if (calories == null || protein == null || fat == null || carbs == null) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Введите КБЖУ и калории числами')),
                );
                return;
              }

              await FirebaseFirestore.instance.collection('Products').doc(productId).update({
                'name': name,
                'category': category,
                'description': descController.text.trim(),
                'calories': calories,
                'protein': protein,
                'fat': fat,
                'carbs': carbs,
              });

              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Продукт обновлен')),
              );
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _showDeleteProductDialog(BuildContext context, String productId, String productName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление продукта'),
        content: Text('Вы уверены, что хотите удалить продукт "$productName"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('Products').doc(productId).delete();
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Продукт удален')),
                );
              } catch (e) {
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка удаления: $e')),
                );
              }
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}

