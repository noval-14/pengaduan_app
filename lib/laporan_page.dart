import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'user_profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'detail_page.dart';
import 'notification_page.dart';
import 'home_page.dart';

class LaporanPage extends StatefulWidget {
  final bool isAdmin;

  const LaporanPage({
    super.key,
    this.isAdmin = false,
  });

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  final TextEditingController searchController = TextEditingController();

  String selectedFilter = "all";

  // =====================================================
  // FILTER BUTTON
  // =====================================================

  Widget filterButton({
    required String text,
    required String value,
    required int total,
    required Color color,
  }) {
    final bool active = selectedFilter == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.14) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: active ? color.withOpacity(0.25) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          "$text ($total)",
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: active ? color : Colors.black54,
          ),
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
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
          color: active ? const Color(0xff2563EB) : Colors.grey,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 8,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? const Color(0xff2563EB) : Colors.grey,
          ),
        ),
      ],
    );
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),

      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('reports')
              .orderBy(
                'created_at',
                descending: true,
              )
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final allReports = snapshot.data!.docs;
            final currentUserId = FirebaseAuth.instance.currentUser?.uid;

            int totalAll = allReports.length;

            final reports = allReports.where((e) {
              final data = e.data() as Map<String, dynamic>;
              final uid = FirebaseAuth.instance.currentUser!.uid;

              final List likes = data['likes'] ?? [];

              final bool isLiked = likes.contains(uid);
              String reportTitle =
                  (data['title'] ?? '').toString().toLowerCase();

              if (!reportTitle.contains(
                searchController.text.toLowerCase(),
              )) {
                return false;
              }
              if (selectedFilter == "all") {
                return true;
              }

              if (selectedFilter == "mine") {
                return data['user_id'] == currentUserId;
              }

              String status = (data['status'] ?? '').toString().toLowerCase();

              if (selectedFilter == "menunggu") {
                return status.contains("menunggu");
              }

              if (selectedFilter == "diproses") {
                return status.contains("diproses");
              }

              if (selectedFilter == "selesai") {
                return status.contains("selesai");
              }

              return true;
            }).toList();

            return Column(
              children: [
                // APPBAR

                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    10,
                    18,
                    0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            "Semua Laporan",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // SEARCH

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                  ),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: searchController,
                      onChanged: (value) {
                        setState(() {});
                      },
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.search),
                        hintText: "Cari laporan...",
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // FILTER

                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                    ),
                    children: [
                      filterButton(
                        text: "Semua",
                        value: "all",
                        total: totalAll,
                        color: Colors.blue,
                      ),
                      filterButton(
                        text: "Laporan Saya",
                        value: "mine",
                        total: 0, // nanti diganti
                        color: Colors.purple,
                      ),
                      filterButton(
                        text: "Menunggu",
                        value: "menunggu",
                        total: allReports.where((e) {
                          final data = e.data() as Map<String, dynamic>;

                          return (data['status'] ?? '')
                              .toString()
                              .toLowerCase()
                              .contains("menunggu");
                        }).length,
                        color: Colors.orange,
                      ),
                      filterButton(
                        text: "Diproses",
                        value: "diproses",
                        total: allReports.where((e) {
                          final data = e.data() as Map<String, dynamic>;

                          return (data['status'] ?? '')
                              .toString()
                              .toLowerCase()
                              .contains("diproses");
                        }).length,
                        color: Colors.blue,
                      ),
                      filterButton(
                        text: "Selesai",
                        value: "selesai",
                        total: allReports.where((e) {
                          final data = e.data() as Map<String, dynamic>;

                          return (data['status'] ?? '')
                              .toString()
                              .toLowerCase()
                              .contains("selesai");
                        }).length,
                        color: Colors.green,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // LIST

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                    ),
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report = reports[index];

                      final data = report.data() as Map<String, dynamic>;

                      final uid = FirebaseAuth.instance.currentUser?.uid ?? "";

                      final List likes = data['likes'] ?? [];

                      final bool isLiked = likes.contains(uid);

                      String title = data['title'] ?? '-';

                      String description = data['description'] ?? '-';

                      String category = data['category'] ?? 'Umum';
                      String status = data['status'] ?? 'Menunggu';
                      String imageUrl = data['image_url'] ?? '';
                      String userName = data['user_name'] ?? 'Pengguna';
                      String photoUrl = data['photo_url'] ?? '';

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailPage(
                                reportId: report.id,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(
                            bottom: 14,
                          ),
                          padding: const EdgeInsets.all(
                            16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundImage: photoUrl.isNotEmpty
                                        ? NetworkImage(photoUrl)
                                        : null,
                                    child: photoUrl.isEmpty
                                        ? const Icon(Icons.person, size: 18)
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      userName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (imageUrl.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Image.network(
                                    imageUrl,
                                    width: double.infinity,
                                    height: 180,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              if (imageUrl.isNotEmpty)
                                const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: status
                                              .toLowerCase()
                                              .contains("selesai")
                                          ? Colors.green.withOpacity(0.12)
                                          : Colors.orange.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: status
                                                .toLowerCase()
                                                .contains("selesai")
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(category),
                              const SizedBox(height: 8),
                              Text(
                                description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  InkWell(
                                    onTap: () async {
                                      if (isLiked) {
                                        await FirebaseFirestore.instance
                                            .collection('reports')
                                            .doc(report.id)
                                            .update({
                                          'likes':
                                              FieldValue.arrayRemove([uid]),
                                        });
                                      } else {
                                        await FirebaseFirestore.instance
                                            .collection('reports')
                                            .doc(report.id)
                                            .update({
                                          'likes': FieldValue.arrayUnion([uid]),
                                        });
                                      }
                                    },
                                    child: Row(
                                      children: [
                                        Icon(
                                          isLiked
                                              ? Icons.thumb_up
                                              : Icons.thumb_up_alt_outlined,
                                          color: isLiked
                                              ? Colors.blue
                                              : Colors.grey,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 5),
                                        Text("${likes.length}"),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),

      // BOTTOM NAV

      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomePage(),
                    ),
                  );
                },
                child: navItem(
                  icon: Icons.home_rounded,
                  label: "Home",
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: navItem(
                  icon: Icons.description_outlined,
                  label: "Laporan",
                  active: true,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    "/add_report",
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(11),
                  decoration: const BoxDecoration(
                    color: Color(0xff2563EB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationPage(),
                    ),
                  );
                },
                child: navItem(
                  icon: Icons.notifications_outlined,
                  label: "Notif",
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UserProfilePage(),
                    ),
                  );
                },
                child: navItem(
                  icon: Icons.person_outline,
                  label: "Akun",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
