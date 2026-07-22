import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final User? _user = FirebaseAuth.instance.currentUser;
  bool _isProcessing = false;

  // =====================================================
  // LOGIKA BACKEND (TETAP SAMA)
  // =====================================================

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(msg, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  Future<void> _updateName(String newName) async {
    setState(() => _isProcessing = true);
    try {
      await _user?.updateDisplayName(newName);
      await _user?.reload();
      if (mounted) {
        setState(() {});
        Navigator.pop(context);
        _showSnackBar("Nama administrator berhasil diperbarui", Colors.green);
      }
    } catch (e) {
      _showSnackBar("Gagal memperbarui nama", Colors.red);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _resetPassword() async {
    if (_user?.email != null) {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _user!.email!);
      _showSnackBar(
          "Link reset password telah dikirim ke email otoritas", Colors.blue);
    }
  }

  void _logout() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 500)); // Animasi feel
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, "/login");
  }

  // =====================================================
  // UI COMPONENTS (REDESIGN)
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("ADMINISTRATOR CONSOLE",
            style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 25),
                      _sectionLabel("MONITORING DATA"),
                      _buildStatGrid(),
                      const SizedBox(height: 25),
                      _sectionLabel("IDENTITAS DIGITAL"),
                      _buildAccountInfoCard(),
                      const SizedBox(height: 25),
                      _sectionLabel("PENGATURAN OTORITAS"),
                      _buildSettingsMenu(),
                      const SizedBox(height: 25),
                      _sectionLabel("SISTEM & TEKNOLOGI"),
                      _buildAboutCard(),
                      const SizedBox(height: 40),
                      _buildDangerZone(),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isProcessing) _buildLoadingOverlay(),
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
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          Hero(
            tag: 'avatar_admin',
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                  color: Color(0xFF2563EB), shape: BoxShape.circle),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: Icon(Icons.admin_panel_settings_rounded,
                    size: 55, color: const Color(0xFF0F172A)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(_user?.displayName ?? "Administrator",
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          Text(_user?.email ?? "admin@sistem.go.id",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white60)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBadge("SUPER ADMIN", Colors.blueAccent),
              const SizedBox(width: 8),
              _buildBadge("ONLINE", Colors.greenAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.5)),
    );
  }

  Widget _buildStatGrid() {
    // Simulasi data statistik (Bisa dihubungkan ke Firestore count)
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.5,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _statCard("Total Laporan", "1,248", Icons.analytics_rounded,
            const Color(0xFF2563EB)),
        _statCard(
            "Menunggu", "12", Icons.hourglass_empty_rounded, Colors.orange),
        _statCard("Diproses", "45", Icons.sync_rounded, Colors.purple),
        _statCard("Selesai", "1,191", Icons.check_circle_rounded, Colors.green),
      ],
    );
  }

  Widget _statCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(count,
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B))),
              Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.w500)),
            ],
          ),
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
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _infoRow(
              Icons.person_outline, "Nama Otoritas", _user?.displayName ?? "-"),
          const Divider(height: 25),
          _infoRow(Icons.alternate_email_rounded, "Email Terdaftar",
              _user?.email ?? "-"),
          const Divider(height: 25),
          _infoRow(Icons.fingerprint_rounded, "Firebase UID", _user?.uid ?? "-",
              isSmall: true),
          const Divider(height: 25),
          _infoRow(Icons.security_rounded, "Provider Auth",
              "Firebase Authentication"),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {bool isSmall = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 20, color: const Color(0xFF64748B)),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.w500)),
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: isSmall ? 12 : 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsMenu() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          _menuTile(Icons.edit_note_rounded, "Edit Profil",
              "Sesuaikan nama tampilan administrator", _showEditProfileSheet),
          const Divider(height: 1, indent: 60),
          _menuTile(Icons.vpn_key_outlined, "Reset Password",
              "Kirim instruksi keamanan ke email", _showResetPasswordDialog),
        ],
      ),
    );
  }

  Widget _menuTile(
      IconData icon, String title, String sub, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: const Color(0xFF0F172A), size: 24),
      ),
      title: Text(title,
          style:
              GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700)),
      subtitle: Text(sub,
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.blueGrey)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          size: 14, color: Colors.grey),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9).withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _aboutItem(
              Icons.info_outline_rounded, "App Version", "v2.0.4-Release"),
          const SizedBox(height: 12),
          _aboutItem(Icons.code_rounded, "Framework", "Flutter 3.x stable"),
          const SizedBox(height: 12),
          _aboutItem(
              Icons.cloud_queue_rounded, "Backend", "Firebase & Cloudinary"),
        ],
      ),
    );
  }

  Widget _aboutItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Text("$label : ",
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.blueGrey)),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildDangerZone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("DANGER ZONE",
            style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.redAccent,
                letterSpacing: 1.5)),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _showLogoutDialog,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFEF2F2),
              foregroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFFFEE2E2))),
              elevation: 0,
            ),
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: Text("KELUAR DARI SISTEM",
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800, fontSize: 13)),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // MODERN DIALOGS & SHEETS
  // =====================================================

  void _showEditProfileSheet() {
    final TextEditingController controller =
        TextEditingController(text: _user?.displayName);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 30,
            left: 24,
            right: 24,
            top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 25),
            Text("Edit Identitas Admin",
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 25),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: "Nama Lengkap Administrator",
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _updateName(controller.text),
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15))),
                child: const Text("Simpan Perubahan"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text("Keamanan Akun",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
            "Link reset password akan dikirim ke email otoritas ${_user?.email}. Lanjutkan?",
            style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal")),
          FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _resetPassword();
              },
              child: const Text("Kirim Email")),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2), shape: BoxShape.circle),
                child: const Icon(Icons.logout_rounded,
                    color: Colors.redAccent, size: 35),
              ),
              const SizedBox(height: 20),
              Text("Konfirmasi Keluar",
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("Apakah Anda yakin ingin keluar dari sistem administrasi?",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: Colors.blueGrey)),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                      child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("Batal",
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: FilledButton(
                          onPressed: _logout,
                          style: FilledButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14))),
                          child: const Text("Logout"))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPERS ---

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF64748B),
              letterSpacing: 1.5)),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black26,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: const CircularProgressIndicator(color: Color(0xFF0F172A)),
        ),
      ),
    );
  }
}
