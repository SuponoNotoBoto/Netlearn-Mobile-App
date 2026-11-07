import 'package:flutter/material.dart';
import 'features/dashboard_lecturer/lecturer_dashboard_page.dart';
import 'features/dashboard_student/student_dashboard_page.dart';

void main() {
  runApp(const NetLearnApp());
}

class NetLearnApp extends StatefulWidget {
  const NetLearnApp({super.key});

  @override
  State<NetLearnApp> createState() => _NetLearnAppState();
}

class _NetLearnAppState extends State<NetLearnApp> {
  // Default dibuka langsung ke Panel Mahasiswa untuk memudahkan pengujian
  bool _isStudentView = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NetLearn',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          primary: const Color(0xFF6366F1),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        fontFamily: 'Inter',
      ),
      home: _isStudentView
          ? StudentDashboardPage(
              onSwitchToLecturer: () => setState(() => _isStudentView = false),
            )
          : Stack(
              children: [
                const LecturerDashboardPage(),
                Positioned(
                  bottom: 80,
                  right: 16,
                  child: FloatingActionButton.extended(
                    heroTag: 'switch_to_student_btn',
                    backgroundColor: const Color(0xFF6366F1),
                    icon: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
                    label: const Text(
                      'Beralih ke Mahasiswa',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    onPressed: () => setState(() => _isStudentView = true),
                  ),
                ),
              ],
            ),
    );
  }
}
