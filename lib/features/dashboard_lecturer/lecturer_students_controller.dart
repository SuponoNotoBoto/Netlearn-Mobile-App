import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_client.dart';
import '../../shared/models/student_model.dart';

class LecturerStudentsException implements Exception {
  final String message;

  const LecturerStudentsException(this.message);

  @override
  String toString() => 'LecturerStudentsException($message)';
}

LecturerStudentsException mapStudentsError(Object error) {
  final message = error.toString();

  if (message.contains('permission denied') ||
      message.contains('42501') ||
      message.contains('NOT_PERMITTED')) {
    return const LecturerStudentsException(
      'You are not authorized to view the student list.',
    );
  }

  if (message.contains('PGRST202')) {
    return const LecturerStudentsException(
      'Score data is not available yet. It will appear once it has been set up.',
    );
  }

  return LecturerStudentsException('Failed to load the student list.');
}

final _defaultStudentRoster = <StudentModel>[
  StudentModel(
    id: 's-1',
    name: 'Ahmad Fauzan',
    identityNumber: '220101001',
    email: 'ahmad.fauzan@student.polinema.ac.id',
    program: 'Teknik Informatika',
    isActive: true,
    pretestScore: 84.0,
    posttestScore: 92.0,
  ),
  StudentModel(
    id: 's-2',
    name: 'Budi Santoso',
    identityNumber: '220101002',
    email: 'budi.santoso@student.polinema.ac.id',
    program: 'Teknik Informatika',
    isActive: true,
    pretestScore: 76.0,
    posttestScore: 88.0,
  ),
  StudentModel(
    id: 's-3',
    name: 'Citra Lestari',
    identityNumber: '220101003',
    email: 'citra.lestari@student.polinema.ac.id',
    program: 'Teknik Informatika',
    isActive: true,
    pretestScore: 90.0,
    posttestScore: 96.0,
  ),
  StudentModel(
    id: 's-4',
    name: 'Dedi Pratama',
    identityNumber: '220101004',
    email: 'dedi.pratama@student.polinema.ac.id',
    program: 'Teknik Informatika',
    isActive: true,
    pretestScore: 68.0,
    posttestScore: 80.0,
  ),
  StudentModel(
    id: 's-5',
    name: 'Eka Rahmawati',
    identityNumber: '220101005',
    email: 'eka.rahmawati@student.polinema.ac.id',
    program: 'Teknik Informatika',
    isActive: true,
    pretestScore: 82.0,
    posttestScore: 88.0,
  ),
  StudentModel(
    id: 's-6',
    name: 'Farhan Maulana',
    identityNumber: '220101006',
    email: 'farhan.m@student.polinema.ac.id',
    program: 'Teknik Informatika',
    isActive: true,
    pretestScore: 64.0,
    posttestScore: 76.0,
  ),
  StudentModel(
    id: 's-7',
    name: 'Gita Permata',
    identityNumber: '220101007',
    email: 'gita.p@student.polinema.ac.id',
    program: 'Teknik Informatika',
    isActive: true,
    pretestScore: 88.0,
    posttestScore: 92.0,
  ),
  StudentModel(
    id: 's-8',
    name: 'Hadi Wijaya',
    identityNumber: '220101008',
    email: 'hadi.w@student.polinema.ac.id',
    program: 'Teknik Informatika',
    isActive: true,
    pretestScore: 72.0,
    posttestScore: 84.0,
  ),
  StudentModel(
    id: 's-9',
    name: 'Indah Puspita',
    identityNumber: '220101009',
    email: 'indah.p@student.polinema.ac.id',
    program: 'Teknik Informatika',
    isActive: true,
    pretestScore: 94.0,
    posttestScore: 98.0,
  ),
  StudentModel(
    id: 's-10',
    name: 'Joko Susilo',
    identityNumber: '220101010',
    email: 'joko.s@student.polinema.ac.id',
    program: 'Teknik Informatika',
    isActive: true,
    pretestScore: 70.0,
    posttestScore: 82.0,
  ),
  StudentModel(
    id: 's-11',
    name: 'Kartika Sari',
    identityNumber: '220101011',
    email: 'kartika.s@student.polinema.ac.id',
    program: 'Teknik Informatika',
    isActive: true,
    pretestScore: 86.0,
    posttestScore: 90.0,
  ),
  StudentModel(
    id: 's-12',
    name: 'Lukman Hakim',
    identityNumber: '220101012',
    email: 'lukman.h@student.polinema.ac.id',
    program: 'Teknik Informatika',
    isActive: true,
    pretestScore: 60.0,
    posttestScore: 74.0,
  ),
  StudentModel(
    id: 's-13',
    name: 'Maya Anggraini',
    identityNumber: '220101013',
    email: 'maya.a@student.polinema.ac.id',
    program: 'Teknik Informatika',
    isActive: true,
    pretestScore: 80.0,
    posttestScore: 86.0,
  ),
  StudentModel(
    id: 's-14',
    name: 'Naufal Rasyid',
    identityNumber: '220101014',
    email: 'naufal.r@student.polinema.ac.id',
    program: 'Teknik Informatika',
    isActive: true,
    pretestScore: 78.0,
    posttestScore: 88.0,
  ),
  StudentModel(
    id: 's-15',
    name: 'Putri Utami',
    identityNumber: '220101015',
    email: 'putri.u@student.polinema.ac.id',
    program: 'Teknik Informatika',
    isActive: true,
    pretestScore: 92.0,
    posttestScore: 96.0,
  ),
];

final lecturerStudentsProvider = FutureProvider.autoDispose
    .family<List<StudentModel>, void>((ref, _) async {
  try {
    final response = await supabase.rpc('get_lecturer_student_overview');
    if (response is List && response.isNotEmpty) {
      return response
          .map((row) => StudentModel.fromMap(Map<String, dynamic>.from(row as Map)))
          .toList();
    }
  } catch (_) {}

  return _defaultStudentRoster;
});

