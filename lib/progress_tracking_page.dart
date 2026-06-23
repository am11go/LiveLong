import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:table_calendar/table_calendar.dart';

enum ProgressPeriod { week, month, threeMonths }


// Progress entry for a specific date (photo + metrics)
class ProgressEntry {
  final String imagePath;
  final String note;
  final double? weightKg;
  final double? waistCm;

  const ProgressEntry({
    required this.imagePath,
    required this.note,
    required this.weightKg,
    required this.waistCm,
  });
}


class ProgressTrackingPage extends StatefulWidget {
  const ProgressTrackingPage({Key? key}) : super(key: key);

  @override
  _ProgressTrackingPageState createState() => _ProgressTrackingPageState();
}

class _ProgressTrackingPageState extends State<ProgressTrackingPage> {
  final ImagePicker _picker = ImagePicker();
  PickedFile? _pickedFile;

  final Map<DateTime, ProgressEntry> _entriesByDay = {};
  bool _isUploading = false;
  bool _uploadError = false;



  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _userId;

  ProgressPeriod _selectedPeriod = ProgressPeriod.week;


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
      _loadImages();
    }
  }

  void _loadImages() {
    if (_userId == null) return;

    FirebaseFirestore.instance
        .collection('Users')
        .doc(_userId)
        .collection('ProgressPhotos')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      final entries = <DateTime, ProgressEntry>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['timestamp'] == null) continue;

        final ts = data['timestamp'] as Timestamp;
        final date = ts.toDate();
        final dateOnly = DateTime(date.year, date.month, date.day);

        final imagePath = data['imagePath'] as String;
        final note = (data['note'] ?? '') as String;

        double? weightKg;
        if (data['weightKg'] != null) {
          final v = data['weightKg'];
          if (v is num) weightKg = v.toDouble();
        }

        double? waistCm;
        if (data['waistCm'] != null) {
          final v = data['waistCm'];
          if (v is num) waistCm = v.toDouble();
        }

        entries[dateOnly] = ProgressEntry(
          imagePath: imagePath,
          note: note,
          weightKg: weightKg,
          waistCm: waistCm,
        );
      }

      if (mounted) {
        setState(() {
          _entriesByDay
            ..clear();
          _entriesByDay.addAll(entries);
        });
      }
    });
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile =
          await _picker.getImage(source: ImageSource.gallery);
      setState(() {
        _pickedFile = pickedFile;
      });
      if (pickedFile != null) {
        _showUploadDialog();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Ошибка выбора изображения: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final pickedFile = await _picker.getImage(source: ImageSource.camera);
      setState(() {
        _pickedFile = pickedFile;
      });
      if (pickedFile != null) {
        _showUploadDialog();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Ошибка камеры: $e');
    }
  }

  void _showUploadDialog() {
    final TextEditingController noteController = TextEditingController();
    final TextEditingController weightController = TextEditingController();
    final TextEditingController waistController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.photo_camera, color: Colors.deepOrange),
                const SizedBox(width: 10),
                Text(
                  'Добавить фото прогресса',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_pickedFile != null)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  image: DecorationImage(
                    image: FileImage(File(_pickedFile!.path)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Заметка (необязательно)',
                border: OutlineInputBorder(),
                hintText: 'Например: Через 2 недели тренировок',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: weightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Вес (кг) (необязательно)',
                border: OutlineInputBorder(),
                hintText: 'Например: 72.5',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: waistController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Обхват талии (см) (необязательно)',
                border: OutlineInputBorder(),
                hintText: 'Например: 78',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _pickImage();
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Галерея'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _takePhoto();
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Камера'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading
                    ? null
                    : () => _uploadImage(
                          noteController.text,
                          weightController.text,
                          waistController.text,
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Сохранить',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadImage(String note, String weightText, String waistText) async {
    if (_pickedFile == null || _userId == null) return;

    double? weightKg;
    final w = weightText.trim();
    if (w.isNotEmpty) {
      weightKg = double.tryParse(w.replaceAll(',', '.'));
    }

    double? waistCm;
    final wa = waistText.trim();
    if (wa.isNotEmpty) {
      waistCm = double.tryParse(wa.replaceAll(',', '.'));
    }


    setState(() {
      _isUploading = true;
      _uploadError = false;
    });

    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = directory.path;

      final fileName =
          DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
      final filePath = '$path/$fileName';

      await File(_pickedFile!.path).copy(filePath);

      final data = <String, dynamic>{
        'imagePath': filePath,
        'note': note,
        'timestamp': DateTime.now(),
      };

      if (weightKg != null) {
        data['weightKg'] = weightKg;
      }
      if (waistCm != null) {
        data['waistCm'] = waistCm;
      }

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(_userId)
          .collection('ProgressPhotos')
          .add(data);

      // Update current user weight in profile as well
      if (weightKg != null) {
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(_userId)
            .update({'weight': weightKg});
      }


      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Фото сохранено!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('Ошибка сохранения: $e');
      setState(() {
        _isUploading = false;
        _uploadError = true;
      });
    }
  }

  Future<void> _deleteImage(String imagePath) async {
    if (_userId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(_userId)
          .collection('ProgressPhotos')
          .where('imagePath', isEqualTo: imagePath)
          .get()
          .then((snapshot) async {
        for (final doc in snapshot.docs) {
          await doc.reference.delete();
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Фото удалено'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('Ошибка удаления: $e');
    }
  }

  DateTime _periodStart() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_selectedPeriod) {
      case ProgressPeriod.week:
        return today.subtract(const Duration(days: 6));
      case ProgressPeriod.month:
        return today.subtract(const Duration(days: 29));
      case ProgressPeriod.threeMonths:
        return today.subtract(const Duration(days: 89));
    }

  }

  int _getPhotosCountInPeriod() {
    if (_entriesByDay.isEmpty) return 0;

    final start = _periodStart();
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day);

    int count = 0;
    for (final day in _entriesByDay.keys) {
      if (!day.isBefore(start) && !day.isAfter(end)) {
        count++;
      }
    }
    return count;
  }

  /// Текущая подряд-серия до today, но внутри выбранного периода.
  int _getStreakInPeriod() {
    if (_entriesByDay.isEmpty) return 0;

    final start = _periodStart();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int streak = 0;
    DateTime checkDate = today;

    while (!checkDate.isBefore(start)) {
      if (_entriesByDay.containsKey(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  String _formatDate(DateTime date) {
    final months = [
      'янв',
      'фев',
      'мар',
      'апр',
      'май',
      'июн',
      'июл',
      'авг',
      'сен',
      'окт',
      'ноя',
      'дек'
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateShort(DateTime date) {
    return '${date.day}.${date.month.toString().padLeft(2, '0')}';
  }

  Widget _buildPeriodChip({
    required String label,
    required ProgressPeriod period,
  }) {
    final isSelected = _selectedPeriod == period;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            _selectedPeriod = period;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.deepOrange : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? Colors.deepOrange
                  : Colors.grey.withOpacity(0.2),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  List<ProgressEntry> _getEntriesInCurrentPeriod({
    required bool onlyWithWeight,
    required bool onlyWithWaist,
  }) {
    if (_entriesByDay.isEmpty) return const [];

    final start = _periodStart();
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day);

    final filteredDays = _entriesByDay.keys
        .where((d) => !d.isBefore(start) && !d.isAfter(end))
        .toList()
      ..sort((a, b) => a.compareTo(b));

    final entries = <ProgressEntry>[];
    for (final d in filteredDays) {
      final e = _entriesByDay[d];
      if (e == null) continue;
      if (onlyWithWeight && e.weightKg == null) continue;
      if (onlyWithWaist && e.waistCm == null) continue;
      entries.add(e);
    }
    return entries;
  }

  String _formatDelta({
    required double? from,
    required double? to,
    required String unit,
    required int decimals,
  }) {
    if (from == null || to == null) return '—';
    final delta = to - from;
    final sign = delta > 0 ? '+' : '';
    final fixed = delta.toStringAsFixed(decimals);
    return '$sign$fixed $unit';
  }

  double? _firstWeightInPeriod() {
    final entries = _getEntriesInCurrentPeriod(
      onlyWithWeight: true,
      onlyWithWaist: false,
    );
    return entries.isEmpty ? null : entries.first.weightKg;
  }

  double? _lastWeightInPeriod() {
    final entries = _getEntriesInCurrentPeriod(
      onlyWithWeight: true,
      onlyWithWaist: false,
    );
    return entries.isEmpty ? null : entries.last.weightKg;
  }

  double? _firstWaistInPeriod() {
    final entries = _getEntriesInCurrentPeriod(
      onlyWithWeight: false,
      onlyWithWaist: true,
    );
    return entries.isEmpty ? null : entries.first.waistCm;
  }

  double? _lastWaistInPeriod() {
    final entries = _getEntriesInCurrentPeriod(
      onlyWithWeight: false,
      onlyWithWaist: true,
    );
    return entries.isEmpty ? null : entries.last.waistCm;
  }

  Widget _buildWeightDeltaItem() {
    final firstW = _firstWeightInPeriod();
    final lastW = _lastWeightInPeriod();
    final firstWaist = _firstWaistInPeriod();
    final lastWaist = _lastWaistInPeriod();

    final weightDeltaText = _formatDelta(
      from: firstW,
      to: lastW,
      unit: 'кг',
      decimals: 1,
    );
    final waistDeltaText = _formatDelta(
      from: firstWaist,
      to: lastWaist,
      unit: 'см',
      decimals: 1,
    );

    final isWeightUp =
        (firstW != null && lastW != null) ? (lastW - firstW) >= 0 : null;
    final color = isWeightUp == null
        ? Colors.blueGrey
        : (isWeightUp ? Colors.deepOrange : Colors.green);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.monitor_weight_rounded,
              color: color, size: 30),
        ),
        const SizedBox(height: 10),
        Text(
          weightDeltaText,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Талия: $waistDeltaText',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }



  Widget _buildPhotoForDay(DateTime day) {
    final dateOnly = DateTime(day.year, day.month, day.day);
    final entry = _entriesByDay[dateOnly];
    final imagePath = entry?.imagePath;
    final weightKg = entry?.weightKg;
    final waistCm = entry?.waistCm;

    String? weightText;
    if (weightKg != null) {
      final v = weightKg.toString();
      weightText = 'Вес: $v кг';
    }

    String? waistText;
    if (waistCm != null) {
      final v = waistCm.toString();
      waistText = 'Талия: $v см';
    }



    if (imagePath == null || !File(imagePath).existsSync()) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.photo_camera,
                  size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'Нет фото за этот день',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(imagePath),
              fit: BoxFit.cover,
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                onPressed: () => _deleteImage(imagePath),
                icon: const Icon(Icons.delete, color: Colors.red),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (weightText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        weightText!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (waistText != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        waistText!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPhotos() {
    if (_entriesByDay.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.photo_library,
                  size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Нет фото прогресса',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Добавьте первое фото!',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final sortedDates = _entriesByDay.keys.toList()
      ..sort((a, b) => b.compareTo(a));


    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: sortedDates.length > 6 ? 6 : sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final imagePath = _entriesByDay[date]?.imagePath;

        if (imagePath == null || !File(imagePath).existsSync()) {
          return const SizedBox();
        }

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDay = date;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Color(0xB3000000),
                            Color(0x00000000),
                          ],
                        ),
                      ),
                      child: Text(
                        _formatDateShort(date),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timeline, color: Colors.white),
            const SizedBox(width: 10),
            const Text('Прогресс', style: TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: Colors.deepOrange,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUploadDialog,
        backgroundColor: Colors.deepOrange,
        icon: const Icon(Icons.add_a_photo, color: Colors.white),
        label: const Text('Фото', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Calendar
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2023, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.deepOrange.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Colors.deepOrange,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonDecoration: BoxDecoration(
                    border: Border.all(color: Colors.deepOrange),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  formatButtonTextStyle: const TextStyle(color: Colors.deepOrange),
                ),
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                eventLoader: (day) {
                  final dateOnly = DateTime(day.year, day.month, day.day);
                  return _entriesByDay.containsKey(dateOnly) ? [true] : [];
                },
              ),
            ),

            // Period selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPeriodChip(
                        label: 'Неделя', period: ProgressPeriod.week),
                    _buildPeriodChip(
                        label: 'Месяц', period: ProgressPeriod.month),
                    _buildPeriodChip(
                        label: '3 месяца',
                        period: ProgressPeriod.threeMonths),

                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Progress Stats
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade50, Colors.teal.shade50],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    icon: Icons.photo_library,
                    value: _getPhotosCountInPeriod().toString(),
                    label: 'Фото за период',
                    color: Colors.green,
                  ),
                  _buildStatItem(
                    icon: Icons.calendar_today,
                    value: _getStreakInPeriod().toString(),
                    label: 'Серия дней',
                    color: Colors.orange,
                  ),
                  _buildWeightDeltaItem(),
                ],
              ),
            ),


            const SizedBox(height: 20),

            // Selected Day Photo
            if (_selectedDay != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Фото за ${_formatDate(_selectedDay!)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _buildPhotoForDay(_selectedDay!),
            ],

            // Recent Photos
            const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Все фото прогресса',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )),
            _buildRecentPhotos(),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

