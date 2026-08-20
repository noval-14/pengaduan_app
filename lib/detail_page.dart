import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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

  // KONFIGURASI CLOUDINARY
  final String _cloudName = "drtda7v9v";
  final String _uploadPreset = "ml_default";

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
  // LOGIC BACKEND (SENTIMENT & FIREBASE) - TIDAK BERUBAH
  // ===========================================================================

  Future<void> _addViewCount() async {
    try {
      final doc =
          await _firestore.collection('reports').doc(widget.reportId).get();
      if (!doc.exists) return;
      final data = doc.data() as Map<String, dynamic>;
      if (data['user_id'] == _currentUser?.uid) return;

      await _firestore.collection('reports').doc(widget.reportId).update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint("Error views: $e");
    }
  }

  Future<void> _toggleLike(List likes) async {
    if (_currentUser == null) return;
    final uid = _currentUser.uid;
    DocumentReference docRef =
        _firestore.collection('reports').doc(widget.reportId);
    try {
      if (likes.contains(uid)) {
        await docRef.update({
          'likes': FieldValue.arrayRemove([uid])
        });
      } else {
        await docRef.update({
          'likes': FieldValue.arrayUnion([uid])
        });
      }
    } catch (e) {
      debugPrint("Error like: $e");
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

  Future<void> _recalculateSystemStatus() async {
    try {
      final commentsSnapshot = await _firestore
          .collection('reports')
          .doc(widget.reportId)
          .collection('comments')
          .get();

      int p = 0, n = 0, nt = 0;
      for (var doc in commentsSnapshot.docs) {
        final s =
            (doc.data()['sentiment'] ?? 'netral').toString().toLowerCase();
        if (s == "positif")
          p++;
        else if (s == "negatif")
          n++;
        else
          nt++;
      }

      await _firestore.collection('reports').doc(widget.reportId).update({
        'comment_count': commentsSnapshot.docs.length,
        'system_status': getReportStatus(p, n, nt),
      });
    } catch (e) {
      debugPrint("Recalculate error: $e");
    }
  }

  Future<Map<String, dynamic>> getSentiment(String text) async {
    final url = Uri.parse("http://192.168.1.9:5000/predict");

    try {
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"text": text}),
          )
          .timeout(const Duration(seconds: 7));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        debugPrint("🔥 RESPONSE INDOBERT: $data");

        final String sentiment =
            (data['sentiment'] ?? "netral").toString().toLowerCase();

        final double confidence =
            double.tryParse(data['confidence'].toString()) ?? 0.0;

        return {
          'sentiment': sentiment,
          'confidence': confidence,
        };
      }

      return {
        'sentiment': 'netral',
        'confidence': 0.0,
      };
    } catch (e) {
      debugPrint("🔥 Error getSentiment: $e");

      return {
        'sentiment': 'netral',
        'confidence': 0.0,
      };
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      final aiResult = await getSentiment(text);

      final String sentiment = aiResult['sentiment']?.toString() ?? 'netral';

      final double confidence =
          (aiResult['confidence'] as num?)?.toDouble() ?? 0.0;

      debugPrint("🔥 SENTIMENT: $sentiment");
      debugPrint("🔥 CONFIDENCE: $confidence");

      await _firestore
          .collection('reports')
          .doc(widget.reportId)
          .collection('comments')
          .add({
        'comment': text,
        'sentiment': sentiment,
        'confidence': confidence,
        'user_email': _currentUser?.email ?? '',
        'user_id': _currentUser?.uid ?? '',
        'created_at': Timestamp.now(),
      });

      _commentController.clear();
      _commentFocusNode.unfocus();

      await _recalculateSystemStatus();

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      debugPrint("Add comment error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await _firestore
          .collection('reports')
          .doc(widget.reportId)
          .collection('comments')
          .doc(commentId)
          .delete();

      await _recalculateSystemStatus();
    } catch (e) {
      debugPrint("Delete error: $e");
    }
  }

  Future<String?> _uploadToCloudinary(File file) async {
    final url = Uri.parse(
      "https://api.cloudinary.com/v1_1/$_cloudName/image/upload",
    );

    final request = http.MultipartRequest("POST", url)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final json = jsonDecode(String.fromCharCodes(responseData));
        return json['secure_url'];
      }

      return null;
    } catch (e) {
      debugPrint("Cloudinary upload error: $e");
      return null;
    }
  }

  // ===========================================================================
  // UI RENDERING (FIX KEYBOARD LAYOUT)
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('reports').doc(widget.reportId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        if (!snapshot.data!.exists)
          return const Scaffold(body: Center(child: Text("Laporan Dihapus")));

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final likes = List.from(data['likes'] ?? []);
        final isOwner = data['user_id'] == _currentUser?.uid;

        return Scaffold(
          backgroundColor: Colors.white,
          // resizeToAvoidBottomInset true agar body mengecil saat keyboard muncul
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            title: const Text("Detail Laporan",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            centerTitle: true,
            elevation: 0,
            actions: [
              if (isOwner)
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'edit') _showEditDialog(data);
                    if (val == 'delete') _showDeleteDialog();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text("Edit")),
                    const PopupMenuItem(
                        value: 'delete',
                        child:
                            Text("Hapus", style: TextStyle(color: Colors.red))),
                  ],
                ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildHeader(data, colorScheme),
                    _buildContent(data),
                    _buildMedia(data['image_url']),
                    _buildStats(likes, data['comment_count'] ?? 0,
                        data['views'] ?? 0, colorScheme),
                    const Divider(thickness: 8, color: Color(0xFFF5F5F5)),
                    _buildCommentSection(),
                  ],
                ),
              ),
              // Bar input diletakkan di dalam Column agar otomatis terdorong keyboard
              _buildInputBar(colorScheme),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(Map<String, dynamic> data, ColorScheme color) {
    final name =
        data['user_name'] ?? data['user_email']?.split('@')[0] ?? "Warga";
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
              backgroundColor: color.primaryContainer,
              child: Text(name[0].toUpperCase())),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            const Text("Baru saja",
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
          const Spacer(),
          _buildStatusLabel(data['system_status']),
        ],
      ),
    );
  }

  Widget _buildStatusLabel(String? status) {
    Color color = Colors.orange;
    if (status == "Valid") color = Colors.green;
    if (status == "Urgent") color = Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color)),
      child: Text(status ?? "Proses",
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildContent(Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(data['title'] ?? "",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(data['description'] ?? "",
            style: const TextStyle(fontSize: 15, height: 1.5)),
        const SizedBox(height: 12),
        if (data['location'] != null)
          Row(children: [
            const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
            const SizedBox(width: 4),
            Expanded(
                child: Text(data['location'],
                    style: const TextStyle(color: Colors.grey, fontSize: 13))),
          ]),
        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _buildMedia(String? url) {
    if (url == null || url.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.network(url,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
                height: 150,
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image))),
      ),
    );
  }

  Widget _buildStats(List likes, int comments, int views, ColorScheme color) {
    final isLiked = likes.contains(_currentUser?.uid);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        IconButton(
          icon: Icon(isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
              color: isLiked ? color.primary : Colors.grey),
          onPressed: () => _toggleLike(likes),
        ),
        Text("${likes.length}"),
        const Spacer(),
        const Icon(Icons.comment_outlined, size: 18, color: Colors.grey),
        const SizedBox(width: 4),
        Text("$comments"),
        const SizedBox(width: 16),
        const Icon(Icons.remove_red_eye_outlined, size: 18, color: Colors.grey),
        const SizedBox(width: 4),
        Text("$views"),
      ]),
    );
  }

  Widget _buildCommentSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('reports')
          .doc(widget.reportId)
          .collection('comments')
          .orderBy('created_at', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final docs = snapshot.data!.docs;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text("Aspirasi Masyarakat",
                    style: TextStyle(fontWeight: FontWeight.bold))),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final c = docs[index].data() as Map<String, dynamic>;
                return ListTile(
                  leading: CircleAvatar(
                      radius: 15,
                      child: Text(c['user_email'][0].toUpperCase(),
                          style: const TextStyle(fontSize: 10))),
                  title: Text(c['user_email'].split('@')[0],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text(c['comment'] ?? ""),
                  trailing: (c['user_id'] == _currentUser?.uid)
                      ? IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: () => _deleteComment(docs[index].id))
                      : null,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildInputBar(ColorScheme color) {
    return Container(
      // Padding standar, SafeArea akan menangani HP ber-poni bawah
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(
            color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2))
      ]),
      child: SafeArea(
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              focusNode: _commentFocusNode,
              decoration: InputDecoration(
                hintText: "Tulis tanggapan...",
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : CircleAvatar(
                  backgroundColor: color.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: _addComment,
                  ),
                )
        ]),
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> data) {
    // Skenario Edit Laporan (Pertahankan logika aslimu)
    final titleCtrl = TextEditingController(text: data['title'] ?? "");
    final descCtrl = TextEditingController(text: data['description'] ?? "");
    final locCtrl = TextEditingController(text: data['location'] ?? "");
    File? selectedImage;
    bool isDialogLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text("Edit Laporan"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: "Judul")),
                TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: "Deskripsi"),
                    maxLines: 3),
                TextField(
                    controller: locCtrl,
                    decoration: const InputDecoration(labelText: "Lokasi")),
                TextButton(
                  onPressed: () async {
                    final picked = await ImagePicker()
                        .pickImage(source: ImageSource.gallery);
                    if (picked != null)
                      setDialogState(() => selectedImage = File(picked.path));
                  },
                  child: const Text("Ganti Gambar"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal")),
            ElevatedButton(
              onPressed: () async {
                setDialogState(() => isDialogLoading = true);
                String finalUrl = data['image_url'] ?? "";
                if (selectedImage != null) {
                  final uploaded = await _uploadToCloudinary(selectedImage!);
                  if (uploaded != null) finalUrl = uploaded;
                }
                await _firestore
                    .collection('reports')
                    .doc(widget.reportId)
                    .update({
                  'title': titleCtrl.text,
                  'description': descCtrl.text,
                  'location': locCtrl.text,
                  'image_url': finalUrl,
                });
                Navigator.pop(context);
              },
              child: isDialogLoading
                  ? const CircularProgressIndicator()
                  : const Text("Simpan"),
            )
          ],
        );
      }),
    );
  }

  void _showDeleteDialog() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Hapus Laporan?"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Batal")),
                TextButton(
                    onPressed: () async {
                      await _firestore
                          .collection('reports')
                          .doc(widget.reportId)
                          .delete();
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text("Hapus",
                        style: TextStyle(color: Colors.red))),
              ],
            ));
  }
}
