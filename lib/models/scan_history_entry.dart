// models/scan_history_entry.dart
class ScanHistoryEntry {
  final String id;
  final String imagePath;
  final List<String> detectedAllergens;
  final DateTime timestamp;
  final String? productName;
  final String? barcode;

  ScanHistoryEntry({
    required this.imagePath,
    required this.detectedAllergens,
    required this.timestamp,
    this.productName,
    this.barcode,
    String? id,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imagePath': imagePath,
      'detectedAllergens': detectedAllergens,
      'timestamp': timestamp.toIso8601String(),
      'productName': productName,
      'barcode': barcode,
    };
  }

  factory ScanHistoryEntry.fromMap(Map<String, dynamic> map) {
    return ScanHistoryEntry(
      id: map['id'],
      imagePath: map['imagePath'],
      detectedAllergens: List<String>.from(map['detectedAllergens']),
      timestamp: DateTime.parse(map['timestamp']),
      productName: map['productName'],
      barcode: map['barcode'],
    );
  }
}