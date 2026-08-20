import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

// Palette Warna
class AppColors {
  static const primary = Color(0xFF2563EB);
  static const bg = Color(0xFFF8FAFC);
  static const card = Colors.white;
  static const textHeadline = Color(0xFF0F172A);
  static const textSub = Color(0xFF64748B);

  static const pos = Color(0xFF10B981);
  static const neg = Color(0xFFEF4444);
  static const net = Color(0xFFF59E0B);

  static const blue = Color(0xFF3B82F6);
  static const purple = Color(0xFF8B5CF6);
  static const indigo = Color(0xFF6366F1);
  static const slate = Color(0xFF475569);
}

class AdminDetailPage extends StatefulWidget {
  final String reportId;
  const AdminDetailPage({super.key, required this.reportId});

  @override
  State<AdminDetailPage> createState() => _AdminDetailPageState();
}

class _AdminDetailPageState extends State<AdminDetailPage>
    with TickerProviderStateMixin {
  final commentController = TextEditingController();
  bool isLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    addView();
  }

  // =====================================================
  // LOGIC BACKEND
  // =====================================================

  Future<void> addView() async {
    await FirebaseFirestore.instance
        .collection('reports')
        .doc(widget.reportId)
        .update({'views': FieldValue.increment(1)});
  }

  String getReportStatus(int positif, int negatif, int netral) {
    int total = positif + negatif + netral;
    if (total == 0) return "Perlu Dicek";
    double pPos = positif / total;
    double pNeg = negatif / total;
    if (pNeg >= 0.6) return "Urgent";
    if (pPos >= 0.6) return "Valid";
    return "Perlu Dicek";
  }

  Future<void> updateSystemStatus(String status) async {
    await FirebaseFirestore.instance
        .collection('reports')
        .doc(widget.reportId)
        .update({'system_status': status});
  }
  // =====================================================

// VALIDASI AKHIR ADMIN

// =====================================================

  Future<void> validateByAdmin() async {
    await FirebaseFirestore.instance
        .collection('reports')
        .doc(widget.reportId)
        .update({
      'admin_validate': true,
    });
  }

  Future<void> cancelAdminValidation() async {
    await FirebaseFirestore.instance
        .collection('reports')
        .doc(widget.reportId)
        .update({
      'admin_validate': false,
    });
  }

  Future<Map<String, dynamic>> getSentiment(String text) async {
    final url = Uri.parse("http://192.168.1.9:5000/predict");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"text": text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        String result = "";
        double confidence = 0.0;

        // Ambil Label
        if (data is Map && data.containsKey('sentiment')) {
          result = data['sentiment'].toString().toLowerCase();
        } else if (data is Map && data.containsKey('label')) {
          result = data['label'].toString().toLowerCase();
        }

        // confidence score ke firestore
        if (data is Map) {
          if (data.containsKey('confidence')) {
            confidence = double.tryParse(data['confidence'].toString()) ?? 0.0;
          } else if (data.containsKey('score')) {
            confidence = double.tryParse(data['score'].toString()) ?? 0.0;
          }
        }

        String sentiment;
        if (result.contains("positif") || result.contains("positive")) {
          sentiment = "positif";
        } else if (result.contains("negatif") || result.contains("negative")) {
          sentiment = "negatif";
        } else {
          sentiment = "netral";
        }

        return {
          'sentiment': sentiment,
          'confidence': confidence, // Nilai  masuk ke sini
        };
      }
      return {'sentiment': 'netral', 'confidence': 0.0};
    } catch (e) {
      debugPrint("Error Flask: $e");
      return {'sentiment': 'netral', 'confidence': 0.0};
    }
  }

  Future<void> addComment() async {
    String text = commentController.text.trim();
    final user = FirebaseAuth.instance.currentUser;

    debugPrint("ADD COMMENT YANG BARU DI JALANKAN");

    if (text.isEmpty) return;

    setState(() => isLoading = true);

    try {
      // 1. Memanggil getSentiment (sekarang sudah bisa baca 'score' dari Flask)
      final aiResult = await getSentiment(text);

      // 2. Mengambil sentiment dan confidence (0.99...)
      final String sentiment = aiResult['sentiment']?.toString() ?? 'netral';
      final double confidence =
          (aiResult['confidence'] as num?)?.toDouble() ?? 0.0;

      debugPrint("SENTIMENT: $sentiment");
      debugPrint("CONFIDENCE: $confidence");

      await FirebaseFirestore.instance
          .collection('reports')
          .doc(widget.reportId)
          .collection('comments')
          .add({
        'comment': text,
        'sentiment': sentiment,
        'confidence': confidence,
        'user_email': user?.email ?? '',
        'created_at': Timestamp.now(),
      });

      // 4. Hitung ulang statistik p, n, nt
      final snapshot = await FirebaseFirestore.instance
          .collection('reports')
          .doc(widget.reportId)
          .collection('comments')
          .get();

      int p = 0, n = 0, nt = 0;
      for (var doc in snapshot.docs) {
        String s = (doc['sentiment'] ?? 'netral').toString().toLowerCase();
        if (s == "positif") {
          p++;
        } else if (s == "negatif") {
          n++;
        } else {
          nt++;
        }
      }

      // 5. Update Status Sistem & Bersihkan UI
      await updateSystemStatus(getReportStatus(p, n, nt));
      commentController.clear();
    } catch (e) {
      debugPrint("Error saat menambah komentar: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }
  // =====================================================
  // UI HELPERS & DESIGN COMPONENTS
  // =====================================================

  Color _getStatusColor(String status) {
    // Normalisasi case agar warna tetap muncul meski di DB lowercase
    switch (status.toLowerCase()) {
      case "menunggu":
        return AppColors.net;
      case "sedang ditinjau":
      case "diproses":
        return AppColors.blue;
      case "petugas dikerahkan":
        return AppColors.purple;
      case "ditangani polisi":
        return AppColors.indigo;
      case "ditangani pemadam":
        return AppColors.neg;
      case "selesai":
        return AppColors.pos;
      default:
        return AppColors.slate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textHeadline, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Dashboard",
            style: TextStyle(
                color: AppColors.textHeadline,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSub,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: "DETAIL"),
            Tab(text: "KOMENTAR"),
            Tab(text: "AI ANALYTICS"),
          ],
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .doc(widget.reportId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data() as Map<String, dynamic>;

          return TabBarView(
            controller: _tabController,
            children: [
              _buildDetailTab(data),
              _buildCommentTab(),
              _buildAIDashboard(data),
            ],
          );
        },
      ),
    );
  }

  // =====================================================
  // TAB 1: DETAIL LAPORAN
  // =====================================================

  Widget _buildDetailTab(Map<String, dynamic> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IDENTITAS PELAPOR
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Pelapor Resmi:",
                          style: TextStyle(
                              fontSize: 10, color: AppColors.textSub)),
                      Text(
                          data['user_name'] ??
                              data['user_email']?.split('@')[0] ??
                              'Warga Ambon',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textHeadline)),
                      Text(data['user_email'] ?? '',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSub)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Hero(
            tag: widget.reportId,
            child: Container(
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                image: DecorationImage(
                  image: NetworkImage(data['image_url'] ?? ''),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(data['title'] ?? '',
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textHeadline)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip(Icons.location_on_rounded, data['location'] ?? '',
                  AppColors.blue),
              _buildChip(
                  Icons.calendar_month_rounded,
                  data['created_at'] != null
                      ? DateFormat('dd MMM yyyy')
                          .format((data['created_at'] as Timestamp).toDate())
                      : '-',
                  AppColors.slate),
              _buildChip(Icons.visibility_rounded,
                  "${data['views'] ?? 0} Views", AppColors.indigo),
              _buildChip(Icons.auto_awesome_rounded,
                  data['system_status'] ?? 'Analysing', AppColors.purple),
            ],
          ),
          const SizedBox(height: 24),
          const Text("Deskripsi Laporan",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textHeadline)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15)
              ],
            ),
            child: Text(data['description'] ?? '',
                style: const TextStyle(
                    color: AppColors.textSub, height: 1.6, fontSize: 15)),
          ),
          const SizedBox(height: 24),
          _buildStatusDropdown(data['status'] ?? 'Menunggu'),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown(String currentStatus) {
    // List opsi didefinisikan di variabel agar bisa dicek keberadaannya
    final List<String> statusOptions = [
      "Menunggu",
      "Sedang Ditinjau",
      "Diproses",
      "Petugas Dikerahkan",
      "Ditangani Polisi",
      "Ditangani Pemadam",
      "Selesai"
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: _getStatusColor(currentStatus).withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Update Status Operasional",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            // PERBAIKAN: Cek apakah currentStatus ada di dalam list. Jika tidak ada (misal: "selesai" vs "Selesai"), set null agar tidak error.
            value: statusOptions.contains(currentStatus) ? currentStatus : null,
            hint: Text(currentStatus), // Tampilkan teks asli jika tidak match
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.shield_rounded,
                  color: _getStatusColor(currentStatus)),
              border: InputBorder.none,
            ),
            items: statusOptions
                .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s,
                        style: const TextStyle(fontWeight: FontWeight.w600))))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                FirebaseFirestore.instance
                    .collection('reports')
                    .doc(widget.reportId)
                    .update({'status': val});
              }
            },
          ),
        ],
      ),
    );
  }

  // =====================================================
  // TAB 2: KOMENTAR (MODERN CHAT)
  // =====================================================

  Widget _buildCommentTab() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('reports')
                .doc(widget.reportId)
                .collection('comments')
                .orderBy('created_at', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              if (snapshot.data!.docs.isEmpty) {
                return Center(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded,
                        size: 64, color: AppColors.textSub.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    const Text("Belum ada interaksi",
                        style: TextStyle(
                            color: AppColors.textSub,
                            fontWeight: FontWeight.bold)),
                  ],
                ));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                reverse: true,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final comment =
                      snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  bool isAdmin = (comment['user_email'] ?? '')
                      .toString()
                      .contains('admin');

                  return TweenAnimationBuilder(
                    duration: Duration(milliseconds: 400 + (index * 50)),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: _buildChatBubble(comment, isAdmin),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        _buildChatInput(),
      ],
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> comment, bool isAdmin) {
    String sentiment = comment['sentiment'] ?? 'netral';
    return Align(
      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isAdmin ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isAdmin ? 20 : 0),
            bottomRight: Radius.circular(isAdmin ? 0 : 20),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isAdmin)
                  const Icon(Icons.verified_rounded,
                      size: 14, color: Colors.white),
                if (isAdmin) const SizedBox(width: 4),
                Text(
                    isAdmin
                        ? "Official Admin"
                        : comment['user_email'].split('@')[0],
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isAdmin ? Colors.white : AppColors.primary)),
                const SizedBox(width: 8),
                if (!isAdmin) _sentimentBadge(sentiment),
              ],
            ),
            const SizedBox(height: 8),
            Text(comment['comment'] ?? '',
                style: TextStyle(
                    color: isAdmin ? Colors.white : AppColors.textHeadline,
                    fontSize: 14,
                    height: 1.4)),
            const SizedBox(height: 8),
            Text(
                comment['created_at'] != null
                    ? DateFormat('HH:mm')
                        .format((comment['created_at'] as Timestamp).toDate())
                    : '-',
                style: TextStyle(
                    fontSize: 10,
                    color: isAdmin ? Colors.white70 : AppColors.textSub)),
          ],
        ),
      ),
    );
  }

  Widget _sentimentBadge(String s) {
    Color c = s == 'positif'
        ? AppColors.pos
        : s == 'negatif'
            ? AppColors.neg
            : AppColors.net;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(s.toUpperCase(),
          style: TextStyle(color: c, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: commentController,
              decoration: InputDecoration(
                hintText: "Berikan tanggapan resmi...",
                border: InputBorder.none,
                hintStyle: TextStyle(color: AppColors.textSub.withOpacity(0.5)),
              ),
            ),
          ),
          isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : IconButton(
                  icon:
                      const Icon(Icons.send_rounded, color: AppColors.primary),
                  onPressed: addComment,
                ),
        ],
      ),
    );
  }

  // =====================================================
  // TAB 3: AI ANALYTICS DASHBOARD
  // =====================================================

  Widget _buildAIDashboard(Map<String, dynamic> data) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .doc(widget.reportId)
          .collection('comments')
          .snapshots(),
      builder: (context, snapshot) {
        int pos = 0, neg = 0, net = 0;
        double totalConfidence = 0.0;

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final commentData = doc.data() as Map<String, dynamic>;
            String s = (commentData['sentiment'] ?? 'netral').toLowerCase();

            // Ambil nilai confidence dari database
            totalConfidence +=
                (commentData['confidence'] as num? ?? 0.0).toDouble();

            if (s == 'positif')
              pos++;
            else if (s == 'negatif')
              neg++;
            else
              net++;
          }
        }

        int total = pos + neg + net;
        // Hitung rata-rata
        double avgConfidence = total > 0 ? (totalConfidence / total) : 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.4,
                children: [
                  _summaryCard("Total Interactions", total.toString(),
                      Icons.analytics_rounded, AppColors.indigo),
                  _summaryCard("Positive", pos.toString(),
                      Icons.sentiment_very_satisfied_rounded, AppColors.pos),
                  _summaryCard("Neutral", net.toString(),
                      Icons.sentiment_neutral_rounded, AppColors.net),
                  _summaryCard("Negative", neg.toString(),
                      Icons.sentiment_very_dissatisfied_rounded, AppColors.neg),
                ],
              ),
              const SizedBox(height: 24),
              _buildAnalyticsCard(pos, net, neg, total),
              const SizedBox(height: 24),
              _buildAIStatusLarge(data['system_status'] ?? 'Analysing'),
              const SizedBox(height: 24),

              // MEMANGGIL UI DENGAN PARAMETER
              _buildConfidenceUI(avgConfidence),

              const SizedBox(height: 24),
              _buildInsightCard(pos, neg, net),
              const SizedBox(height: 24),
              _buildAITimeline(data),
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)
        ],
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center, // Pusatkan agar tidak mepet bawah
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          FittedBox(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900))),
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSub,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(int pos, int net, int neg, int total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Sentiment Probability",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          _progressRow("Positive", pos, total, AppColors.pos),
          _progressRow("Neutral", net, total, AppColors.net),
          _progressRow("Negative", neg, total, AppColors.neg),
        ],
      ),
    );
  }

  Widget _progressRow(String label, int val, int total, Color color) {
    double percent = total == 0 ? 0 : val / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
              Text("${(percent * 100).toInt()}%",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIStatusLarge(String status) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.indigo, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const Icon(Icons.psychology_outlined, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          Text(status.toUpperCase(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2)),
          const Text("AI SYSTEM CLASSIFICATION",
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5)),
        ],
      ),
    );
  }

  // TAMBAHKAN PARAMETER double avgConfidence DI SINI
  Widget _buildConfidenceUI(double avgConfidence) {
    double displayPercent = avgConfidence * 100;

    Color statusColor = AppColors.net;
    String label = "Medium Confidence";

    if (avgConfidence >= 0.8) {
      statusColor = AppColors.pos;
      label = "High Confidence Score";
    } else if (avgConfidence < 0.4) {
      statusColor = AppColors.neg;
      label = "Low Confidence Score";
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(28)),
      child: Row(
        children: [
          SizedBox(
            height: 60,
            width: 60,
            child: CircularProgressIndicator(
                value: avgConfidence, // Menampilkan data real
                strokeWidth: 8,
                backgroundColor: AppColors.bg,
                color: statusColor),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("AI Confidence",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("${displayPercent.toStringAsFixed(1)}% $label",
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInsightCard(int pos, int neg, int net) {
    String insight =
        "Komentar masyarakat masih beragam sehingga diperlukan verifikasi lanjutan.";
    if (pos > neg && pos > net)
      insight =
          "Mayoritas komentar masyarakat bersifat positif sehingga laporan dianggap valid.";
    if (neg > pos && neg > net)
      insight =
          "Mayoritas komentar masyarakat bersifat negatif sehingga laporan memerlukan perhatian segera.";

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology_alt_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text("AI Semantic Insight",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          Text(insight,
              style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textHeadline,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildAITimeline(Map<String, dynamic> data) {
    bool validated = data['admin_validate'] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Processing Timeline",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 20),
        _timelineItem("Laporan dibuat", true),
        _timelineItem("AI membaca laporan", true),
        _timelineItem("AI menganalisis komentar", true),
        _timelineItem("AI menghasilkan status", true),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () async {
            if (validated) {
              await cancelAdminValidation();
            } else {
              await validateByAdmin();
            }
          },
          icon: Icon(validated ? Icons.close : Icons.check),
          label: Text(
            validated ? "Batalkan Validasi" : "Validasi Laporan",
          ),
        ),
        const SizedBox(height: 12),
        _timelineItem(
          "Validasi akhir Admin",
          validated,
        ),
      ],
    );
  }

  Widget _timelineItem(String text, bool isDone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(
              isDone
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isDone ? AppColors.pos : AppColors.textSub,
              size: 20),
          const SizedBox(width: 12),
          Text(text,
              style: TextStyle(
                  color: isDone ? AppColors.textHeadline : AppColors.textSub,
                  fontWeight: isDone ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
