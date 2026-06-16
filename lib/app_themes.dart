import 'package:flutter/material.dart';

class AppPalette {
  final String name;
  final Color seed;
  final bool forceDark;

  const AppPalette({
    required this.name,
    required this.seed,
    this.forceDark = false,
  });

  ThemeData lightTheme() =>
      _buildTheme(forceDark ? Brightness.dark : Brightness.light);

  ThemeData darkTheme() => _buildTheme(Brightness.dark);

  // Light palettes always show light — don't follow system dark mode.
  // Use "Tech Oscuro" if you want a dark theme.
  ThemeMode get themeMode =>
      forceDark ? ThemeMode.dark : ThemeMode.light;

  ThemeData _buildTheme(Brightness brightness) {
    // Step 1 — generate the M3 colour scheme from the seed colour.
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: brightness),
    );
    final cs = base.colorScheme;

    // Reusable border radius constants (8px grid).
    const radiusCard   = BorderRadius.all(Radius.circular(16));
    const radiusInput  = BorderRadius.all(Radius.circular(12));
    const radiusButton = BorderRadius.all(Radius.circular(12));
    const radiusSheet  = BorderRadius.vertical(top: Radius.circular(24));
    const radiusDialog = BorderRadius.all(Radius.circular(24));
    const radiusChip   = BorderRadius.all(Radius.circular(8));

    // Helper: OutlineInputBorder with consistent radius.
    OutlineInputBorder inputBorder(Color color, {double width = 1}) =>
        OutlineInputBorder(
          borderRadius: radiusInput,
          borderSide: BorderSide(color: color, width: width),
        );

    // Step 2 — apply design system on top of the generated base.
    return base.copyWith(
      // ── Cards ────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: cs.shadow.withValues(alpha: 0.15),
        shape: const RoundedRectangleBorder(borderRadius: radiusCard),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      ),

      // ── Input fields ─────────────────────────────────────────────────────
      // Consistent 12px radius + 16px vertical padding = breathing room.
      inputDecorationTheme: InputDecorationTheme(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border:           inputBorder(cs.outline),
        enabledBorder:    inputBorder(cs.outline),
        focusedBorder:    inputBorder(cs.primary, width: 2),
        errorBorder:      inputBorder(cs.error),
        focusedErrorBorder: inputBorder(cs.error, width: 2),
      ),

      // ── Buttons ──────────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(88, 52),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: const RoundedRectangleBorder(borderRadius: radiusButton),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: radiusButton),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(88, 52),
          shape: const RoundedRectangleBorder(borderRadius: radiusButton),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(88, 52),
          shape: const RoundedRectangleBorder(borderRadius: radiusButton),
        ),
      ),

      // ── Chips ────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(borderRadius: radiusChip),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // ── Bottom sheets ────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: radiusSheet),
        showDragHandle: true,
      ),

      // ── Dialogs ──────────────────────────────────────────────────────────
      dialogTheme: const DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: radiusDialog),
      ),

      // ── ListTiles ────────────────────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minVerticalPadding: 12,
      ),
    );
  }
}

const List<AppPalette> appPalettes = [
  AppPalette(name: 'Celeste',     seed: Color(0xFF0284C7)),
  AppPalette(name: 'Verde',       seed: Color(0xFF10B981)),
  AppPalette(name: 'Tech Oscuro', seed: Color(0xFF6366F1), forceDark: true),
  AppPalette(name: 'Rosado',      seed: Color(0xFFEC4899)),
];
