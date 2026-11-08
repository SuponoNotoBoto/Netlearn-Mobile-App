import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../shared/models/material_model.dart';
import '../virtual_lab/virtual_lab_controller.dart';
import '../virtual_lab/virtual_lab_model.dart';

/// Konfigurasi dan metadata pengikatan (binding) antara Modul Pembelajaran
/// NetLearn dengan skenario praktikum di Virtual Lab 2D.
class MaterialLabBinding {
  /// Apakah materi ini memiliki praktikum terkait.
  final bool enabled;

  /// ID preset bawaan ('star', 'dual_subnet', 'p2p', 'dhcp_server', 'blank', atau 'custom').
  final String preset;

  /// Preset topologi referensi/contoh (opsional, sebagai bahan perbandingan jika mahasiswa butuh referensi).
  final String? referencePreset;

  /// Judul praktikum (misal: "Praktikum Topologi Star LAN").
  final String title;

  /// Deskripsi singkat tujuan praktikum.
  final String? description;

  /// Daftar poin instruksi langkah kerja praktikum.
  final List<String> instructions;

  /// Topologi kustom (opsional, jika dosen memilih dari topologi tersimpan cloud miliknya).
  final Map<String, dynamic>? customTopology;

  /// ID materi yang terhubung.
  final String? materialId;

  /// Judul materi asal.
  final String? materialTitle;

  const MaterialLabBinding({
    this.enabled = true,
    required this.preset,
    this.referencePreset,
    required this.title,
    this.description,
    this.instructions = const [],
    this.customTopology,
    this.materialId,
    this.materialTitle,
  });

  MaterialLabBinding copyWith({
    bool? enabled,
    String? preset,
    String? referencePreset,
    String? title,
    String? description,
    List<String>? instructions,
    Map<String, dynamic>? customTopology,
    String? materialId,
    String? materialTitle,
  }) {
    return MaterialLabBinding(
      enabled: enabled ?? this.enabled,
      preset: preset ?? this.preset,
      referencePreset: referencePreset ?? this.referencePreset,
      title: title ?? this.title,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      customTopology: customTopology ?? this.customTopology,
      materialId: materialId ?? this.materialId,
      materialTitle: materialTitle ?? this.materialTitle,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'preset': preset,
        if (referencePreset != null) 'reference_preset': referencePreset,
        'title': title,
        if (description != null) 'description': description,
        if (instructions.isNotEmpty) 'instructions': instructions,
        if (customTopology != null) 'custom_topology': customTopology,
        if (materialId != null) 'material_id': materialId,
        if (materialTitle != null) 'material_title': materialTitle,
      };

  factory MaterialLabBinding.fromJson(Map<String, dynamic> json) {
    return MaterialLabBinding(
      enabled: json['enabled'] as bool? ?? true,
      preset: json['preset'] as String? ?? 'star',
      referencePreset: json['reference_preset'] as String?,
      title: json['title'] as String? ?? 'Praktikum Virtual Lab',
      description: json['description'] as String?,
      instructions: (json['instructions'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      customTopology: json['custom_topology'] is Map
          ? Map<String, dynamic>.from(json['custom_topology'] as Map)
          : null,
      materialId: json['material_id'] as String?,
      materialTitle: json['material_title'] as String?,
    );
  }

  /// Tag penanda metadata lab yang disematkan pada teks konten materi.
  static const String tagPrefix = '<!--netlearn-lab:';
  static const String tagSuffix = '-->';
  static final RegExp tagRegExp =
      RegExp(r'<!--netlearn-lab:(.*?)-->', dotAll: true);

  /// Menghapus tag penanda lab dari teks materi agar tidak tampak pada tampilan baca mahasiswa.
  static String stripLabTag(String text) {
    return text.replaceAll(tagRegExp, '').trim();
  }

  /// Menyematkan atau memperbarui tag penanda lab di akhir teks konten materi.
  static String embedLabTag(String content, MaterialLabBinding? binding) {
    final clean = stripLabTag(content);
    if (binding == null || !binding.enabled) {
      return clean;
    }
    final jsonStr = jsonEncode(binding.toJson());
    return '$clean\n\n$tagPrefix$jsonStr$tagSuffix';
  }

  /// Mengekstrak binding lab dari [MaterialModel].
  ///
  /// Membaca konfigurasi eksplisit dari tag `<!--netlearn-lab:...-->` di kolom konten.
  /// Jika belum ada konfigurasi eksplisit, sistem memberikan fallback cerdas
  /// untuk Modul Inti 1 sampai 4.
  static MaterialLabBinding? fromMaterial(MaterialModel material) {
    // 1. Cek konfigurasi eksplisit di kolom konten
    final rawContent = material.content ??
        material.contentId ??
        material.contentEn ??
        '';
    final match = tagRegExp.firstMatch(rawContent);
    if (match != null) {
      try {
        final jsonStr = match.group(1)?.trim();
        if (jsonStr != null && jsonStr.isNotEmpty) {
          final data = jsonDecode(jsonStr) as Map<String, dynamic>;
          final binding = MaterialLabBinding.fromJson(data);
          if (!binding.enabled) {
            return null; // Praktikum dinonaktifkan secara eksplisit oleh dosen
          }
          return binding.copyWith(
            materialId: material.id,
            materialTitle: material.title,
          );
        }
      } catch (e) {
        debugPrint('Failed to parse MaterialLabBinding tag: $e');
      }
    }

    // 2. Smart fallback untuk Modul Inti 1 s/d 4 bawaan NetLearn
    final mod = material.moduleNumber;
    if (mod != null && mod >= 1 && mod <= 4) {
      return fallbackForModule(
        mod,
        materialId: material.id,
        materialTitle: material.title,
      );
    }

    return null;
  }

  /// Konfigurasi praktikum standar untuk modul-modul inti NetLearn.
  static MaterialLabBinding fallbackForModule(
    int moduleNumber, {
    String? materialId,
    String? materialTitle,
  }) {
    switch (moduleNumber) {
      case 1:
        return MaterialLabBinding(
          preset: 'blank',
          referencePreset: 'p2p',
          title: 'Praktikum Topologi Dasar (Peer-to-Peer)',
          description:
              'Eksperimen merancang koneksi langsung antar 2 PC dengan kabel LAN dan konfigurasi IP.',
          instructions: const [
            'Tambahkan 2 unit PC ke kanvas menggunakan toolbar [+PC].',
            'Sambungkan kabel dari PC 1 ke PC 2.',
            'Buka konfigurasi PC 1 (atur IP 10.0.0.1/24) dan PC 2 (atur IP 10.0.0.2/24).',
            'Buka Terminal di PC 1 lalu jalankan: ping 10.0.0.2 untuk memverifikasi koneksi.',
          ],
          materialId: materialId,
          materialTitle: materialTitle,
        );
      case 2:
        return MaterialLabBinding(
          preset: 'blank',
          referencePreset: 'star',
          title: 'Praktikum Topologi Star (LAN 1 Subnet)',
          description:
              'Rancang jaringan lokal (LAN) menggunakan Switch untuk menghubungkan 3 unit PC.',
          instructions: const [
            'Tambahkan 1 unit Switch dan 3 unit PC ke kanvas.',
            'Tarik kabel dari masing-masing PC menuju port Switch.',
            'Konfigurasikan IP static satu subnet pada ketiga PC (misal 192.168.1.2 - 192.168.1.4, Mask 255.255.255.0).',
            'Buka Terminal CLI di PC 1 lalu uji ping ke PC 2 dan PC 3.',
          ],
          materialId: materialId,
          materialTitle: materialTitle,
        );
      case 3:
        return MaterialLabBinding(
          preset: 'blank',
          referencePreset: 'dual_subnet',
          title: 'Praktikum Routing Statis & Gateway (Layer 3)',
          description:
              'Rancang konektivitas dua subnet jaringan yang berbeda melintasi Router Layer 3.',
          instructions: const [
            'Tambahkan 1 Router, 2 Switch, dan 2 PC ke kanvas.',
            'Hubungkan Switch 1 ke Router port eth0 dan Switch 2 ke Router port eth1.',
            'Sambungkan PC 1 ke Switch 1 (Subnet 192.168.1.0/24) dan PC 2 ke Switch 2 (Subnet 192.168.2.0/24).',
            'Pastikan Default Gateway pada PC 1 (192.168.1.1) dan PC 2 (192.168.2.1) terisi.',
            'Buka Terminal di PC 1 lalu jalankan: tracert 192.168.2.2 untuk mengamati hop rute router.',
          ],
          materialId: materialId,
          materialTitle: materialTitle,
        );
      case 4:
        return MaterialLabBinding(
          preset: 'blank',
          referencePreset: 'dhcp_server',
          title: 'Praktikum Layanan Server (DHCP & Web HTTP)',
          description:
              'Bangun arsitektur Client-Server LAN dengan layanan alokasi IP otomatis dan Web Server.',
          instructions: const [
            'Tambahkan 1 Server, 1 Switch, dan 2 PC ke kanvas.',
            'Sambungkan Server dan kedua PC ke port Switch.',
            'Buka konfigurasi Server, atur IP Static (192.168.1.1), dan aktifkan layanan DHCP Server.',
            'Buka konfigurasi PC client, ubah ke mode [DHCP] atau ketik ipconfig /renew di terminal.',
            'Setelah PC memperoleh alamat IP otomatis, uji akses web server: curl 192.168.1.1.',
          ],
          materialId: materialId,
          materialTitle: materialTitle,
        );
      default:
        return MaterialLabBinding(
          preset: 'blank',
          title: 'Praktikum Eksperimen Jaringan Bebas',
          description: 'Rancang topologi jaringan sesuai dengan materi modul.',
          instructions: const [
            'Tambahkan perangkat dan sambungkan kabel sesuai kebutuhan modul praktikum.',
          ],
          materialId: materialId,
          materialTitle: materialTitle,
        );
    }
  }

  /// Mengembalikan topologi referensi/contoh solusi praktikum jika mahasiswa membutuhkan bantuan.
  VirtualLabSession? resolveReferenceSession() {
    final ref = referencePreset ?? (preset != 'blank' ? preset : null);
    if (ref == null) return null;
    switch (ref) {
      case 'p2p':
        return VirtualLabController.presetPeerToPeer();
      case 'star':
        return VirtualLabController.presetStar();
      case 'dual_subnet':
        return VirtualLabController.presetDualSubnet();
      case 'dhcp_server':
        return VirtualLabController.presetDhcpServer();
      default:
        return null;
    }
  }

  /// Menyelesaikan sesi awal topologi kanvas Virtual Lab berdasarkan preset yang dipilih.
  VirtualLabSession resolveInitialSession() {
    if (customTopology != null) {
      try {
        return VirtualLabSession.fromJson(customTopology!);
      } catch (e) {
        debugPrint('Failed to deserialize custom topology session: $e');
      }
    }

    switch (preset) {
      case 'p2p':
        return VirtualLabController.presetPeerToPeer();
      case 'star':
        return VirtualLabController.presetStar();
      case 'dual_subnet':
        return VirtualLabController.presetDualSubnet();
      case 'dhcp_server':
        return VirtualLabController.presetDhcpServer();
      case 'blank':
      default:
        return VirtualLabController.presetBlank();
    }
  }
}
