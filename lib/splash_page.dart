import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Konfigurasi Animasi agar muncul perlahan (Fade In)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();

    _startAppLogic();
  }

  Future<void> _startAppLogic() async {
    // WAJIB: Tahan selama 3 detik agar Splash terlihat
    await Future.delayed(const Duration(seconds: 3));

    final user = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (user == null) {
      // Belum login -> Pindah ke Login
      Navigator.pushReplacementNamed(context, "/login");
    } else {
      // Sudah login -> Cek Role di Firestore
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          String role = userDoc.get('role') ?? 'user';
          if (role == 'admin') {
            Navigator.pushReplacementNamed(context, "/admin");
          } else {
            Navigator.pushReplacementNamed(context, "/home");
          }
        } else {
          Navigator.pushReplacementNamed(context, "/home");
        }
      } catch (e) {
        // Jika internet error/firestore gagal, tetap ke login
        Navigator.pushReplacementNamed(context, "/login");
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Latar belakang putih sesuai mockup
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 80),
              // LOGO LINGKARAN BIRU
              const Center(child: LogoLapor()),
              const Spacer(),
              // ILUSTRASI (Representasi Visual Kota)
              const Icon(Icons.location_city_rounded,
                  size: 200, color: Color(0xFFE5E7EB)),
              const Spacer(),
              // TEXT BRANDING
              const Text(
                "LAPOR!",
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0D47A1),
                  letterSpacing: 2,
                ),
              ),
              const Text(
                "Pengaduan Masyarakat",
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 60),
              // PAGE INDICATOR
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 25,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D47A1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 5),
                  _dot(),
                  _dot(),
                  _dot(),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot() {
    return Container(
      width: 8,
      height: 8,
      decoration:
          const BoxDecoration(color: Color(0xFFE0E0E0), shape: BoxShape.circle),
    );
  }
}

// WIDGET LOGO (Sesuai Mockup)
class LogoLapor extends StatelessWidget {
  const LogoLapor({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration:
          const BoxDecoration(color: Color(0xFF0D47A1), shape: BoxShape.circle),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 20,
            left: 20,
            child: Container(
                width: 25,
                height: 25,
                decoration: const BoxDecoration(color: Color(0xFF0D47A1))),
          ),
          const Icon(Icons.priority_high_rounded,
              color: Colors.white, size: 55),
        ],
      ),
    );
  }
}
