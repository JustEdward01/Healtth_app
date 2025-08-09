import 'package:flutter/material.dart';
import 'dart:io';
import '../services/user_service.dart';
import '../modules/result_handler.dart';
import '../models/user_profile.dart';
import '../modules/image_selector.dart';
import 'settings_screen.dart';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final ImageSelector _imageSelector = ImageSelector();

  UserProfile? get currentUser => _userService.currentUser;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Profilul meu',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D5A3D),
              ),
            ),
            const SizedBox(height: 24),

            // Avatar și informații de bază
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: const Color(0xFF6B9B76).withValues(alpha:0.1),
                        backgroundImage: currentUser!.hasAvatar
                            ? FileImage(File(currentUser!.avatarPath!))
                            : null,
                        child: currentUser!.hasAvatar
                            ? null
                            : const Icon(
                                Icons.person,
                                size: 60,
                                color: Color(0xFF6B9B76),
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _changeAvatar,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6B9B76),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currentUser!.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D5A3D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentUser!.email,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Statistici
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Statistici',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D5A3D),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        value: '${currentUser!.allergenCount}',
                        label: 'Alergeni\nMonitorizați',
                        icon: Icons.warning_amber,
                        color: Colors.orange,
                      ),
                      _buildStatItem(
                        value: '${DateTime.now().difference(currentUser!.createdAt).inDays}',
                        label: 'Zile de\nUtilizare',
                        icon: Icons.calendar_today,
                        color: Colors.blue,
                      ),
                      _buildStatItem(
                        value: '0', // TODO: Implementează istoric scanări
                        label: 'Produse\nScanate',
                        icon: Icons.qr_code_scanner,
                        color: Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Alergeni monitorizați
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Alergenii mei',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D5A3D),
                        ),
                      ),
                      TextButton(
                        onPressed: _editAllergens,
                        child: const Text('Editează'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (currentUser!.selectedAllergens.isEmpty)
                    const Text(
                      'Nu ai selectat niciun alergen',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: currentUser!.selectedAllergens.map((allergen) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B9B76).withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF6B9B76),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.warning,
                                size: 14,
                                color: Color(0xFF6B9B76),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                allergen,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6B9B76),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Acțiuni rapide
            const Text(
              'Acțiuni',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D5A3D),
              ),
            ),
            const SizedBox(height: 16),
            
            _buildActionButton(
              icon: Icons.edit,
              title: 'Editează Profilul',
              subtitle: 'Schimbă numele, email-ul sau avatar-ul',
              onTap: _editProfile,
            ),
            const SizedBox(height: 12),
            
            _buildActionButton(
              icon: Icons.settings,
              title: 'Setări',
              subtitle: 'Notificări, tema, limba și alte preferințe',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            
            _buildActionButton(
              icon: Icons.info_outline,
              title: 'Despre AllerFree',
              subtitle: 'Versiune, licențe și informații legale',
              onTap: _showAbout,
            ),
            const SizedBox(height: 12),
            
            _buildActionButton(
              icon: Icons.logout,
              title: 'Resetează Aplicația',
              subtitle: 'Șterge toate datele și reîncepe',
              onTap: _resetApp,
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D5A3D),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDestructive 
                    ? Colors.red.withValues(alpha:0.1)
                    : const Color(0xFF6B9B76).withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : const Color(0xFF6B9B76),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? Colors.red : const Color(0xFF2D5A3D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF6B7280),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeAvatar() async {
  try {
    final File? image = await _imageSelector.pickFromGallery();
    if (image != null) {
      await _userService.updateAvatar(image.path);
      if (!mounted) return; // <-- Add this line
      setState(() {});
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avatar actualizat cu succes!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    if (!mounted) return; // <-- Add this line
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Eroare la actualizarea avatar-ului: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

void _editAllergens() {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) { // Use dialogContext for the dialog
      return _AllergenEditDialog(
        currentAllergens: currentUser!.selectedAllergens,
        onSave: (selectedAllergens) async {
          try {
            await _userService.updateProfile(selectedAllergens: selectedAllergens);
            if (!dialogContext.mounted) return; // Use dialogContext here
            setState(() {});
            Navigator.of(dialogContext).pop();

            ScaffoldMessenger.of(dialogContext).showSnackBar(
              const SnackBar(
                content: Text('Alergenii au fost actualizați!'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            if (!dialogContext.mounted) return; // Use dialogContext here
            ScaffoldMessenger.of(dialogContext).showSnackBar(
              SnackBar(
                content: Text('Eroare: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
    },
  );
}

  void _editProfile() {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return _ProfileEditDialog(
        currentUser: currentUser!,
        onSave: (name, email) async {
          try {
            await _userService.updateProfile(name: name, email: email);
            if (!dialogContext.mounted) return;
            setState(() {});
            Navigator.of(dialogContext).pop();

            ScaffoldMessenger.of(dialogContext).showSnackBar(
              const SnackBar(
                content: Text('Profilul a fost actualizat!'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            if (!dialogContext.mounted) return;
            ScaffoldMessenger.of(dialogContext).showSnackBar(
              SnackBar(
                content: Text('Eroare: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
    },
  );
}

  void _showAbout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Despre AllerFree'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AllerFree v1.0.0'),
              SizedBox(height: 8),
              Text('Aplicația ta personală pentru detectarea alergenilor în alimente.'),
              SizedBox(height: 16),
              Text('Dezvoltat cu ❤️ pentru siguranța ta alimentară.'),
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

  void _resetApp() {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Resetează Aplicația'),
        content: const Text(
          'Această acțiune va șterge toate datele tale (profil, setări, istoric). '
          'Vei fi redirectat la ecranul de onboarding.\n\n'
          'Ești sigur că vrei să continui?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Anulează'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _userService.clearUserData();
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).popUntil((route) => route.isFirst);
                // Restart app - în producție ar trebui să redirectezi la SplashScreen
              } catch (e) {
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text('Eroare: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Resetează'),
          ),
        ],
      );
    },
  );
}
}

// Dialog pentru editarea alergenilor
class _AllergenEditDialog extends StatefulWidget {
  final List<String> currentAllergens;
  final Function(List<String>) onSave;

  const _AllergenEditDialog({
    required this.currentAllergens,
    required this.onSave,
  });

  @override
  State<_AllergenEditDialog> createState() => _AllergenEditDialogState();
}

class _AllergenEditDialogState extends State<_AllergenEditDialog> {
  final ResultHandler _resultHandler = ResultHandler();
  late List<String> selectedAllergens;

  @override
  void initState() {
    super.initState();
    selectedAllergens = List.from(widget.currentAllergens);
  }

  @override
  Widget build(BuildContext context) {
    final availableAllergens = [
  'cereals_gluten',   // în loc de ce era înainte
  'crustaceans',
  'eggs', 
  'fish',
  'peanuts',
  'soybeans',
  'milk',
  'tree_nuts',
  'celery',
  'mustard',          // în loc de 'mustar'
  'sesame',
  'sulphites',
  'lupin',
  'molluscs'
];

final allergenDisplayNames = {
  'cereals_gluten': 'Cereale cu gluten',
  'crustaceans': 'Crustacee',
  'eggs': 'Ouă',
  'fish': 'Pește', 
  'peanuts': 'Arahide',
  'soybeans': 'Soia',
  'milk': 'Lapte',
  'tree_nuts': 'Nuci',
  'celery': 'Țelină',
  'mustard': 'Muștar',        // afișează frumos
  'sesame': 'Susan',
  'sulphites': 'Sulfiți',
  'lupin': 'Lupin',
  'molluscs': 'Moluște'
};
    return AlertDialog(
      title: const Text('Editează Alergenii'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.5,
          ),
          itemCount: availableAllergens.length,
          itemBuilder: (context, index) {
            final allergen = availableAllergens[index];
            final isSelected = selectedAllergens.contains(allergen);

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    selectedAllergens.remove(allergen);
                  } else {
                    selectedAllergens.add(allergen);
                  }
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF6B9B76) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF6B9B76) : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    allergen,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF2D5A3D),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anulează'),
        ),
        ElevatedButton(
          onPressed: () => widget.onSave(selectedAllergens),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6B9B76),
          ),
          child: const Text('Salvează', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// Dialog pentru editarea profilului
class _ProfileEditDialog extends StatefulWidget {
  final UserProfile currentUser;
  final Function(String name, String email) onSave;

  const _ProfileEditDialog({
    required this.currentUser,
    required this.onSave,
  });

  @override
  State<_ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<_ProfileEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentUser.name);
    _emailController = TextEditingController(text: widget.currentUser.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editează Profilul'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nume',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anulează'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty && _emailController.text.isNotEmpty) {
              widget.onSave(_nameController.text, _emailController.text);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6B9B76),
          ),
          child: const Text('Salvează', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}