import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/presentation/pages/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://kmjjjclgazkgtmllmwzs.supabase.co',
    publishableKey:
        'sb_publishable_RS29PpYC6miM_41I4jAAXA_2cyEihKi',
  );

  runApp(const MotoraApp());
}

class MotoraApp extends StatelessWidget {
  const MotoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MOTORA',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF101114),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF8ED00),
          surface: Color(0xFF1E2024),
        ),
        fontFamily: 'Roboto',
      ),
      home: const AuthGate(),
    );
  }
}