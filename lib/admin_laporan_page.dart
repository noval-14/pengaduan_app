import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// Import halaman detail
import 'admin_detail_page.dart';

class AdminLaporanPage extends StatefulWidget {
  const AdminLaporanPage({super.key});

  @override
  State<AdminLaporanPage> createState() => _AdminLaporanPageState();
}

class _AdminLaporanPageState extends State<AdminLaporanPage> {
  String searchQuery = "";
  String filterStatus = "Semua"; // Filter: Semua, Menunggu, Diproses, Selesai

  // =====================================================
  // LOGIC ASLI (DIPERTAHANKAN)
  // =====================================================

  void updateStatus(String id, String status) {
    FirebaseFirestore.instance.collection('reports').doc(id).update({
      'status': status,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Status diperbarui menjadi $status")),
    );
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "diproses":
        return Colors.blue;
      case "selesai":
        return Colors.green;
      case "menunggu":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      // =====================================================
      // APPBAR DENGAN SEARCH & FILTER
      // =====================================================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: Text("Daftar Laporan",
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    onChanged: (val) =>
                        setState(() => searchQuery = val.toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: "Cari judul laporan...",
                      prefixIcon: Icon(Icons.search, size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: ["Semua", "Menunggu", "Diproses", "Selesai"]
                      .map((status) {
                    bool isSelected = filterStatus == status;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(status),
                        selected: isSelected,
                        onSelected: (val) =>
                            setState(() => filterStatus = status),
                        selectedColor: const Color(0xFF2563EB),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),

      // =====================================================
      // BODY: LIST DATA
      // =====================================================
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          // Logika Filter & Search
          final reports = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final title = (data['title'] ?? '').toString().toLowerCase();
            final status = (data['status'] ?? '').toString().toLowerCase();

            bool matchSearch = title.contains(searchQuery);
            bool matchFilter = filterStatus == "Semua" ||
                status.contains(filterStatus.toLowerCase());

            return matchSearch && matchFilter;
          }).toList();

          if (reports.isEmpty) {
            return Center(
              child: Text("Tidak ada laporan ditemukan",
                  style: GoogleFonts.poppins(color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              final data = report.data() as Map<String, dynamic>;
              String title = data['title'] ?? '-';
              String status = data['status'] ?? 'menunggu';
              String imageUrl = data['image_url'] ?? '';
              Timestamp? createdAt = data['created_at'] as Timestamp?;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: InkWell(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminDetailPage(reportId: report.id),
                      )),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: imageUrl.isNotEmpty
                                  ? Image.network(imageUrl,
                                      width: 60, height: 60, fit: BoxFit.cover)
                                  : Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[100],
                                      child: const Icon(Icons.image)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title,
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  _statusBadge(status),
                                  const SizedBox(height: 4),
                                  Text(
                                      createdAt != null
                                          ? DateFormat('dd MMM yyyy')
                                              .format(createdAt.toDate())
                                          : "-",
                                      style: const TextStyle(
                                          fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: Colors.grey, size: 18),
                          ],
                        ),
                        const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(height: 1)),
                        Row(
                          children: [
                            _actionButton("PROSES", Colors.blue,
                                () => updateStatus(report.id, "diproses")),
                            const SizedBox(width: 8),
                            _actionButton("SELESAI", Colors.green,
                                () => updateStatus(report.id, "selesai")),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Helper Widget: Badge Status
  Widget _statusBadge(String status) {
    Color color = getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(status.toUpperCase(),
          style: TextStyle(
              color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  // Helper Widget: Quick Action Button
  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(vertical: 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
