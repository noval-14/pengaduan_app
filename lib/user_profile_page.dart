import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'detail_page.dart';

// =====================================================
// CLOUDINARY CONFIGURATION
// =====================================================
final cloudinary = CloudinaryPublic(
  'degl95l5m',
  'pengaduan_unsigned',
  cache: false,
);

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage>
    with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isUpdating = false;

  @override
  void dispose() {
    super.dispose();
  }

  // =====================================================
  // LOGIC METHODS
  // =====================================================

  Future<void> _handleLogout() async {
    try {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
    } catch (e) {
      _showSnackBar("Gagal keluar: $e", isError: true);
    }
  }

  Future<String?> _uploadToCloudinary(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile =
          await picker.pickImage(source: source, imageQuality: 50);
      if (pickedFile == null) return null;

      _showSnackBar("Mengunggah foto...", isError: false);
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(pickedFile.path),
      );
      return response.secureUrl;
    } catch (e) {
      _showSnackBar("Gagal mengunggah foto profil", isError: true);
      return null;
    }
  }

  Future<void> _updateProfile(String name, String? photoUrl) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      _showSnackBar("Nama tidak boleh kosong", isError: true);
      return;
    }

    if (mounted) setState(() => _isUpdating = true);

    try {
      // 1. Update Firebase Auth (Sync purposes)
      await user.updateDisplayName(cleanName);
      if (photoUrl != null) await user.updatePhotoURL(photoUrl);
      await user.reload();

      // 2. Update Firestore as primary source (merge: true to protect role/email)
      await _firestore.collection('users').doc(user.uid).set({
        'display_name': cleanName,
        'photo_url': photoUrl ?? user.photoURL,
        'updated_at': FieldValue.serverTimestamp(),
        'email': user.email, // Ensure email exists
      }, SetOptions(merge: true));

      if (mounted) _showSnackBar("Profil berhasil diperbarui", isError: false);
    } catch (e) {
      _showSnackBar("Terjadi kesalahan saat menyimpan data", isError: true);
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // =====================================================
  // UI DIALOGS & SHEETS
  // =====================================================

  void _showEditProfileDialog(String currentName, String? currentPhoto) {
    final nameController = TextEditingController(text: currentName);
    String? tempPreviewUrl = currentPhoto;

    showDialog(
      context: context,
      barrierDismissible: !_isUpdating,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: const Text("Edit Profil",
                style: TextStyle(fontWeight: FontWeight.w900)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.blue.shade100, width: 2)),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.blue.shade50,
                          backgroundImage: tempPreviewUrl != null
                              ? NetworkImage(tempPreviewUrl!)
                              : null,
                          child: tempPreviewUrl == null
                              ? const Icon(Icons.person, size: 40)
                              : null,
                        ),
                      ),
                      if (!_isUpdating)
                        GestureDetector(
                          onTap: () async {
                            final url =
                                await _uploadToCloudinary(ImageSource.gallery);
                            if (url != null)
                              setDialogState(() => tempPreviewUrl = url);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                                color: Colors.blue, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt_rounded,
                                size: 16, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: nameController,
                    enabled: !_isUpdating,
                    maxLength: 50,
                    decoration: InputDecoration(
                      labelText: "Nama Lengkap",
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: _isUpdating ? null : () => Navigator.pop(context),
                  child: const Text("Batal",
                      style: TextStyle(color: Colors.grey))),
              _isUpdating
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : FilledButton(
                      onPressed: () async {
                        await _updateProfile(
                            nameController.text, tempPreviewUrl);
                        if (mounted && !_isUpdating) Navigator.pop(context);
                      },
                      child: const Text("Simpan"),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettingsBottomSheet(String currentName, String? currentPhoto) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 32),
              const Text("Pengaturan",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 24),
              _settingsItem(Icons.person_outline_rounded, "Edit Profil",
                  "Ubah nama dan foto profil", () {
                Navigator.pop(context);
                _showEditProfileDialog(currentName, currentPhoto);
              }),
              _settingsItem(Icons.info_outline_rounded, "Tentang Aplikasi",
                  "Versi dan informasi pengembang", () {
                Navigator.pop(context);
                showAboutDialog(
                    context: context, applicationName: "Lapor Pak!");
              }),
              const Divider(height: 32),
              _settingsItem(Icons.logout_rounded, "Keluar Akun",
                  "Akhiri sesi dari perangkat ini", () {
                Navigator.pop(context);
                _showLogoutConfirm();
              }, isDanger: true),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirm() {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          icon: const Icon(Icons.logout_rounded,
              size: 48, color: Colors.redAccent),
          title: const Text("Konfirmasi Keluar"),
          content: const Text("Apakah Anda yakin ingin keluar dari akun ini?"),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal")),
            FilledButton(
              onPressed: _handleLogout,
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text("Ya, Keluar"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsItem(
      IconData icon, String title, String sub, VoidCallback onTap,
      {bool isDanger = false}) {
    return ListTile(
      leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: isDanger ? Colors.red.shade50 : Colors.grey.shade50,
              shape: BoxShape.circle),
          child: Icon(icon,
              size: 20, color: isDanger ? Colors.redAccent : Colors.black87)),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isDanger ? Colors.redAccent : Colors.black87)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  // =====================================================
  // MAIN UI BUILDER
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null)
      return const Scaffold(body: Center(child: Text("Sesi berakhir")));

    return StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(user.uid).snapshots(),
        builder: (context, userSnapshot) {
          // Safe data access for Profile
          final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
          final String name = userData?['display_name']?.toString() ??
              user.displayName ??
              "User";
          final String? photo =
              userData?['photo_url']?.toString() ?? user.photoURL;

          return Scaffold(
            backgroundColor: const Color(0xFFFBFBFE),
            body: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('reports')
                  .where('user_id', isEqualTo: user.uid)
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, reportSnapshot) {
                if (reportSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator.adaptive());
                }

                final docs = reportSnapshot.data?.docs ?? [];

                // Statistics logic
                int total = docs.length;
                int menunggu = docs
                    .where((doc) =>
                        (doc.data() as Map<String, dynamic>?)?['status']
                            ?.toString()
                            .toLowerCase()
                            .contains('menunggu') ??
                        false)
                    .length;
                int diproses = docs
                    .where((doc) =>
                        (doc.data() as Map<String, dynamic>?)?['status']
                            ?.toString()
                            .toLowerCase()
                            .contains('diproses') ??
                        false)
                    .length;
                int selesai = docs
                    .where((doc) =>
                        (doc.data() as Map<String, dynamic>?)?['status']
                            ?.toString()
                            .toLowerCase()
                            .contains('selesai') ??
                        false)
                    .length;

                return RefreshIndicator(
                  onRefresh: () async => await user.reload(),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                          child: _buildHeader(name, user.email ?? "", photo)),
                      const SliverToBoxAdapter(child: SizedBox(height: 20)),
                      SliverToBoxAdapter(
                          child: _buildStatsCard(
                              total, menunggu, diproses, selesai)),
                      _buildRiwayatHeader(total),
                      docs.isEmpty
                          ? SliverToBoxAdapter(child: _buildEmptyState())
                          : SliverPadding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final data = docs[index].data()
                                        as Map<String, dynamic>;
                                    return _buildReportCard(
                                        context, docs[index].id, data);
                                  },
                                  childCount: docs.length,
                                ),
                              ),
                            ),
                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  ),
                );
              },
            ),
          );
        });
  }

  Widget _buildHeader(String name, String email, String? photoUrl) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
              bottom: BorderSide(color: Colors.grey.shade100, width: 1))),
      padding: const EdgeInsets.only(top: 60, bottom: 24),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 48),
                const Text('Profil',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                IconButton.filledTonal(
                  icon: const Icon(Icons.settings_rounded, size: 20),
                  onPressed: () => _showSettingsBottomSheet(name, photoUrl),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Hero(
            tag: 'user_avatar_hero',
            child: CircleAvatar(
              radius: 55,
              backgroundColor: Colors.blue.shade50,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? Text(name.isNotEmpty ? name[0].toUpperCase() : "U",
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue))
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(name,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          Text(email,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)),
            child: const Text("Warga Aktif",
                style: TextStyle(
                    color: Colors.blue,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(int total, int menunggu, int diproses, int selesai) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 5))
            ]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statItem('Total', total, Colors.blue),
            _statItem('Tunggu', menunggu, Colors.orange),
            _statItem('Proses', diproses, Colors.blue),
            _statItem('Selesai', selesai, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, int val, Color color) {
    return Column(children: [
      Text(val.toString(),
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w900, color: color)),
      Text(label,
          style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
    ]);
  }

  Widget _buildRiwayatHeader(int total) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Riwayat Laporan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            Text('$total Laporan',
                style: const TextStyle(
                    color: Colors.blue, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(
      BuildContext context, String docId, Map<String, dynamic> data) {
    String statusStr = data['status']?.toString() ?? 'Menunggu';
    Color statusColor = statusStr.toLowerCase().contains('selesai')
        ? Colors.green
        : statusStr.toLowerCase().contains('diproses')
            ? Colors.blue
            : Colors.orange;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 1,
        shadowColor: Colors.black12,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => DetailPage(reportId: docId))),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Hero(
                    tag: 'img_$docId',
                    child: Image.network(data['image_url'] ?? '',
                        width: 85,
                        height: 85,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                            width: 85,
                            height: 85,
                            color: Colors.grey.shade100,
                            child: const Icon(Icons.image_outlined,
                                color: Colors.grey))),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['title'] ?? 'Laporan Tanpa Judul',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(statusStr.toUpperCase(),
                            style: TextStyle(
                                color: statusColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.forum_rounded,
                              size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text('${data['comment_count'] ?? 0}',
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Text(
                              data['created_at'] != null
                                  ? DateFormat('d MMM yyyy').format(
                                      (data['created_at'] as Timestamp)
                                          .toDate())
                                  : "",
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
        child: Padding(
            padding: EdgeInsets.all(40),
            child: Text("Belum ada laporan terkirim")));
  }
}
