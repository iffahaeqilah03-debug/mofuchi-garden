import 'package:flutter/material.dart';
import '../models/mood_entry.dart';

class AppState extends ChangeNotifier {
  static final AppState instance = AppState._internal();
  AppState._internal();

  final List<MoodEntry> _entries = [
    MoodEntry(
      id: '1',
      mood: 'Happy',
      intensity: 4,
      category: 'Academic',
      note: "I'm so happy today! We finished the project milestones early.",
      timestamp: DateTime(2026, 6, 16, 20, 30),
    ),
    MoodEntry(
      id: '2',
      mood: 'Surprise',
      intensity: 3,
      category: 'Family',
      note: 'Got a sudden pleasant surprise from home today.',
      timestamp: DateTime(2026, 6, 14, 19, 45),
    ),
  ];

  int _streakCount = 3;

  List<MoodEntry> get entries => List.unmodifiable(_entries);
  int get streakCount => _streakCount;

  void addEntry({
    required String mood,
    required int intensity,
    required String category,
    required String note,
    String? mediaPath,
    String? mediaType,
  }) {
    final formattedMood = mood.trim().isEmpty
        ? 'Happy'
        : mood.trim().substring(0, 1).toUpperCase() + mood.trim().substring(1).toLowerCase();

    final newEntry = MoodEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      mood: formattedMood,
      intensity: intensity,
      category: category.trim().isEmpty ? 'General' : category.trim(),
      note: note,
      mediaPath: mediaPath,
      mediaType: mediaType,
      timestamp: DateTime.now(),
    );

    _entries.insert(0, newEntry);
    _streakCount++;
    notifyListeners();
  }

  String get dominantMood {
    if (_entries.isEmpty) return 'Happy';
    final count = <String, int>{};
    for (var e in _entries) {
      final key = e.mood.trim();
      count[key] = (count[key] ?? 0) + 1;
    }
    var highestMood = _entries.first.mood;
    var maxVal = -1;
    count.forEach((moodName, countVal) {
      if (countVal > maxVal) {
        maxVal = countVal;
        highestMood = moodName;
      }
    });
    return highestMood;
  }

  String get dominantCategory {
    if (_entries.isEmpty) return 'Academic';
    final count = <String, int>{};
    for (var e in _entries) {
      final key = e.category.trim();
      count[key] = (count[key] ?? 0) + 1;
    }
    var topCategory = 'Academic';
    var maxVal = -1;
    count.forEach((cat, countVal) {
      if (countVal > maxVal) {
        maxVal = countVal;
        topCategory = cat;
      }
    });
    return topCategory;
  }

  double getMoodPercentage(String mood) {
    if (_entries.isEmpty) return 0.0;
    final matching = _entries
        .where((e) => e.mood.toLowerCase() == mood.toLowerCase())
        .length;
    return (matching / _entries.length) * 100;
  }
}