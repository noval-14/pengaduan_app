import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'splash_page.dart'; // Import untuk memanggil LogoLapor

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscureText = true;
  bool isLoading = false;

  // FUNGSI LOGIN
  Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _showSnackBar("Isi email dan password");
      return;
    }
    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      _checkUserRole();
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? "Login Gagal", isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  // FUNGSI CEK ROLE (Sesuai logic lama Anda)
  Future<void> _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (doc.exists && doc['role'] == "admin") {
      Navigator.pushReplacementNamed(context, "/admin");
    } else {
      Navigator.pushReplacementNamed(context, "/home");
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: isError ? Colors.red : Colors.blue[900]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: const BackButton(color: Colors.black)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const LogoLapor(),
            const SizedBox(height: 30),
            const Text(
              "Selamat Datang!",
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 8),
            const Text(
              "Silakan masuk untuk melanjutkan",
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 40),

            // INPUT EMAIL
            _buildTextField(
              hint: "Email",
              icon: Icons.person_outline,
              controller: emailController,
            ),
            const SizedBox(height: 20),

            // INPUT PASSWORD
            _buildTextField(
              hint: "Password",
              icon: Icons.lock_outline,
              controller: passwordController,
              isPassword: true,
            ),

            // LUPA PASSWORD
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text("Lupa password?",
                    style: TextStyle(
                        color: Color(0xFF0D47A1), fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),

            // TOMBOL LOGIN
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isLoading ? null : login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Login",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 50),

            // FOOTER DAFTAR
            const Text("Belum punya akun?",
                style: TextStyle(color: Colors.grey)),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, "/register"),
              child: const Text("Daftar di sini",
                  style: TextStyle(
                      color: Color(0xFF0D47A1),
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      {required String hint,
      required IconData icon,
      required TextEditingController controller,
      bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? obscureText : false,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey),
                onPressed: () => setState(() => obscureText = !obscureText),
              )
            : null,
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2)),
      ),
    );
  }
}
