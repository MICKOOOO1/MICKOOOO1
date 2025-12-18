import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ScanResult {
  final String beanType;
  final double confidence;
  final DateTime timestamp;
  final String? imagePath;

  ScanResult({
    required this.beanType,
    required this.confidence,
    required this.timestamp,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
        'beanType': beanType,
        'confidence': confidence,
        'timestamp': timestamp.toIso8601String(),
        'imagePath': imagePath,
      };

  factory ScanResult.fromJson(Map<String, dynamic> json) => ScanResult(
        beanType: json['beanType'],
        confidence: json['confidence'],
        timestamp: DateTime.parse(json['timestamp']),
        imagePath: json['imagePath'],
      );
}

class ScanHistory {
  static const String _key = 'scan_history';

  static Future<void> saveScan(ScanResult scan) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    history.insert(0, scan); // Add to beginning

    // Keep only last 50 scans
    if (history.length > 50) {
      history.removeRange(50, history.length);
    }

    final jsonList = history.map((s) => s.toJson()).toList();
    await prefs.setString(_key, jsonEncode(jsonList));
  }

  static Future<List<ScanResult>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return [];

    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => ScanResult.fromJson(json)).toList();
  }

  static Future<void> deleteScan(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    
    if (index >= 0 && index < history.length) {
      history.removeAt(index);
      final jsonList = history.map((s) => s.toJson()).toList();
      await prefs.setString(_key, jsonEncode(jsonList));
    }
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
