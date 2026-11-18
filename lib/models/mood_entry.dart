class MoodEntry {
  final String id;
  final String mood; // 'Happy', 'Surprise', 'Sad', 'Angry', 'Disgust', 'Fear'
  final int intensity;
  final String category;
  final String note;
  final String? mediaPath;
  final String? mediaType;
  final DateTime timestamp;

  MoodEntry({
    required this.id,
    required this.mood,
    required this.intensity,
    required this.category,
    required this.note,
    this.mediaPath,
    this.mediaType,
    required this.timestamp,
  });

  String get emoji {
    switch (mood.toLowerCase()) {
      case 'happy':
        return '☀️';
      case 'surprise':
        return '⚡';
      case 'sad':
        return '🌧️';
      case 'angry':
        return '⛈️';
      case 'disgust':
        return '🍃';
      case 'fear':
        return '🌫️';
      default:
        return '🌱';
    }
  }
}