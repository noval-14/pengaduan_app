import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'admin_page.dart';
import 'add_report_page.dart';
import 'detail_page.dart';
import 'register_page.dart';
import 'splash_page.dart';
import 'analisis_ai_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pengaduan App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // home: LoginPage(), // <--- 2. KODE LAMA (DIHAPUS/KOMENTAR)
      home:
          const SplashPage(), // <--- 3. UBAH JADI SPLASH PAGE AGAR MUNCUL PERTAMA KALI
      routes: {
        "/register": (context) => const RegisterPage(),
        "/home": (context) => HomePage(),
        "/admin": (context) => AdminPage(),
        "/login": (context) => LoginPage(),
        "/add_report": (context) => AddReportPage(),
        "/analisis_ai": (context) => const AnalisisAiPage(),
        "/detail": (context) {
          final reportId = ModalRoute.of(context)!.settings.arguments as String;
          return DetailPage(reportId: reportId);
        }
      },
    );
  }
}
