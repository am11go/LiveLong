import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:livelong_flutter/admin_dashboard.dart';
import 'package:livelong_flutter/uihelper.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  // List of admin emails - in production, this should be stored in Firestore
  // For demo purposes, you can use any of these emails with password "admin123"
  final List<String> adminEmails = [
    'admin@livelong.com',
    'admin1@livelong.com',
    'admin2@livelong.com',
    'demo@livelong.com',
  ];

  login(String email, String password) async {
    if (email == "" && password == "") {
      return UiHelper.CustomAlertBox(context, "Введите необходимые поля");
    }

    // Check if email is in admin list
    if (!adminEmails.contains(email.toLowerCase())) {
      return UiHelper.CustomAlertBox(context, "У вас нет доступа к админ-панели");
    }

    UserCredential? usercredential;
    try {
      usercredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      ).then((value) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboard()),
        );
      });
    } on FirebaseAuthException catch (ex) {
      return UiHelper.CustomAlertBox(context, ex.code.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Админ-панель"),
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.admin_panel_settings,
            size: 80,
            color: Colors.deepOrange,
          ),
          const SizedBox(height: 20),
          const Text(
            'Вход для администратора',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          UiHelper.CustomTextField(
            emailController,
            "Email администратора",
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
          const SizedBox(height: 30),
          UiHelper.CustomButton(() {
            login(emailController.text.toString(), passwordController.text.toString());
          }, "Войти как админ"),
        ],
      ),
    );
  }
}
