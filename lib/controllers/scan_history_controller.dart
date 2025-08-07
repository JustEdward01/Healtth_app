// controllers/scan_history_controller.dart
import 'package:flutter/material.dart';
import '../models/scan_history_entry.dart';
import '../services/local_storage_service.dart';

class ScanHistoryController with ChangeNotifier {
  final LocalStorageService _storage;
  List<ScanHistoryEntry> _entries = [];

  List<ScanHistoryEntry> get entries => _entries;

  ScanHistoryController(this._storage) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    _entries = await _storage.getScanHistory();
    notifyListeners();
  }

  Future<void> addEntry(ScanHistoryEntry entry) async {
    _entries.insert(0, entry);
    await _storage.saveScanHistory(_entries);
    notifyListeners();
  }

  Future<void> removeEntry(String id) async {
    _entries.removeWhere((entry) => entry.id == id);
    await _storage.saveScanHistory(_entries);
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _entries = [];
    await _storage.clearScanHistory();
    notifyListeners();
  }
}