import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';

// Import halaman tujuan
import 'user_profile_page.dart';
import 'add_report_page.dart';
import 'notification_page.dart';
import 'detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser;

  // VARIABLE UNTUK FITUR SEARCH
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  // Logika pembantu untuk format waktu
  String _getTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return "";
    DateTime postDate = timestamp.toDate();
    Duration diff = DateTime.now().difference(postDate);

    if (diff.inDays > 0) return "${diff.inDays} hari yang lalu";
    if (diff.inHours > 0) return "${diff.inHours} jam yang lalu";
    if (diff.inMinutes > 0) return "${diff.inMinutes} menit yang lalu";
    return "Baru saja";
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ==========================================
            // HEADER
            // ==========================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 32),
                  const Text(
                    "Beranda",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationPage()),
                      );
                    },
                    child: const Icon(Icons.notifications_none_rounded,
                        size: 28, color: Colors.black),
                  ),
                ],
              ),
            ),

            // ==========================================
            // SEARCH BAR (SEKARANG SUDAH BERFUNGSI)
            // ==========================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search,
                        color: Color(0xFF94A3B8), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          // Update state saat user mengetik
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: "Cari judul laporan...",
                          hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8), fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          // Tombol hapus pencarian jika ada teks
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = "";
                                    });
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ==========================================
            // FEED LIST (DENGAN LOGIKA FILTER SEARCH)
            // ==========================================
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('reports')
                    .orderBy('created_at', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("Belum ada laporan"));
                  }

                  // LOGIKA FILTERING: Saring data berdasarkan input di Search Bar
                  final allDocs = snapshot.data!.docs;
                  final filteredReports = allDocs.where((doc) {
                    final title = (doc['title'] ?? "").toString().toLowerCase();
                    return title.contains(_searchQuery);
                  }).toList();

                  if (filteredReports.isEmpty) {
                    return const Center(
                      child: Text("Laporan tidak ditemukan",
                          style: TextStyle(color: Colors.grey)),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredReports.length,
                    padding: const EdgeInsets.only(top: 10),
                    itemBuilder: (context, index) {
                      final data =
                          filteredReports[index].data() as Map<String, dynamic>;
                      final reportId = filteredReports[index].id;
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      final List likes = data['likes'] ?? [];
                      final bool isLiked = uid != null && likes.contains(uid);

                      // Logic Warna Status
                      String statusRaw = (data['status'] ?? "MENUNGGU")
                          .toString()
                          .toUpperCase();
                      Color statusBg = const Color(0xFFFFF7ED);
                      Color statusTxt = const Color(0xFFF59E0B);

                      if (statusRaw.contains("DIPROSES")) {
                        statusBg = const Color(0xFFEFF6FF);
                        statusTxt = const Color(0xFF2563EB);
                      } else if (statusRaw.contains("SELESAI")) {
                        statusBg = const Color(0xFFF0FDF4);
                        statusTxt = const Color(0xFF16A34A);
                      }

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => DetailPage(reportId: reportId)),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                height: 1, color: const Color(0xFFF1F5F9)),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: const Color(0xFFE2E8F0),
                                    backgroundImage:
                                        (data['user_photo'] ?? "").isNotEmpty
                                            ? NetworkImage(data['user_photo'])
                                            : null,
                                    child: (data['user_photo'] ?? "").isEmpty
                                        ? const Icon(Icons.person,
                                            color: Colors.white)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['user_name'] ??
                                              data['user_email']
                                                  ?.split('@')[0] ??
                                              "User",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "${data['location'] ?? ''} • ${_getTimeAgo(data['created_at'])}",
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF64748B)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if ((data['image_url'] ?? "").isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    data['image_url'],
                                    width: double.infinity,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['title'] ?? "",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        color: Color(0xFF111827)),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    data['description'] ?? "",
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Color(0xFF4B5563),
                                        fontSize: 13,
                                        height: 1.5),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                        color: statusBg,
                                        borderRadius: BorderRadius.circular(8)),
                                    child: Text(statusRaw,
                                        style: TextStyle(
                                            color: statusTxt,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 10)),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 18, 20, 24),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      if (uid == null) return;
                                      final docRef = FirebaseFirestore.instance
                                          .collection('reports')
                                          .doc(reportId);
                                      if (isLiked) {
                                        await docRef.update({
                                          'likes': FieldValue.arrayRemove([uid])
                                        });
                                      } else {
                                        await docRef.update({
                                          'likes': FieldValue.arrayUnion([uid])
                                        });
                                      }
                                    },
                                    child: Row(
                                      children: [
                                        Icon(
                                            isLiked
                                                ? Icons.thumb_up
                                                : Icons.thumb_up_alt_outlined,
                                            size: 20,
                                            color: isLiked
                                                ? const Color(0xFF2563EB)
                                                : const Color(0xFF64748B)),
                                        const SizedBox(width: 8),
                                        Text("${likes.length}",
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: isLiked
                                                    ? const Color(0xFF2563EB)
                                                    : const Color(0xFF64748B),
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.mode_comment_outlined,
                                          size: 20, color: Color(0xFF64748B)),
                                      const SizedBox(width: 8),
                                      Text("${data['comment_count'] ?? 0}",
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF64748B),
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.remove_red_eye_outlined,
                                          size: 20, color: Color(0xFF64748B)),
                                      const SizedBox(width: 8),
                                      Text("${data['views'] ?? 0}",
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF64748B),
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: () => Share.share(
                                        '📢 ${data['title']}\n\nStatus: ${data['status']}'),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.share_outlined,
                                            size: 20, color: Color(0xFF64748B)),
                                        const SizedBox(width: 8),
                                        const Text("Bagikan",
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF64748B),
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
              top: BorderSide(color: Color(0xFFF1F5F9), width: 1.5)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, -5))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            GestureDetector(
              onTap: () {},
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.home_rounded, size: 28, color: Color(0xFF2563EB)),
                  SizedBox(height: 4),
                  Text("Beranda",
                      style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AddReportPage())),
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                    color: Color(0xFF2563EB), shape: BoxShape.circle),
                child: const Icon(Icons.add, color: Colors.white, size: 32),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const UserProfilePage())),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.person_outline_rounded,
                      size: 28, color: Color(0xFF94A3B8)),
                  SizedBox(height: 4),
                  Text("Profil",
                      style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
