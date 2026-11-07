import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
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
          seedColor: NetLearnColors.primary,
          primary: NetLearnColors.primary,
          surface: Colors.white,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: NetLearnColors.appBg,
        fontFamily: 'Inter',
      ),
      home: const LecturerDashboardPage(),
    );
  }
}
