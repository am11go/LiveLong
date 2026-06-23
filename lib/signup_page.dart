import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:livelong_flutter/home.dart';
import 'package:livelong_flutter/uihelper.dart';

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
  String experience = '';
  String goal = '';
  String activity = '';

  bool _obscurePassword = true;
  bool _isLoading = false;

  double calculateBMI(int height, int weight) {
    if (height <= 0) return 0;
    final heightInMeters = height / 100.0;
    final bmi = weight / (heightInMeters * heightInMeters);
    return bmi;
  }

  signUp() async {
    if (emailController.text == "" ||
        passwordController.text == "" ||
        nameController.text == "" ||
        ageController.text == "" ||
        gender == "" ||
        heightController.text == "" ||
        weightController.text == "" ||
        experience == "" ||
        goal == "" ||
        activity == "") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Пожалуйста, заполните все поля'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // Calculate BMI
      double bmi = calculateBMI(
        int.parse(heightController.text),
        int.parse(weightController.text),
      );

      // Store user information in Firestore with BMI
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userCredential.user!.uid)
          .set({
        'name': nameController.text,
        'email': emailController.text,
        'age': int.parse(ageController.text),
        'gender': gender,
        'height': int.parse(heightController.text),
        'weight': int.parse(weightController.text),
        'bmi': bmi,
        'experience': experience,
        'goal': goal,
        'activity': activity,
        'createdAt': DateTime.now(),
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    } on FirebaseAuthException catch (ex) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getAuthErrorMessage(ex.code)),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Произошла ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Этот email уже используется';
      case 'invalid-email':
        return 'Неверный формат email';
      case 'weak-password':
        return 'Пароль слишком слабый';
      case 'operation-not-allowed':
        return 'Операция запрещена';
      default:
        return 'Ошибка: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepOrange,
              Colors.orange.shade300,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 80,
                      color: Colors.white,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'LIVELONG',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 4,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Создайте свой аккаунт',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              // Form
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Name Field
                        _buildTextField(
                          controller: nameController,
                          label: 'Имя',
                          icon: Icons.person,
                          keyboardType: TextInputType.name,
                        ),
                        SizedBox(height: 16),

                        // Email Field
                        _buildTextField(
                          controller: emailController,
                          label: 'Email',
                          icon: Icons.mail,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        SizedBox(height: 16),

                        // Password Field
                        TextField(
                          controller: passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Пароль',
                            prefixIcon: Icon(Icons.lock, color: Colors.deepOrange),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: Colors.deepOrange, width: 2),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),

                        // Age Field
                        _buildTextField(
                          controller: ageController,
                          label: 'Возраст',
                          icon: Icons.cake,
                          keyboardType: TextInputType.number,
                        ),
                        SizedBox(height: 16),

                        // Gender Selection
                        Text(
                          'Пол',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _buildGenderChip('Муж', 'Муж')),
                            SizedBox(width: 8),
                            Expanded(child: _buildGenderChip('Жен', 'Жен')),
                          ],
                        ),
                        SizedBox(height: 16),

                        // Experience Dropdown
                        _buildDropdownField(
                          label: 'Какой у вас опыт в зале?',
                          value: experience,
                          items: const [
                            DropdownMenuItem(
                              value: 'Нет опыта',
                              child: Text('Нет опыта'),
                            ),
                            DropdownMenuItem(
                              value: 'Начинающий (до 1 года)',
                              child: Text('Начинающий (до 1 года)'),
                            ),
                            DropdownMenuItem(
                              value: 'Средний (1-2 года)',
                              child: Text('Средний (1-2 года)'),
                            ),
                            DropdownMenuItem(
                              value: 'Продвинутый (более 2 лет)',
                              child: Text('Продвинутый (более 2 лет)'),
                            ),
                          ],
                          onChanged: (val) {
                            setState(() {
                              experience = val ?? '';
                            });
                          },
                        ),
                        SizedBox(height: 16),

                        // Goal Dropdown
                        _buildDropdownField(
                          label: 'Какая у тебя цель?',
                          value: goal,
                          items: const [
                            DropdownMenuItem(
                              value: 'Снижение веса',
                              child: Text('Снижение веса'),
                            ),
                            DropdownMenuItem(
                              value: 'Мышечный тонус',
                              child: Text('Мышечный тонус'),
                            ),
                            DropdownMenuItem(
                              value: 'Набор мышечной массы',
                              child: Text('Набор мышечной массы'),
                            ),
                          ],
                          onChanged: (val) {
                            setState(() {
                              goal = val ?? '';
                            });
                          },
                        ),
                        SizedBox(height: 16),

                        // Activity Dropdown
                        _buildDropdownField(
                          label: 'Какая активность?',
                          value: activity,
                          items: const [
                            DropdownMenuItem(
                              value: 'Нет физических нагрузок',
                              child: Text('Нет физических нагрузок'),
                            ),
                            DropdownMenuItem(
                              value: '1-2 тренировки в неделю',
                              child: Text('1-2 тренировки в неделю'),
                            ),
                            DropdownMenuItem(
                              value: '3-4 тренировки в неделю',
                              child: Text('3-4 тренировки в неделю'),
                            ),
                            DropdownMenuItem(
                              value: '5-7 тренировок в неделю',
                              child: Text('5-7 тренировок в неделю'),
                            ),
                            DropdownMenuItem(
                              value: 'Тяж. труд + тренировки каждый день',
                              child: Text('Тяж. труд + тренировки каждый день'),
                            ),
                          ],
                          onChanged: (val) {
                            setState(() {
                              activity = val ?? '';
                            });
                          },
                        ),
                        SizedBox(height: 16),

                        // Height and Weight
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: heightController,
                                label: 'Рост (см)',
                                icon: Icons.height,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: weightController,
                                label: 'Вес (кг)',
                                icon: Icons.monitor_weight,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),

                        // Register Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: _isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  'Зарегистрироваться',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                        SizedBox(height: 16),

                        // Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Уже есть аккаунт?',
                              style: TextStyle(color: Colors.grey),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                'Войти',
                                style: TextStyle(
                                  color: Colors.deepOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepOrange),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.deepOrange, width: 2),
        ),
      ),
    );
  }

  Widget _buildGenderChip(String label, String value) {
    final isSelected = gender == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          gender = value;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepOrange : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(15),
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

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value.isEmpty ? null : value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.deepOrange, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          ),
        ),
      ],
    );
  }
}
