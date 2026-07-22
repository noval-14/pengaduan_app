import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

// Import semua halaman tujuan
import 'admin_laporan_page.dart';
import 'admin_detail_page.dart';
import 'analisis_ai_page.dart';
import 'statistik_page.dart';
import 'admin_profile_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  String selectedStatus = "Semua";

  // FUNGSI LOGOUT
  void logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, "/login");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text("Dashboard",
            style: GoogleFonts.poppins(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        centerTitle: true,
      ),

      // =====================================================
      // SIDEBAR DRAWER (SESUAI MOCKUP)
      // =====================================================
      drawer: Drawer(
        child: Container(
          color: const Color(0xFF0F172A), // Biru gelap sesuai mockup
          child: Column(
            children: [
              // 1. Logo Section
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Row(
                    children: [
                      const Icon(Icons.security, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        "LAPOR! ADMIN",
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 2. Menu Items
              _drawerItem(
                icon: Icons.home_filled,
                label: "Dashboard",
                isActive: true, // Halaman ini sendiri
                onTap: () => Navigator.pop(context),
              ),
              _drawerItem(
                icon: Icons.description_rounded,
                label: "Laporan",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminLaporanPage()));
                },
              ),
              _drawerItem(
                icon: Icons.psychology_rounded,
                label: "Analisis AI",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AnalisisAiPage()));
                },
              ),
              _drawerItem(
                icon: Icons.bar_chart_rounded,
                label: "Grafik",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const StatistikPage()));
                },
              ),
              _drawerItem(
                icon: Icons.person_rounded,
                label: "Pengguna",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminProfilePage()));
                },
              ),
              _drawerItem(
                icon: Icons.settings_rounded,
                label: "Pengaturan",
                onTap: () {
                  Navigator.pop(context);
                  // Tambahkan navigasi ke pengaturan jika ada
                },
              ),

              const Spacer(), // Dorong menu keluar ke paling bawah

              // 3. Bottom Section (Logout)
              const Divider(
                  color: Colors.white10,
                  thickness: 1,
                  indent: 20,
                  endIndent: 20),
              _drawerItem(
                icon: Icons.logout_rounded,
                label: "Keluar",
                isDestructive: true,
                onTap: logout,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final allReports = snapshot.data!.docs;

          // --- LOGIKA HITUNG STATISTIK ---
          int totalCount = allReports.length;
          int menungguCount = allReports
              .where((d) =>
                  d['status'].toString().toLowerCase().contains('menunggu'))
              .length;
          int diprosesCount = allReports
              .where((d) =>
                  d['status'].toString().toLowerCase().contains('proses'))
              .length;
          int selesaiCount = allReports
              .where((d) =>
                  d['status'].toString().toLowerCase().contains('selesai'))
              .length;

          // --- LOGIKA FILTER LIST ---
          List<QueryDocumentSnapshot> displayReports;
          if (selectedStatus == "Semua") {
            displayReports = allReports;
          } else {
            displayReports = allReports.where((d) {
              return d['status']
                  .toString()
                  .toLowerCase()
                  .contains(selectedStatus.toLowerCase());
            }).toList();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. STATS ROW
                Row(
                  children: [
                    _topStatCard("Total", totalCount.toString(),
                        const Color(0xFFEEF2FF), Colors.blue[900]!, "Semua"),
                    _topStatCard(
                        "Menunggu",
                        menungguCount.toString(),
                        const Color(0xFFFFF7ED),
                        Colors.orange[800]!,
                        "Menunggu"),
                    _topStatCard("Diproses", diprosesCount.toString(),
                        const Color(0xFFEFF6FF), Colors.blue[600]!, "Diproses"),
                    _topStatCard("Selesai", selesaiCount.toString(),
                        const Color(0xFFF0FDF4), Colors.green[700]!, "Selesai"),
                  ],
                ),
                const SizedBox(height: 20),

                // 2. CHART CARD
                GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AnalisisAiPage())),
                  child: _sectionCard(
                    title: "Grafik Status Laporan",
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: SizedBox(
                            height: 140,
                            child: PieChart(
                              PieChartData(
                                centerSpaceRadius: 35,
                                sections: [
                                  if (menungguCount > 0)
                                    _pieSection(menungguCount.toDouble(),
                                        Colors.orange),
                                  if (diprosesCount > 0)
                                    _pieSection(
                                        diprosesCount.toDouble(), Colors.blue),
                                  if (selesaiCount > 0)
                                    _pieSection(
                                        selesaiCount.toDouble(), Colors.green),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 6,
                          child: Column(
                            children: [
                              _legendItem("Menunggu", menungguCount, totalCount,
                                  Colors.orange),
                              _legendItem("Diproses", diprosesCount, totalCount,
                                  Colors.blue),
                              _legendItem("Selesai", selesaiCount, totalCount,
                                  Colors.green),
                              const SizedBox(height: 8),
                              const Text("Lihat Detail AI >",
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 3. RECENT REPORTS
                _sectionCard(
                  title: selectedStatus == "Semua"
                      ? "Laporan Terbaru"
                      : "Laporan: $selectedStatus",
                  child: Column(
                    children: [
                      if (displayReports.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text("Tidak ada laporan untuk status ini",
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12)),
                        )
                      else
                        ...displayReports
                            .take(5)
                            .map((doc) => _reportItem(doc))
                            .toList(),
                      const SizedBox(height: 15),
                      Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AdminLaporanPage())),
                          child: Text("Lihat semua laporan",
                              style: GoogleFonts.poppins(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          );
        },
      ),
    );
  }

  // =====================================================
  // SIDEBAR ITEM BUILDER (PRIVATE WIDGET)
  // =====================================================
  Widget _drawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    bool isDestructive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          onTap: onTap,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Icon(icon,
              color: isDestructive
                  ? Colors.redAccent
                  : (isActive ? Colors.white : Colors.white60),
              size: 22),
          title: Text(
            label,
            style: GoogleFonts.poppins(
              color: isDestructive
                  ? Colors.redAccent
                  : (isActive ? Colors.white : Colors.white60),
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          dense: true,
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---
  Widget _topStatCard(
      String title, String val, Color bg, Color textCol, String filterType) {
    bool isSelected = selectedStatus == filterType;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedStatus = filterType),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? textCol : bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: textCol.withOpacity(0.2)),
            boxShadow: isSelected
                ? [BoxShadow(color: textCol.withOpacity(0.3), blurRadius: 8)]
                : [],
          ),
          child: Column(
            children: [
              Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 9,
                      color: isSelected ? Colors.white : textCol,
                      fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                  maxLines: 1),
              const SizedBox(height: 4),
              Text(val,
                  style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : textCol)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10)
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 16),
        child,
      ]),
    );
  }

  PieChartSectionData _pieSection(double val, Color col) =>
      PieChartSectionData(value: val, color: col, radius: 18, showTitle: false);

  Widget _legendItem(String label, int val, int total, Color col) {
    double percent = total > 0 ? (val / total) * 100 : 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        CircleAvatar(radius: 4, backgroundColor: col),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: GoogleFonts.poppins(fontSize: 11))),
        Text("$val (${percent.toStringAsFixed(0)}%)",
            style:
                GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _reportItem(DocumentSnapshot doc) {
    String status = doc['status'] ?? "MENUNGGU";
    Color statusColor = status.toLowerCase().contains("selesai")
        ? Colors.green
        : status.toLowerCase().contains("proses")
            ? Colors.blue
            : Colors.orange;
    return InkWell(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => AdminDetailPage(reportId: doc.id))),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: (doc['image_url'] != null && doc['image_url'] != "")
                  ? Image.network(doc['image_url'],
                      width: 50, height: 50, fit: BoxFit.cover)
                  : Container(
                      color: Colors.grey[100],
                      width: 50,
                      height: 50,
                      child: const Icon(Icons.image, color: Colors.grey)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc['title'] ?? "-",
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _statusBadge(status.toUpperCase(), statusColor),
                      const Spacer(),
                      Text(
                          DateFormat('dd MMM').format(
                              (doc['created_at'] as Timestamp).toDate()),
                          style: GoogleFonts.poppins(
                              fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String label, Color col) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
          color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(label,
          style: GoogleFonts.poppins(
              color: col, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }
}
