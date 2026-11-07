import 'package:flutter/material.dart';
import 'features/dashboard_lecturer/lecturer_dashboard_page.dart';

void main() {
  runApp(const NetLearnApp());
}

class NetLearnApp extends StatelessWidget {
  const NetLearnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NetLearn - Panel Dosen',
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
      home: const LecturerDashboardPage(),
    );
  }
}
