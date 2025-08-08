import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '/models/user_profile.dart';

class UserService {
  static const String _userProfileKey = 'user_profile';
  static const String _hasCompletedOnboardingKey = 'has_completed_onboarding';
  
  UserProfile? _currentUser;
  
  /// Singleton instance
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  /// Obține utilizatorul curent
  UserProfile? get currentUser => _currentUser;
  bool get hasUser => _currentUser != null;
  bool get isLoggedIn => hasUser;

  /// Încarcă profilul utilizatorului din storage
  Future<UserProfile?> loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userProfileKey);
      
      if (userJson != null) {
        final userData = jsonDecode(userJson);
        _currentUser = UserProfile.fromJson(userData);
        return _currentUser;
      }
      return null;
    } catch (e) {
      throw Exception('Eroare la încărcarea profilului: $e');
    }
  }

  /// Salvează profilul utilizatorului
  Future<void> saveUserProfile(UserProfile user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updatedUser = user.copyWith(updatedAt: DateTime.now());
      final userJson = jsonEncode(updatedUser.toJson());
      
      await prefs.setString(_userProfileKey, userJson);
      _currentUser = updatedUser;
    } catch (e) {
      throw Exception('Eroare la salvarea profilului: $e');
    }
  }

  /// Creează un nou utilizator (prima dată când deschide aplicația)
  Future<UserProfile> createUser({
    required String name,
    required String email,
    required List<String> selectedAllergens,
    String? avatarPath,
    UserPreferences? preferences,
  }) async {
    try {
      final now = DateTime.now();
      final user = UserProfile(
        id: _generateUserId(),
        name: name,
        email: email,
        avatarPath: avatarPath,
        selectedAllergens: selectedAllergens,
        createdAt: now,
        updatedAt: now,
        preferences: preferences ?? UserPreferences.defaultPreferences,
      );

      await saveUserProfile(user);
      await setOnboardingCompleted(true);
      return user;
    } catch (e) {
      throw Exception('Eroare la crearea utilizatorului: $e');
    }
  }

  /// Actualizează profilul utilizatorului
  Future<void> updateProfile({
    String? name,
    String? email,
    String? avatarPath,
    List<String>? selectedAllergens,
  }) async {
    if (_currentUser == null) throw Exception('Nu există utilizator logat');

    try {
      final updatedUser = _currentUser!.copyWith(
        name: name,
        email: email,
        avatarPath: avatarPath,
        selectedAllergens: selectedAllergens,
      );

      await saveUserProfile(updatedUser);
    } catch (e) {
      throw Exception('Eroare la actualizarea profilului: $e');
    }
  }

  /// Actualizează preferințele utilizatorului
  Future<void> updatePreferences(UserPreferences preferences) async {
    if (_currentUser == null) throw Exception('Nu există utilizator logat');

    try {
      final updatedUser = _currentUser!.copyWith(preferences: preferences);
      await saveUserProfile(updatedUser);
    } catch (e) {
      throw Exception('Eroare la actualizarea preferințelor: $e');
    }
  }

  /// Adaugă un alergen la lista utilizatorului
  Future<void> addAllergen(String allergen) async {
    if (_currentUser == null) throw Exception('Nu există utilizator logat');

    try {
      final currentAllergens = List<String>.from(_currentUser!.selectedAllergens);
      if (!currentAllergens.contains(allergen)) {
        currentAllergens.add(allergen);
        await updateProfile(selectedAllergens: currentAllergens);
      }
    } catch (e) {
      throw Exception('Eroare la adăugarea alergenului: $e');
    }
  }

  /// Elimină un alergen din lista utilizatorului
  Future<void> removeAllergen(String allergen) async {
    if (_currentUser == null) throw Exception('Nu există utilizator logat');

    try {
      final currentAllergens = List<String>.from(_currentUser!.selectedAllergens);
      currentAllergens.remove(allergen);
      await updateProfile(selectedAllergens: currentAllergens);
    } catch (e) {
      throw Exception('Eroare la eliminarea alergenului: $e');
    }
  }

  /// Verifică dacă utilizatorul are un anumit alergen
  bool hasAllergen(String allergen) {
    return _currentUser?.hasAllergen(allergen) ?? false;
  }

  /// Onboarding
  Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasCompletedOnboardingKey) ?? false;
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasCompletedOnboardingKey, completed);
  }

  /// Avatar management
  Future<void> updateAvatar(String imagePath) async {
    if (_currentUser == null) throw Exception('Nu există utilizator logat');

    try {
      // Copiază imaginea în directorul aplicației
      final appDir = Directory.systemTemp; // În producție, folosește getApplicationDocumentsDirectory()
      final fileName = 'avatar_${_currentUser!.id}.jpg';
      final newPath = '${appDir.path}/$fileName';
      
      final originalFile = File(imagePath);
      final newFile = await originalFile.copy(newPath);
      
      await updateProfile(avatarPath: newFile.path);
    } catch (e) {
      throw Exception('Eroare la actualizarea avatar-ului: $e');
    }
  }

  /// Șterge datele utilizatorului (logout/reset)
  Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userProfileKey);
      await prefs.remove(_hasCompletedOnboardingKey);
      _currentUser = null;
    } catch (e) {
      throw Exception('Eroare la ștergerea datelor: $e');
    }
  }

  /// Generează un ID unic pentru utilizator
  String _generateUserId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Export/Import data (pentru backup)
  Map<String, dynamic> exportUserData() {
    if (_currentUser == null) throw Exception('Nu există utilizator logat');
    return _currentUser!.toJson();
  }

  Future<void> importUserData(Map<String, dynamic> userData) async {
    try {
      final user = UserProfile.fromJson(userData);
      await saveUserProfile(user);
    } catch (e) {
      throw Exception('Eroare la importul datelor: $e');
    }
  }

  /// Statistici pentru utilizator
  Map<String, dynamic> getUserStats() {
    if (_currentUser == null) return {};
    
    final daysSinceCreated = DateTime.now().difference(_currentUser!.createdAt).inDays;
    
    return {
      'allergenCount': _currentUser!.allergenCount,
      'daysSinceJoined': daysSinceCreated,
      'hasAvatar': _currentUser!.hasAvatar,
      'notificationsEnabled': _currentUser!.preferences.enableNotifications,
      'language': _currentUser!.preferences.language,
    };
  }
}