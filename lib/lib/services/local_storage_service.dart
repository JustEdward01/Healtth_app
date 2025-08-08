// services/local_storage_service.dart
import 'package:flutter/material.dart';
import '../models/scan_history_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocalStorageService {
  static const String _scanHistoryKey = 'scan_history';

  Future<List<ScanHistoryEntry>> getScanHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_scanHistoryKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => ScanHistoryEntry.fromMap(json)).toList();
    } catch (e) {
      debugPrint('Error parsing scan history: $e');
      return [];
    }
  }

  Future<void> saveScanHistory(List<ScanHistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = entries.map((entry) => entry.toMap()).toList();
    await prefs.setString(_scanHistoryKey, json.encode(jsonList));
  }

  Future<void> clearScanHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_scanHistoryKey);
  }
}