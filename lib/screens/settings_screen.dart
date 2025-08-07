import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../models/user_profile.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserService _userService = UserService();
  UserPreferences? preferences;

  @override
  void initState() {
    super.initState();
    preferences = _userService.currentUser?.preferences;
  }

  Future<void> _updatePreferences(UserPreferences newPreferences) async {
  try {
    await _userService.updatePreferences(newPreferences);
    if (!mounted) return;
    setState(() {
      preferences = newPreferences;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Setările au fost actualizate!'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Eroare: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    if (preferences == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Setări'),
          backgroundColor: const Color(0xFF6B9B76),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setări'),
        backgroundColor: const Color(0xFF6B9B76),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notificări
              _buildSectionHeader('Notificări'),
              _buildSettingsTile(
                title: 'Activează notificările',
                subtitle: 'Primește alerte când sunt detectați alergeni',
                value: preferences!.enableNotifications,
                onChanged: (value) {
                  _updatePreferences(preferences!.copyWith(enableNotifications: value));
                },
              ),
              if (preferences!.enableNotifications) ...[
                _buildSettingsTile(
                  title: 'Notificări push',
                  subtitle: 'Alerte instant pe telefon',
                  value: preferences!.enablePushNotifications,
                  onChanged: (value) {
                    _updatePreferences(preferences!.copyWith(enablePushNotifications: value));
                  },
                ),
                _buildSettingsTile(
                  title: 'Notificări email',
                  subtitle: 'Primește rezumate pe email',
                  value: preferences!.enableEmailNotifications,
                  onChanged: (value) {
                    _updatePreferences(preferences!.copyWith(enableEmailNotifications: value));
                  },
                ),
                _buildSettingsTile(
                  title: 'Vibrație',
                  subtitle: 'Vibrează când sunt detectați alergeni',
                  value: preferences!.enableVibration,
                  onChanged: (value) {
                    _updatePreferences(preferences!.copyWith(enableVibration: value));
                  },
                ),
                _buildSettingsTile(
                  title: 'Sunet',
                  subtitle: 'Redă sunete pentru alerte',
                  value: preferences!.enableSound,
                  onChanged: (value) {
                    _updatePreferences(preferences!.copyWith(enableSound: value));
                  },
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Aplicație
              _buildSectionHeader('Aplicație'),
              _buildSelectTile(
                title: 'Limba',
                subtitle: 'Selectează limba aplicației',
                value: _getLanguageDisplay(preferences!.language),
                onTap: () => _showLanguageDialog(),
              ),
              _buildSelectTile(
                title: 'Tema',
                subtitle: 'Alege aspectul aplicației',
                value: _getThemeDisplay(preferences!.theme),
                onTap: () => _showThemeDialog(),
              ),
              _buildSettingsTile(
                title: 'Scanare automată',
                subtitle: 'Procesează imaginile automat după selectare',
                value: preferences!.autoScan,
                onChanged: (value) {
                  _updatePreferences(preferences!.copyWith(autoScan: value));
                },
              ),
              
              const SizedBox(height: 24),
              
              // Date și confidențialitate
              _buildSectionHeader('Date și Confidențialitate'),
              _buildSettingsTile(
                title: 'Salvează istoricul',
                subtitle: 'Păstrează istoricul scanărilor pentru statistici',
                value: preferences!.saveHistory,
                onChanged: (value) {
                  _updatePreferences(preferences!.copyWith(saveHistory: value));
                },
              ),
              _buildSettingsTile(
                title: 'Partajare date anonime',
                subtitle: 'Ajută la îmbunătățirea aplicației',
                value: preferences!.shareData,
                onChanged: (value) {
                  _updatePreferences(preferences!.copyWith(shareData: value));
                },
              ),
              
              const SizedBox(height: 24),
              
              // Informații
              _buildSectionHeader('Informații'),
              _buildActionTile(
                title: 'Politica de confidențialitate',
                subtitle: 'Cum îți protejăm datele',
                onTap: () => _showPrivacyPolicy(),
              ),
              _buildActionTile(
                title: 'Termeni și condiții',
                subtitle: 'Condițiile de utilizare',
                onTap: () => _showTermsOfService(),
              ),
              _buildActionTile(
                title: 'Contact și suport',
                subtitle: 'Obține ajutor sau raportează probleme',
                onTap: () => _showContactInfo(),
              ),
              
              const SizedBox(height: 32),
              
              // Export/Import date
              Center(
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _exportData,
                      icon: const Icon(Icons.download),
                      label: const Text('Exportă datele mele'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B9B76),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _importData,
                      icon: const Icon(Icons.upload),
                      label: const Text('Importă date'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF6B9B76),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style:  TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.titleLarge?.color
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,

        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D5A3D),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF6B9B76),
      ),
    );
  }

  Widget _buildSelectTile({
    required String title,
    required String subtitle,
    required String value,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,

        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black..withValues(alpha:0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D5A3D),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B9B76),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF6B7280),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,

        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D5A3D),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Color(0xFF6B7280),
        ),
        onTap: onTap,
      ),
    );
  }

  String _getLanguageDisplay(String languageCode) {
    switch (languageCode) {
      case 'ro':
        return 'Română';
      case 'en':
        return 'English';
      default:
        return 'Română';
    }
  }

String _getThemeDisplay(String theme) {
  final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
  return themeProvider.currentThemeName;
}

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selectează limba'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption('ro', 'Română'),
              _buildLanguageOption('en', 'English'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(String code, String name) {
    return RadioListTile<String>(
      title: Text(name),
      value: code,
      groupValue: preferences!.language,
      onChanged: (value) {
        if (value != null) {
          _updatePreferences(preferences!.copyWith(language: value));
          Navigator.of(context).pop();
        }
      },
      activeColor: const Color(0xFF6B9B76),
    );
  }

  void _showThemeDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return AlertDialog(
            title: const Text('Selectează tema'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('Sistem'),
                  subtitle: const Text('Urmează setările sistemului'),
                  value: ThemeMode.system,
                  groupValue: themeProvider.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      themeProvider.setThemeMode(value);
                      Navigator.of(context).pop();
                    }
                  },
                  activeColor: const Color(0xFF6B9B76),
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Luminos'),
                  subtitle: const Text('Tema luminoasă'),
                  value: ThemeMode.light,
                  groupValue: themeProvider.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      themeProvider.setThemeMode(value);
                      Navigator.of(context).pop();
                    }
                  },
                  activeColor: const Color(0xFF6B9B76),
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Întunecat'),
                  subtitle: const Text('Tema întunecată'),
                  value: ThemeMode.dark,
                  groupValue: themeProvider.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      themeProvider.setThemeMode(value);
                      Navigator.of(context).pop();
                    }
                  },
                  activeColor: const Color(0xFF6B9B76),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

  

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Politica de confidențialitate'),
          content: const SingleChildScrollView(
            child: Text(
              'AllerFree respectă confidențialitatea datelor tale.\n\n'
              'Date colectate:\n'
              '• Informații de profil (nume, email)\n'
              '• Lista ta de alergeni\n'
              '• Preferințele aplicației\n'
              '• Istoricul scanărilor (opțional)\n\n'
              'Datele tale sunt stocate local pe dispozitiv și nu sunt partajate cu terți fără consimțământul tău explicit.\n\n'
              'Pentru mai multe informații, contactează-ne la support@allerfree.com',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Am înțeles'),
            ),
          ],
        );
      },
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Termeni și condiții'),
          content: const SingleChildScrollView(
            child: Text(
              'Prin utilizarea AllerFree, accepți următorii termeni:\n\n'
              '1. AllerFree este un instrument de asistență și nu înlocuiește sfatul medical profesional.\n\n'
              '2. Verifică întotdeauna etichetele produselor și consultă un medic pentru sfaturi medicale.\n\n'
              '3. Nu ne asumăm responsabilitatea pentru reacții alergice cauzate de informații incorecte sau incomplete.\n\n'
              '4. Folosești aplicația pe propria răspundere.\n\n'
              '5. Ne rezervăm dreptul de a actualiza acești termeni.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Am înțeles'),
            ),
          ],
        );
      },
    );
  }

  void _showContactInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Contact și suport'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ai nevoie de ajutor? Contactează-ne:'),
              SizedBox(height: 16),
              Text('📧 Email: support@allerfree.com'),
              SizedBox(height: 8),
              Text('🌐 Website: www.allerfree.com'),
              SizedBox(height: 8),
              Text('📱 Versiune: 1.0.0'),
              SizedBox(height: 16),
              Text('Răspundem în maximum 24 de ore!'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _exportData() {
    try {
      final userData = _userService.exportUserData();
      
      // În producție, aici ai salva într-un fișier sau ai partaja
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Date exportate'),
            content: SingleChildScrollView(
              child: Text(
                'Datele tale:\n\n${userData.toString()}',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Datele au fost exportate cu succes!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Eroare la exportul datelor: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _importData() {
    // În producție, aici ai selecta un fișier și ai importa datele
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Import date'),
          content: const Text(
            'Funcționalitatea de import va fi disponibilă în curând.\n\n'
            'Vei putea importa datele dintr-un backup anterior pentru a-ți restabili profilul.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}