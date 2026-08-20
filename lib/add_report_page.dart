import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'location_picker.dart'; // Tetap dipertahankan
import 'package:cloudinary_public/cloudinary_public.dart';

// LOGIC BACKEND - TIDAK DIUBAH
final cloudinary = CloudinaryPublic(
  'degl95l5m',
  'pengaduan_unsigned',
  cache: false,
);

class AddReportPage extends StatefulWidget {
  const AddReportPage({super.key});

  @override
  State<AddReportPage> createState() => _AddReportPageState();
}

class _AddReportPageState extends State<AddReportPage>
    with TickerProviderStateMixin {
  // VARIABLE & CONTROLLER - TIDAK DIUBAH
  final titleController = TextEditingController();
  final descController = TextEditingController();
  final locationController = TextEditingController();
  String selectedCategory = "Infrastruktur";
  bool isLoading = false;
  File? imageFile;

  // UI STATE HELPERS
  late ScrollController _scrollController;
  final categories = [
    "Infrastruktur",
    "Kebersihan",
    "Drainase",
    "Keamanan",
    "Lainnya"
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    titleController.addListener(() => setState(() {}));
    descController.addListener(() => setState(() {}));
    locationController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    titleController.dispose();
    descController.dispose();
    locationController.dispose();
    super.dispose();
  }

  // =====================================================
  // LOGIC FUNCTIONS (MEMPERTAHANKAN LOGIKA ASLI)
  // =====================================================

  Future<void> pickImage(ImageSource source) async {
    HapticFeedback.lightImpact();
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 70,
    );

    if (picked != null) {
      setState(() {
        imageFile = File(picked.path);
      });
    }
  }

  Future<String?> uploadImage() async {
    try {
      if (imageFile == null) return null;
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(imageFile!.path),
      );
      return response.secureUrl;
    } catch (e) {
      return null;
    }
  }

  Future<void> submitReport() async {
    if (titleController.text.isEmpty ||
        descController.text.isEmpty ||
        locationController.text.isEmpty) {
      HapticFeedback.vibrate();
      _showErrorSnackBar("Lengkapi semua data terlebih dahulu");
      return;
    }

    setState(() => isLoading = true);

    try {
      String? imageUrl = await uploadImage();
      final user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance.collection('reports').add({
        'title': titleController.text.trim(),
        'description': descController.text.trim(),
        'location': locationController.text.trim(),
        'category': selectedCategory,
        'image_url': imageUrl,
        'user_id': user?.uid,
        'user_email': user?.email,
        'user_name': user?.email,
        'status': 'menunggu',
        'handled_by': '',
        'system_status': 'Perlu Dicek',
        'views': 0,
        'likes': [],
        'comment_count': 0,
        'created_at': Timestamp.now(),
      });

      _buildSuccessDialog();
    } catch (e) {
      _showErrorSnackBar("Gagal mengirim laporan. Silakan coba lagi.");
    }

    setState(() => isLoading = false);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // =====================================================
  // UI BUILDERS (REDESIGN TOTAL)
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildHeader(colorScheme),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  child: Column(
                    children: [
                      _buildPhotoPicker(colorScheme),
                      const SizedBox(height: 32),
                      _buildCategory(colorScheme),
                      const SizedBox(height: 32),
                      _buildTextFields(colorScheme),
                      const SizedBox(height: 32),
                      _buildLocation(colorScheme),
                      const SizedBox(height: 32),
                      _buildSummary(colorScheme),
                      const SizedBox(height: 40),
                      _buildSubmitButton(colorScheme),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (isLoading) _buildLoadingOverlay(colorScheme),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme color) {
    int completedSteps = 0;
    if (imageFile != null) completedSteps++;
    if (titleController.text.isNotEmpty && descController.text.isNotEmpty)
      completedSteps++;
    if (locationController.text.isNotEmpty) completedSteps++;
    double progress = completedSteps / 3;

    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 2,
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.campaign_rounded,
                          color: color.primary, size: 32),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text("Buat Laporan",
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5)),
                const Text("Lengkapi data untuk membantu kami memproses cepat",
                    style: TextStyle(color: Colors.grey, fontSize: 14)),
                const Spacer(),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Progress Laporan",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: color.primary,
                                fontSize: 12)),
                        Text("${(progress * 100).toInt()}%",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: color.surfaceVariant,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(color.primary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPicker(ColorScheme color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Bukti Visual",
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _buildBottomSheet(color),
          child: Hero(
            tag: 'photo_report',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 240,
              decoration: BoxDecoration(
                color: imageFile == null ? Colors.white : color.surfaceVariant,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                    color: imageFile == null
                        ? color.outlineVariant
                        : Colors.transparent,
                    width: 2,
                    style: BorderStyle.solid),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 10))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: imageFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_rounded,
                                size: 48, color: color.primary),
                            const SizedBox(height: 16),
                            const Text("Tambah Foto Bukti",
                                style: TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 16)),
                            Text("Klik untuk ambil bukti kejadian",
                                style: TextStyle(
                                    color: color.outline, fontSize: 12)),
                          ],
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(imageFile!, fit: BoxFit.cover),
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black38],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 16,
                              right: 16,
                              child: _glassButton(Icons.edit_rounded,
                                  () => _buildBottomSheet(color)),
                            ),
                            Positioned(
                              top: 16,
                              left: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20)),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: color.primary, size: 16),
                                    const SizedBox(width: 4),
                                    const Text("Foto terpilih",
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategory(ColorScheme color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Pilih Kategori",
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: categories.map((cat) {
              bool isSelected = selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ChoiceChip(
                  label: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(cat),
                  ),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) {
                      HapticFeedback.selectionClick();
                      setState(() => selectedCategory = cat);
                    }
                  },
                  selectedColor: color.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : color.onSurfaceVariant,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  avatar: isSelected
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 18)
                      : null,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: isSelected ? 4 : 0,
                  pressElevation: 8,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTextFields(ColorScheme color) {
    return Column(
      children: [
        _buildPremiumTextField(
          controller: titleController,
          label: "Judul Laporan",
          hint: "Apa yang ingin dilaporkan?",
          icon: Icons.title_rounded,
          color: color,
          maxLength: 50,
        ),
        const SizedBox(height: 24),
        _buildPremiumTextField(
          controller: descController,
          label: "Deskripsi Lengkap",
          hint: "Ceritakan detail kejadian secara kronologis...",
          icon: Icons.description_rounded,
          color: color,
          maxLines: 4,
          maxLength: 1000,
        ),
      ],
    );
  }

  Widget _buildLocation(ColorScheme color) {
    bool hasLocation = locationController.text.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Lokasi Kejadian",
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 16),
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: hasLocation ? Colors.green.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
                color:
                    hasLocation ? Colors.green.shade200 : color.outlineVariant),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: hasLocation
                          ? Colors.green.shade100
                          : color.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.map_rounded,
                        color: hasLocation ? Colors.green : color.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            hasLocation
                                ? "Lokasi Ditetapkan"
                                : "Titik Belum Dipilih",
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 16)),
                        Text(
                          hasLocation
                              ? locationController.text
                              : "Pilih lokasi spesifik di peta",
                          style: TextStyle(color: color.outline, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LocationPickerOSM()),
                    );
                    if (result != null) {
                      setState(() {
                        locationController.text = result['address'];
                      });
                    }
                  },
                  icon: const Icon(Icons.add_location_alt_rounded, size: 20),
                  label: const Text("Pilih Dari Peta",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasLocation ? Colors.green : color.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(ColorScheme color) {
    final bool photoOk = imageFile != null;
    final bool titleOk = titleController.text.isNotEmpty;
    final bool descOk = descController.text.isNotEmpty;
    final bool locationOk = locationController.text.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: color.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Ringkasan Laporan",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 20),
          _summaryRow("Bukti Foto", photoOk, color),
          _summaryRow("Judul & Kategori", titleOk, color),
          _summaryRow("Deskripsi Laporan", descOk, color),
          _summaryRow("Koordinat Lokasi", locationOk, color),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(ColorScheme color) {
    bool isComplete = imageFile != null &&
        titleController.text.isNotEmpty &&
        descController.text.isNotEmpty &&
        locationController.text.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isComplete
                ? color.primary.withOpacity(0.3)
                : Colors.transparent,
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Material(
        color: isComplete ? color.primary : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: isComplete ? submitReport : null,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: double.infinity,
            height: 64,
            alignment: Alignment.center,
            child: const Text(
              "Kirim Laporan Resmi",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // UI HELPERS & COMPONENTS
  // =====================================================

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ColorScheme color,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: color.primary),
            filled: true,
            fillColor: Colors.white,
            counterStyle: const TextStyle(fontSize: 10),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: color.outlineVariant)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: color.primary, width: 2)),
            contentPadding: const EdgeInsets.all(20),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String text, bool isOk, ColorScheme color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(isOk ? Icons.check_circle : Icons.error_outline_rounded,
                key: ValueKey(isOk),
                color: isOk ? Colors.green : Colors.redAccent,
                size: 20),
          ),
          const SizedBox(width: 12),
          Text(text,
              style: TextStyle(
                  fontWeight: isOk ? FontWeight.bold : FontWeight.w500,
                  color: isOk ? Colors.black87 : Colors.grey)),
          const Spacer(),
          if (isOk)
            Text("SIAP",
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700)),
        ],
      ),
    );
  }

  void _buildBottomSheet(ColorScheme color) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 24),
              const Text("Lampirkan Bukti",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _bottomSheetItem(Icons.camera_rounded, "Ambil Foto", color,
                      () {
                    Navigator.pop(context);
                    pickImage(ImageSource.camera);
                  }),
                  _bottomSheetItem(Icons.photo_library_rounded, "Galeri", color,
                      () {
                    Navigator.pop(context);
                    pickImage(ImageSource.gallery);
                  }),
                ],
              ),
              const SizedBox(height: 24),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal",
                      style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomSheetItem(
      IconData icon, String label, ColorScheme color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: color.primaryContainer,
                borderRadius: BorderRadius.circular(24)),
            child: Icon(icon, color: color.primary, size: 32),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _buildSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                          value: 1, color: Colors.green, strokeWidth: 2)),
                  Icon(Icons.check_circle_rounded,
                      color: Colors.green, size: 80),
                ],
              ),
              const SizedBox(height: 32),
              const Text("Laporan Terkirim!",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              const Text(
                  "Data Anda telah kami terima dan akan segera masuk tahap verifikasi oleh tim Admin.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text("Kembali ke Beranda",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay(ColorScheme color) {
    return Container(
      color: Colors.black.withOpacity(0.4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(32)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                  strokeWidth: 6,
                  valueColor: AlwaysStoppedAnimation<Color>(color.primary)),
              const SizedBox(height: 24),
              const Text("Mengirim Laporan...",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white24,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}
