import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_client.dart';
import '../../shared/models/material_model.dart';

final _defaultMaterials = <MaterialModel>[
  const MaterialModel(
    id: '8cf2edbc-1042-411a-add9-64c45d72946d',
    title: 'Dasar-Dasar Jaringan Komputer',
    titleEn: 'Computer Network Basics',
    titleId: 'Dasar-Dasar Jaringan Komputer',
    moduleNumber: 1,
    isCore: true,
    orderIndex: 0,
    published: true,
    lockStatus: 'unlocked',
  ),
  const MaterialModel(
    id: 'af067b9d-3bba-4f31-a848-6bb94026b9cb',
    title: 'Perangkat Jaringan',
    titleEn: 'Network Devices',
    titleId: 'Perangkat Jaringan',
    moduleNumber: 2,
    isCore: true,
    orderIndex: 1,
    published: true,
    lockStatus: 'unlocked',
  ),
  const MaterialModel(
    id: 'd50fcc91-ea26-47c1-8acf-2ee6d1cd2bcf',
    title: 'Topologi Jaringan',
    titleEn: 'Network Topologies',
    titleId: 'Topologi Jaringan',
    moduleNumber: 3,
    isCore: true,
    orderIndex: 2,
    published: true,
    lockStatus: 'unlocked',
  ),
  const MaterialModel(
    id: 'd349d421-ef85-4e52-a875-957369b9eaae',
    title: 'IP Address',
    titleEn: 'IP Addressing & Subnetting',
    titleId: 'IP Address',
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
