import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/features/materials/material_lab_binding.dart';
import 'package:netlearn/shared/models/material_model.dart';

void main() {
  group('MaterialLabBinding Tests', () {
    test('Smart fallback for core module 1 (P2P)', () {
      const material = MaterialModel(
        id: 'mat-1',
        title: 'Pengantar Jaringan Komputer',
        moduleNumber: 1,
        isCore: true,
        orderIndex: 1,
        published: true,
        lockStatus: 'default',
        content: 'Isi materi pengenalan jaringan...',
      );

      final binding = MaterialLabBinding.fromMaterial(material);
      expect(binding, isNotNull);
      expect(binding!.preset, equals('blank'));
      expect(binding.referencePreset, equals('p2p'));
      expect(binding.instructions, isNotEmpty);
      expect(binding.instructions.first, contains('Tambahkan 2 unit PC'));

      // Kanvas awal harus bersih agar mahasiswa merancang sendiri dari nol
      final initialSession = binding.resolveInitialSession();
      expect(initialSession.devices.length, equals(0));

      // Referensi solusi tetap tersedia jika dibutuhkan
      final refSession = binding.resolveReferenceSession();
      expect(refSession, isNotNull);
      expect(refSession!.devices.length, equals(2));
      expect(refSession.cables.length, equals(1));
    });

    test('Smart fallback for core module 2 (Star Topology)', () {
      const material = MaterialModel(
        id: 'mat-2',
        title: 'Topologi Star LAN',
        moduleNumber: 2,
        isCore: true,
        orderIndex: 1,
        published: true,
        lockStatus: 'default',
        content: 'Materi topologi switch dan pc...',
      );

      final binding = MaterialLabBinding.fromMaterial(material);
      expect(binding, isNotNull);
      expect(binding!.preset, equals('blank'));
      expect(binding.referencePreset, equals('star'));
      expect(binding.instructions.first, contains('Tambahkan 1 unit Switch'));

      final initialSession = binding.resolveInitialSession();
      expect(initialSession.devices.length, equals(0));

      final refSession = binding.resolveReferenceSession();
      expect(refSession, isNotNull);
      expect(refSession!.devices.length, equals(4)); // 1 Switch + 3 PC
      expect(refSession.cables.length, equals(3));
    });

    test('Smart fallback for core module 3 (Routing Statis)', () {
      const material = MaterialModel(
        id: 'mat-3',
        title: 'Routing Layer 3',
        moduleNumber: 3,
        isCore: true,
        orderIndex: 1,
        published: true,
        lockStatus: 'default',
      );

      final binding = MaterialLabBinding.fromMaterial(material);
      expect(binding, isNotNull);
      expect(binding!.preset, equals('blank'));
      expect(binding.referencePreset, equals('dual_subnet'));

      final refSession = binding.resolveReferenceSession();
      expect(refSession, isNotNull);
      expect(refSession!.devices.length, equals(5)); // 1 Router + 2 Switch + 2 PC
    });

    test('Smart fallback for core module 4 (DHCP & Web Server)', () {
      const material = MaterialModel(
        id: 'mat-4',
        title: 'Layanan Server DHCP dan Web',
        moduleNumber: 4,
        isCore: true,
        orderIndex: 1,
        published: true,
        lockStatus: 'default',
      );

      final binding = MaterialLabBinding.fromMaterial(material);
      expect(binding, isNotNull);
      expect(binding!.preset, equals('blank'));
      expect(binding.referencePreset, equals('dhcp_server'));

      final refSession = binding.resolveReferenceSession();
      expect(refSession, isNotNull);
      expect(refSession!.devices.length, equals(4)); // 1 Server + 1 Switch + 2 PC
    });

    test('Custom module without tag returns null (no forced lab)', () {
      const material = MaterialModel(
        id: 'mat-custom-1',
        title: 'Etika Profesi IT',
        moduleNumber: 5,
        isCore: false,
        orderIndex: 1,
        published: true,
        lockStatus: 'default',
        content: 'Teori tentang etika profesi...',
      );

      final binding = MaterialLabBinding.fromMaterial(material);
      expect(binding, isNull);
    });

    test('Extract explicit lab binding tag from content', () {
      final customJson = jsonEncode({
        'enabled': true,
        'preset': 'dual_subnet',
        'title': 'Praktikum Custom Routing Dosen',
        'description': 'Tugas praktikum minggu ke-5',
        'instructions': ['Langkah 1: Setup router', 'Langkah 2: Uji ping'],
      });

      final material = MaterialModel(
        id: 'mat-custom-2',
        title: 'Materi Praktikum Khusus',
        moduleNumber: 8,
        isCore: false,
        orderIndex: 1,
        published: true,
        lockStatus: 'default',
        content: 'Berikut adalah materi pembahasan routing.\n\n<!--netlearn-lab:$customJson-->',
      );

      final binding = MaterialLabBinding.fromMaterial(material);
      expect(binding, isNotNull);
      expect(binding!.preset, equals('dual_subnet'));
      expect(binding.title, equals('Praktikum Custom Routing Dosen'));
      expect(binding.instructions.length, equals(2));
      expect(binding.instructions.first, equals('Langkah 1: Setup router'));
    });

    test('Explicit disabled tag turns off lab even on core module', () {
      final disabledJson = jsonEncode({
        'enabled': false,
        'preset': 'p2p',
        'title': 'Disabled Lab',
      });

      final material = MaterialModel(
        id: 'mat-disabled',
        title: 'Materi Teori Modul 1 Tanpa Lab',
        moduleNumber: 1,
        isCore: true,
        orderIndex: 1,
        published: true,
        lockStatus: 'default',
        content: 'Materi teori murni.\n<!--netlearn-lab:$disabledJson-->',
      );

      final binding = MaterialLabBinding.fromMaterial(material);
      expect(binding, isNull);
    });

    test('stripLabTag cleans content text', () {
      const raw = 'Paragraf pertama materi.\n\n<!--netlearn-lab:{"enabled":true}-->';
      final clean = MaterialLabBinding.stripLabTag(raw);
      expect(clean, equals('Paragraf pertama materi.'));
      expect(clean.contains('netlearn-lab'), isFalse);
    });

    test('embedLabTag correctly appends tag and round-trips', () {
      const baseContent = 'Isi penjelasan materi.';
      const originalBinding = MaterialLabBinding(
        preset: 'star',
        title: 'Ujian Lab Praktikum LAN',
        instructions: ['Konfigurasi IP Static', 'Lakukan uji ping'],
      );

      final embedded = MaterialLabBinding.embedLabTag(baseContent, originalBinding);
      expect(embedded, contains(baseContent));
      expect(embedded, contains('<!--netlearn-lab:'));

      final material = MaterialModel(
        id: 'mat-embed-test',
        title: 'Ujian Lab',
        isCore: false,
        orderIndex: 1,
        published: true,
        lockStatus: 'default',
        content: embedded,
      );

      final parsed = MaterialLabBinding.fromMaterial(material);
      expect(parsed, isNotNull);
      expect(parsed!.preset, equals('star'));
      expect(parsed.title, equals('Ujian Lab Praktikum LAN'));
      expect(parsed.instructions.length, equals(2));
    });
  });
}
