import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutPage extends StatefulWidget {
  @override
  _WorkoutPageState createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> with SingleTickerProviderStateMixin {
  double _totalCaloriesBurned = 0.0;
  String? _userId;
  late TabController _tabController;
  String _selectedFilter = 'Все';
  TextEditingController _searchController = TextEditingController();

  // --- Workout sequencing state ---
  List<Map<String, dynamic>> _activeWorkoutExercises = const [];
  int _activeWorkoutIndex = 0;


  // Exercise library
  final List<Map<String, dynamic>> _exerciseLibrary = [
    // Грудь
    {
      'name': 'Жим лёжа',
      'muscle': 'Грудь',
      'type': 'Силовая',
      'technique': 'Лопатки сведите и удерживайте, прогиб небольшой. Снимите штангу с опор и опустите её на нижнюю/среднюю часть груди контролируемо. Жмите вверх по траектории «чуть назад к плечам», не отрывая ступни и ягодицы. В верхней точке не «втыкайте» локти — держите напряжение.'
    },
    {
      'name': 'Жим гантелей',
      'muscle': 'Грудь',
      'type': 'Силовая',
      'technique': 'Лягте на скамью, лопатки сведены. Старт: гантели над грудью, нейтральный хват или слегка развернутые. Опускайте гантели до комфортного растяжения, локти под контролем (обычно ~45° к корпусу). Жмите вверх без рывка, сводя гантели над серединой груди.'
    },
    {
      'name': 'Разводка гантелей',
      'muscle': 'Грудь',
      'type': 'Силовая',
      'technique': 'Небольшой изгиб в локтях сохраняйте на протяжении подхода. Опускайте гантели по широкой дуге до растяжения грудных, не проваливая плечи. Поднимайте обратно, сводя в точке над грудью, держите контроль и не «отбивайте» весом.'
    },
    {
      'name': 'Отжимания',
      'muscle': 'Грудь',
      'type': 'Силовая',
      'technique': 'Корпус прямой (без прогиба и провисания). Руки под плечами, локти держите ближе к корпусу (или слегка в стороны). Опускайтесь до уровня, при котором грудь почти касается пола, затем мощно выжимайте вверх, сохраняя напряжение в корпусе.'
    },
    {
      'name': 'Пуловер',
      'muscle': 'Грудь',
      'type': 'Силовая',
      'technique': 'Сядьте/лягте так, чтобы верх спины имел опору. Держите гантель/гриф обеими руками с небольшим сгибом в локтях. Опускайте вес за голову контролируемо до растяжения грудных/широчайших, затем поднимайте по дуге, не разгибая локти полностью и не «дергая» плечами.'
    },
    {
      'name': 'Жим в тренажёре',
      'muscle': 'Грудь',
      'type': 'Силовая',
      'technique': 'Подстройте сиденье так, чтобы траектория была комфортной. Сводите лопатки и сохраняйте лёгкий прогиб. Опускайте рукояти контролируемо до нужной глубины, затем жмите вверх, не поднимая плечи к ушам. Работайте плавно, без рывков.'
    },

    // Спина
    {
      'name': 'Подтягивания',
      'muscle': 'Спина',
      'type': 'Силовая',
      'technique': 'Начните с активных лопаток: «потяните» их вниз. Подтягивайтесь за счёт спины, грудь стремится к перекладине. Не раскачивайтесь, корпус держите в контроле. Внизу не расслабляйте полностью — сохраняйте напряжение.'
    },
    {
      'name': 'Тяга штанги',
      'muscle': 'Спина',
      'type': 'Силовая',
      'technique': 'Спина нейтральная, таз отводится назад. Штанга начинается с уровня ниже/у бедра, тяните локтями, а не бицепсом. Поднимайте штангу к поясу, удерживая лопатки сведёнными. Опускайте контролируемо, не округляя спину.'
    },
    {
      'name': 'Тяга гантели',
      'muscle': 'Спина',
      'type': 'Силовая',
      'technique': 'Опора рукой/коленом позволяет держать корпус стабильно. Тяните гантель к тазу, локоть ведите вдоль корпуса. В верхней точке сводите лопатку, внизу сохраняйте контроль. Избегайте поворотов корпуса.'
    },
    {
      'name': 'Тяга верхнего блока',
      'muscle': 'Спина',
      'type': 'Силовая',
      'technique': 'Сведите лопатки в начале движения. Тяните рукоять вниз к верхней груди/ключицам, удерживая корпус неподвижным. Локти ведите вниз и чуть в стороны. Вверху полностью не разгибайте плечи — сохраняйте напряжение широчайших.'
    },
    {
      'name': 'Тяга нижнего блока',
      'muscle': 'Спина',
      'type': 'Силовая',
      'technique': 'Корпус фиксирован, прогиб умеренный. Тяните рукоять к нижней части живота/поясу, сводя лопатки. Локти направляйте назад. В конце подхода удержите секунду, затем возвращайтесь медленно.'
    },
    {
      'name': 'Становая тяга',
      'muscle': 'Спина',
      'type': 'Силовая',
      'technique': 'Стойка по ширине плеч. Старт: штанга близко к голеням, спина нейтральная, грудь «смотрит» вперёд. Поднимайте за счёт ног и разгибания в тазобедренном, штанга движется вдоль тела. В верхней точке расправьте корпус, затем опускайте, сохраняя спину.'
    },

    // Ноги
    {
      'name': 'Приседания',
      'muscle': 'Ноги',
      'type': 'Силовая',
      'technique': 'Стопы устойчиво, колени движутся в сторону носков. Спина нейтральная, корпус «собран». Опускайтесь до комфортной глубины, сохраняя контроль. Поднимайтесь мощно, удерживая вес на средней части стопы.'
    },
    {
      'name': 'Жим ногами',
      'muscle': 'Ноги',
      'type': 'Силовая',
      'technique': 'Спину прижмите к спинке тренажёра (без отрыва поясницы). Ноги ставьте на платформу в устойчивом положении. Опускайте платформу до нужной глубины, колени не заваливайте внутрь. Жмите вверх без «разгиба коленей до удара».'
    },
    {
      'name': 'Выпады',
      'muscle': 'Ноги',
      'type': 'Силовая',
      'technique': 'Сделайте шаг вперёд, опускайтесь так, чтобы переднее колено не уходило сильно за носок. Спина вертикально/слегка наклонена, корпус стабильный. Толкайтесь пяткой передней ноги, возвращаясь. Колени держите по линии стоп.'
    },
    {
      'name': 'Румынская тяга',
      'muscle': 'Ноги',
      'type': 'Силовая',
      'technique': 'Ноги слегка согнуты, наклон корпуса происходит в тазобедренном суставе. Штанга/гантели опускаются вдоль ног, спина нейтральная. Тяните ягодицами, поднимая вес до выпрямления корпуса. Локти фиксированы, плечи не поднимаются.'
    },
    {
      'name': 'Сгибание ног',
      'muscle': 'Ноги',
      'type': 'Силовая',
      'technique': 'Прижмите таз к скамье/сиденью. Сгибайте ноги, сокращая заднюю поверхность бедра. Пауза в верхней точке 0.5–1 сек, затем медленное опускание. Держите контроль, не раскачивайте корпус.'
    },
    {
      'name': 'Разгибание ног',
      'muscle': 'Ноги',
      'type': 'Силовая',
      'technique': 'Спина и таз закреплены, колени под осью в правильной точке. Разгибайте ноги без рывков, сверху задержка на секунду. Внизу не расслабляйте полностью — сохраняйте натяжение квадрицепса.'
    },
    {
      'name': 'Подъёмы на носки',
      'muscle': 'Ноги',
      'type': 'Силовая',
      'technique': 'Стойка стабильная, пятки ниже опоры (если возможно). Опускайтесь вниз до растяжения икр, затем поднимайтесь на носки, удерживая паузу вверху. Колени слегка согнуты по желанию, корпус ровный.'
    },

    // Пресс
    {
      'name': 'Скручивания',
      'muscle': 'Пресс',
      'type': 'Силовая',
      'technique': 'Лягте на спину, поясница не отрывается (или отрывайте минимально). Поднимайте корпус за счёт пресса, подбородок держите чуть от груди. Медленно возвращайтесь, не тяните шею руками.'
    },
    {
      'name': 'Подъёмы ног',
      'muscle': 'Пресс',
      'type': 'Силовая',
      'technique': 'Лягте/повесьтесь так, чтобы тело было стабильно. Поднимайте ноги, сгибая корпус за счёт пресса (избегайте рывка). В верхней точке удержите 0.5 сек, затем опускайте медленно, не включая поясницу.'
    },
    {
      'name': 'Планка',
      'muscle': 'Пресс',
      'type': 'Изометрия',
      'technique': 'Локти под плечами, тело в одну линию. Живот подтянут, ягодицы не провисают. Удерживайте дыхание ровно, напрягайте пресс и мышцы корпуса. Не опускайте голову — шея нейтральная.'
    },
    {
      'name': 'Боковая планка',
      'muscle': 'Пресс',
      'type': 'Изометрия',
      'technique': 'Опора на локоть и бок стопы. Тело прямое, таз не проваливается. Напрягайте боковые мышцы корпуса, удерживайте ровное дыхание. Вверху не «крутитесь» — сохраняйте стабильность плеча.'
    },
    {
      'name': 'Велосипед',
      'muscle': 'Пресс',
      'type': 'Кардио',
      'technique': 'Лягте на спину, руки за головой без тяги за шею. Поочерёдно подтягивайте колено к противоположному локтю/плечу, скручиваясь корпусом. Движения контролируемые, без рывков, поясница не уходит в провисание.'
    },

    // Плечи
    {
      'name': 'Жим штанги',
      'muscle': 'Плечи',
      'type': 'Силовая',
      'technique': 'Стопы на ширине плеч, корпус собран. Штанга стартует у ключиц/передней дельты. Жмите вверх по прямой линии, слегка разводя лопатки и сохраняя нейтральную поясницу. Опускайте контролируемо до уровня груди/ключиц.'
    },
    {
      'name': 'Жим гантелей',
      'muscle': 'Плечи',
      'type': 'Силовая',
      'technique': 'Сидя или стоя, удерживайте корпус неподвижным. Гантели на уровне плеч, затем жмите вверх, не закидывая голову назад. Локти вверху не «выстреливают» за сустав — держите контроль.'
    },
    {
      'name': 'Подъёмы в стороны',
      'muscle': 'Плечи',
      'type': 'Силовая',
      'technique': 'Наклон корпуса минимальный, спина ровная. Поднимайте гантели через стороны до уровня чуть ниже параллели с полом. Локти слегка согнуты, запястья нейтральные. Опускайте медленно, не заваливая плечи вверх.'
    },
    {
      'name': 'Подъёмы вперёд',
      'muscle': 'Плечи',
      'type': 'Силовая',
      'technique': 'Слегка согните колени, корпус стабилен. Поднимайте гантели вперёд до уровня плеч или чуть ниже, сохраняя небольшой сгиб в локтях. Опускайте контролируемо, не раскачиваясь корпусом.'
    },
    {
      'name': 'Тяга к подбородку',
      'muscle': 'Плечи',
      'type': 'Силовая',
      'technique': 'Хват узкий/средний, штанга/рукоять движется близко к корпусу. Тяните локтями вверх, поднимая плечи умеренно. Важно: не делать слишком широкий «развод» плеч, контролируйте глубину и не допускайте боли в суставах.'
    },
    {
      'name': 'Махи',
      'muscle': 'Плечи',
      'type': 'Силовая',
      'technique': 'Корпус слегка наклонён вперёд (если вариант в наклоне) или держите ровно. Поднимайте гантели/рукояти по заданной амплитуде, сохраняя небольшой сгиб в локтях. Не включайте поясницу и трапеции слишком сильно — цель в работе задней/средней дельты.'
    },

    // Руки
    {
      'name': 'Сгибание на бицепс',
      'muscle': 'Руки',
      'type': 'Силовая',
      'technique': 'Локти прижаты к корпусу, плечи неподвижны. Сгибайте руку за счёт бицепса, удерживая запястье ровным. В верхней точке короткая пауза, затем медленное опускание без «падения» веса.'
    },
    {
      'name': 'Молотковые сгибания',
      'muscle': 'Руки',
      'type': 'Силовая',
      'technique': 'Хват нейтральный (ладони смотрят друг на друга). Поднимайте гантели к плечам, не раскачивая корпус. Держите локти близко, запястья не заваливайте внутрь. Опускайте медленно, сохраняя напряжение в предплечьях.'
    },
    {
      'name': 'Французский жим',
      'muscle': 'Руки',
      'type': 'Силовая',
      'technique': 'Локти держите неподвижными и направленными вперёд/чуть вверх (в зависимости от варианта). Опускайте гриф/гантели за голову или ко лбу контролируемо, чувствуя растяжение трицепса. Поднимайте обратно, не разгибая локти резко и не «хлопая» весом.'
    },
    {
      'name': 'Жим лёжа узким хватом',
      'muscle': 'Руки',
      'type': 'Силовая',
      'technique': 'Хват уже стандартного, лопатки сведены. Опускайте штангу к нижней/средней части груди, локти ведите ближе к корпусу. Жмите вверх силой груди и трицепса, сохраняя ровный корпус и стабильные стопы.'
    },
    {
      'name': 'Подъёмы на бицепс',
      'muscle': 'Руки',
      'type': 'Силовая',
      'technique': 'Движение контролируемое: поднимайте к уровню плеч, не отрывая плечи. Сохраняйте нейтральное положение запястий. Опускайте до полного контроля, не позволяя локтям «уезжать» назад.'
    },
    {
      'name': 'Трицепс на блоке',
      'muscle': 'Руки',
      'type': 'Силовая',
      'technique': 'Локти прижаты к корпусу, не разводите их. Тяните рукоять вниз до полного разгибания без рывка. Удерживайте секунду внизу, затем поднимайте обратно контролируемо, сохраняя напряжение трицепса.'
    },
  ];


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, color: Colors.white),
            SizedBox(width: 10),
            Text('Тренировки', style: TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: Colors.deepOrange,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(icon: Icon(Icons.play_arrow), text: 'Тренировка'),
            Tab(icon: Icon(Icons.library_books), text: 'Упражнения'),
            Tab(icon: Icon(Icons.history), text: 'История'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWorkoutTab(),
          _buildExerciseLibraryTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildWorkoutTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Stats Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepOrange, Colors.orange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
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
                    Icon(Icons.local_fire_department, color: Colors.white, size: 32),
                    SizedBox(width: 10),
                    Text(
                      _totalCaloriesBurned.toStringAsFixed(0),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ' ккал',
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Сожжено за сегодня',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          // Workout modes
          Text(
            'Режимы тренировки',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Column(
            children: [
              _buildModeCard(
                title: 'Фулбади',
                subtitle: 'Последовательно: Всё тело',
                color: Colors.deepOrange,
                icon: Icons.all_inclusive,
                onTap: () => _startSequentialWorkout(_getFullBodyExercises()),
              ),
              SizedBox(height: 12),
              _buildModeCard(
                title: 'Верх',
                subtitle: 'Спина + грудь + плечи',
                color: Colors.blue,
                icon: Icons.sports,
                onTap: () => _startSequentialWorkout(_getUpperBodyExercises()),
              ),
              SizedBox(height: 12),
              _buildModeCard(
                title: 'Низ',
                subtitle: 'Ноги + ягодицы + пресс',
                color: Colors.green,
                icon: Icons.safety_check,
                onTap: () => _startSequentialWorkout(_getLowerBodyExercises()),
              ),
              SizedBox(height: 12),
              _buildModeCard(
                title: 'Собрать свою тренировку',
                subtitle: 'Выберите несколько упражнений',
                color: Colors.orange,
                icon: Icons.add_box_outlined,
                onTap: _showBuildYourWorkoutDialog,
              ),
            ],
          ),

        ],
      ),
    );
  }

  Widget _buildQuickStartCard(String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => _startQuickWorkout(title),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredExercises {
    var exercises = _exerciseLibrary;

    // Filter by muscle group
    if (_selectedFilter != 'Все') {
      exercises = exercises.where((e) => e['muscle'] == _selectedFilter).toList();
    }

    // Filter by search query
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      exercises = exercises
          .where((e) => e['name'].toString().toLowerCase().contains(query))
          .toList();
    }

    // Sort alphabetically by name
    final result = List<Map<String, dynamic>>.from(exercises);
    result.sort((a, b) {
      final an = a['name']?.toString() ?? '';
      final bn = b['name']?.toString() ?? '';
      return an.compareTo(bn);
    });

    return result;
  }


  Widget _buildExerciseLibraryTab() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Поиск упражнений...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
        ),
        
        // Muscle Group Filter
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildFilterChip('Все'),
              _buildFilterChip('Грудь'),
              _buildFilterChip('Спина'),
              _buildFilterChip('Ноги'),
              _buildFilterChip('Пресс'),
              _buildFilterChip('Плечи'),
              _buildFilterChip('Руки'),
            ],
          ),
        ),
        SizedBox(height: 16),
        
        // Exercise List
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredExercises.length,
            itemBuilder: (context, index) {
              var exercise = _filteredExercises[index];
              return _buildExerciseCard(exercise);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: _selectedFilter == label,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = label;
          });
        },
        selectedColor: Colors.deepOrange.shade100,
        checkmarkColor: Colors.deepOrange,
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise) {
    Color muscleColor = _getMuscleColor(exercise['muscle']);
    
    return Card(
      margin: EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: muscleColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.fitness_center, color: muscleColor),
        ),
        title: Text(
          exercise['name'],
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${exercise['muscle']} • ${exercise['type']}',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),

        onTap: () => _showExerciseDetails(exercise),

      ),
    );
  }

  Color _getMuscleColor(String muscle) {
    switch (muscle) {
      case 'Грудь': return Colors.red;
      case 'Спина': return Colors.blue;
      case 'Ноги': return Colors.green;
      case 'Пресс': return Colors.orange;
      case 'Плечи': return Colors.purple;
      case 'Руки': return Colors.teal;
      default: return Colors.grey;
    }
  }

  Widget _buildHistoryTab() {
    if (_userId == null) {
      return Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('Users')
          .doc(_userId)
          .collection('Workouts')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey.shade300),
                SizedBox(height: 16),
                Text('Нет тренировок', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var workout = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            DateTime timestamp = (workout['timestamp'] as Timestamp).toDate();

            return Card(
              margin: EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          workout['name'] ?? 'Тренировка',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${workout['calories']?.toStringAsFixed(0) ?? 0} ккал',
                            style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          _formatDate(timestamp),
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        SizedBox(width: 16),
                        Icon(Icons.fitness_center, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          workout['muscle'] ?? '',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    if (workout['sets'] != null) ...[
                      SizedBox(height: 8),
                      Text(
                        '${workout['sets']} подходов × ${workout['reps']} повторений',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showStartWorkoutDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.fitness_center, color: Colors.deepOrange),
                  SizedBox(width: 10),
                  Text(
                    'Выберите упражнения',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _exerciseLibrary.length,
                itemBuilder: (context, index) {
                  var exercise = _exerciseLibrary[index];
                  return ListTile(
                    trailing: Icon(Icons.play_arrow, color: Colors.deepOrange),
                    title: Text(exercise['name']),
                    subtitle: Text(exercise['muscle']),
                    onTap: () {
                      Navigator.pop(context);
                      _startExerciseSession(exercise);
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

  void _startQuickWorkout(String muscleGroup) {
    var exercise = _exerciseLibrary.firstWhere(
      (e) => e['muscle'] == muscleGroup,
      orElse: () => _exerciseLibrary.first,
    );
    _startExerciseSession(exercise);
  }

  void _addExerciseToWorkout(Map<String, dynamic> exercise) {
    _startExerciseSession(exercise);
  }

  void _showExerciseDetails(Map<String, dynamic> exercise) {
    final technique = (exercise['technique'] ?? 'Техника выполнения скоро будет добавлена.').toString();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.fitness_center, color: Colors.deepOrange, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                exercise['name'],
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  _buildInfoChip(
                    Icons.accessibility_new,
                    exercise['muscle'],
                    _getMuscleColor(exercise['muscle']),
                  ),
                  _buildInfoChip(
                    Icons.category,
                    exercise['type'],
                    Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Техника',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                technique,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }


  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _startExerciseSession(Map<String, dynamic> exercise) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseSessionPage(
          exercise: exercise,
          onComplete: (calories) {
            setState(() {
              _totalCaloriesBurned += calories;
            });

            // If we are running a sequential workout, move to next exercise.
            if (_activeWorkoutExercises.isNotEmpty) {
              _goToNextSequentialExercise(calories);
            }
          },
        ),

      ),
    );
  }

  void _startSequentialWorkout(List<Map<String, dynamic>> exercises) {
    if (exercises.isEmpty) return;

    setState(() {
      _activeWorkoutExercises = List<Map<String, dynamic>>.from(exercises);
      _activeWorkoutIndex = 0;
    });

    _startExerciseSession(_activeWorkoutExercises.first);
  }

  Widget _buildModeCard({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color, size: 26),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFullBodyExercises() {
    // Keep it based on current library.
    final pickNames = <String>{
      'Приседания',
      'Отжимания',
      'Подтягивания',
      'Жим гантелей',
      'Скручивания',
    };

    return _exerciseLibrary.where((e) => pickNames.contains(e['name'])).toList();
  }

  List<Map<String, dynamic>> _getUpperBodyExercises() {
    final pickNames = <String>{
      'Подтягивания',
      'Тяга верхнего блока',
      'Жим лёжа',
      'Жим штанги',
      'Тяга к подбородку',
    };

    return _exerciseLibrary.where((e) => pickNames.contains(e['name'])).toList();
  }

  List<Map<String, dynamic>> _getLowerBodyExercises() {
    final pickNames = <String>{
      'Приседания',
      'Румынская тяга',
      'Выпады',
      'Сгибание ног',
      'Подъёмы на носки',
      'Планка',
    };

    return _exerciseLibrary.where((e) => pickNames.contains(e['name'])).toList();
  }

  void _showBuildYourWorkoutDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final selected = <Map<String, dynamic>>[];
        return StatefulBuilder(
          builder: (context, setModalState) {
            bool isSelected(Map<String, dynamic> ex) {
              return selected.any((s) => s['name'] == ex['name']);
            }

            void toggle(Map<String, dynamic> ex) {
              setModalState(() {
                if (isSelected(ex)) {
                  selected.removeWhere((s) => s['name'] == ex['name']);
                } else {
                  selected.add(ex);
                }
              });
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              maxChildSize: 0.95,
              minChildSize: 0.6,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.add_box_outlined, color: Colors.orange),
                              SizedBox(width: 10),
                              Text(
                                'Собрать свою тренировку',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Text(
                            'Выбрано: ${selected.length}',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: _exerciseLibrary.length,
                        itemBuilder: (context, index) {
                          final ex = _exerciseLibrary[index];
                          final checked = isSelected(ex);
                          return CheckboxListTile(
                            value: checked,
                            onChanged: (_) => toggle(ex),
                            title: Text(ex['name']),
                            subtitle: Text(ex['muscle']),
                            secondary: Icon(Icons.fitness_center, color: _getMuscleColor(ex['muscle'])),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (selected.isEmpty) {
                              Navigator.pop(context);
                              return;
                            }
                            Navigator.pop(context);
                            _startSequentialWorkout(selected);
                          },
                          icon: Icon(Icons.play_arrow, size: 24),
                          label: Text('Начать (${selected.length})', style: TextStyle(fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
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

  void _goToNextSequentialExercise(double calories) {

    // calories уже добавлены коллбеком onComplete у страницы.
    if (_activeWorkoutExercises.isEmpty) return;

    final nextIndex = _activeWorkoutIndex + 1;
    if (nextIndex < _activeWorkoutExercises.length) {
      setState(() {
        _activeWorkoutIndex = nextIndex;
      });
      _startExerciseSession(_activeWorkoutExercises[nextIndex]);
      return;
    }

    // Тренировка завершена
    setState(() {
      _activeWorkoutExercises = const [];
      _activeWorkoutIndex = 0;
    });
  }


  String _formatDate(DateTime date) {
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class ExerciseSessionPage extends StatefulWidget {
  final Map<String, dynamic> exercise;
  final ValueChanged<double> onComplete;

  ExerciseSessionPage({
    required this.exercise,
    required this.onComplete,
  });

  @override
  _ExerciseSessionPageState createState() => _ExerciseSessionPageState();
}

class _ExerciseSessionPageState extends State<ExerciseSessionPage> {
  int _currentSet = 1;
  int _totalSets = 3;
  int _reps = 10;
  int _restSeconds = 90;
  bool _isResting = false;
  int _restTimeRemaining = 0;
  String? _userId;
  
  List<Map<String, dynamic>> _completedSets = [];
  Timer? _timer;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise['name']),
        backgroundColor: Colors.deepOrange,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: _isResting ? _buildRestScreen() : _buildExerciseScreen(),
    );
  }

  Widget _buildExerciseScreen() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Exercise Info
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepOrange.shade50, Colors.orange.shade50],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.fitness_center,
                  size: 64,
                  color: Colors.deepOrange,
                ),
                SizedBox(height: 16),
                Text(
                  widget.exercise['name'],
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.exercise['muscle'],
                    style: TextStyle(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 32),

          // Sets Counter
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _currentSet > 1
                    ? () => setState(() => _currentSet--)
                    : null,
                icon: Icon(Icons.remove_circle_outline),
                iconSize: 40,
                color: Colors.deepOrange,
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Подход $_currentSet из $_totalSets',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                    Text(
                      '$_reps повторений',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _currentSet++),
                icon: Icon(Icons.add_circle_outline),
                iconSize: 40,
                color: Colors.deepOrange,
              ),
            ],
          ),
          SizedBox(height: 32),

          // Weight Input
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Вес: ', style: TextStyle(fontSize: 16)),
                SizedBox(
                  width: 80,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: '0',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
                Text(' кг', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
          SizedBox(height: 32),

          // Complete Set Button
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _completeSet,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check, size: 28),
                  SizedBox(width: 8),
                  Text(
                    'Подход выполнен!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Previous Sets
          if (_completedSets.isNotEmpty) ...[
            Text('Выполненные подходы:', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _completedSets.map((set) {
                return Chip(
                  label: Text('${set['set']}×${set['reps']}'),
                  backgroundColor: Colors.green.shade100,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRestScreen() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer, size: 80, color: Colors.blue),
          SizedBox(height: 24),
          Text(
            'Отдых',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 40),
          
          // Timer Circle
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 180,
                width: 180,
                child: CircularProgressIndicator(
                  value: _restTimeRemaining / _restSeconds,
                  strokeWidth: 15,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_restTimeRemaining',
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    'секунд',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 40),

          // Rest Time Buttons
          Wrap(
            spacing: 8,
            children: [
              _buildRestTimeButton(30),
              _buildRestTimeButton(60),
              _buildRestTimeButton(90),
              _buildRestTimeButton(120),
            ],
          ),
          SizedBox(height: 24),

          // Skip Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _skipRest,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15),
              ),
              child: Text('Пропустить'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestTimeButton(int seconds) {
    return ActionChip(
      label: Text('$seconds сек'),
      onPressed: () {
        setState(() {
          _restSeconds = seconds;
          _restTimeRemaining = seconds;
        });
      },
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Настройки'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text('Подходы: '),
                Expanded(
                  child: Slider(
                    value: _totalSets.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: _totalSets.toString(),
                    onChanged: (value) {
                      setState(() {
                        _totalSets = value.toInt();
                      });
                    },
                  ),
                ),
                Text('$_totalSets'),
              ],
            ),
            Row(
              children: [
                Text('Повторы: '),
                Expanded(
                  child: Slider(
                    value: _reps.toDouble(),
                    min: 1,
                    max: 50,
                    divisions: 49,
                    label: _reps.toString(),
                    onChanged: (value) {
                      setState(() {
                        _reps = value.toInt();
                      });
                    },
                  ),
                ),
                Text('$_reps'),
              ],
            ),
            Row(
              children: [
                Text('Отдых: '),
                Expanded(
                  child: Slider(
                    value: _restSeconds.toDouble(),
                    min: 15,
                    max: 180,
                    divisions: 11,
                    label: '$_restSeconds сек',
                    onChanged: (value) {
                      setState(() {
                        _restSeconds = value.toInt();
                      });
                    },
                  ),
                ),
                Text('$_restSeconds сек'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _completeSet() {
    _completedSets.add({
      'set': _currentSet,
      'reps': _reps,
    });

    if (_currentSet < _totalSets) {
      // Start rest
      setState(() {
        _isResting = true;
        _restTimeRemaining = _restSeconds;
      });
      
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          if (_restTimeRemaining > 0) {
            _restTimeRemaining--;
          } else {
            timer.cancel();
            _currentSet++;
            _isResting = false;
          }
        });
      });
    } else {
      // Workout complete
      _saveWorkout();
      
      double calories = _completedSets.length * 7.5;
      widget.onComplete(calories);
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.celebration, color: Colors.deepOrange),
              SizedBox(width: 10),
              Text('Тренировка завершена!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Выполнено подходов: ${_completedSets.length}'),
              Text('Повторений за подход: $_reps'),
              SizedBox(height: 12),
              Text(
                'Сожжено: ~${calories.toStringAsFixed(0)} ккал',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
              ),
              child: Text('Отлично!', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  void _skipRest() {
    _timer?.cancel();
    setState(() {
      _isResting = false;
      _currentSet++;
    });
  }

  void _saveWorkout() {
    if (_userId == null) return;

    FirebaseFirestore.instance
        .collection('Users')
        .doc(_userId)
        .collection('Workouts')
        .add({
      'name': widget.exercise['name'],
      'muscle': widget.exercise['muscle'],
      'type': widget.exercise['type'],
      'sets': _completedSets.length,
      'reps': _reps,
      'restSeconds': _restSeconds,
      'calories': _completedSets.length * 7.5,
      'timestamp': DateTime.now(),
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
