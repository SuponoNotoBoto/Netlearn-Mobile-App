import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_client.dart';
import '../../shared/models/material_model.dart';

final _defaultMaterials = <MaterialModel>[
  const MaterialModel(
    id: 'mat-1',
    title: 'Pengenalan Jaringan Komputer & Topologi Dasar',
    titleEn: 'Introduction to Computer Networks & Basic Topologies',
    titleId: 'Pengenalan Jaringan Komputer & Topologi Dasar',
    moduleNumber: 1,
    isCore: true,
    orderIndex: 0,
    published: true,
    lockStatus: 'unlocked',
  ),
  const MaterialModel(
    id: 'mat-2',
    title: 'Model Referensi OSI & TCP/IP Protocol Suite',
    titleEn: 'OSI Reference Model & TCP/IP Protocol Suite',
    titleId: 'Model Referensi OSI & TCP/IP Protocol Suite',
    moduleNumber: 2,
    isCore: true,
    orderIndex: 1,
    published: true,
    lockStatus: 'unlocked',
  ),
  const MaterialModel(
    id: 'mat-3',
    title: 'Pengalamatan IPv4, Subnetting & CIDR Calculation',
    titleEn: 'IPv4 Addressing, Subnetting & CIDR Calculation',
    titleId: 'Pengalamatan IPv4, Subnetting & CIDR Calculation',
    moduleNumber: 3,
    isCore: true,
    orderIndex: 2,
    published: true,
    lockStatus: 'unlocked',
  ),
  const MaterialModel(
    id: 'mat-4',
    title: 'Konfigurasi Routing Statis & Dinamis (RIP, OSPF)',
    titleEn: 'Static & Dynamic Routing Configuration (RIP, OSPF)',
    titleId: 'Konfigurasi Routing Statis & Dinamis (RIP, OSPF)',
    moduleNumber: 4,
    isCore: true,
    orderIndex: 3,
    published: true,
    lockStatus: 'unlocked',
  ),
];

final lecturerMaterialsProvider =
    FutureProvider.autoDispose<List<MaterialModel>>((ref) async {
  try {
    final response = await supabase
        .from('materials')
        .select('id, title, title_en, title_id, module_number, is_core, published')
        .order('module_number');

    final rows = (response as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    if (rows.isNotEmpty) {
      return rows.map((r) => MaterialModel.fromMap(r)).toList();
    }
  } catch (_) {}

  return _defaultMaterials;
});
