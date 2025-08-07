import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// Switch rapid pentru tema (Dark/Light)
class ThemeToggleButton extends StatelessWidget {
 final bool isCompact;
 
 const ThemeToggleButton({
   super.key,
   this.isCompact = true,
 });

 @override
 Widget build(BuildContext context) {
   return Consumer<ThemeProvider>(
     builder: (context, themeProvider, child) {
       if (isCompact) {
         // Versiunea compactă pentru main menu
         return Container(
           padding: const EdgeInsets.all(8),
           decoration: BoxDecoration(
             color: Theme.of(context).cardColor,
             borderRadius: BorderRadius.circular(8),
             boxShadow: [
               BoxShadow(
                 color: Colors.black.withOpacity(0.1),
                 blurRadius: 4,
                 offset: const Offset(0, 2),
               ),
             ],
           ),
           child: InkWell(
             onTap: () => themeProvider.toggleTheme(),
             borderRadius: BorderRadius.circular(8),
             child: Row(
               mainAxisSize: MainAxisSize.min,
               children: [
                 Icon(
                   themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                   size: 20,
                   color: const Color(0xFF6B9B76),
                 ),
                 const SizedBox(width: 4),
                 Text(
                   themeProvider.isDarkMode ? 'Dark' : 'Light',
                   style: TextStyle(
                     fontSize: 12,
                     fontWeight: FontWeight.w600,
                     color: Theme.of(context).textTheme.bodyLarge?.color,
                   ),
                 ),
               ],
             ),
           ),
         );
       } else {
         // Versiunea extinsă pentru settings
         return SwitchListTile(
           secondary: Icon(
             themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
             color: const Color(0xFF6B9B76),
           ),
           title: const Text('Temă întunecată'),
           subtitle: Text(themeProvider.currentThemeName),
           value: themeProvider.isDarkMode,
           onChanged: (value) {
             if (value) {
               themeProvider.setThemeMode(ThemeMode.dark);
             } else {
               themeProvider.setThemeMode(ThemeMode.light);
             }
           },
         );
       }
     },
   );
 }
}

/// Switch rapid pentru limba (RO/EN)
class LanguageToggleButton extends StatelessWidget {
 final bool isCompact;
 
 const LanguageToggleButton({
   super.key,
   this.isCompact = true,
 });

 @override
 Widget build(BuildContext context) {
   return Consumer<ThemeProvider>(
     builder: (context, themeProvider, child) {
       if (isCompact) {
         // Versiunea compactă pentru main menu
         return Container(
           padding: const EdgeInsets.all(8),
           decoration: BoxDecoration(
             color: Theme.of(context).cardColor,
             borderRadius: BorderRadius.circular(8),
             boxShadow: [
               BoxShadow(
                 color: Colors.black.withOpacity(0.1),
                 blurRadius: 4,
                 offset: const Offset(0, 2),
               ),
             ],
           ),
           child: InkWell(
             onTap: () => themeProvider.toggleLanguage(),
             borderRadius: BorderRadius.circular(8),
             child: Row(
               mainAxisSize: MainAxisSize.min,
               children: [
                 const Icon(
                   Icons.language,
                   size: 20,
                   color: Color(0xFF6B9B76),
                 ),
                 const SizedBox(width: 4),
                 Text(
                   themeProvider.languageCode.toUpperCase(),
                   style: TextStyle(
                     fontSize: 12,
                     fontWeight: FontWeight.w600,
                     color: Theme.of(context).textTheme.bodyLarge?.color,
                   ),
                 ),
               ],
             ),
           ),
         );
       } else {
         // Versiunea extinsă pentru settings
         return ListTile(
           leading: const Icon(Icons.language, color: Color(0xFF6B9B76)),
           title: const Text('Limba'),
           subtitle: Text(themeProvider.currentLanguageName),
           trailing: Row(
             mainAxisSize: MainAxisSize.min,
             children: [
               Text(
                 themeProvider.languageCode.toUpperCase(),
                 style: const TextStyle(
                   fontSize: 14,
                   color: Color(0xFF6B9B76),
                   fontWeight: FontWeight.w600,
                 ),
               ),
               const SizedBox(width: 8),
               const Icon(Icons.chevron_right, color: Colors.grey),
             ],
           ),
           onTap: () => _showLanguageDialog(context, themeProvider),
         );
       }
     },
   );
 }

 void _showLanguageDialog(BuildContext context, ThemeProvider themeProvider) {
   showDialog(
     context: context,
     builder: (context) => AlertDialog(
       title: const Text('Selectează limba'),
       content: Column(
         mainAxisSize: MainAxisSize.min,
         children: [
           RadioListTile<String>(
             title: const Text('Română'),
             value: 'ro',
             groupValue: themeProvider.languageCode,
             onChanged: (value) {
               if (value != null) {
                 themeProvider.setLanguage(value);
                 Navigator.pop(context);
               }
             },
             activeColor: const Color(0xFF6B9B76),
           ),
           RadioListTile<String>(
             title: const Text('English'),
             value: 'en',
             groupValue: themeProvider.languageCode,
             onChanged: (value) {
               if (value != null) {
                 themeProvider.setLanguage(value);
                 Navigator.pop(context);
               }
             },
             activeColor: const Color(0xFF6B9B76),
           ),
         ],
       ),
     ),
   );
 }
}

/// Widget combinat pentru quick settings în main menu
class QuickSettingsRow extends StatelessWidget {
 const QuickSettingsRow({super.key});

 @override
 Widget build(BuildContext context) {
   return Padding(
     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
     child: Row(
       mainAxisAlignment: MainAxisAlignment.end,
       children: [
         const ThemeToggleButton(),
         const SizedBox(width: 8),
         const LanguageToggleButton(),
         const SizedBox(width: 8),
         // Buton pentru Settings complete
         Container(
           padding: const EdgeInsets.all(8),
           decoration: BoxDecoration(
             color: Theme.of(context).cardColor,
             borderRadius: BorderRadius.circular(8),
             boxShadow: [
               BoxShadow(
                 color: Colors.black.withOpacity(0.1),
                 blurRadius: 4,
                 offset: const Offset(0, 2),
               ),
             ],
           ),
           child: InkWell(
             onTap: () {
               Navigator.pushNamed(context, '/settings');
             },
             borderRadius: BorderRadius.circular(8),
             child: const Icon(
               Icons.settings,
               size: 20,
               color: Color(0xFF6B9B76),
             ),
           ),
         ),
       ],
     ),
   );
 }
}

/// Floating Action Button pentru quick theme toggle
class ThemeToggleFAB extends StatelessWidget {
 const ThemeToggleFAB({super.key});

 @override
 Widget build(BuildContext context) {
   return Consumer<ThemeProvider>(
     builder: (context, themeProvider, child) {
       return FloatingActionButton.small(
         onPressed: () => themeProvider.toggleTheme(),
         backgroundColor: const Color(0xFF6B9B76),
         child: Icon(
           themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
           color: Colors.white,
         ),
       );
     },
   );
 }
}