import '../../core/avatar/nl_avatar_models.dart';

/// Filter role pada halaman Kelola Pengguna untuk Admin.
enum UserRoleFilter {
  all,
  student,
  lecturer,
  admin,
}

/// Representasi satu akun pengguna yang dikelola oleh Admin.
class ManagedUserAccount {
  final String id;
  final String name;
  final String email;
  final String identityNumber;
  final String? program;
  final String role;
  final bool isActive;
  final AvatarConfig? avatarConfig;
  final DateTime? createdAt;

  const ManagedUserAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.identityNumber,
    this.program,
    required this.role,
    required this.isActive,
    this.avatarConfig,
    this.createdAt,
  });

  bool get isStudent => role == 'student';
  bool get isLecturer => role == 'lecturer';
  bool get isAdmin => role == 'admin';

  ManagedUserAccount copyWith({
    String? name,
    String? email,
    String? identityNumber,
    String? program,
    String? role,
    bool? isActive,
    AvatarConfig? avatarConfig,
  }) {
    return ManagedUserAccount(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      identityNumber: identityNumber ?? this.identityNumber,
      program: program ?? this.program,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      avatarConfig: avatarConfig ?? this.avatarConfig,
      createdAt: createdAt,
    );
  }

  factory ManagedUserAccount.fromMap(Map<String, dynamic> map) {
    final rawName = (map['name'] ?? map['full_name'])?.toString().trim();
    final rawEmail = map['email']?.toString().trim() ?? '';
    final displayName = (rawName != null && rawName.isNotEmpty)
        ? rawName
        : (rawEmail.isNotEmpty ? rawEmail.split('@').first : 'Pengguna');

    return ManagedUserAccount(
      id: map['id']?.toString() ?? '',
      name: displayName,
      email: rawEmail,
      identityNumber: map['identity_number']?.toString().trim() ?? '',
      program: map['program']?.toString().trim(),
      role: map['role']?.toString().trim() ?? 'student',
      isActive: map['is_active'] != false,
      avatarConfig: AvatarConfig.fromDynamic(map['avatar_config']),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
    );
  }
}

