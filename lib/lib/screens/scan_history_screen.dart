import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';  // Now properly imported
import '../controllers/scan_history_controller.dart';
import '../models/scan_history_entry.dart';
import 'dart:io';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Istoric Scanări'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmClearHistory(context),
          ),
        ],
      ),
      body: Consumer<ScanHistoryController>(
        builder: (context, controller, child) {
          if (controller.entries.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Nicio scanare salvată încă',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: controller.entries.length,
            itemBuilder: (context, index) {
              final entry = controller.entries[index];
              return _buildHistoryItem(context, entry);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, ScanHistoryEntry entry) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetails(context, entry),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(entry.imagePath),
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.productName ?? 'Produs necunoscut',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.detectedAllergens.isNotEmpty
                          ? 'Alergeni: ${entry.detectedAllergens.join(', ')}'
                          : 'Niciun alergen detectat',
                      style: TextStyle(
                        color: entry.detectedAllergens.isNotEmpty
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(entry.timestamp),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.grey),
                onPressed: () => _confirmDelete(context, entry.id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, ScanHistoryEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(entry.imagePath),
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (entry.productName != null) ...[
                  Text(
                    entry.productName!,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (entry.barcode != null) ...[
                  Text('Cod bare: ${entry.barcode}'),
                  const SizedBox(height: 8),
                ],
                Text(
                  'Scanat la: ${DateFormat('dd MMM yyyy, HH:mm').format(entry.timestamp)}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Text(
                  entry.detectedAllergens.isNotEmpty
                      ? '⚠️ Alergeni detectați:'
                      : '✅ Nicio problemă detectată',
                  style: TextStyle(
                    fontSize: 18,
                    color: entry.detectedAllergens.isNotEmpty
                        ? Colors.red
                        : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (entry.detectedAllergens.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...entry.detectedAllergens.map(
                    (allergen) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Text(allergen),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Închide'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Șterge scanarea'),
        content: const Text('Ești sigur că vrei să ștergi această scanare?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anulează'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Șterge', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<ScanHistoryController>().removeEntry(id);
    }
  }

  Future<void> _confirmClearHistory(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Șterge tot istoricul'),
        content: const Text('Ești sigur că vrei să ștergi întregul istoric?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anulează'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Șterge tot', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<ScanHistoryController>().clearHistory();
    }
  }
}