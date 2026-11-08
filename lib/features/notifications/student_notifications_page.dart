import 'package:flutter/material.dart';
import '../../core/notifications/announcement_read_store.dart';
import '../../shared/models/announcement_model.dart';
import '../../shared/models/reminder_model.dart';

class StudentNotificationsPage extends StatefulWidget {
  final String userId;

  const StudentNotificationsPage({
    super.key,
    this.userId = 'student-2201010042',
  });

  @override
  State<StudentNotificationsPage> createState() => _StudentNotificationsPageState();
}

class _StudentNotificationsPageState extends State<StudentNotificationsPage> {
  int _selectedTabIndex = 0; // 0 = Pengumuman, 1 = Pengingat
  bool _isLoading = true;
  bool _isSavingRead = false;
  Set<String> _readAnnouncementIds = {};

  // Mock data pengumuman sesuai struktur netlearn-2.0
  late List<AnnouncementModel> _announcements;
  late List<ReminderItem> _reminders;

  @override
  void initState() {
    super.initState();
    _initData();
    _loadReadState();
  }

  void _initData() {
    _announcements = [
      AnnouncementModel(
        id: 'announcement-1',
        lecturerId: 'Dr. Supono, M.Kom.',
        classId: 'TI-2026-A',
        title: 'Jadwal Praktikum Tambahan Modul 3',
        content:
            'Praktikum tatap muka untuk materi crimping kabel UTP Cat5e/6 akan diadakan pada hari Rabu pukul 10:00 WIB di Laboratorium Jaringan 2. Mohon membawa perlengkapan masing-masing.',
        recipientScope: 'class',
        published: true,
        publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      AnnouncementModel(
        id: 'announcement-2',
        lecturerId: 'Dr. Supono, M.Kom.',
        classId: 'TI-2026-A',
        title: 'Panduan Evaluasi & Tugas AR Scanner',
        content:
            'Mahasiswa diharapkan mengunduh marker 3D yang tersedia pada menu AR Scanner untuk latihan identifikasi port switch dan router sebelum sesi ujian tengah semester dimulai.',
        recipientScope: 'class',
        published: true,
        publishedAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      ),
      AnnouncementModel(
        id: 'announcement-3',
        lecturerId: 'Bagian Akademik FT',
        classId: null,
        title: 'Pemeliharaan Server Virtual Lab Kampus',
        content:
            'Server virtual lab 2D akan menjalani pemeliharaan berkala pada hari Sabtu pukul 22:00–02:00 WIB. Akses praktikum simulasi paket data dihentikan sementara selama masa pemeliharaan.',
        recipientScope: 'all_students',
        published: true,
        publishedAt: DateTime.now().subtract(const Duration(days: 3)),
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];

    _reminders = [
      ReminderItem(
        id: 'reminder-1',
        title: 'Tugas Praktikum 3: Simulasi Jaringan LAN',
        deadline: DateTime.now().add(const Duration(days: 1, hours: 2)),
        assessmentType: 'assignment',
        reason: ReminderReason.deadline,
      ),
      ReminderItem(
        id: 'reminder-2',
        title: 'Kuis Modul 2: Konfigurasi VLAN',
        deadline: DateTime.now().add(const Duration(hours: 8)),
        assessmentType: 'quiz',
        reason: ReminderReason.deadline,
      ),
      ReminderItem(
        id: 'reminder-3',
        title: 'Pretest Jaringan Komputer',
        subject: 'Wajib diselesaikan sebelum membuka materi',
        deadline: null,
        assessmentType: 'pretest',
        reason: ReminderReason.notCompleted,
      ),
    ];
  }

  Future<void> _loadReadState() async {
    setState(() => _isLoading = true);
    final readIds = await AnnouncementReadStore.load(widget.userId);
    if (mounted) {
      setState(() {
        _readAnnouncementIds = readIds;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAnnouncementAsRead(AnnouncementModel announcement) async {
    if (_readAnnouncementIds.contains(announcement.id)) {
      _showDetailModal(announcement);
      return;
    }

    final success = await AnnouncementReadStore.markRead(
      userId: widget.userId,
      announcementId: announcement.id,
    );

    if (success && mounted) {
      setState(() {
        _readAnnouncementIds.add(announcement.id);
      });
    }

    if (mounted) {
      _showDetailModal(announcement);
    }
  }

  Future<void> _markAllAnnouncementsRead() async {
    if (_isSavingRead || _announcements.isEmpty) return;

    setState(() => _isSavingRead = true);

    final success = await AnnouncementReadStore.markAllRead(
      userId: widget.userId,
      announcementIds: _announcements.map((a) => a.id),
    );

    if (mounted) {
      setState(() {
        _isSavingRead = false;
        if (success) {
          _readAnnouncementIds.addAll(_announcements.map((a) => a.id));
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua pengumuman berhasil ditandai telah dibaca.')),
      );
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inMinutes < 60) {
      return difference.inMinutes <= 1 ? 'Baru saja' : '${difference.inMinutes} menit lalu';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    }
    return '${difference.inDays} hari lalu';
  }

  @override
  Widget build(BuildContext context) {
    final int unreadCount = _announcements
        .where((a) => !_readAnnouncementIds.contains(a.id))
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: const Text(
          'Pusat Notifikasi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        actions: [
          if (_selectedTabIndex == 0 && unreadCount > 0)
            TextButton.icon(
              onPressed: _isSavingRead ? null : _markAllAnnouncementsRead,
              icon: const Icon(Icons.done_all_rounded, size: 16, color: Color(0xFF6366F1)),
              label: const Text(
                'Tandai Dibaca',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6366F1),
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : RefreshIndicator(
              color: const Color(0xFF6366F1),
              onRefresh: _loadReadState,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  _buildSegmentedTab(),
                  const SizedBox(height: 16),
                  if (_selectedTabIndex == 0)
                    ..._buildAnnouncementsSection(unreadCount)
                  else
                    ..._buildRemindersSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildSegmentedTab() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              title: 'Pengumuman',
              index: 0,
              icon: Icons.campaign_rounded,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              title: 'Pengingat Deadline',
              index: 1,
              icon: Icons.alarm_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required int index,
    required IconData icon,
  }) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAnnouncementsSection(int unreadCount) {
    if (_announcements.isEmpty) {
      return [
        _buildEmptyState(
          icon: Icons.campaign_outlined,
          title: 'Tidak Ada Pengumuman',
          message: 'Saat ini belum ada pengumuman baru dari dosen atau akademik.',
        ),
      ];
    }

    return _announcements.map((announcement) {
      final isUnread = !_readAnnouncementIds.contains(announcement.id);
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isUnread ? const Color(0xFFF5F3FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUnread ? const Color(0xFFC7D2FE) : const Color(0xFFE2E8F0),
            width: isUnread ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _markAnnouncementAsRead(announcement),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isUnread ? const Color(0xFFEEF2FF) : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.campaign_rounded,
                      color: Color(0xFF6366F1),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                announcement.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            if (isUnread) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF6366F1),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${announcement.lecturerId} • ${_formatTimeAgo(announcement.publishedAt ?? announcement.createdAt)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          announcement.displayContent,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                            height: 1.4,
                          ),
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
    }).toList();
  }

  List<Widget> _buildRemindersSection() {
    if (_reminders.isEmpty) {
      return [
        _buildEmptyState(
          icon: Icons.alarm_off_rounded,
          title: 'Tidak Ada Pengingat',
          message: 'Semua tugas dan evaluasi telah Anda selesaikan dengan baik.',
        ),
      ];
    }

    return _reminders.map((reminder) {
      final isDeadline = reminder.reason == ReminderReason.deadline;
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDeadline ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDeadline ? Icons.alarm_rounded : Icons.info_outline_rounded,
                  color: isDeadline ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDeadline ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDeadline ? const Color(0xFFFECACA) : const Color(0xFFFDE68A),
                        ),
                      ),
                      child: Text(
                        reminder.subtitle(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDeadline ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(icon, size: 54, color: const Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  void _showDetailModal(AnnouncementModel announcement) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              announcement.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(
                  announcement.lecturerId,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(
                  _formatTimeAgo(announcement.publishedAt ?? announcement.createdAt),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Text(
                  announcement.displayContent,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

