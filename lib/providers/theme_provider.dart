import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('isDark') ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', _isDark);
    notifyListeners();
  }
}

class AppTheme {
  static const _accent = Color(0xFF6C63FF);
  static const _accentDark = Color(0xFF8B85FF);

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _accent,
          brightness: Brightness.light,
        ).copyWith(primary: _accent, secondary: _accent),
        scaffoldBackgroundColor: const Color(0xFFF8F8FC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F8FC),
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
          iconTheme: IconThemeData(color: Color(0xFF1A1A2E)),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF0F0F8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Color(0xFF1A1A2E)),
          titleMedium: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF1A1A2E)),
          bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF4A4A6A)),
          bodySmall: TextStyle(fontSize: 12, color: Color(0xFF8888AA)),
        ),
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _accentDark,
          brightness: Brightness.dark,
        ).copyWith(primary: _accentDark, secondary: _accentDark),
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F0F1A),
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFFF0F0FF),
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
          iconTheme: IconThemeData(color: Color(0xFFF0F0FF)),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1A1A2E),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E1E32),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Color(0xFFF0F0FF)),
          titleMedium: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFFF0F0FF)),
          bodyMedium: TextStyle(fontSize: 14, color: Color(0xFFAAAAAA)),
          bodySmall: TextStyle(fontSize: 12, color: Color(0xFF666688)),
        ),
      );
}
