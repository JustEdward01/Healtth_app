import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../modules/result_handler.dart';
import 'main_screen.dart'; 
import '../modules/eu_result_handler.dart';
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final UserService _userService = UserService();
  final ResultHandler _resultHandler = ResultHandler();
  
  int currentPage = 0;
  String name = '';
  String email = '';
  List<String> selectedAllergens = [];
  bool isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    if (name.isEmpty || email.isEmpty) {
      _showErrorSnackBar('Te rog completează numele și email-ul');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await _userService.createUser(
        name: name,
        email: email,
        selectedAllergens: selectedAllergens,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Eroare la crearea profilului: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: List.generate(3, (index) {
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                      height: 4,
                      decoration: BoxDecoration(
                        color: index <= currentPage 
                            ? const Color(0xFF6B9B76)
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            
            // Content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    currentPage = page;
                  });
                },
                children: [
                  _buildWelcomePage(),
                  _buildProfilePage(),
                  _buildAllergensPage(),
                ],
              ),
            ),
            
            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (currentPage > 0)
                    TextButton(
                      onPressed: _previousPage,
                      child: const Text(
                        'Înapoi',
                        style: TextStyle(
                          color: Color(0xFF6B9B76),
                          fontSize: 16,
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  
                  ElevatedButton(
                    onPressed: isLoading ? null : _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B9B76),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            currentPage < 2 ? 'Continuă' : 'Finalizează',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF6B9B76),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.restaurant_menu,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Bun venit în AllerFree!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D5A3D),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Aplicația ta personală pentru detectarea alergenilor în alimente. Să configurăm profilul tău pentru a te proteja mai bine.',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
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
            child: const Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF10B981)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('Scanează produse instant'),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF10B981)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('Detectează 14+ alergeni majori'),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF10B981)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('Profil personalizat pentru siguranța ta'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Text(
            'Să ne cunoaștem!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D5A3D),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Aceste informații ne ajută să personalizăm experiența ta.',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 32),
          
          // Avatar placeholder
          Center(
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B9B76).withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 50,
                    color: Color(0xFF6B9B76),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B9B76),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Form fields
          const Text(
            'Numele tău',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D5A3D),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            onChanged: (value) => name = value,
            decoration: InputDecoration(
              hintText: 'ex: Maria Popescu',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 24),
          
          const Text(
            'Email',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D5A3D),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            onChanged: (value) => email = value,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'ex: maria@example.com',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllergensPage() {
    final availableAllergens = _resultHandler.availableAllergens;
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Text(
            'Alergiile tale',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D5A3D),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Selectează alergenii pe care îi ai pentru a primi alertele potrivite.',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
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
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF6B9B76) : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isSelected)
                            const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          Flexible(
                            child: Text(
                              allergen,
                              style: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF2D5A3D),
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          if (selectedAllergens.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ai selectat ${selectedAllergens.length} ${selectedAllergens.length == 1 ? 'alergen' : 'alergeni'}. Poți modifica această listă oricând din setări.',
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}