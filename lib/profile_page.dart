import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'laporan_page.dart';
import 'statistik_page.dart';
import 'user_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool notif = true;

  final user = FirebaseAuth.instance.currentUser;

  // =====================================================
  // MENU ITEM
  // =====================================================

  Widget menuItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
    Color color = Colors.black87,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: color,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            trailing ??
                const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // NAV ITEM
  // =====================================================

  Widget navItem({
    required IconData icon,
    required String label,
    bool active = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: active ? const Color(0xff2563EB) : Colors.grey,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? const Color(0xff2563EB) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // LOGOUT
  // =====================================================

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      "/login",
    );
  }

  // =====================================================
  // UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      body: SafeArea(
        child: Column(
          children: [
            // =====================================================
            // HEADER
            // =====================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                20,
                30,
                20,
                40,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xff2563EB),
                    Color(0xff4F46E5),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(34),
                  bottomRight: Radius.circular(34),
                ),
              ),
              child: Column(
                children: [
                  // FOTO

                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundColor: const Color(0xff2563EB),
                      child: Text(
                        (user?.email ?? "Admin")[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // NAMA

                  Text(
                    "Admin",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // EMAIL

                  Text(
                    user?.email ?? "admin@gmail.com",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // BADGE

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      "Administrator",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // =====================================================
            // MENU
            // =====================================================

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      menuItem(
                        icon: Icons.person_outline,
                        title: "Profil Saya",
                      ),

                      Divider(
                        height: 1,
                        color: Colors.grey.shade200,
                      ),

                      menuItem(
                        icon: Icons.lock_outline,
                        title: "Ubah Password",
                      ),

                      Divider(
                        height: 1,
                        color: Colors.grey.shade200,
                      ),

                      menuItem(
                        icon: Icons.notifications_none,
                        title: "Notifikasi",
                        trailing: Switch(
                          value: notif,
                          activeColor: const Color(0xff2563EB),
                          onChanged: (value) {
                            setState(() {
                              notif = value;
                            });
                          },
                        ),
                      ),

                      Divider(
                        height: 1,
                        color: Colors.grey.shade200,
                      ),

                      menuItem(
                        icon: Icons.light_mode_outlined,
                        title: "Tema",
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Terang",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),

                      Divider(
                        height: 1,
                        color: Colors.grey.shade200,
                      ),

                      menuItem(
                        icon: Icons.info_outline,
                        title: "Tentang Aplikasi",
                      ),

                      Divider(
                        height: 1,
                        color: Colors.grey.shade200,
                      ),

                      menuItem(
                        icon: Icons.help_outline,
                        title: "Bantuan & FAQ",
                      ),

                      const SizedBox(height: 20),

                      // LOGOUT

                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: logout,
                            icon: const Icon(
                              Icons.logout,
                              color: Colors.red,
                            ),
                            label: Text(
                              "Keluar",
                              style: GoogleFonts.poppins(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Colors.red.shade200,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // =====================================================
      // BOTTOM NAVIGATION
      // =====================================================

      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              navItem(
                icon: Icons.home_rounded,
                label: "Dashboard",
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UserProfilePage(),
                    ),
                  );
                },
              ),
              navItem(
                icon: Icons.description_outlined,
                label: "Laporan",
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LaporanPage(
                        isAdmin: false,
                      ),
                    ),
                  );
                },
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xff2563EB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              navItem(
                icon: Icons.bar_chart_rounded,
                label: "Statistik",
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StatistikPage(),
                    ),
                  );
                },
              ),
              navItem(
                icon: Icons.person,
                label: "Akun",
                active: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
