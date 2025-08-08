class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? avatarPath;
  final List<String> selectedAllergens;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserPreferences preferences;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.avatarPath,
    required this.selectedAllergens,
    required this.createdAt,
    required this.updatedAt,
    required this.preferences,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarPath,
    List<String>? selectedAllergens,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserPreferences? preferences,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarPath: avatarPath ?? this.avatarPath,
      selectedAllergens: selectedAllergens ?? this.selectedAllergens,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      preferences: preferences ?? this.preferences,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarPath': avatarPath,
      'selectedAllergens': selectedAllergens,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'preferences': preferences.toJson(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatarPath: json['avatarPath'],
      selectedAllergens: List<String>.from(json['selectedAllergens'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      preferences: UserPreferences.fromJson(json['preferences'] ?? {}),
    );
  }

  bool hasAllergen(String allergen) {
    return selectedAllergens.contains(allergen);
  }

  int get allergenCount => selectedAllergens.length;
  bool get hasAvatar => avatarPath != null && avatarPath!.isNotEmpty;
}

class UserPreferences {
  final bool enableNotifications;
  final bool enablePushNotifications;
  final bool enableEmailNotifications;
  final bool enableVibration;
  final bool enableSound;
  final String language;
  final String theme; // 'light', 'dark', 'system'
  final bool autoScan;
  final bool saveHistory;
  final bool shareData;

  UserPreferences({
    this.enableNotifications = true,
    this.enablePushNotifications = true,
    this.enableEmailNotifications = false,
    this.enableVibration = true,
    this.enableSound = true,
    this.language = 'ro',
    this.theme = 'system',
    this.autoScan = true,
    this.saveHistory = true,
    this.shareData = false,
  });

  UserPreferences copyWith({
    bool? enableNotifications,
    bool? enablePushNotifications,
    bool? enableEmailNotifications,
    bool? enableVibration,
    bool? enableSound,
    String? language,
    String? theme,
    bool? autoScan,
    bool? saveHistory,
    bool? shareData,
  }) {
    return UserPreferences(
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enablePushNotifications: enablePushNotifications ?? this.enablePushNotifications,
      enableEmailNotifications: enableEmailNotifications ?? this.enableEmailNotifications,
      enableVibration: enableVibration ?? this.enableVibration,
      enableSound: enableSound ?? this.enableSound,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      autoScan: autoScan ?? this.autoScan,
      saveHistory: saveHistory ?? this.saveHistory,
      shareData: shareData ?? this.shareData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enableNotifications': enableNotifications,
      'enablePushNotifications': enablePushNotifications,
      'enableEmailNotifications': enableEmailNotifications,
      'enableVibration': enableVibration,
      'enableSound': enableSound,
      'language': language,
      'theme': theme,
      'autoScan': autoScan,
      'saveHistory': saveHistory,
      'shareData': shareData,
    };
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      enableNotifications: json['enableNotifications'] ?? true,
      enablePushNotifications: json['enablePushNotifications'] ?? true,
      enableEmailNotifications: json['enableEmailNotifications'] ?? false,
      enableVibration: json['enableVibration'] ?? true,
      enableSound: json['enableSound'] ?? true,
      language: json['language'] ?? 'ro',
      theme: json['theme'] ?? 'system',
      autoScan: json['autoScan'] ?? true,
      saveHistory: json['saveHistory'] ?? true,
      shareData: json['shareData'] ?? false,
    );
  }

  static UserPreferences get defaultPreferences => UserPreferences();
}