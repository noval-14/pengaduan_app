import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'detail_page.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  String _selectedFilter = 'Semua';
  final List<String> _filters = ['Semua', 'Belum Dibaca', 'Komentar', 'Status'];
  final currentUser = FirebaseAuth.instance.currentUser;

  // ===========================================================================
  // LOGIC & FILTERING
  // ===========================================================================

  bool _applyFilter(Map<String, dynamic> data) {
    final title = (data['title'] ?? '').toLowerCase();
    final msg = (data['message'] ?? '').toLowerCase();
    final isRead = data['is_read'] ?? false;

    if (_selectedFilter == 'Belum Dibaca') return isRead == false;
    if (_selectedFilter == 'Komentar') {
      return title.contains('komentar') ||
          msg.contains('mengomentari') ||
          title.contains('balasan');
    }
    if (_selectedFilter == 'Status') {
      return title.contains('status') ||
          title.contains('diproses') ||
          title.contains('selesai') ||
          title.contains('diverifikasi');
    }
    return true; // Semua
  }

  String _getGroupLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final week = today.subtract(const Duration(days: 7));
    final month = today.subtract(const Duration(days: 30));

    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) return "Hari Ini";
    if (checkDate == yesterday) return "Kemarin";
    if (checkDate.isAfter(week)) return "Minggu Ini";
    if (checkDate.isAfter(month)) return "Bulan Ini";
    return "Lebih Lama";
  }

  Future<void> _markAsRead(String docId) async {
    await FirebaseFirestore.instance
        .collection('user_notifications')
        .doc(docId)
        .update({'is_read': true});
  }

  // ===========================================================================
  // UI COMPONENTS
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(theme),
          _buildFilterChips(theme),
          _buildNotificationStream(theme),
        ],
      ),
      floatingActionButton: _buildDeleteAllFAB(theme),
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: theme.colorScheme.surface,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(start: 20, bottom: 16),
        centerTitle: false,
        title: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('user_notifications')
              .where('user_id', isEqualTo: currentUser?.uid)
              .where('is_read', isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) {
            int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Notifikasi",
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900)),
                if (count > 0)
                  Text("$count pemberitahuan terbaru",
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.primary)),
              ],
            );
          },
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_active_outlined),
          tooltip: "Pengaturan",
        ),
      ],
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 60,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _filters.length,
          itemBuilder: (context, index) {
            final isSelected = _selectedFilter == _filters[index];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_filters[index]),
                selected: isSelected,
                onSelected: (val) {
                  if (val) {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedFilter = _filters[index]);
                  }
                },
                selectedColor: theme.colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                side: BorderSide.none,
                showCheckmark: false,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationStream(ThemeData theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user_notifications')
          .where('user_id', isEqualTo: currentUser?.uid)
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(child: _ShimmerLoader());
        }

        final allDocs = snapshot.data?.docs ?? [];
        final filteredDocs = allDocs
            .where((doc) => _applyFilter(doc.data() as Map<String, dynamic>))
            .toList();

        if (filteredDocs.isEmpty) {
          return SliverFillRemaining(
              child: _EmptyState(filter: _selectedFilter));
        }

        // Grouping Data
        Map<String, List<QueryDocumentSnapshot>> groups = {};
        for (var doc in filteredDocs) {
          final date =
              (doc['created_at'] as Timestamp?)?.toDate() ?? DateTime.now();
          final label = _getGroupLabel(date);
          groups.putIfAbsent(label, () => []).add(doc);
        }

        final labels = [
          "Hari Ini",
          "Kemarin",
          "Minggu Ini",
          "Bulan Ini",
          "Lebih Lama"
        ];

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final label =
                  labels.where((l) => groups.containsKey(l)).elementAt(index);
              final groupItems = groups[label]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(label,
                        style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2)),
                  ),
                  ...groupItems.map((doc) => _NotificationCard(
                        docId: doc.id,
                        data: doc.data() as Map<String, dynamic>,
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          await _markAsRead(doc.id);
                          if (context.mounted && doc['report_id'] != null) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => DetailPage(
                                        reportId: doc['report_id'])));
                          }
                        },
                      )),
                ],
              );
            },
            childCount: labels.where((l) => groups.containsKey(l)).length,
          ),
        );
      },
    );
  }

  Widget _buildDeleteAllFAB(ThemeData theme) {
    return FloatingActionButton.extended(
      onPressed: () => _showDeleteAllDialog(theme),
      icon: const Icon(Icons.delete_sweep_outlined),
      label: const Text("Bersihkan"),
      backgroundColor: theme.colorScheme.errorContainer,
      foregroundColor: theme.colorScheme.onErrorContainer,
    );
  }

  void _showDeleteAllDialog(ThemeData theme) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DeleteAllDialog(userId: currentUser?.uid),
    );
  }
}

// ===========================================================================
// SUB-WIDGETS & ANIMATIONS
// ===========================================================================

class _NotificationCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _NotificationCard(
      {required this.docId, required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRead = data['is_read'] ?? false;
    final createdAt =
        (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now();
    final title = data['title'] ?? '-';

    // UI Deterministic logic
    IconData iconData = Icons.notifications_active_outlined;
    Color iconColor = theme.colorScheme.primary;
    if (title.toLowerCase().contains("komentar")) {
      iconData = Icons.chat_bubble_outline_rounded;
      iconColor = Colors.blue;
    } else if (title.toLowerCase().contains("like")) {
      iconData = Icons.favorite_border_rounded;
      iconColor = Colors.redAccent;
    } else if (title.toLowerCase().contains("status")) {
      iconData = Icons.sync_rounded;
      iconColor = Colors.green;
    }

    return Dismissible(
      key: Key(docId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        FirebaseFirestore.instance
            .collection('user_notifications')
            .doc(docId)
            .delete();
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: theme.colorScheme.error,
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                  color:
                      isRead ? Colors.transparent : theme.colorScheme.primary,
                  width: 4),
              bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                  width: 1),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: isRead
                                      ? FontWeight.normal
                                      : FontWeight.w900,
                                  color: isRead
                                      ? theme.colorScheme.onSurfaceVariant
                                      : theme.colorScheme.onSurface)),
                        ),
                        if (!isRead)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(4)),
                            child: const Text("BARU",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(data['message'] ?? '-',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    Text(DateFormat('HH:mm').format(createdAt),
                        style: theme.textTheme.labelSmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteAllDialog extends StatefulWidget {
  final String? userId;
  const _DeleteAllDialog({this.userId});

  @override
  State<_DeleteAllDialog> createState() => _DeleteAllDialogState();
}

class _DeleteAllDialogState extends State<_DeleteAllDialog> {
  String state = "confirm"; // confirm, deleting, success

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      content: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildContent(theme),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (state == "deleting") {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text("Menghapus notifikasi..."),
        ],
      );
    }
    if (state == "success") {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.check_circle_outline, color: Colors.green, size: 64),
          SizedBox(height: 16),
          Text("Berhasil",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text("Semua notifikasi telah dibersihkan."),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.delete_sweep_rounded,
            size: 64, color: theme.colorScheme.error),
        const SizedBox(height: 16),
        const Text("Hapus Semua Notifikasi",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        const Text(
            "Tindakan ini permanen. Seluruh riwayat pemberitahuan Anda akan dihapus.",
            textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal")),
            const SizedBox(width: 8),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error),
              onPressed: () async {
                setState(() => state = "deleting");
                final snapshot = await FirebaseFirestore.instance
                    .collection('user_notifications')
                    .where('user_id', isEqualTo: widget.userId)
                    .get();

                final batch = FirebaseFirestore.instance.batch();
                for (var doc in snapshot.docs) {
                  batch.delete(doc.reference);
                }
                await batch.commit();

                setState(() => state = "success");
                await Future.delayed(const Duration(seconds: 2));
                if (mounted) Navigator.pop(context);
              },
              child: const Text("Hapus Semua"),
            ),
          ],
        )
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_off_outlined,
              size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          Text("Tidak ada notifikasi",
              style: Theme.of(context).textTheme.titleLarge),
          Text("Filter '$filter' saat ini kosong.",
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Kembali ke Beranda")),
        ],
      ),
    );
  }
}

class _ShimmerLoader extends StatefulWidget {
  const _ShimmerLoader();
  @override
  State<_ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<_ShimmerLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ListView.builder(
          itemCount: 5,
          padding: const EdgeInsets.all(20),
          itemBuilder: (context, index) => Container(
            height: 80,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade200,
                  Colors.grey.shade100,
                  Colors.grey.shade200
                ],
                stops: [0.0, _controller.value, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }
}
