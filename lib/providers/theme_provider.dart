import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme';
  static const String _languageKey = 'app_language';
  
  ThemeMode _themeMode = ThemeMode.system;
  String _languageCode = 'ro';
  
  ThemeMode get themeMode => _themeMode;
  String get languageCode => _languageCode;
  
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  ThemeProvider() {
    _loadFromPrefs();
  }

  // Încarcă tema și limba din SharedPreferences
  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Încarcă tema
      final themeString = prefs.getString(_themeKey) ?? 'system';
      switch (themeString) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        default:
          _themeMode = ThemeMode.system;
      }
      
      // Încarcă limba
      _languageCode = prefs.getString(_languageKey) ?? 'ro';
      
      notifyListeners();
    } catch (e) {
      debugPrint('Eroare la încărcarea temei: $e');
    }
  }

  // Schimbă tema
  Future<void> setThemeMode(ThemeMode themeMode) async {
    _themeMode = themeMode;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      String themeString = 'system';
      switch (themeMode) {
        case ThemeMode.light:
          themeString = 'light';
          break;
        case ThemeMode.dark:
          themeString = 'dark';
          break;
        case ThemeMode.system:
          themeString = 'system';
          break;
      }
      await prefs.setString(_themeKey, themeString);
    } catch (e) {
      debugPrint('Eroare la salvarea temei: $e');
    }
  }

  // Schimbă limba
  Future<void> setLanguage(String languageCode) async {
    _languageCode = languageCode;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
    } catch (e) {
      debugPrint('Eroare la salvarea limbii: $e');
    }
  }

  // Toggle între light și dark (pentru switch rapid)
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }

  // Toggle între română și engleză (pentru switch rapid)
  Future<void> toggleLanguage() async {
    if (_languageCode == 'ro') {
      await setLanguage('en');
    } else {
      await setLanguage('ro');
    }
  }

  // Obține tema curentă ca string
  String get currentThemeString {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  // Obține numele temei în română
  String get currentThemeName {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Luminos';
      case ThemeMode.dark:
        return 'Întunecat';
      case ThemeMode.system:
        return 'Sistem';
    }
  }

  // Obține numele limbii
  String get currentLanguageName {
    switch (_languageCode) {
      case 'ro':
        return 'Română';
      case 'en':
        return 'English';
      default:
        return 'Română';
    }
  }
}

// Temele aplicației
class AppThemes {
  // Tema luminoasă
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF5a7d5a),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFf8faf5), // Alb-verzui pal
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF5a7d5a),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: const Color(0xFFd9ead3), // Verde pal
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5a7d5a), // Buton scanare
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF4caf50); // Accent verde
        }
        return Colors.grey;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF4caf50).withOpacity(0.5);
        }
        return Colors.grey.withOpacity(0.3);
      }),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF2f5233)), // Text principal
      bodyMedium: TextStyle(color: Color(0xFF6b7a6b)), // Text secundar
      titleLarge: TextStyle(color: Color(0xFF2f5233)),
      titleMedium: TextStyle(color: Color(0xFF2f5233)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFFe9f0e6), // Bară jos
    ),
  );

  // Tema întunecată cu paleta ta
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF81c784),
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF121b16), // Verde închis/negru
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1a2420), // Verde foarte închis
      foregroundColor: Color(0xFFe8f5e9), // Text alb-verzui
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF1e2b25), // Verde-oliv foarte închis
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFa5d6a7), // Verde pastel luminos
        foregroundColor: const Color(0xFF121b16), // Text închis pe buton
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF81c784); // Verde viu adaptat
        }
        return const Color(0xFFa0b8a5);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF81c784).withOpacity(0.5);
        }
        return const Color(0xFFa0b8a5).withOpacity(0.3);
      }),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFe8f5e9)), // Text principal alb-verzui
      bodyMedium: TextStyle(color: Color(0xFFa0b8a5)), // Text secundar verde-gri
      titleLarge: TextStyle(color: Color(0xFFe8f5e9)),
      titleMedium: TextStyle(color: Color(0xFFe8f5e9)),
      headlineLarge: TextStyle(color: Color(0xFFe8f5e9)),
      headlineMedium: TextStyle(color: Color(0xFFe8f5e9)),
      displayLarge: TextStyle(color: Color(0xFFe8f5e9)),
      displayMedium: TextStyle(color: Color(0xFFe8f5e9)),
    ),
    // Culori pentru containere și carduri
    canvasColor: const Color(0xFF121b16),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF1e2b25),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1a2420), // Bară jos închisă
      selectedItemColor: Color(0xFF81c784), // Verde viu
      unselectedItemColor: Color(0xFFa0b8a5), // Verde-gri
    ),
    // Icon theme
    iconTheme: const IconThemeData(
      color: Color(0xFFa0b8a5), // Verde-gri pentru iconițe
    ),
    primaryIconTheme: const IconThemeData(
      color: Color(0xFF81c784), // Verde viu pentru iconițe principale
    ), dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF1e2b25)),
  );
}
