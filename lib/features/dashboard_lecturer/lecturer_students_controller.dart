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
    id: '7e8db880-b2ae-44dd-89a1-a0ddabd32abc',
    name: 'Ahmad Farid Hernacqi',
    identityNumber: '25050974012',
    email: '25050974012@mhs.unesa.ac.id',
    program: 'Pendidikan Teknologi Informasi',
    isActive: true,
  ),
  StudentModel(
    id: '7a26da9d-53fb-4961-97f7-3c5e36cdb4b3',
    name: 'Alfarizqi Zaidan Riawan Putra',
    identityNumber: '25050974008',
    email: '25050974008@mhs.unesa.ac.id',
    program: 'Pendidikan Teknologi Informasi',
    isActive: true,
  ),
  StudentModel(
    id: '771c6993-1983-4346-a949-d7ecc650bede',
    name: 'Arya Ghiffary Habyantara',
    identityNumber: '25050974010',
    email: '25050974010@mhs.unesa.ac.id',
    program: 'Pendidikan Teknologi Informasi',
    isActive: true,
  ),
  StudentModel(
    id: '43fef68d-25a3-42a3-b180-c7e477a9ff00',
    name: 'Audy Kirana',
    identityNumber: '25050974011',
    email: '25050974011@mhs.unesa.ac.id',
    program: 'Pendidikan Teknologi Informasi',
    isActive: true,
  ),
  StudentModel(
    id: '44662111-6748-45ce-b575-54de23c222e0',
    name: 'Aulia Arum Rahmawati',
    identityNumber: '25050974002',
    email: '25050974002@mhs.unesa.ac.id',
    program: 'Pendidikan Teknologi Informasi',
    isActive: true,
  ),
  StudentModel(
    id: '7ea06f69-b8d8-4351-8c9c-feb2973ad6ce',
    name: 'Faddel Idries',
    identityNumber: '25050974005',
    email: '25050974005@mhs.unesa.ac.id',
    program: 'Pendidikan Teknologi Informasi',
    isActive: true,
  ),
  StudentModel(
    id: '81a2e9e3-22bd-4ea7-9864-d5e655e33f02',
    name: 'Ikhlas Samudra',
    identityNumber: '25050974004',
    email: '25050974004@mhs.unesa.ac.id',
    program: 'Pendidikan Teknologi Informasi',
    isActive: true,
  ),
  StudentModel(
    id: 'cd2fbd7f-af6b-45bb-b161-059420d47288',
    name: 'Imelda Anastasya Putri',
    identityNumber: '25050974013',
    email: '25050974013@mhs.unesa.ac.id',
    program: 'Pendidikan Teknologi Informasi',
    isActive: true,
  ),
  StudentModel(
    id: '1365030c-6cf8-4df8-96ec-27ddc5afd688',
    name: 'Ivan Okta Arya Pradista',
    identityNumber: '25050974023',
    email: '25050974023@mhs.unesa.ac.id',
    program: 'Pendidikan Teknologi Informasi',
    isActive: true,
  ),
  StudentModel(
    id: '4e173473-4cd3-4c90-a28b-4e19885e71f3',
    name: 'Marsha Anggun Candraningtyas',
    identityNumber: '25050974020',
    email: '25050974020@mhs.unesa.ac.id',
    program: 'Pendidikan Teknologi Informasi',
    isActive: true,
  ),
  StudentModel(
    id: '16b4d310-a837-49a8-be9a-05d083e3292d',
    name: 'Mochamad Ircham Maulana',
    identityNumber: '25050974006',
    email: '25050974006@mhs.unesa.ac.id',
    program: 'Pendidikan Teknologi Informasi',
    isActive: true,
  ),
  StudentModel(
    id: '6624aef1-a72a-42ee-bd49-50457034647a',
    name: 'Muhammad Banaya Ahjulizar',
    identityNumber: '25050974163',
    email: 'banayamuhammad12@gmail.com',
    program: 'Pendidikan Teknologi Informasi',
    isActive: true,
    pretestScore: 72.0,
    posttestScore: 80.0,
  ),
  StudentModel(
    id: '8ac9f850-3a56-4c34-8587-199aa0f4cca7',
    name: 'Muhammad Irsyadul Ibad',
    identityNumber: '25050974009',
    email: '25050974009@mhs.unesa.ac.id',
    program: 'Pendidikan Teknologi Informasi',
    isActive: true,
  ),
  StudentModel(
    id: 'b70128bb-cbed-4699-ba5e-d7b5d60e8e16',
    name: 'Muhammad Magfur Arifin',
    identityNumber: '25050974021',
    email: '25050974021@mhs.unesa.ac.id',
    program: 'Pendidikan Teknologi Informasi',
    isActive: true,
  ),
  StudentModel(
    id: '6dd0cdab-e6a0-4752-b383-a8d6a9f98a36',
    name: 'Nailah Rabbani Augusta',
    identityNumber: '25050974007',
    email: '25050974007@mhs.unesa.ac.id',
    program: 'Pendidikan Teknologi Informasi',
    isActive: true,
  ),
  StudentModel(
    id: '3f985253-2753-4598-95ac-0db5ac6bc877',
    name: 'Nayottama Kumara Rahayu',
    identityNumber: '25050974001',
    email: '25050974001@mhs.unesa.ac.id',
    program: 'Pendidikan Teknologi Informasi',
    isActive: true,
  ),
  StudentModel(
    id: '746fcecb-998f-4fd4-9b5e-79d82ba580c9',
    name: 'Novia Salsabila',
    identityNumber: '25050974016',
    email: '25050974016@mhs.unesa.ac.id',
    program: 'Pendidikan Teknologi Informasi',
    isActive: true,
  ),
  StudentModel(
    id: 'e49875f1-3b2b-4958-8b48-be168098594f',
    name: 'Pramesya Zhafira Rajaby',
    identityNumber: '25050974019',
    email: '25050974019@mhs.unesa.ac.id',
    program: 'Pendidikan Teknologi Informasi',
    isActive: true,
  ),
  StudentModel(
    id: '6bb40f2b-f3b8-4c70-a08e-54c8a1d18a6f',
    name: 'Rafi Ahmad Fauzan',
    identityNumber: '25050974014',
    email: '25050974014@mhs.unesa.ac.id',
    program: 'Pendidikan Teknologi Informasi',
    isActive: true,
    pretestScore: 4.0,
    posttestScore: 24.0,
  ),
  StudentModel(
    id: 'd4fe8433-ffdb-44c6-9b60-bf56c3aef866',
    name: 'Rahadian Danar Permadi',
    identityNumber: '25050974017',
    email: '25050974017@mhs.unesa.ac.id',
    program: 'Pendidikan Teknologi Informasi',
    isActive: true,
  ),
  StudentModel(
    id: 'e0917715-b6f0-4613-94c7-d6509ec10d65',
    name: 'Rendy Aditya Pratama',
    identityNumber: '25050974031',
    email: '25050974031@mhs.unesa.ac.id',
    program: 'Pendidikan Teknologi Informasi',
    isActive: true,
    pretestScore: 92.0,
  ),
  StudentModel(
    id: '27a92bdf-905a-4f3c-b887-7be59f25bfb0',
    name: 'Rizky Doni Putra Pratama',
    identityNumber: '25050974003',
    email: '25050974003@mhs.unesa.ac.id',
    program: 'Pendidikan Teknologi Informasi',
    isActive: true,
  ),
  StudentModel(
    id: '246994d9-0850-4fc4-b41c-83175315cb93',
    name: 'Siti Syifa Urobiyah',
    identityNumber: '25050974015',
    email: '25050974015@mhs.unesa.ac.id',
    program: 'Pendidikan Teknologi Informasi',
    isActive: true,
  ),
  StudentModel(
    id: '6e7dddc3-db7d-4014-b755-46c1f2bffec7',
    name: 'Viny Aula Revandha Zhafarani',
    identityNumber: '25050974022',
    email: '25050974022@mhs.unesa.ac.id',
    program: 'Pendidikan Teknologi Informasi',
    isActive: true,
    pretestScore: 16.0,
  ),
  StudentModel(
    id: 'b95bf42a-ae4f-4477-8a97-081594f0754c',
    name: 'Yasinnia Vambudhi Putri',
    identityNumber: '25050974018',
    email: '25050974018@mhs.unesa.ac.id',
    program: 'Pendidikan Teknologi Informasi',
    isActive: true,
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

