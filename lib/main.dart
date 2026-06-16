import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_state.dart';
import 'app_router.dart';
import 'app_themes.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final prefs = await SharedPreferences.getInstance();
  appStorage = StorageService(prefs);
  // Load saved palette index (defaults to 0 = Celeste on first install).
  themeIndexNotifier.value = appStorage.getThemeIndex();
  runApp(const MisionApp());
}

class MisionApp extends StatelessWidget {
  const MisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: themeIndexNotifier,
      builder: (context, idx, _) {
        final palette =
            appPalettes[idx.clamp(0, appPalettes.length - 1)];
        return MaterialApp.router(
          title: 'MisionApp',
          debugShowCheckedModeBanner: false,
          theme: palette.lightTheme(),
          darkTheme: palette.darkTheme(),
          themeMode: palette.themeMode,
          routerConfig: createAppRouter(),
        );
      },
    );
  }
}
