import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Tambah ini
import 'package:google_fonts/google_fonts.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final User? _user = FirebaseAuth.instance.currentUser;
  bool _isProcessing = false;

  // FUNGSI LOGOUT
  void _logout() async {
    setState(() => _isProcessing = true);
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, "/login");
  }

  // FUNGSI HITUNG DATA REAL DARI FIRESTORE
  Future<Map<String, int>> _getRealStats() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('reports').get();
    int total = snapshot.docs.length;
    int menunggu = snapshot.docs
        .where((d) => d['status'].toString().toLowerCase().contains('menunggu'))
        .length;
    int proses = snapshot.docs
        .where((d) => d['status'].toString().toLowerCase().contains('proses'))
        .length;
    int selesai = snapshot.docs
        .where((d) => d['status'].toString().toLowerCase().contains('selesai'))
        .length;

    return {
      'total': total,
      'menunggu': menunggu,
      'proses': proses,
      'selesai': selesai
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("ADMINISTRATOR PROFILE",
            style: GoogleFonts.poppins(
                fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 25),
                      _sectionLabel("REAL-TIME MONITORING"),

                      // STATISTIK REAL DARI DATABASE
                      FutureBuilder<Map<String, int>>(
                        future: _getRealStats(),
                        builder: (context, snapshot) {
                          final data = snapshot.data ??
                              {
                                'total': 0,
                                'menunggu': 0,
                                'proses': 0,
                                'selesai': 0
                              };
                          return GridView.count(
                            shrinkWrap: true,
                            crossAxisCount: 2,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            childAspectRatio: 1.6,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _statCard(
                                  "Total Laporan",
                                  data['total'].toString(),
                                  Icons.analytics_rounded,
                                  Colors.blue),
                              _statCard("Menunggu", data['menunggu'].toString(),
                                  Icons.hourglass_bottom, Colors.orange),
                              _statCard("Diproses", data['proses'].toString(),
                                  Icons.sync_rounded, Colors.purple),
                              _statCard("Selesai", data['selesai'].toString(),
                                  Icons.check_circle_rounded, Colors.green),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 25),
                      _sectionLabel("INFORMASI AKUN"),
                      _buildAccountInfoCard(),

                      const SizedBox(height: 30),
                      _buildActionButtons(),

                      const SizedBox(height: 40),
                      Center(
                        child: Text("Sistem Pengaduan V2.0 - ITB STIKOM AMBON",
                            style: GoogleFonts.poppins(
                                fontSize: 10, color: Colors.grey)),
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isProcessing) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 45,
            backgroundColor: Colors.white24,
            child: Icon(Icons.admin_panel_settings_rounded,
                size: 50, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(_user?.displayName ?? "Administrator",
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Text(_user?.email ?? "admin@lapor.ambon.go.id",
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.white60)),
          const SizedBox(height: 12),
          _buildBadge("OTORITAS PENUH", Colors.blueAccent),
        ],
      ),
    );
  }

  Widget _buildAccountInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: [
          _infoRow(
              Icons.person, "Username", _user?.displayName ?? "admin_lapor"),
          const Divider(),
          _infoRow(Icons.email, "Email", _user?.email ?? "-"),
          const Divider(),
          _infoRow(Icons.vpn_key, "Otentikasi", "Firebase Auth"),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => FirebaseAuth.instance
                .sendPasswordResetEmail(email: _user!.email!),
            icon: const Icon(Icons.lock_reset),
            label: const Text("RESET PASSWORD"),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(color: Colors.grey.shade300))),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text("KELUAR SISTEM"),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                elevation: 0),
          ),
        ),
      ],
    );
  }

  // --- REUSABLE WIDGETS ---
  Widget _statCard(String title, String val, IconData icon, Color col) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)
          ]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: col, size: 20),
          const SizedBox(height: 4),
          Text(val,
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          Text(title,
              style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(icon, size: 18, color: Colors.blueGrey),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const Spacer(),
        Text(val,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5))),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 9, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.blueGrey,
              letterSpacing: 1.2)),
    );
  }
}
