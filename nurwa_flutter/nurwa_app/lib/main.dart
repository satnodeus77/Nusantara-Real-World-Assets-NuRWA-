import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/app_provider.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: const NuRWAApp(),
    ),
  );
}

class NuRWAApp extends StatelessWidget {
  const NuRWAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NuRWA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050505), // Darkest background for Web Desktop
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF14F195),
          secondary: Color(0xFF9945FF),
          surface: Color(0xFF0A0A0A),
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
      ),
      home: const LoginScreen(),
    );
  }
}