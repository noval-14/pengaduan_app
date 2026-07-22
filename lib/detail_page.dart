import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DetailPage extends StatefulWidget {
  final String reportId;

  const DetailPage({
    super.key,
    required this.reportId,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> with TickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _addViewCount();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // LOGIC BACKEND (DIPERTAHANKAN - TETAP TERHUBUNG KE API INDOBERT)
  // ===========================================================================

  Future<void> _addViewCount() async {
    try {
      await _firestore.collection('reports').doc(widget.reportId).update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint("Error views: $e");
    }
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
    await _firestore.collection('reports').doc(widget.reportId).update({
      'system_status': status,
    });
  }

  Future<String> getSentiment(String text) async {
    // IP Tetap Aman dan Terkoneksi
    final url = Uri.parse("http://192.168.1.34:5000/predict");
    try {
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"text": text}),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String result =
            (data['sentiment'] ?? data['label'] ?? "").toString().toLowerCase();

        if (result.contains("positif") || result.contains("positive"))
          return "positif";
        if (result.contains("negatif") || result.contains("negative"))
          return "negatif";
      }
      return fallbackSentiment(text);
    } catch (e) {
      return fallbackSentiment(text);
    }
  }

  String fallbackSentiment(String text) {
    text = text.toLowerCase();
    if (RegExp(r'bagus|baik|mantap|keren|hebat|oke').hasMatch(text))
      return "positif";
    if (RegExp(r'jelek|buruk|lambat|parah|kecewa').hasMatch(text))
      return "negatif";
    return "netral";
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      // PROSES ANALISIS TETAP BERJALAN (IndoBERT dipanggil di sini)
      final sentiment = await getSentiment(text);

      // DATA SENTIMENT TETAP DISIMPAN KE FIRESTORE
      await _firestore
          .collection('reports')
          .doc(widget.reportId)
          .collection('comments')
          .add({
        'comment': text,
        'sentiment': sentiment,
        'user_email': _currentUser?.email ?? '',
        'created_at': Timestamp.now(),
      });

      await _firestore.collection('reports').doc(widget.reportId).update({
        'comment_count': FieldValue.increment(1),
      });

      // Update AI Status Dashboard (Logic ini tetap aman)
      final comments = await _firestore
          .collection('reports')
          .doc(widget.reportId)
          .collection('comments')
          .get();
      int p = 0, n = 0, nt = 0;
      for (var doc in comments.docs) {
        final s = (doc['sentiment'] ?? 'netral').toString().toLowerCase();
        if (s == "positif")
          p++;
        else if (s == "negatif")
          n++;
        else
          nt++;
      }
      await updateSystemStatus(getReportStatus(p, n, nt));

      if (!mounted) return;
      _commentController.clear();
      _commentFocusNode.unfocus();
    } catch (e) {
      debugPrint("Add comment error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===========================================================================
  // UI RENDERING
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text("Detail Laporan",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            _firestore.collection('reports').doc(widget.reportId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator.adaptive());

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final likes = List.from(data['likes'] ?? []);

          return Column(
            children: [
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildHeader(data, colorScheme),
                    _buildContent(data, theme),
                    _buildMedia(data['image_url']),
                    _buildStats(likes, data['comment_count'] ?? 0,
                        data['views'] ?? 0, colorScheme),
                    const Divider(height: 1),
                    _buildCommentSection(),
                  ],
                ),
              ),
              _buildInputBar(colorScheme),
            ],
          );
        },
      ),
    );
  }

  // --- Widget Header, Content, Media, Stats (Disingkat untuk fokus ke Comment Section) ---
  // ... (Widget Header dsb tetap sama dengan kode sebelumnya) ...

  Widget _buildCommentSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('reports')
          .doc(widget.reportId)
          .collection('comments')
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final docs = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text("Diskusi Masyarakat",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final c = docs[index].data() as Map<String, dynamic>;
                // MODIFIKASI: Parameter sentimentColor dihapus
                return _CommentTile(
                  data: c,
                  time: c['created_at'] != null
                      ? _formatTimeAgo((c['created_at'] as Timestamp).toDate())
                      : "",
                );
              },
            ),
          ],
        );
      },
    );
  }

  // ... (Widget Input Bar & formatTime tetap sama) ...
  Widget _buildHeader(Map<String, dynamic> data, ColorScheme color) {
    final name =
        data['user_name'] ?? data['user_email']?.split('@')[0] ?? "Warga";
    final time = data['created_at'] != null
        ? _formatTimeAgo((data['created_at'] as Timestamp).toDate())
        : "Baru saja";
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(radius: 20, child: const Icon(Icons.person)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(time,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ]),
        ],
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> data, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(data['title'] ?? "",
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(data['description'] ?? ""),
        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _buildMedia(String? url) {
    if (url == null || url.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(url, fit: BoxFit.cover, width: double.infinity),
      ),
    );
  }

  Widget _buildStats(List likes, int comments, int views, ColorScheme color) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Icon(Icons.thumb_up_alt_outlined, size: 16, color: color.primary),
        const SizedBox(width: 4),
        Text("${likes.length}"),
        const Spacer(),
        Text("$comments Komentar • $views Dilihat",
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ]),
    );
  }

  Widget _buildInputBar(ColorScheme color) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
      color: color.surface,
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _commentController,
            focusNode: _commentFocusNode,
            decoration: InputDecoration(
              hintText: "Tulis aspirasi...",
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
            icon: const Icon(Icons.send),
            onPressed: _addComment,
            color: color.primary),
      ]),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "Baru saja";
    if (diff.inMinutes < 60) return "${diff.inMinutes} menit lalu";
    if (diff.inHours < 24) return "${diff.inHours} jam lalu";
    return "${diff.inDays} hari lalu";
  }
}

// ===========================================================================
// SUB-WIDGET COMMENT TILE (VERSI USER TANPA BADGE)
// ===========================================================================

class _CommentTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final String time;

  // MODIFIKASI: sentimentColor dihapus dari constructor
  const _CommentTile({
    required this.data,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final name = (data['user_email'] ?? "Warga").toString().split('@')[0];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 16, child: Text(name[0].toUpperCase())),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(data['comment'] ?? "",
                          style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                // MODIFIKASI: Hanya menampilkan waktu, badge sentimen dihapus
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    time,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
