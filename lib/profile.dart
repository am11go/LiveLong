import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:livelong_flutter/home.dart';
import 'package:livelong_flutter/uihelper.dart';
import 'loginpage.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController ageController = TextEditingController();
  TextEditingController heightController = TextEditingController();
  TextEditingController weightController = TextEditingController();
  String gender = '';

  signUp() async {
    if (emailController.text == "" ||
        passwordController.text == "" ||
        nameController.text == "" ||
        ageController.text == "" ||
        gender == "" ||
        heightController.text == "" ||
        weightController.text == "") {
      UiHelper.CustomAlertBox(context, "Введите все обязательные поля");
    } else {
      try {
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );

        // Store user information in Firestore
        FirebaseFirestore.instance
            .collection('Users')
            .doc(userCredential.user!.uid)
            .set({
          'name': nameController.text,
          'email': emailController.text,
          'age': int.parse(ageController.text),
          'gender': gender,
          'height': int.parse(heightController.text),
          'weight': int.parse(weightController.text),
          'createdAt': DateTime.now(),
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ProfilePage(userId: userCredential.user!.uid),
          ),
        );
      } on FirebaseAuthException catch (ex) {
        return UiHelper.CustomAlertBox(context, ex.code.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Страница регистрации"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Icon(Icons.person),
                  SizedBox(width: 10),
                  Text(
                    "Hello, ${nameController.text}",
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
            UiHelper.CustomTextField(
              nameController,
              "Имя",
              Icons.person,
              false,
              TextInputType.text,
              false,
            ),
            UiHelper.CustomTextField(
              emailController,
              "Email",
              Icons.mail,
              false,
              TextInputType.emailAddress,
              false,
            ),
            UiHelper.CustomTextField(
              passwordController,
              "Пароль",
              Icons.password,
              true,
              TextInputType.text,
              true,
            ),
            UiHelper.CustomTextField(
              ageController,
              "Возраст",
              Icons.date_range,
              false,
              TextInputType.number,
              false,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Radio(
                  value: 'Муж',
                  groupValue: gender,
                  onChanged: (value) {
                    setState(() {
                      gender = value.toString();
                    });
                  },
                ),
                Text('Муж'),
                Radio(
                  value: 'Жен',
                  groupValue: gender,
                  onChanged: (value) {
                    setState(() {
                      gender = value.toString();
                    });
                  },
                ),
                Text('Жен'),
                Radio(
                  value: 'Трансгендер',
                  groupValue: gender,
                  onChanged: (value) {
                    setState(() {
                      gender = value.toString();
                    });
                  },
                ),
                Text('Трансгендер'),
              ],
            ),
            UiHelper.CustomTextField(
              heightController,
              "Рост (см)",
              Icons.height,
              false,
              TextInputType.number,
              false,
            ),
            UiHelper.CustomTextField(
              weightController,
              "Вес (кг)",
              Icons.line_weight,
              false,
              TextInputType.number,
              false,
            ),
            SizedBox(height: 30),
            UiHelper.CustomButton(
              () {
                signUp();
              },
              "Зарегистрироваться",
            ),
          ],
        ),
      ),
    );
  }
}

class BzhuCalculator {
  /// Returns norm in grams and calories:
  /// { 'calories': double, 'proteinG': double, 'fatsG': double, 'carbsG': double }
  static Map<String, double>? calcBzhuNorm(Map<String, dynamic>? userData) {
    if (userData == null) return null;

    final ageRaw = userData['age'];
    final heightRaw = userData['height'];
    final weightRaw = userData['weight'];
    final genderRaw = userData['gender'];
    final goalRaw = userData['goal'];
    final activityRaw = userData['activity'];

    final age = (ageRaw is num)
        ? ageRaw.toDouble()
        : double.tryParse(ageRaw?.toString() ?? '');
    final heightCm = (heightRaw is num)
        ? heightRaw.toDouble()
        : double.tryParse(heightRaw?.toString() ?? '');
    final weightKg = (weightRaw is num)
        ? weightRaw.toDouble()
        : double.tryParse(weightRaw?.toString() ?? '');

    if (age == null || heightCm == null || weightKg == null) return null;
    if (age <= 0 || heightCm <= 0 || weightKg <= 0) return null;

    final gender = (genderRaw ?? '').toString().toLowerCase();
    final goal = (goalRaw ?? '').toString().toLowerCase();
    final activity = (activityRaw ?? '').toString().toLowerCase();

    // BMR: Mifflin–St Jeor
    final isMale = gender.contains('муж');
    final bmr =
        10 * weightKg + 6.25 * heightCm - 5 * age + (isMale ? 5 : -161);

    // Activity coefficient
    double activityCoef = 1.2;
    if (activity.contains('нет физических') || activity.contains('нет физ')) {
      activityCoef = 1.2;
    } else if (activity.contains('1-2')) {
      activityCoef = 1.375;
    } else if (activity.contains('3-4')) {
      activityCoef = 1.55;
    } else if (activity.contains('5-7')) {
      activityCoef = 1.725;
    } else if (activity.contains('тяжелый') ||
        activity.contains('каждый день')) {
      activityCoef = 1.9;
    }

    var tdee = bmr * activityCoef;

    // Goal adjustment
    if (goal.contains('снижение')) {
      tdee *= 0.85; // -15%
    } else if (goal.contains('набор')) {
      tdee *= 1.15; // +15%
    } else if (goal.contains('мышеч')) {
      tdee *= 1.05; // +5%
    }

    final calories = tdee;

    // Macro distribution by goal (P/F/C fractions of calories)
    double pPerc = 0.30, fPerc = 0.25, cPerc = 0.45; // defaults: снижение
    if (goal.contains('набор')) {
      pPerc = 0.35;
      fPerc = 0.25;
      cPerc = 0.40;
    } else if (goal.contains('мышеч')) {
      pPerc = 0.30;
      fPerc = 0.25;
      cPerc = 0.45;
    }

    // grams: protein(4 kcal/g), carbs(4 kcal/g), fats(9 kcal/g)
    final proteinG = calories * pPerc / 4;
    final fatsG = calories * fPerc / 9;
    final carbsG = calories * cPerc / 4;

    if (!proteinG.isFinite ||
        !fatsG.isFinite ||
        !carbsG.isFinite ||
        !calories.isFinite) {
      return null;
    }

    return {
      'calories': calories,
      'proteinG': proteinG,
      'fatsG': fatsG,
      'carbsG': carbsG,
    };
  }
}

class ProfilePage extends StatelessWidget {
  final String userId;

  ProfilePage({required this.userId});

  Map<String, double>? _calcBzhuNorm(Map<String, dynamic>? userData) {
    // Keep existing method but reuse shared calculator logic
    return BzhuCalculator.calcBzhuNorm(userData);
  }

  Widget _legendDot({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 6),
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }

  Widget _buildBzhuDonutCard(Map<String, dynamic>? userData) {
    final norm = _calcBzhuNorm(userData);

    final kcal = norm?['calories'];
    final proteinG = norm?['proteinG'];
    final fatsG = norm?['fatsG'];
    final carbsG = norm?['carbsG'];

    if (norm == null ||
        kcal == null ||
        proteinG == null ||
        fatsG == null ||
        carbsG == null) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.restaurant_menu_outlined,
                        color: Colors.deepOrange),
                    SizedBox(width: 10),
                    Text(
                      'Норма КБЖУ',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  'Недостаточно данных для расчёта. Заполните возраст/пол/рост/вес и параметры цели/активности.',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Convert grams to kcal shares for painting
    final pKcal = proteinG * 4;
    final fKcal = fatsG * 9;
    final cKcal = carbsG * 4;
    final sumKcal = pKcal + fKcal + cKcal;

    final pPerc = sumKcal > 0 ? (pKcal / sumKcal) : 0.30;
    final fPerc = sumKcal > 0 ? (fKcal / sumKcal) : 0.25;
    final cPerc = sumKcal > 0 ? (cKcal / sumKcal) : 0.45;

    const double size = 170;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        elevation: 4,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu_outlined,
                      color: Colors.deepOrange),
                  SizedBox(width: 10),
                  Text(
                    'Норма КБЖУ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 10),
              SizedBox(
                width: size,
                height: size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: Size(size, size),
                      painter: _BzhuDonutPainter(
                        proteinPerc: pPerc,
                        fatsPerc: fPerc,
                        carbsPerc: cPerc,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${kcal.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Норма',
                          style: TextStyle(
                              fontSize: 14, color: const Color.fromARGB(255, 77, 77, 77)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14),
              Text(
                'Белки: ${proteinG.toStringAsFixed(0)} • Жиры: ${fatsG.toStringAsFixed(0)} • Углеводы: ${carbsG.toStringAsFixed(0)}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legendDot(color: Colors.blueAccent, label: 'Белки'),
                  SizedBox(width: 10),
                  _legendDot(color: Colors.green, label: 'Жиры'),
                  SizedBox(width: 10),
                  _legendDot(color: Colors.orange, label: 'Углеводы'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade600),
      title: Text(title),
      trailing: Icon(Icons.arrow_forward_ios,
          size: 16, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }

  Widget _buildGenderChip(String label, String value, String currentValue,
      Function(String) onTap) {
    final isSelected = value == currentValue;
    return InkWell(
      onTap: () => onTap(value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepOrange : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.deepOrange : Colors.grey.shade300,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      {required IconData icon,
      required String label,
      required String value,
      required Color color}) {
    return Container(
      width: 100,
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(
      {required IconData icon,
      required String title,
      required String value}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.deepOrange, size: 20),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  value,
                  style: TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(
      BuildContext context, Map<String, dynamic>? userData) {
    final nameController =
        TextEditingController(text: userData?['name'] ?? '');
    final ageController =
        TextEditingController(text: userData?['age']?.toString() ?? '');
    final heightController = TextEditingController(
        text: userData?['height']?.toString() ?? '');
    final weightController = TextEditingController(
        text: userData?['weight']?.toString() ?? '');

    String gender = userData?['gender'] ?? '';
    String experience = userData?['experience'] ?? '';
    String goal = userData?['goal'] ?? '';
    String activity = userData?['activity'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.edit, color: Colors.deepOrange),
                    SizedBox(width: 10),
                    Text(
                      'Редактировать профиль',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 24),

                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Имя',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-Zа-яА-ЯёЁ\s\-]')),
                  ],
                ),
                SizedBox(height: 16),

                TextField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Возраст',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.cake),
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                SizedBox(height: 16),

                Text(
                  'Пол',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildGenderChip(
                          'Муж', 'Муж', gender, (val) {
                        setModalState(() => gender = val);
                      }),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildGenderChip(
                          'Жен', 'Жен', gender, (val) {
                        setModalState(() => gender = val);
                      }),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                Text(
                  'Какой у вас опыт в зале?',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: experience.isEmpty ? null : experience,
                  items: const [
                    DropdownMenuItem(
                        value: 'Нет опыта', child: Text('Нет опыта')),
                    DropdownMenuItem(
                        value: 'Начинающий (до 1 года)',
                        child: Text('Начинающий (до 1 года)')),
                    DropdownMenuItem(
                        value: 'Средний (1-2 года)',
                        child: Text('Средний (1-2 года)')),
                    DropdownMenuItem(
                        value: 'Продвинутый (более 2 лет)',
                        child: Text('Продвинутый (более 2 лет)')),
                  ],
                  onChanged: (val) =>
                      setModalState(() => experience = val ?? ''),
                  decoration: InputDecoration(
                    labelText: 'Опыт в зале',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),

                Text(
                  'Какая у тебя цель?',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: goal.isEmpty ? null : goal,
                  items: const [
                    DropdownMenuItem(
                        value: 'Снижение веса',
                        child: Text('Снижение веса')),
                    DropdownMenuItem(
                        value: 'Мышечный тонус',
                        child: Text('Мышечный тонус')),
                    DropdownMenuItem(
                        value: 'Набор мышечной массы',
                        child: Text('Набор мышечной массы')),
                  ],
                  onChanged: (val) => setModalState(() => goal = val ?? ''),
                  decoration: InputDecoration(
                    labelText: 'Цель',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),

                Text(
                  'Какая активность?',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: activity.isEmpty ? null : activity,
                  items: const [
                    DropdownMenuItem(
                        value: 'Нет физических нагрузок',
                        child: Text('Нет физических нагрузок')),
                    DropdownMenuItem(
                        value: '1-2 тренировки в неделю',
                        child: Text('1-2 тренировки в неделю')),
                    DropdownMenuItem(
                        value: '3-4 тренировки в неделю',
                        child: Text('3-4 тренировки в неделю')),
                    DropdownMenuItem(
                        value: '5-7 тренировок в неделю',
                        child: Text('5-7 тренировок в неделю')),
                    DropdownMenuItem(
                        value: 'Тяжелый труд + тренировки каждый день',
                        child: Text(
                            'Тяжелый труд + тренировки каждый день')),
                  ],
                  onChanged: (val) => setModalState(() => activity = val ?? ''),
                  decoration: InputDecoration(
                    labelText: 'Активность',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: heightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Рост (см)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.height),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: weightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Вес (кг)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.line_weight),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('Users')
                          .doc(userId)
                          .update({
                        'name': nameController.text,
                        'age': int.tryParse(ageController.text),
                        'gender': gender,
                        'height': int.tryParse(heightController.text),
                        'weight': int.tryParse(weightController.text),
                        'experience': experience,
                        'goal': goal,
                        'activity': activity,
                      });

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Профиль обновлен!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Сохранить изменения',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Профиль')),
        body: Center(child: Text('ID пуст')),
      );
    }

    return Scaffold(
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance.collection('Users').doc(userId).get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Ошибка: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: Colors.deepOrange),
            );
          }

          final userData = snapshot.data?.data();

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: Colors.deepOrange,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.deepOrange, Colors.orange],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 40),
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            child: Text(
                              (userData?['name'] ?? 'U')
                                  .toString()
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                              ),
                            ),
                          ),
                          SizedBox(height: 15),
                          Text(
                            userData?['name'] ?? 'Имя не указано',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            userData?['email'] ?? 'Email не указан',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.white),
                    onPressed: () => _showEditProfileDialog(context, userData),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatCard(
                            icon: Icons.cake,
                            label: 'Возраст',
                            value: '${userData?['age'] ?? 'N/A'}',
                            color: Colors.purple,
                          ),
                          _buildStatCard(
                            icon: Icons.height,
                            label: 'Рост',
                            value: '${userData?['height'] ?? 'N/A'} см',
                            color: Colors.blue,
                          ),
                          _buildStatCard(
                            icon: Icons.line_weight,
                            label: 'Вес',
                            value: '${userData?['weight'] ?? 'N/A'} кг',
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30),

                    _buildBzhuDonutCard(userData),

                    SizedBox(height: 20),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.person, color: Colors.deepOrange),
                                  SizedBox(width: 10),
                                  Text(
                                    'Информация о пользователе',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              _buildProfileItem(
                                icon: Icons.person_outline,
                                title: 'Имя',
                                value: userData?['name'] ?? 'Не указано',
                              ),
                              Divider(),
                              _buildProfileItem(
                                icon: Icons.mail_outline,
                                title: 'Email',
                                value: userData?['email'] ?? 'Не указан',
                              ),
                              Divider(),
                              _buildProfileItem(
                                icon: Icons.cake_outlined,
                                title: 'Возраст',
                                value: '${userData?['age'] ?? 'Не указан'} лет',
                              ),
                              Divider(),
                              _buildProfileItem(
                                icon: Icons.wc_outlined,
                                title: 'Пол',
                                value: userData?['gender'] ?? 'Не указан',
                              ),
                              Divider(),
                              _buildProfileItem(
                                icon: Icons.height,
                                title: 'Рост',
                                value: '${userData?['height'] ?? 'Не указан'} см',
                              ),
                              Divider(),
                              _buildProfileItem(
                                icon: Icons.monitor_weight_outlined,
                                title: 'Вес',
                                value: '${userData?['weight'] ?? 'Не указан'} кг',
                              ),
                              Divider(),
                              _buildProfileItem(
                                icon: Icons.fitness_center_outlined,
                                title: 'Опыт в зале',
                                value: userData?['experience'] ?? 'Не указан',
                              ),
                              Divider(),
                              _buildProfileItem(
                                icon: Icons.flag_outlined,
                                title: 'Цель',
                                value: userData?['goal'] ?? 'Не указана',
                              ),
                              Divider(),
                              _buildProfileItem(
                                icon: Icons.bolt_outlined,
                                title: 'Активность',
                                value: userData?['activity'] ?? 'Не указана',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => LoginPage()),
                                (route) => false,
                              );
                            }
                          },
                          icon: Icon(Icons.logout),
                          label: Text('Выйти из аккаунта'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BzhuDonutPainter extends CustomPainter {
  final double proteinPerc;
  final double fatsPerc;
  final double carbsPerc;

  _BzhuDonutPainter({
    required this.proteinPerc,
    required this.fatsPerc,
    required this.carbsPerc,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 10;

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..color = Colors.deepOrange.withOpacity(0.12);

    canvas.drawCircle(center, radius, basePaint);

    double startAngle = -math.pi / 2;

    void drawSegment(double perc, Color color) {
      if (perc <= 0) return;

      final sweep = (perc.clamp(0.0, 1.0)) * 2 * math.pi;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.butt
        ..color = color;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        paint,
      );

      startAngle += sweep;
    }

    drawSegment(proteinPerc, Colors.blueAccent);
    drawSegment(fatsPerc, Colors.green);
    drawSegment(carbsPerc, Colors.orange);
  }

  @override
  bool shouldRepaint(covariant _BzhuDonutPainter oldDelegate) {
    return proteinPerc != oldDelegate.proteinPerc ||
        fatsPerc != oldDelegate.fatsPerc ||
        carbsPerc != oldDelegate.carbsPerc;
  }
}
