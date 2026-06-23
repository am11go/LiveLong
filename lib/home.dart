import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:livelong_flutter/profile.dart';
import 'package:livelong_flutter/signuppage.dart';
import 'meal_page.dart';
import 'progress_tracking_page.dart';
import 'workout_page.dart';
import 'profile.dart';
import 'loginpage.dart';

class MainShell extends StatefulWidget {
  const MainShell({Key? key}) : super(key: key);

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 2;
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
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 5 вкладок: слева-направо [Питание, Тренировки, Главная, Прогресс, Профиль]
    // Центральная вкладка "Главная".
    final pages = <Widget>[
      MealPage(),
      WorkoutPage(),
      HomeTabContent(userId: _userId),
      ProgressTrackingPage(),
      if (_userId != null) ProfilePage(userId: _userId!) else const SizedBox(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepOrange,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: 'Питание',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Тренировки',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timeline),
            label: 'Прогресс',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}

class HomeTabContent extends StatelessWidget {
  final String? userId;

  const HomeTabContent({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {},
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            UserProfileSection(userId: userId!),
            DailyProgressSection(userId: userId!),
            RecentActivitySection(userId: userId!),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}


class UserProfileSection extends StatelessWidget {
  final String userId;

  UserProfileSection({required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('Users').doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Container(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30.0,
                  backgroundImage: AssetImage('assets/images/avatar.png'),
                ),
                SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Пользователь',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.0),
                      LinearProgressIndicator(
                        value: 0.6,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        var userData = snapshot.data!.data();
        String userName = userData?['name'] ?? 'Пользователь';

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepOrange, Colors.orange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 35.0,
                      backgroundColor: Colors.white,
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ),
                    SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Привет, $userName! 👋',
                            style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Продолжай свой путь к здоровью!',
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class QuickActionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Быстрые действия',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ActionButton(
                icon: Icons.restaurant_menu,
                label: 'Питание',
                color: Colors.orange,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MealPage()),
                  );
                },
              ),
              ActionButton(
                icon: Icons.fitness_center,
                label: 'Тренировка',
                color: Colors.blue,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => WorkoutPage()),
                  );
                },
              ),
              ActionButton(
                icon: Icons.camera_alt,
                label: 'Прогресс',
                color: Colors.green,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProgressTrackingPage()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 100,
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DailyProgressSection extends StatelessWidget {
  final String userId;

  DailyProgressSection({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Дневной прогресс',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          FutureBuilder<Map<String, double>>(
            future: _loadTotalsAndNorms(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                );
              }

              final data = snapshot.data!;
              final totalCalories = data['calories'] ?? 0;
              final totalProtein = data['protein'] ?? 0;
              final totalFat = data['fat'] ?? 0;
              final totalCarbs = data['carbs'] ?? 0;

              final normCalories = data['normCalories'] ?? 0;
              final normProtein = data['normProtein'] ?? 0;
              final normFat = data['normFat'] ?? 0;
              final normCarbs = data['normCarbs'] ?? 0;

              return Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepOrange.shade50, Colors.orange.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.deepOrange.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNutrientCard(
                          'Калории',
                          totalCalories,
                          normCalories,
                          Colors.orange,
                          Icons.local_fire_department,
                        ),
                        _buildNutrientCard(
                          'Белки',
                          totalProtein,
                          normProtein,
                          Colors.red,
                          Icons.egg,
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNutrientCard(
                          'Жиры',
                          totalFat,
                          normFat,
                          Colors.yellow.shade700,
                          Icons.opacity,
                        ),
                        _buildNutrientCard(
                          'Углеводы',
                          totalCarbs,
                          normCarbs,
                          Colors.green,
                          Icons.grain,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<Map<String, double>> _loadTotalsAndNorms() async {
    // 1) Norms
    final userSnap =
        await FirebaseFirestore.instance.collection('Users').doc(userId).get();
    final userData = userSnap.data();

    final norm = BzhuCalculator.calcBzhuNorm(userData);
    final normCalories = (norm?['calories'] ?? 0).toDouble();
    final normProtein = (norm?['proteinG'] ?? 0).toDouble();
    final normFat = (norm?['fatsG'] ?? 0).toDouble();
    final normCarbs = (norm?['carbsG'] ?? 0).toDouble();

    // 2) Today's totals (meals)
    final mealsSnap = await FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('Meals')
        .where('timestamp', isGreaterThanOrEqualTo: _getTodayStart())
        .get();

    double consumedCalories = 0;
    double totalProtein = 0;
    double totalFat = 0;
    double totalCarbs = 0;

    for (var doc in mealsSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      consumedCalories += (data['calories'] ?? 0).toDouble();
      totalProtein += (data['protein'] ?? 0).toDouble();
      totalFat += (data['fat'] ?? 0).toDouble();
      totalCarbs += (data['carbs'] ?? 0).toDouble();
    }

    // 3) Workout calories burned today (from Workouts)
    final workoutsSnap = await FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('Workouts')
        .where('timestamp', isGreaterThanOrEqualTo: _getTodayStart())
        .get();

    double burnedWorkoutCalories = 0;
    for (var doc in workoutsSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      burnedWorkoutCalories += (data['calories'] ?? 0).toDouble();
    }

    // Calorie balance for the "Калории" card:
    // for user expectation: съедено - сожжено
    final netCalories = (consumedCalories - burnedWorkoutCalories).clamp(0.0, double.infinity);

    // NOTE: "calories" here is the net value (meals minus workout burn).
    return {
      'calories': netCalories,

      'protein': totalProtein,
      'fat': totalFat,
      'carbs': totalCarbs,
      'normCalories': normCalories,
      'normProtein': normProtein,
      'normFat': normFat,
      'normCarbs': normCarbs,
    };
  }

  DateTime _getTodayStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Widget _buildNutrientCard(String label, double value, double goal, Color color, IconData icon) {
    double progress = (value / goal).clamp(0.0, 1.0);
    return Container(
      width: 140,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 50,
                width: 50,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Text(
                value.toStringAsFixed(0),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          Text(
            '/ ${goal.toStringAsFixed(1)}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

class RecentActivitySection extends StatelessWidget {
  final String userId;

  RecentActivitySection({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Недавняя активность',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.0),
          FutureBuilder<List<QuerySnapshot>>(
            future: Future.wait([
              FirebaseFirestore.instance
                  .collection('Users')
                  .doc(userId)
                  .collection('Meals')
                  .orderBy('timestamp', descending: true)
                  .limit(3)
                  .get(),
            ]),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data == null) {
                return _buildEmptyActivity();
              }

              final mealsSnapshot = snapshot.data![0];
              final activities = <Map<String, dynamic>>[];

              for (var doc in mealsSnapshot.docs) {
                var data = doc.data() as Map<String, dynamic>;
                activities.add({
                  'type': 'meal',
                  'title': data['name'] ?? 'Прием пищи',
                  'subtitle': '${data['calories']?.toStringAsFixed(0) ?? 0} ккал',
                  'timestamp': data['timestamp'],
                  'icon': _getMealIcon(data['mealType']),
                });
              }

              if (activities.isEmpty) {
                return _buildEmptyActivity();
              }

              return Column(
                children: activities.map((activity) => _buildActivityCard(activity)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyActivity() {
    return Container(
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey.shade300),
            SizedBox(height: 12),
            Text(
              'Пока нет активности',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 4),
            Text(
              'Начните отслеживать питание!',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    DateTime? timestamp = activity['timestamp']?.toDate();
    String timeStr = '';
    if (timestamp != null) {
      timeStr = '${timestamp.day}.${timestamp.month.toString().padLeft(2, '0')} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.deepOrange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              activity['icon'] ?? Icons.restaurant,
              color: Colors.deepOrange,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  activity['subtitle'] ?? '',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            timeStr,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
        ],
      ),
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
}

/// Compatibility alias.
/// Some parts of the app use `HomePage()` but the main screen is implemented as `MainShell`.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainShell();
  }
}
