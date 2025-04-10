import 'package:flutter/material.dart';
import 'screens/vacina_screen.dart';

void main() {
  runApp(const VacinaPreviewApp());
}

class VacinaPreviewApp extends StatelessWidget {
  const VacinaPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0080FF),
          primary: const Color(0xFF0080FF),
        ),
        useMaterial3: true,
      ),
      home: const VacinaScreen(),
    );
  }
} 