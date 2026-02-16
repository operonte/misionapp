import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_state.dart';
import 'app_router.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final prefs = await SharedPreferences.getInstance();
  appStorage = StorageService(prefs);
  runApp(const MisionApp());
}

class MisionApp extends StatelessWidget {
  const MisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MisionApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF29B6F6), // celeste
          primary: const Color(0xFF29B6F6),
          secondary: const Color(0xFF26A69A), // verde agua
          surface: Colors.white,
          brightness: Brightness.light,
        ),
      ),
      routerConfig: createAppRouter(),
    );
  }
}
