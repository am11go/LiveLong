import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart';

import 'admin_db_work_view.dart';

// NOTE: Reports PDF export uses dart:html and is Web-only.
// For mobile/desktop builds we avoid referencing dart:html at all.

// ------------------------
// AdminConfig (Firestore)
// ------------------------

class AdminConfig {
  final bool emailEnabled;
  final bool pushEnabled;
  final bool remindersEnabled;
  final bool requireStrongPassword;
  final bool twoFactorEnabled;

  const AdminConfig({
    required this.emailEnabled,
    required this.pushEnabled,
    required this.remindersEnabled,
    required this.requireStrongPassword,
    required this.twoFactorEnabled,
  });

  Map<String, dynamic> toMap() => {
        'emailEnabled': emailEnabled,
        'pushEnabled': pushEnabled,
        'remindersEnabled': remindersEnabled,
        'requireStrongPassword': requireStrongPassword,
        'twoFactorEnabled': twoFactorEnabled,
      };

  static AdminConfig fromMap(Map<String, dynamic> map) {
    bool readBool(String key, {bool defaultValue = false}) {
      final v = map[key];
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final lower = v.toLowerCase().trim();
        if (lower == 'true' || lower == '1') return true;
        if (lower == 'false' || lower == '0') return false;
      }
      return defaultValue;
    }

    return AdminConfig(
      emailEnabled: readBool('emailEnabled', defaultValue: true),
      pushEnabled: readBool('pushEnabled', defaultValue: true),
      remindersEnabled: readBool('remindersEnabled', defaultValue: true),
      requireStrongPassword: readBool('requireStrongPassword', defaultValue: true),
      twoFactorEnabled: readBool('twoFactorEnabled', defaultValue: false),
    );
  }
}

class AdminConfigService {
  static const _configDocPath = 'AdminConfig/main';

  static DocumentReference<Map<String, dynamic>> configDoc() =>
      FirebaseFirestore.instance.doc(_configDocPath);

  static CollectionReference<Map<String, dynamic>> adminsCollection() =>
      FirebaseFirestore.instance.collection('AdminConfig/admins');

  static Future<AdminConfig> loadConfig() async {
    final snap = await configDoc().get();
    final data = snap.data();
    if (data == null) {
      return const AdminConfig(
        emailEnabled: true,
        pushEnabled: true,
        remindersEnabled: true,
        requireStrongPassword: true,
        twoFactorEnabled: false,
      );
    }
    return AdminConfig.fromMap(data);
  }

  static Future<void> saveConfig(AdminConfig config) {
    return configDoc().set(config.toMap(), SetOptions(merge: true));
  }

  static Future<void> addAdmin({required String email, String? name}) {
    final normalized = email.trim().toLowerCase();
    final id = normalized;
    return adminsCollection().doc(id).set({
      'email': normalized,
      'name': (name ?? '').trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> deleteAdminById(String adminDocId) {
    return adminsCollection().doc(adminDocId).delete();
  }

  static Future<bool> adminExists(String adminDocId) async {
    final snap = await adminsCollection().doc(adminDocId).get();
    return snap.exists;
  }
}

// ------------------------
// Admin Dashboard
// ------------------------

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Админ-панель'),
        backgroundColor: Colors.deepOrange,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: _buildContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.black54,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.storage),
            label: 'Работа с БД',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Статистика',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Отчёты',
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const AdminDbWorkView();
      case 1:
        return const StatisticsView();
      case 2:
        return const ReportsView();
      case 3:
        return const ReportsView();
      default:
        return const AdminDbWorkView();
    }
  }
}

// ------------------------
// StatisticsView
// ------------------------

class StatisticsView extends StatefulWidget {
  const StatisticsView({super.key});

  @override
  State<StatisticsView> createState() => _StatisticsViewState();
}

class _StatisticsViewState extends State<StatisticsView> {
  // 0=all, 7=last 7 days, 30=last 30 days
  int _periodDays = 30;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Статистика приложения',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Период:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: _periodDays,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('За всё время')),
                    DropdownMenuItem(value: 7, child: Text('Последние 7 дней')),
                    DropdownMenuItem(value: 30, child: Text('Последние 30 дней')),
                  ],
                  onChanged: (v) => setState(() => _periodDays = v ?? 30),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: FutureBuilder<_AdminStats>(
                future: _periodDays == 0
                    ? _loadStatsAllTime()
                    : _loadStatsLastNDays(_periodDays),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Ошибка загрузки статистики: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: Text('Нет данных'));
                  }

                  final stats = snapshot.data!;

                  return ListView(
                    children: [
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildStatCard('Пользователи', stats.totalUsers.toString(),
                              Icons.people, Colors.blue),
                          _buildStatCard('Активные', stats.activeUsers.toString(),
                              Icons.trending_up, Colors.green),
                          _buildStatCard('Meals', stats.mealsCount.toString(),
                              Icons.restaurant_menu, Colors.orange),
                          _buildStatCard('Workouts', stats.workoutsCount.toString(),
                              Icons.fitness_center, Colors.purple),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildBigStatCard(
                        title: 'Питание (суммарно)',
                        subtitle:
                            'Ккал: ${stats.mealsCalories.toStringAsFixed(0)}\nБ: ${stats.mealsProtein.toStringAsFixed(1)}  Ж: ${stats.mealsFat.toStringAsFixed(1)}\nУ: ${stats.mealsCarbs.toStringAsFixed(1)}',
                        icon: Icons.local_fire_department,
                        color: Colors.deepOrange,
                      ),
                      const SizedBox(height: 16),
                      _buildBigStatCard(
                        title: 'Тренировки (суммарно)',
                        subtitle:
                            'Ккал: ${stats.workoutsCalories.toStringAsFixed(0)}\nВсего подходов: ${stats.totalSets.toStringAsFixed(0)}\nВсего повторов: ${stats.totalReps.toStringAsFixed(0)}',
                        icon: Icons.sports,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      _buildBigStatCard(
                        title: 'Прогресс-фото',
                        subtitle:
                            'Фото: ${stats.progressPhotosCount.toString()} (агрегировано по всем пользователям)',
                        icon: Icons.photo_library,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 16),
                      _buildTopList(stats),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(value,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 6),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildBigStatCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(subtitle, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopList(_AdminStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Топы', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Top по количеству тренировок',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...stats.topUsersByWorkouts.map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(child: Text(e.userName, overflow: TextOverflow.ellipsis)),
                        Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Top по сумме калорий (тренировки)',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...stats.topUsersByCalories.map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(child: Text(e.userName, overflow: TextOverflow.ellipsis)),
                        Text(e.valueDouble?.toStringAsFixed(0) ?? e.value.toString(),
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  DateTime _periodStart(int days) {
    final now = DateTime.now();
    if (days <= 0) return DateTime.fromMillisecondsSinceEpoch(0);
    final start = now.subtract(Duration(days: days));
    return DateTime(start.year, start.month, start.day);
  }

  Future<_AdminStats> _loadStatsAllTime() => _loadStatsLastNDays(0);

  Future<_AdminStats> _loadStatsLastNDays(int days) async {
    final start = days <= 0 ? DateTime.fromMillisecondsSinceEpoch(0) : _periodStart(days);

    final usersSnap = await FirebaseFirestore.instance.collection('Users').get();
    final userDocs = usersSnap.docs;

    int totalUsers = userDocs.length;
    int activeUsers = 0;

    int mealsCount = 0;
    double mealsCalories = 0;
    double mealsProtein = 0;
    double mealsFat = 0;
    double mealsCarbs = 0;

    int workoutsCount = 0;
    double workoutsCalories = 0;
    double totalSets = 0;
    double totalReps = 0;

    int progressPhotosCount = 0;

    final workoutsByUser = <String, _TopEntryStringToDouble>{};
    final caloriesByUser = <String, _TopEntryStringToDouble>{};

    for (final userDoc in userDocs) {
      final uid = userDoc.id;
      final userName = (userDoc.data() as Map<String, dynamic>)['name']?.toString() ?? 'Без имени';

      bool userActive = false;

      final mealsSnap = await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .collection('Meals')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .get();

      for (final doc in mealsSnap.docs) {
        userActive = true;
        mealsCount++;
        final data = doc.data() as Map<String, dynamic>;
        mealsCalories += (data['calories'] ?? 0).toDouble();
        mealsProtein += (data['protein'] ?? 0).toDouble();
        mealsFat += (data['fat'] ?? 0).toDouble();
        mealsCarbs += (data['carbs'] ?? 0).toDouble();
      }

      final workoutsSnap = await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .collection('Workouts')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .get();

      for (final doc in workoutsSnap.docs) {
        userActive = true;
        workoutsCount++;
        final data = doc.data() as Map<String, dynamic>;
        workoutsCalories += (data['calories'] ?? 0).toDouble();
        totalSets += (data['sets'] ?? 0).toDouble();
        totalReps += (data['reps'] ?? 0).toDouble();

        final key = uid;
        workoutsByUser.putIfAbsent(
          key,
          () => _TopEntryStringToDouble(userId: uid, userName: userName, value: 0),
        );
        workoutsByUser[key] = workoutsByUser[key]!.copyWithValue(workoutsByUser[key]!.value + 1);

        caloriesByUser.putIfAbsent(
          key,
          () => _TopEntryStringToDouble(userId: uid, userName: userName, value: 0),
        );
        caloriesByUser[key] =
            caloriesByUser[key]!.copyWithValue(caloriesByUser[key]!.value + (data['calories'] ?? 0).toDouble());
      }

      final progressSnap = await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .collection('ProgressPhotos')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .get();

      if (progressSnap.docs.isNotEmpty) {
        userActive = true;
        progressPhotosCount += progressSnap.docs.length;
      }

      if (userActive) activeUsers++;
    }

    final topUsersByWorkouts = workoutsByUser.values.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topUsersByCalories = caloriesByUser.values.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _AdminStats(
      totalUsers: totalUsers,
      activeUsers: activeUsers,
      mealsCount: mealsCount,
      mealsCalories: mealsCalories,
      mealsProtein: mealsProtein,
      mealsFat: mealsFat,
      mealsCarbs: mealsCarbs,
      workoutsCount: workoutsCount,
      workoutsCalories: workoutsCalories,
      totalSets: totalSets,
      totalReps: totalReps,
      progressPhotosCount: progressPhotosCount,
      topUsersByWorkouts: topUsersByWorkouts
          .take(5)
          .map((e) => _TopEntry(userName: e.userName, value: e.value.toInt()))
          .toList(),
      topUsersByCalories: topUsersByCalories
          .take(5)
          .map((e) => _TopEntry(userName: e.userName, value: e.value.toInt(), valueDouble: e.value))
          .toList(),
    );
  }
}

class _TopEntry {
  final String userName;
  final int value;
  final double? valueDouble;

  _TopEntry({required this.userName, required this.value, this.valueDouble});
}

class _TopEntryStringToDouble {
  final String userId;
  final String userName;
  final double value;

  const _TopEntryStringToDouble({required this.userId, required this.userName, required this.value});

  _TopEntryStringToDouble copyWithValue(double newValue) {
    return _TopEntryStringToDouble(userId: userId, userName: userName, value: newValue);
  }
}

class _AdminStats {
  final int totalUsers;
  final int activeUsers;

  final int mealsCount;
  final double mealsCalories;
  final double mealsProtein;
  final double mealsFat;
  final double mealsCarbs;

  final int workoutsCount;
  final double workoutsCalories;
  final double totalSets;
  final double totalReps;

  final int progressPhotosCount;

  final List<_TopEntry> topUsersByWorkouts;
  final List<_TopEntry> topUsersByCalories;

  const _AdminStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.mealsCount,
    required this.mealsCalories,
    required this.mealsProtein,
    required this.mealsFat,
    required this.mealsCarbs,
    required this.workoutsCount,
    required this.workoutsCalories,
    required this.totalSets,
    required this.totalReps,
    required this.progressPhotosCount,
    required this.topUsersByWorkouts,
    required this.topUsersByCalories,
  });
}

// ------------------------
// ReportsView (web: table + PDF)
// ------------------------

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  // 0=all, 7=last 7 days, 30=last 30 days
  int _periodDays = 30;

  bool _loading = false;
  String? _error;

  List<_UserReportRow> _rows = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTime _periodStart(int days) {
    final now = DateTime.now();
    if (days <= 0) return DateTime.fromMillisecondsSinceEpoch(0);
    final start = now.subtract(Duration(days: days));
    return DateTime(start.year, start.month, start.day);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final start = _periodDays == 0
          ? DateTime.fromMillisecondsSinceEpoch(0)
          : _periodStart(_periodDays);

      final usersSnap = await FirebaseFirestore.instance.collection('Users').get();
      final users = usersSnap.docs;

      final rows = <_UserReportRow>[];

      for (final userDoc in users) {
        final uid = userDoc.id;
        final data = userDoc.data();
        final name = (data is Map<String, dynamic>) ? (data['name']?.toString() ?? 'Без имени') : 'Без имени';

        final mealsSnap = await FirebaseFirestore.instance
            .collection('Users')
            .doc(uid)
            .collection('Meals')
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .get();

        double mealsCalories = 0;
        double mealsProtein = 0;
        double mealsFat = 0;
        double mealsCarbs = 0;
        int mealsCount = 0;

        for (final doc in mealsSnap.docs) {
          final m = doc.data() as Map<String, dynamic>;
          mealsCount++;
          mealsCalories += (m['calories'] ?? 0).toDouble();
          mealsProtein += (m['protein'] ?? 0).toDouble();
          mealsFat += (m['fat'] ?? 0).toDouble();
          mealsCarbs += (m['carbs'] ?? 0).toDouble();
        }

        final workoutsSnap = await FirebaseFirestore.instance
            .collection('Users')
            .doc(uid)
            .collection('Workouts')
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .get();

        int workoutsCount = 0;
        double workoutsCalories = 0;
        double totalSets = 0;
        double totalReps = 0;

        for (final doc in workoutsSnap.docs) {
          final w = doc.data() as Map<String, dynamic>;
          workoutsCount++;
          workoutsCalories += (w['calories'] ?? 0).toDouble();
          totalSets += (w['sets'] ?? 0).toDouble();
          totalReps += (w['reps'] ?? 0).toDouble();
        }

        final progressSnap = await FirebaseFirestore.instance
            .collection('Users')
            .doc(uid)
            .collection('ProgressPhotos')
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .get();

        rows.add(
          _UserReportRow(
            userName: name,
            mealsCount: mealsCount,
            mealsCalories: mealsCalories,
            mealsProtein: mealsProtein,
            mealsFat: mealsFat,
            mealsCarbs: mealsCarbs,
            workoutsCount: workoutsCount,
            workoutsCalories: workoutsCalories,
            totalSets: totalSets,
            totalReps: totalReps,
            progressPhotosCount: progressSnap.docs.length,
          ),
        );
      }

      rows.sort((a, b) => b.workoutsCalories.compareTo(a.workoutsCalories));

      if (!mounted) return;
      setState(() => _rows = rows);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _exportPdf() async {
    // PDF экспорт делаем только на web (dart:html + скачивание файла).
    // На Android/desktop этот метод не должен компилироваться/падать.
    throw UnimplementedError('PDF export is supported on web only');
  }

  Future<void> _exportPdfWeb() async {
    throw UnimplementedError('PDF export implementation depends on platform-specific html/PDF APIs');
  }

  // Web/PDF export is disabled for now to keep non-web compilation working.
  // If you need PDF export, implement it using web-only imports and/or
  // split the code into separate *_web.dart files.


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Отчёты', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Период:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: _periodDays,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('За всё время')),
                    DropdownMenuItem(value: 7, child: Text('Последние 7 дней')),
                    DropdownMenuItem(value: 30, child: Text('Последние 30 дней')),
                  ],
                  onChanged: (v) {
                    setState(() => _periodDays = v ?? 30);
                    _load();
                  },
                ),
                const Spacer(),
                // PDF экспорт полностью удалён из админки
                const SizedBox.shrink(),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Ошибка: $_error',
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : _rows.isEmpty
                          ? const Center(child: Text('Нет данных'))
                          : _buildTable(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable() {
    final headers = <String>[
      'Пользователь',
      'Meals',
      'Meals kcal',
      'Б',
      'Ж',
      'У',
      'Workouts',
      'Workouts kcal',
      'Sets',
      'Reps',
      'Фото',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: headers
            .map((h) => DataColumn(
                  label: Text(h, style: const TextStyle(fontWeight: FontWeight.w600)),
                ))
            .toList(),
        rows: _rows
            .map(
              (r) => DataRow(
                cells: [
                  DataCell(Text(r.userName)),
                  DataCell(Text(r.mealsCount.toString())),
                  DataCell(Text(r.mealsCalories.toStringAsFixed(0))),
                  DataCell(Text(r.mealsProtein.toStringAsFixed(1))),
                  DataCell(Text(r.mealsFat.toStringAsFixed(1))),
                  DataCell(Text(r.mealsCarbs.toStringAsFixed(1))),
                  DataCell(Text(r.workoutsCount.toString())),
                  DataCell(Text(r.workoutsCalories.toStringAsFixed(0))),
                  DataCell(Text(r.totalSets.toStringAsFixed(0))),
                  DataCell(Text(r.totalReps.toStringAsFixed(0))),
                  DataCell(Text(r.progressPhotosCount.toString())),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _UserReportRow {
  final String userName;

  final int mealsCount;
  final double mealsCalories;
  final double mealsProtein;
  final double mealsFat;
  final double mealsCarbs;

  final int workoutsCount;
  final double workoutsCalories;
  final double totalSets;
  final double totalReps;

  final int progressPhotosCount;

  const _UserReportRow({
    required this.userName,
    required this.mealsCount,
    required this.mealsCalories,
    required this.mealsProtein,
    required this.mealsFat,
    required this.mealsCarbs,
    required this.workoutsCount,
    required this.workoutsCalories,
    required this.totalSets,
    required this.totalReps,
    required this.progressPhotosCount,
  });
}

class _HtmlEscaper {
  const _HtmlEscaper();

  String convert(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '<')
        .replaceAll('>', '>')
        .replaceAll('"', '"')
        .replaceAll("'", '&#39;');
  }
}

// ------------------------
// SettingsView
// ------------------------

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Настройки админ-панели', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildSettingsCard(
              context,
              Icons.admin_panel_settings,
              'Управление админами',
              'CRUD администраторов через Firestore AdminConfig/admins',
              () => _showManageAdminsDialog(context),
            ),
            _buildSettingsCard(
              context,
              Icons.notifications,
              'Уведомления',
              'Загружать/сохранять флаги уведомлений в AdminConfig/main',
              () => _showNotificationsDialog(context),
            ),
            _buildSettingsCard(
              context,
              Icons.security,
              'Безопасность',
              'Загружать/сохранять security-параметры в AdminConfig/main',
              () => _showSecurityDialog(context),
            ),
            _buildSettingsCard(
              context,
              Icons.fitness_center,
              'Управление упражнениями',
              'Заглушка (не относится к шагу 4)',
              () => _showStubDialog(context, 'Управление упражнениями'),
            ),
            _buildSettingsCard(
              context,
              Icons.restaurant,
              'Управление питанием',
              'Заглушка (не относится к шагу 4)',
              () => _showStubDialog(context, 'Управление питанием'),
            ),
            _buildSettingsCard(
              context,
              Icons.backup,
              'Резервное копирование',
              'Заглушка (не относится к шагу 4)',
              () => _showStubDialog(context, 'Резервное копирование'),
            ),
            _buildSettingsCard(
              context,
              Icons.info,
              'О приложении',
              'Версия 1.0.0',
              () => _showAboutDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.deepOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.deepOrange),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showStubDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text('Раздел пока не реализован. Шаг 4 фокусируется на AdminConfig/main и CRUD админов.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Закрыть')),
        ],
      ),
    );
  }

  void _showManageAdminsDialog(BuildContext context) {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Управление администраторами'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email нового админа',
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Список админов:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 220,
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: AdminConfigService.adminsCollection().snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Ошибка: ${snapshot.error}'));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Center(child: Text('Нет админов'));
                      }

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data();
                          final email = (data['email'] ?? '').toString();
                          final name = (data['name'] ?? '').toString();

                          return ListTile(
                            leading: const Icon(Icons.admin_panel_settings),
                            title: Text(email.isNotEmpty ? email : doc.id),
                            subtitle: Text(name.isNotEmpty ? name : 'Админ'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await AdminConfigService.deleteAdminById(doc.id);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Админ удален')),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Закрыть'),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Введите email')),
                  );
                  return;
                }

                final normalized = email.toLowerCase();
                await AdminConfigService.addAdmin(email: normalized);
                emailController.clear();

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Админ добавлен')),
                );
              },
              child: const Text('Добавить'),
            ),
          ],
        );
      },
    );
  }

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return FutureBuilder<AdminConfig>(
          future: AdminConfigService.loadConfig(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                content: SizedBox(height: 72, child: Center(child: CircularProgressIndicator())),
              );
            }
            if (!snapshot.hasData) {
              return const AlertDialog(content: Text('Не удалось загрузить AdminConfig'));
            }

            final cfg = snapshot.data!;
            bool emailEnabled = cfg.emailEnabled;
            bool pushEnabled = cfg.pushEnabled;
            bool remindersEnabled = cfg.remindersEnabled;

            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: const Text('Настройки уведомлений'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SwitchListTile(
                        title: const Text('Email уведомления'),
                        value: emailEnabled,
                        onChanged: (v) => setState(() => emailEnabled = v),
                      ),
                      SwitchListTile(
                        title: const Text('Push уведомления'),
                        value: pushEnabled,
                        onChanged: (v) => setState(() => pushEnabled = v),
                      ),
                      SwitchListTile(
                        title: const Text('Напоминания о тренировках'),
                        value: remindersEnabled,
                        onChanged: (v) => setState(() => remindersEnabled = v),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Закрыть'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final updated = AdminConfig(
                          emailEnabled: emailEnabled,
                          pushEnabled: pushEnabled,
                          remindersEnabled: remindersEnabled,
                          requireStrongPassword: cfg.requireStrongPassword,
                          twoFactorEnabled: cfg.twoFactorEnabled,
                        );
                        await AdminConfigService.saveConfig(updated);

                        if (!context.mounted) return;
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Настройки сохранены')),
                        );
                      },
                      child: const Text('Сохранить'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showSecurityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return FutureBuilder<AdminConfig>(
          future: AdminConfigService.loadConfig(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                content: SizedBox(height: 72, child: Center(child: CircularProgressIndicator())),
              );
            }
            if (!snapshot.hasData) {
              return const AlertDialog(content: Text('Не удалось загрузить AdminConfig'));
            }

            final cfg = snapshot.data!;
            bool twoFactorEnabled = cfg.twoFactorEnabled;
            bool requireStrongPassword = cfg.requireStrongPassword;

            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: const Text('Безопасность'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SwitchListTile(
                        title: const Text('Двухфакторная аутентификация'),
                        value: twoFactorEnabled,
                        onChanged: (v) => setState(() => twoFactorEnabled = v),
                      ),
                      SwitchListTile(
                        title: const Text('Требовать сложный пароль'),
                        value: requireStrongPassword,
                        onChanged: (v) => setState(() => requireStrongPassword = v),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Закрыть'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final updated = AdminConfig(
                          emailEnabled: cfg.emailEnabled,
                          pushEnabled: cfg.pushEnabled,
                          remindersEnabled: cfg.remindersEnabled,
                          requireStrongPassword: requireStrongPassword,
                          twoFactorEnabled: twoFactorEnabled,
                        );
                        await AdminConfigService.saveConfig(updated);

                        if (!context.mounted) return;
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Настройки сохранены')),
                        );
                      },
                      child: const Text('Сохранить'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.fitness_center, color: Colors.deepOrange),
            SizedBox(width: 8),
            Text('LIVELONG'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Версия: 1.0.0'),
            SizedBox(height: 8),
            Text('LIVELONG - приложение для фитнеса и здорового образа жизни.'),
            SizedBox(height: 8),
            Text('© 2025 LIVELONG'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Закрыть')),
        ],
      ),
    );
  }
}

