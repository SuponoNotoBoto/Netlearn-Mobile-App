import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/avatar/nl_avatar_models.dart';
import '../../core/avatar/nl_avatar_widget.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/nl_empty_state.dart';
import '../../shared/widgets/nl_error_view.dart';
import '../../shared/widgets/nl_snack_bar.dart';
import '../../shared/widgets/nl_topbar.dart';
import 'add_user_dialog.dart';
import 'user_management_controller.dart';
import 'user_management_models.dart';

/// Halaman Kelola Pengguna khusus untuk Admin (Mahasiswa, Dosen, & Admin).
class UserManagementPage extends ConsumerStatefulWidget {
  const UserManagementPage({super.key});

  @override
  ConsumerState<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends ConsumerState<UserManagementPage> {
  final _searchCtrl = TextEditingController();
  UserRoleFilter _filter = UserRoleFilter.all;
  String _query = '';
  final Set<String> _busyUserIds = <String>{};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(managedUsersProvider);
    await ref.read(managedUsersProvider.future);
  }

  Future<void> _openAddUser() async {
    final initialRole = switch (_filter) {
      UserRoleFilter.lecturer => 'lecturer',
      UserRoleFilter.admin => 'admin',
      _ => 'student',
    };
    final created = await showAddUserSheet(context, initialRole: initialRole);
    if (created && mounted) {
      final isId = Localizations.localeOf(context).languageCode == 'id';
      NlSnackBar.show(
        context,
        isId ? 'Akun pengguna baru berhasil dibuat.' : 'New user account created.',
        tone: NlSnackTone.success,
      );
      ref.invalidate(managedUsersProvider);
    }
  }

  Future<void> _toggleActive(ManagedUserAccount user, bool nextActive) async {
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final currentUid = supabase.auth.currentUser?.id;

    if (user.id == currentUid) {
      NlSnackBar.show(
        context,
        isId
            ? 'Anda tidak dapat menonaktifkan akun yang sedang dipakai.'
            : 'You cannot deactivate your own active account.',
        tone: NlSnackTone.warning,
      );
      return;
    }

    if (!nextActive) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(isId ? 'Nonaktifkan Akun?' : 'Deactivate Account?'),
          content: Text(
            isId
                ? 'Akun "${user.name}" tidak akan dapat masuk ke aplikasi sampai diaktifkan kembali.'
                : 'Account "${user.name}" will not be able to sign in until reactivated.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(isId ? 'Batal' : 'Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(isId ? 'Nonaktifkan' : 'Deactivate'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _busyUserIds.add(user.id));
    try {
      await UserManagementService.setUserActive(
        userId: user.id,
        isActive: nextActive,
      );
      if (!mounted) return;
      NlSnackBar.show(
        context,
        nextActive
            ? (isId ? 'Akun ${user.name} diaktifkan.' : '${user.name} activated.')
            : (isId ? 'Akun ${user.name} dinonaktifkan.' : '${user.name} deactivated.'),
        tone: NlSnackTone.success,
      );
      ref.invalidate(managedUsersProvider);
    } catch (e) {
      if (!mounted) return;
      NlSnackBar.show(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        tone: NlSnackTone.error,
      );
    } finally {
      if (mounted) {
        setState(() => _busyUserIds.remove(user.id));
      }
    }
  }

  Future<void> _confirmDelete(ManagedUserAccount user) async {
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final currentUid = supabase.auth.currentUser?.id;

    if (user.id == currentUid) {
      NlSnackBar.show(
        context,
        isId
            ? 'Anda tidak dapat menghapus akun Anda sendiri.'
            : 'You cannot delete your own account.',
        tone: NlSnackTone.warning,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: NetLearnColors.danger,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(isId ? 'Hapus Akun Permanen?' : 'Delete Account?'),
            ),
          ],
        ),
        content: Text(
          isId
              ? 'Apakah Anda yakin ingin menghapus akun "${user.name}" (${user.email})? Tindakan ini tidak dapat dibatalkan.'
              : 'Are you sure you want to permanently delete "${user.name}" (${user.email})? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isId ? 'Batal' : 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: NetLearnColors.danger,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isId ? 'Hapus Akun' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _busyUserIds.add(user.id));
    try {
      await UserManagementService.deleteUser(userId: user.id);
      if (!mounted) return;
      NlSnackBar.show(
        context,
        isId
            ? 'Akun ${user.name} berhasil dihapus.'
            : 'Account ${user.name} deleted.',
        tone: NlSnackTone.success,
      );
      ref.invalidate(managedUsersProvider);
    } catch (e) {
      if (!mounted) return;
      NlSnackBar.show(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        tone: NlSnackTone.error,
      );
    } finally {
      if (mounted) {
        setState(() => _busyUserIds.remove(user.id));
      }
    }
  }

  List<ManagedUserAccount> _applyFilter(List<ManagedUserAccount> users) {
    final q = _query.trim().toLowerCase();
    return users.where((u) {
      final matchesRole = switch (_filter) {
        UserRoleFilter.all => true,
        UserRoleFilter.student => u.role == 'student',
        UserRoleFilter.lecturer => u.role == 'lecturer',
        UserRoleFilter.admin => u.role == 'admin',
      };
      if (!matchesRole) return false;
      if (q.isEmpty) return true;
      return u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.identityNumber.toLowerCase().contains(q) ||
          (u.program?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final usersAsync = ref.watch(managedUsersProvider);
    final currentUid = supabase.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: context.background,
      appBar: NlTopBar(
        title: isId ? 'Kelola Pengguna' : 'User Management',
        onBack: () => context.pop(),
        actions: IconButton(
          tooltip: isId ? 'Muat Ulang' : 'Refresh',
          icon: const Icon(Icons.refresh_rounded, size: 20),
          onPressed: _refresh,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddUser,
        backgroundColor: context.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(
          isId ? 'Tambah Akun' : 'Add Account',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: usersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => NlErrorView(
            message: err.toString().replaceFirst('Exception: ', ''),
            onRetry: _refresh,
          ),
          data: (allUsers) {
            final filtered = _applyFilter(allUsers);
            final studentCount = allUsers.where((u) => u.isStudent).length;
            final lecturerCount = allUsers.where((u) => u.isLecturer).length;
            final adminCount = allUsers.where((u) => u.isAdmin).length;
            final activeCount = allUsers.where((u) => u.isActive).length;

            return RefreshIndicator(
              color: context.accent,
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ringkasan jumlah akun
                          _SummaryStrip(
                            total: allUsers.length,
                            active: activeCount,
                            students: studentCount,
                            lecturers: lecturerCount,
                            isId: isId,
                          ),
                          const SizedBox(height: 14),

                          // Search bar
                          TextField(
                            controller: _searchCtrl,
                            onChanged: (v) => setState(() => _query = v),
                            decoration: InputDecoration(
                              hintText: isId
                                  ? 'Cari nama, email, NIM, atau NIDN...'
                                  : 'Search name, email, ID...',
                              prefixIcon: const Icon(Icons.search_rounded, size: 20),
                              suffixIcon: _query.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 18),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        setState(() => _query = '');
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: context.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: context.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: context.border),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Filter chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _FilterChip(
                                  label: '${isId ? "Semua" : "All"} (${allUsers.length})',
                                  selected: _filter == UserRoleFilter.all,
                                  onTap: () =>
                                      setState(() => _filter = UserRoleFilter.all),
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: '${isId ? "Mahasiswa" : "Students"} ($studentCount)',
                                  selected: _filter == UserRoleFilter.student,
                                  onTap: () => setState(
                                    () => _filter = UserRoleFilter.student,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: '${isId ? "Dosen" : "Lecturers"} ($lecturerCount)',
                                  selected: _filter == UserRoleFilter.lecturer,
                                  onTap: () => setState(
                                    () => _filter = UserRoleFilter.lecturer,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'Admin ($adminCount)',
                                  selected: _filter == UserRoleFilter.admin,
                                  onTap: () => setState(
                                    () => _filter = UserRoleFilter.admin,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (filtered.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: NlEmptyState(
                        icon: Icons.people_outline_rounded,
                        title: isId
                            ? 'Tidak ada pengguna ditemukan'
                            : 'No users found',
                        message: isId
                            ? 'Coba ubah filter atau kata kunci pencarian Anda.'
                            : 'Try adjusting your search or role filter.',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                      sliver: SliverList.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final user = filtered[index];
                          final isMe = user.id == currentUid;
                          final isBusy = _busyUserIds.contains(user.id);

                          return _UserAccountCard(
                            user: user,
                            isMe: isMe,
                            isBusy: isBusy,
                            isId: isId,
                            onToggleActive: (val) => _toggleActive(user, val),
                            onDelete: () => _confirmDelete(user),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  final int total;
  final int active;
  final int students;
  final int lecturers;
  final bool isId;

  const _SummaryStrip({
    required this.total,
    required this.active,
    required this.students,
    required this.lecturers,
    required this.isId,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatPill(
          label: isId ? 'Total Akun' : 'Total',
          value: '$total',
          color: context.accent,
        ),
        const SizedBox(width: 8),
        _StatPill(
          label: isId ? 'Aktif' : 'Active',
          value: '$active',
          color: const Color(0xFF16A34A),
        ),
        const SizedBox(width: 8),
        _StatPill(
          label: isId ? 'Mahasiswa' : 'Students',
          value: '$students',
          color: const Color(0xFF2563EB),
        ),
        const SizedBox(width: 8),
        _StatPill(
          label: isId ? 'Dosen' : 'Lecturers',
          value: '$lecturers',
          color: const Color(0xFF7C3AED),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.border),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: context.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? context.accent : context.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? context.accent : context.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : context.onSurface,
          ),
        ),
      ),
    );
  }
}

class _UserAccountCard extends StatelessWidget {
  final ManagedUserAccount user;
  final bool isMe;
  final bool isBusy;
  final bool isId;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onDelete;

  const _UserAccountCard({
    required this.user,
    required this.isMe,
    required this.isBusy,
    required this.isId,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final (roleLabel, roleColor) = switch (user.role) {
      'admin' => ('Admin', const Color(0xFFD97706)),
      'lecturer' => (isId ? 'Dosen' : 'Lecturer', const Color(0xFF7C3AED)),
      _ => (isId ? 'Mahasiswa' : 'Student', const Color(0xFF2563EB)),
    };

    return Opacity(
      opacity: user.isActive ? 1.0 : 0.72,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: user.isActive ? context.border : NetLearnColors.danger.withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NlAvatarWidget(
                  config: user.avatarConfig ??
                      AvatarConfig.defaultFor(
                        user.id.isNotEmpty ? user.id : user.name,
                      ),
                  size: 44,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: context.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isId ? 'Anda' : 'You',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: context.accent,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (user.email.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: context.mutedText,
                          ),
                        ),
                      ],
                      if (user.identityNumber.isNotEmpty ||
                          (user.program != null && user.program!.isNotEmpty)) ...[
                        const SizedBox(height: 3),
                        Text(
                          [
                            if (user.identityNumber.isNotEmpty) user.identityNumber,
                            if (user.program != null && user.program!.isNotEmpty)
                              user.program!,
                          ].join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.mutedText,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _BadgePill(
                            label: roleLabel,
                            color: roleColor,
                          ),
                          _BadgePill(
                            label: user.isActive
                                ? (isId ? 'Aktif' : 'Active')
                                : (isId ? 'Nonaktif' : 'Inactive'),
                            color: user.isActive
                                ? const Color(0xFF16A34A)
                                : NetLearnColors.danger,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!isMe) ...[
              const SizedBox(height: 10),
              Divider(height: 1, color: context.border),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        SizedBox(
                          height: 30,
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: Switch.adaptive(
                              value: user.isActive,
                              activeTrackColor: const Color(0xFF16A34A),
                              onChanged: isBusy ? null : onToggleActive,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          user.isActive
                              ? (isId ? 'Akun Aktif' : 'Active')
                              : (isId ? 'Dinonaktifkan' : 'Deactivated'),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: user.isActive
                                ? const Color(0xFF16A34A)
                                : NetLearnColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isBusy)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    TextButton.icon(
                      onPressed: onDelete,
                      style: TextButton.styleFrom(
                        foregroundColor: NetLearnColors.danger,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 17),
                      label: Text(
                        isId ? 'Hapus' : 'Delete',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  final String label;
  final Color color;

  const _BadgePill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

