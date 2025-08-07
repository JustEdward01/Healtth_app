import 'package:flutter/material.dart';
import 'services/user_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_screen.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'screens/settings_screen.dart';
import 'providers/allergen_provider.dart';
// ❌ ELIMINAT: import 'services/hybrid_detection_service.dart';
import 'allergen/screens/allergen_scanner_screen.dart';
import '../screens/camera/smart_camera_screen.dart';
import 'screens/camera/smart_camera_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ❌ ELIMINAT: HybridDetectionService().initialize();
  // Dictionary-based service nu necesită inițializare specială
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => AllergenProvider()), // ✅ Updated pentru Dictionary
      ],
      child: const AllerFreeApp(),
    ),
  );
}

class AllerFreeApp extends StatelessWidget {
  const AllerFreeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'AllerFree',
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
          debugShowCheckedModeBanner: false,
          routes: {
  '/settings': (context) => const SettingsScreen(),
  '/allergen-scanner': (context) => const AllergenScannerScreen(),
  '/smart-camera': (context) => const SmartCameraScreen(), // <-- Add this line
},
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    // ✅ Splash screen mai rapid fără BERT loading
    await Future.delayed(const Duration(seconds: 1)); // Reduced from 2 seconds
    
    try {
      final hasCompletedOnboarding = await _userService.hasCompletedOnboarding();
      
      if (mounted) {
        if (hasCompletedOnboarding) {
          // Încarcă profilul utilizatorului
          await _userService.loadUserProfile();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        }
      }
    } catch (e) {
      debugPrint('Eroare la verificarea onboarding-ului: $e');
      // În caz de eroare, mergi la onboarding
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6B9B76),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.restaurant_menu,
                size: 60,
                color: Color(0xFF6B9B76),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'AllerFree',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Eat Safe, Live Free',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 48),
            // ✅ Loading indicator pentru UI consistency
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 16),
            // 🆕 Mesaj updated pentru Dictionary approach
            const Text(
              'Inițializare detectare alergeni...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🆕 Class pentru tema aplicației (dacă nu există deja)
class AppThemes {
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.green,
      primaryColor: const Color(0xFF6B9B76),
      scaffoldBackgroundColor: Colors.grey[50],
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF6B9B76),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6B9B76),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      primarySwatch: Colors.green,
      primaryColor: const Color(0xFF6B9B76),
      scaffoldBackgroundColor: Colors.grey[900],
      brightness: Brightness.dark,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF6B9B76),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}