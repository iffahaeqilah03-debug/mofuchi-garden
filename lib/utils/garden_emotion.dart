// Mofuchi Garden emotion categories, shared across check-in and garden UI.
// Surprise is intentionally treated as neutral for this prototype.
enum GardenEmotionCategory { positive, neutral, negative, unknown }

extension GardenEmotionCategoryLabel on GardenEmotionCategory {
  String get label => name[0].toUpperCase() + name.substring(1);
}

GardenEmotionCategory gardenEmotionCategory(String emotion) {
  switch (emotion.trim().toLowerCase()) {
    case 'happy':
      return GardenEmotionCategory.positive;
    case 'surprise':
      return GardenEmotionCategory.neutral;
    case 'sad':
    case 'angry':
    case 'fear':
    case 'disgust':
      return GardenEmotionCategory.negative;
    default:
      return GardenEmotionCategory.unknown;
  }
}

// All supported emotions count toward the weekly garden's unique-day progress.
bool countsForWeeklyBloom(String emotion) =>
    gardenEmotionCategory(emotion) != GardenEmotionCategory.unknown;

// Positive and neutral moods may use the gentle bloom visual after a NEW day.
bool usesGentleBloomVisual(String emotion) {
  final category = gardenEmotionCategory(emotion);
  return category == GardenEmotionCategory.positive ||
      category == GardenEmotionCategory.neutral;
}
