import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

// ignore: unused_import
import '../widgets/mofuchi_background.dart';
import 'checkin_screen.dart';
import 'garden_shop_screen.dart';
import '../main.dart' show MofuchiTheme;

const _ink = Color(0xFF30273C);
const _purple = Color(0xFF8060C6);
const _muted = Color(0xFF847A91);
const _sage = Color(0xFF67866A);
const _heroText = Color(0xFFFDFDFF);
// ignore: unused_element
const _heroMuted = Color(0xE6FFFFFF);
const _heroSoft = Color(0xCCFFFFFF);
// Full-bleed hero environment backgrounds. Keep these image files in
// assets/images/sky/ and declare that directory in pubspec.yaml.
const _emotionHeroBackgrounds = <String, String>{
  'happy': 'assets/images/sky/bg_happy_day.png',
  'sad': 'assets/images/sky/bg_sad_day.png',
  'angry': 'assets/images/sky/bg_angry_day.png',
  'surprise': 'assets/images/sky/bg_surprise_day.png',
  'disgust': 'assets/images/sky/bg_disgust_day.png',
  'fear': 'assets/images/sky/bg_fear_day.png',
};

// Display a suitable soft gradient until an emotion-specific image is added.
const _emotionHeroFallbacks = <String, List<Color>>{
  'happy': [Color(0xFF88C5F9), Color(0xFFF8E6CF)],
  'sad': [Color(0xFF586C9F), Color(0xFFD8D1EB)],
  'angry': [Color(0xFF743F5C), Color(0xFFE5A39C)],
  'surprise': [Color(0xFF8E9CE1), Color(0xFFF9C9E4)],
  'disgust': [Color(0xFF607568), Color(0xFFCDDAC6)],
  'fear': [Color(0xFF7581A5), Color(0xFFE4DDED)],
};

const _weatherAssets = <String, String>{
  'happy': 'assets/images/weather_img/weather_sun.png',
  'surprise': 'assets/images/weather_img/weather_surprised_rainbow.png',
  'sad': 'assets/images/weather_img/weather_rain.png',
  'angry': 'assets/images/weather_img/weather_thunder.png',
  'disgust': 'assets/images/weather_img/weather_gloomy.png',
  'fear': 'assets/images/weather_img/weather_foggy.png',
};


// Rebuild the Image widget when Firestore's latest emotion changes.
// A missing PNG shows a clear message instead of silently retaining the old sky.
class _EmotionHeroImage extends StatelessWidget {
  final String mood;
  const _EmotionHeroImage({required this.mood});

  @override
  Widget build(BuildContext context) {
    final normalized = mood.trim().toLowerCase();
    final path = _emotionHeroBackgrounds[normalized] ??
        _emotionHeroBackgrounds['happy']!;

    final treatment = _heroImageTreatment(normalized);

    Widget child = Image.asset(
      path,
      key: ValueKey<String>('emotion-sky-$path'),
      fit: BoxFit.cover,
      alignment: treatment.alignment,
      gaplessPlayback: false,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('MOFUCHI SKY ERROR: $path -> $error');
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _emotionHeroFallbacks[normalized] ??
                  _emotionHeroFallbacks['happy']!,
            ),
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 7, left: 18, right: 18),
                child: Text(
                  'Sky image missing: $path',
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF542F43),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (treatment.blurSigma > 0) {
      child = ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: treatment.blurSigma,
          sigmaY: treatment.blurSigma,
        ),
        child: child,
      );
    }

    if (treatment.colorFilter != null) {
      child = ColorFiltered(colorFilter: treatment.colorFilter!, child: child);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(opacity: treatment.opacity, child: child),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: treatment.overlayColors,
              stops: const [0.0, 0.52, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroImageTreatment {
  final double opacity;
  final double blurSigma;
  final Alignment alignment;
  final List<Color> overlayColors;
  final ColorFilter? colorFilter;
  const _HeroImageTreatment({
    required this.opacity,
    required this.blurSigma,
    required this.alignment,
    required this.overlayColors,
    this.colorFilter,
  });
}

_HeroImageTreatment _heroImageTreatment(String mood) {
  switch (mood) {
    case 'angry':
      return const _HeroImageTreatment(
        opacity: 0.73,
        blurSigma: 1.6,
        alignment: Alignment.topCenter,
        overlayColors: [
          Color(0x66452C53),
          Color(0x3D82638B),
          Color(0x00FFFFFF),
        ],
      );
    case 'surprise':
      return const _HeroImageTreatment(
        opacity: 0.76,
        blurSigma: 1.3,
        alignment: Alignment.topCenter,
        overlayColors: [
          Color(0x54FFFFFF),
          Color(0x26F4E8FF),
          Color(0x00FFFFFF),
        ],
      );
    case 'disgust':
      return _HeroImageTreatment(
        opacity: 0.72,
        blurSigma: 1.8,
        alignment: Alignment.topCenter,
        overlayColors: const [
          Color(0x4EEDF2EC),
          Color(0x32DDE6DA),
          Color(0x00FFFFFF),
        ],
        colorFilter: const ColorFilter.matrix(<double>[
          0.72, 0.20, 0.08, 0, 0,
          0.16, 0.70, 0.14, 0, 0,
          0.14, 0.22, 0.64, 0, 0,
          0, 0, 0, 1, 0,
        ]),
      );
    case 'fear':
      return const _HeroImageTreatment(
        opacity: 0.84,
        blurSigma: 0.8,
        alignment: Alignment.topCenter,
        overlayColors: [
          Color(0x22F7F7FF),
          Color(0x0FE5E1F1),
          Color(0x00FFFFFF),
        ],
      );
    case 'sad':
      return const _HeroImageTreatment(
        opacity: 0.9,
        blurSigma: 0.0,
        alignment: Alignment.topCenter,
        overlayColors: [
          Color(0x120B0F35),
          Color(0x09FFFFFF),
          Color(0x00FFFFFF),
        ],
      );
    default:
      return const _HeroImageTreatment(
        opacity: 0.92,
        blurSigma: 0.0,
        alignment: Alignment.topCenter,
        overlayColors: [
          Color(0x0FFFFFFF),
          Color(0x06FFFFFF),
          Color(0x00FFFFFF),
        ],
      );
  }
}

class HomeScreen extends StatefulWidget {
  final VoidCallback? onOpenDashboard;
  const HomeScreen({super.key, this.onOpenDashboard});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late DateTime _currentNow;
  Timer? _clockTimer;

  void _refreshClock() {
    if (!mounted) return;
    final fresh = DateTime.now();
    if (fresh.year != _currentNow.year ||
        fresh.month != _currentNow.month ||
        fresh.day != _currentNow.day ||
        fresh.hour != _currentNow.hour ||
        fresh.minute != _currentNow.minute) {
      setState(() => _currentNow = fresh);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshClock();
  }

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _logs;

  // Home appearance follows the app-wide saved setting.
  // Never keep another local _darkMode value: it would reset when Home rebuilds.
  // Read the same persisted global theme used by MaterialApp.
  bool get _darkMode => MofuchiTheme.isDark;
  Color get _surface => _darkMode ? const Color(0xFF211D2B) : Colors.white;
  Color get _contentInk => _darkMode ? const Color(0xFFF8F5FF) : _ink;
  Color get _contentMuted => _darkMode ? const Color(0xFFC2B9D0) : _muted;
  Color get _contentSage => _darkMode ? const Color(0xFFB5C9B4) : _sage;
  Color get _contentPurple => _darkMode ? const Color(0xFFBDA5F1) : _purple;


  @override
  void initState() {
    super.initState();
    _currentNow = DateTime.now();
    WidgetsBinding.instance.addObserver(this);
    _clockTimer = Timer.periodic(const Duration(seconds: 15), (_) => _refreshClock());
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _logs = FirebaseFirestore.instance
        .collection('emotion_logs')
        .where('userId', isEqualTo: uid)
        .snapshots();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  DateTime _date(DateTime d) => DateTime(d.year, d.month, d.day);

  List<_HomeLog> _parse(QuerySnapshot<Map<String, dynamic>> result) {
    final logs = <_HomeLog>[];
    for (final doc in result.docs) {
      final data = doc.data();
      final mood = (data['emotion'] as String? ?? '').trim().toLowerCase();
      final time = data['createdAt'];
      if (!_weatherAssets.containsKey(mood) || time is! Timestamp) continue;
      final intensity = (data['intensity'] as num?)?.toInt();
      logs.add(_HomeLog(
        mood: mood,
        timestamp: time.toDate().toLocal(),
        intensity: intensity != null && intensity >= 1 && intensity <= 5
            ? intensity : null,
        category: (data['eventCategory'] as String?)?.trim() ?? '',
      ));
    }
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs;
  }

  int _streak(Set<DateTime> days, DateTime today) {
    // An ongoing streak includes yesterday if today's check-in is pending.
    var cursor = days.contains(today)
        ? today
        : today.subtract(const Duration(days: 1));
    var count = 0;
    while (days.contains(cursor)) {
      count++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }

  String _title(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

  String _greeting(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _shortDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}';
  }

  String _timeLabel(DateTime date) {
    final local = date.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minutes = local.minute.toString().padLeft(2, '0');
    return '$hour:$minutes ${local.hour >= 12 ? 'PM' : 'AM'}';
  }

  String _dominant(List<_HomeLog> logs) {
    if (logs.isEmpty) return '';
    final counts = <String, int>{};
    for (final log in logs) {
      counts[log.mood] = (counts[log.mood] ?? 0) + 1;
    }
    final ranked = counts.entries.toList()
      ..sort((a, b) {
        final difference = b.value.compareTo(a.value);
        return difference != 0 ? difference : a.key.compareTo(b.key);
      });
    return ranked.first.key;
  }

  Widget _card({required Widget child, EdgeInsets? padding}) => Container(
    padding: padding ?? const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: _darkMode ? const Color(0xFF41394E) : const Color(0xFFF1EDF7)),
      boxShadow: [BoxShadow(
        color: Colors.black.withValues(alpha: _darkMode ? 0.20 : 0.06),
        blurRadius: 18,
        offset: const Offset(0, 6),
      )],
    ),
    child: child,
  );

  Widget _weather(String mood, double size) => Image.asset(
    _weatherAssets[mood]!,
    width: size,
    height: size,
    fit: BoxFit.contain,
    errorBuilder: (_, _, _) => Icon(Icons.cloud_outlined,
        size: size * .65, color: _purple),
  );

  bool _checkInOpening = false;

  Future<void> _checkIn() async {
    if (_checkInOpening || !mounted) return;
    _checkInOpening = true;
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const CheckInScreen()),
      );
    } finally {
      _checkInOpening = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please sign in to visit your garden.'));
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _logs,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Could not load your garden.\n${snapshot.error}',
              textAlign: TextAlign.center));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _purple));
        }
        final now = _currentNow;
        // Display the first name saved in Firebase Auth during registration.
        // Never infer a name from the email address.
        final fullName = user.displayName?.trim() ?? '';
        final firstName = fullName.isEmpty ? '' : fullName.split(RegExp(r'\s+')).first;
        final today = _date(now);
        final logs = _parse(snapshot.data!);
        final days = logs.map((e) => _date(e.timestamp)).toSet();
        final checkedInToday = days.contains(today);
        final streak = _streak(days, today);
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 7));
        final weekLogs = logs.where((log) =>
          !log.timestamp.isBefore(weekStart) && log.timestamp.isBefore(weekEnd)).toList();
        // 1 bloom stage per unique check-in day (any emotion), max 7 per week.
        // This currently drives the Flutter progress display. The GLB animations
        // are separate clips and need a cumulative animation setup before they
        // can accurately represent this progress inside the 3D scene.
        final bloomLevel = weekLogs.map((log) => _date(log.timestamp)).toSet().length;
        final dominant = _dominant(weekLogs);
        final latest = logs.isEmpty ? null : logs.first;
        final positive = weekLogs.where((e) => e.mood == 'happy').length;
        final categoryCounts = <String, int>{};
        for (final log in weekLogs) {
          if (log.category.isNotEmpty) {
            categoryCounts[log.category] = (categoryCounts[log.category] ?? 0) + 1;
          }
        }
        final rankedCategories = categoryCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final commonCategory = rankedCategories.isEmpty ? '' : rankedCategories.first.key;

        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: _darkMode ? const Color(0xFF151321) : const Color(0xFFF5F4F8)),
            // The hero background sits BEHIND the greeting and Sakura Garden.
            // It starts at the top of the available HomeScreen viewport.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 1040,
              child: IgnorePointer(
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,
                      Colors.white,
                      Colors.white,
                      Colors.transparent,
                    ],
                    stops: [0, 0.50, 0.74, 1],
                  ).createShader(bounds),
                  child: _EmotionHeroImage(
                    mood: latest?.mood ?? 'happy',
                  ),
                ),
              ),
            ),
            // Weather effect stays behind the content so text/cards remain readable.
            // It only needs to cover the hero area around the greeting and 3D garden.
            if (latest != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 620,
                child: IgnorePointer(
                  child: ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (bounds) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white,
                        Colors.white,
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.78, 1.0],
                    ).createShader(bounds),
                    child: _buildFullHeroWeather(latest.mood),
                  ),
                ),
              ),
            if (_darkMode)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 1040,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0x350D0B24),
                    ),
                  ),
                ),
              ),
            // Cinematic contrast veil behind HERO typography only.
            // Weather remains behind foreground content and stays visible.
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 355,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x8D171321),
                        Color(0x50171321),
                        Color(0x00171321),
                      ],
                      stops: [0.0, 0.56, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
              children: [
                // Gently floating butterfly, isolated from Home's Firestore rebuilds.
                const Center(child: _FloatingHomeButterfly()),
                const SizedBox(height: 15),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0x24FFFFFF),
                      border: Border.all(color: const Color(0x50FFFFFF), width: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_shortDate(now).toUpperCase()} • ${_timeLabel(now)}',
                      style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w700,
                        color: _heroText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        '${_greeting(now.hour)}${firstName.isEmpty ? '' : ', $firstName'} 🌷',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 25,
                          height: 1.22,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          color: _heroText,
                          shadows: [Shadow(color: Color(0x66000000), blurRadius: 14)],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Semantics(
                      button: true,
                      label: _darkMode ? 'Switch to light mode' : 'Switch to dark mode',
                      child: Tooltip(
                        message: _darkMode ? 'Light mode' : 'Dark mode',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            key: const ValueKey('mofuchi-theme-toggle'),
                            onTap: () {
                              MofuchiTheme.toggle();
                            },
                            borderRadius: BorderRadius.circular(30),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _darkMode
                                    ? const Color(0x66504B7D)
                                    : const Color(0x33FFFFFF),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0x80FFFFFF)),
                                boxShadow: const [
                                  BoxShadow(color: Color(0x25000000), blurRadius: 12),
                                ],
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: Icon(
                                  _darkMode ? Icons.wb_sunny_rounded : Icons.dark_mode_rounded,
                                  key: ValueKey(_darkMode),
                                  color: Colors.white,
                                  size: 23,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Welcome back to your little garden.',
                    style: TextStyle(fontSize: 12, color: _heroSoft,
                        shadows: [Shadow(color: Color(0x55000000), blurRadius: 10)])),
                const SizedBox(height: 17),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                  child: Column(children: [
                    Row(children: [
                      const Icon(Icons.spa_outlined, size: 18, color: _heroText),
                      const SizedBox(width: 7),
                      const Expanded(child: Text('Your Sakura Garden',
                          style: TextStyle(fontWeight: FontWeight.w700,
                              color: _heroText, fontSize: 16,
                              shadows: [Shadow(color: Color(0x66000000), blurRadius: 12)]))),
                      _GardenShopAccess(uid: user.uid),
                    ]),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('${weekLogs.length} moments this week',
                        style: const TextStyle(color: _heroText, fontSize: 10,
                          fontWeight: FontWeight.w500,
                          shadows: [Shadow(color: Color(0x55000000), blurRadius: 8)])),
                    ),
                    const SizedBox(height: 8),
                    // Live XP / Gardener Level shown immediately above the 3D garden.
                    _GardenXpHeader(uid: user.uid),
                    const SizedBox(height: 10),
                    // No rounded garden card or local weather box:
                    // the 3D island floats directly over the emotion hero sky.
                    SizedBox(
                      width: double.infinity,
                      height: 365,
                      // Lift only the 3D garden slightly without moving the
                      // title, XP header, or the rest of the Home layout.
                      child: Transform.translate(
                        offset: const Offset(0, -18),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _BloomDiagnosticGarden(
                              firebaseLevel: bloomLevel,
                              mood: latest?.mood ?? '',
                              onGardenTap: _checkIn,
                            ),
                            // Flutter-only mood details sit within the 3D
                            // garden viewport. They never intercept taps or
                            // horizontal rotation gestures on the GLB.
                            if (latest != null)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: _GardenMoodAccent(mood: latest.mood),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 0),
                    // Transparent CTA with a subtle shadow (light/dark aware).
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                        decoration: BoxDecoration(
                          color: _darkMode
                              ? const Color(0x22FFFFFF)
                              : const Color(0x26FFFFFF),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0x80FFFFFF)),
                          boxShadow: [BoxShadow(
                            color: Colors.black.withValues(alpha: 0.13),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          )],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.touch_app_rounded,
                                color: _darkMode ? Colors.white : const Color(0xFF493660), size: 17),
                            const SizedBox(width: 7),
                            Flexible(child: Text(
                              'Tap the garden to reflect',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _darkMode ? Colors.white : const Color(0xFF493660),
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                shadows: const [Shadow(color: Color(0x88FFFFFF), blurRadius: 8)],
                              ),
                            )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // No solid card; shadows keep the overlay legible on bright skies.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Weekly bloom progress',
                          style: TextStyle(
                            color: _darkMode ? Colors.white : const Color(0xFF382E52),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            shadows: const [
                              Shadow(color: Color(0xDDFFFFFF), blurRadius: 8),
                              Shadow(color: Color(0x66000000), blurRadius: 15, offset: Offset(0, 2)),
                            ],
                          )),
                        Text('$bloomLevel / 7 days',
                          style: TextStyle(
                            color: _darkMode ? Colors.white : const Color(0xFF382E52),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            shadows: const [
                              Shadow(color: Color(0xDDFFFFFF), blurRadius: 8),
                              Shadow(color: Color(0x66000000), blurRadius: 15, offset: Offset(0, 2)),
                            ],
                          )),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: [BoxShadow(
                          color: Colors.black.withValues(alpha: 0.20),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        )],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: bloomLevel / 7.0,
                          minHeight: 6,
                          color: _darkMode ? const Color(0xFFD6B3FF) : _purple,
                          backgroundColor: const Color(0xCCFFFFFF),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      bloomLevel == 0
                        ? 'Your first check-in this week starts the bloom journey.'
                        : bloomLevel == 7
                          ? 'Seven days of showing up for yourself. 🌸'
                          : 'Each day you check in helps your weekly garden grow.',
                      style: TextStyle(
                        color: _darkMode ? Colors.white : const Color(0xFF493660),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        shadows: const [
                          Shadow(color: Color(0xEEFFFFFF), blurRadius: 9),
                          Shadow(color: Color(0x44000000), blurRadius: 12),
                        ],
                      ),
                    ),
                    if (bloomLevel == 3 || bloomLevel == 7)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          bloomLevel == 7
                              ? '🏵️ Weekly bloom milestone reached!'
                              : '🌷 Three bloom days — a lovely milestone!',
                          style: const TextStyle(color: _heroText,
                              fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                  ]),
                ),
                _card(child: Row(children: [
                  SizedBox(width: 88, height: 96,
                      child: latest == null
                          ? Icon(Icons.cloud_outlined, size: 56, color: _contentPurple)
                          : _weather(latest.mood, 90)),
                  SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('YOUR LATEST WEATHER', style: TextStyle(
                          fontSize: 10, letterSpacing: .6,
                          fontWeight: FontWeight.w700, color: _contentMuted)),
                      SizedBox(height: 5),
                      Text(latest == null ? 'No check-ins yet' : _title(latest.mood),
                          style: TextStyle(fontSize: 19,
                              fontWeight: FontWeight.w700, color: _contentInk)),
                      SizedBox(height: 3),
                      Text(latest == null
                          ? 'A little check-in starts your journey.'
                          : '${_shortDate(latest.timestamp)} • ${_timeLabel(latest.timestamp)}  •  Intensity ${latest.intensity?.toString() ?? '—'}/5',
                          style: TextStyle(color: _contentMuted, fontSize: 11)),
                      SizedBox(height: 8),
                      Text(checkedInToday ? '🌸 You checked in today!' : '🌱 How are you feeling today?',
                          style: TextStyle(fontSize: 11, color: _contentSage)),
                    ],
                  )),
                ])),
                // DAILY GARDEN QUEST — computed from the same Firestore logs
                // as Home, Dashboard and History. Any emotion counts.
                const SizedBox(height: 13),
                _card(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(checkedInToday
                          ? Icons.task_alt_rounded
                          : Icons.flag_outlined,
                          color: checkedInToday ? _contentSage : _contentPurple,
                          size: 24),
                      const SizedBox(width: 9),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DAILY GARDEN QUEST', style: TextStyle(
                            fontSize: 10, letterSpacing: 1.1,
                            fontWeight: FontWeight.w700, color: _contentMuted)),
                          const SizedBox(height: 3),
                          Text(checkedInToday
                              ? 'Quest completed! 🌸'
                              : 'Reflect on your feelings',
                            style: TextStyle(fontSize: 16,
                              fontWeight: FontWeight.w700, color: _contentInk)),
                        ],
                      )),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _darkMode ? const Color(0xFF413452) : const Color(0xFFF2EAFB),
                          borderRadius: BorderRadius.circular(99)),
                        child: Text(checkedInToday ? '1 / 1' : '0 / 1',
                          style: TextStyle(color: _contentPurple,
                            fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: checkedInToday ? 1 : 0,
                        minHeight: 8,
                        color: const Color(0xFF8060C6),
                        backgroundColor: _darkMode
                            ? const Color(0xFF50455D)
                            : const Color(0xFFECE5F4),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(checkedInToday
                        ? 'Thank you for showing up for yourself today. '
                          'Every emotion belongs here. 💜'
                        : 'Complete one check-in today to nurture your Sakura. '
                          'There is no right or wrong emotion.',
                      style: TextStyle(fontSize: 11, height: 1.5,
                        color: _contentMuted)),
                    if (!checkedInToday) ...[
                      const SizedBox(height: 12),
                      SizedBox(width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _checkIn,
                          icon: const Icon(Icons.edit_note_rounded, size: 18),
                          label: const Text('Start today’s reflection'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _contentPurple,
                            side: BorderSide(color: _contentPurple.withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13)),
                          ),
                        ),
                      ),
                    ],
                  ],
                )),
                const SizedBox(height: 13),
                if (!checkedInToday) ...[
                  const SizedBox(height: 13),
                  SizedBox(
                    height: 51,
                    child: ElevatedButton.icon(
                      onPressed: _checkIn,
                      icon: const Icon(Icons.edit_note_rounded),
                      label: const Text('Check in with your feelings'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 13),
                _card(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.local_fire_department_rounded,
                          color: Color(0xFFE6A05B), size: 23),
                      SizedBox(width: 7),
                      Expanded(child: Text('Your Garden Streak',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                              color: _contentInk))),
                      Text('$streak ${streak == 1 ? 'day' : 'days'}',
                          style: TextStyle(fontSize: 17,
                              color: _contentPurple, fontWeight: FontWeight.bold)),
                    ]),
                    SizedBox(height: 5),
                    Text(checkedInToday
                        ? 'You have nurtured your garden today. 🌸'
                        : streak > 0
                            ? 'A little check-in today can continue your streak.'
                            : 'Your next check-in can start a new streak.',
                        style: TextStyle(fontSize: 11, color: _contentMuted)),
                    SizedBox(height: 16),
                    Row(children: List.generate(7, (index) {
                      final day = weekStart.add(Duration(days: index));
                      final done = days.contains(day);
                      final isToday = day == today;
                      const names = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                      return Expanded(child: Column(children: [
                        Text(names[index],
                            style: TextStyle(fontSize: 10, color: _contentMuted)),
                        SizedBox(height: 6),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 34, height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: done ? (_darkMode ? const Color(0xFF4A3658) : const Color(0xFFF8E5F3)) : _surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: isToday
                                ? _purple : (_darkMode ? const Color(0xFF5D526A) : const Color(0xFFEDE7F2)), width: isToday ? 2 : 1),
                          ),
                          child: Text(done ? '🌸' : '🌱',
                              style: TextStyle(fontSize: 15)),
                        ),
                      ]));
                    })),
                    SizedBox(height: 9),
                    Text('One or more check-ins on the same day count as one streak day.',
                        style: TextStyle(fontSize: 10, color: _contentMuted)),
                  ],
                )),
                SizedBox(height: 13),
                _card(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text('🌷 Your week in bloom',
                          style: TextStyle(fontSize: 16, color: _contentInk,
                              fontWeight: FontWeight.w700))),
                      TextButton(
                        onPressed: widget.onOpenDashboard,
                        child: Text('View dashboard →',
                            style: TextStyle(fontSize: 11, color: _contentPurple)),
                      ),
                    ]),
                    SizedBox(height: 7),
                    if (weekLogs.isEmpty)
                      Text('Your weekly story is waiting for its first check-in.',
                          style: TextStyle(fontSize: 12, color: _contentMuted))
                    else ...[
                      Text('You recorded ${weekLogs.length} ${weekLogs.length == 1 ? 'feeling' : 'feelings'} this week. '
                          '${_title(dominant)} was your most recorded emotion.',
                          style: TextStyle(fontSize: 12, height: 1.5, color: _contentInk)),
                      SizedBox(height: 7),
                      Text(positive > weekLogs.length / 2
                          ? 'Uplifting moments appeared more often. Notice what helped create them. 🌼'
                          : 'Every feeling matters. Take a moment to notice what supported you. 🌱',
                          style: TextStyle(fontSize: 11, color: _contentSage)),
                      if (commonCategory.isNotEmpty) ...[
                        SizedBox(height: 7),
                        Text('Most common category: $commonCategory',
                            style: TextStyle(fontSize: 11, color: _contentMuted)),
                      ],
                    ],
                  ],
                )),
              ],
            ),
          ),
          ],
        );
      },
    );
  }
}

/// Live garden coin balance and a direct entry point to Garden Shop.
/// This is a separate Firestore listener: changing coin balance does not
/// require changing the Sakura ModelViewer or its bloom synchronization.
class _GardenShopAccess extends StatelessWidget {
  final String uid;
  const _GardenShopAccess({required this.uid});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('gamification_progress').doc(uid).snapshots(),
        builder: (context, snapshot) {
          final raw = snapshot.data?.data()?['coinBalance'];
          final coins = raw is num ? math.max(0, raw.toInt()) : 0;
          return Tooltip(
            message: snapshot.hasError
                ? 'Could not load coins'
                : '$coins Garden Coins',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0x38FFFFFF),
                border: Border.all(color: const Color(0x80FFFFFF)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.monetization_on_rounded,
                    color: Color(0xFFFFDF85), size: 17),
                const SizedBox(width: 4),
                Text(snapshot.hasError ? '—' : '$coins',
                    style: const TextStyle(color: Colors.white, fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          );
        },
      ),
      const SizedBox(width: 7),
      Tooltip(
        message: 'Open Garden Shop',
        child: Material(
          color: const Color(0x44FFFFFF),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            key: const ValueKey('open-garden-shop'),
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const GardenShopScreen(),
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.all(9),
              child: Icon(Icons.storefront_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    ]);
  }
}

/// Compact Gardener Level header, reading the existing XP progress document.
/// No XP is awarded here: points are handled by the check-in service.
class _GardenXpHeader extends StatelessWidget {
  final String uid;
  const _GardenXpHeader({required this.uid});

  static const _levels = <({int xp, String name})>[
    (xp: 0, name: 'Little Sprout'),
    (xp: 50, name: 'Growing Bud'),
    (xp: 120, name: 'Blooming Heart'),
    (xp: 220, name: 'Sakura Keeper'),
    (xp: 350, name: 'Garden Guardian'),
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('gamification_progress')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        final raw = snapshot.data?.data()?['totalXp'];
        final xp = raw is num ? math.max(0, raw.toInt()) : 0;
        var levelIndex = 0;
        for (var i = 1; i < _levels.length; i++) {
          if (xp >= _levels[i].xp) levelIndex = i;
        }
        final current = _levels[levelIndex];
        final next = levelIndex + 1 < _levels.length
            ? _levels[levelIndex + 1]
            : null;
        final progress = next == null
            ? 1.0
            : ((xp - current.xp) / (next.xp - current.xp))
                .clamp(0.0, 1.0);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0x30FFFFFF)
                : const Color(0x77FFFFFF),
            border: Border.all(color: const Color(0xCCFFFFFF), width: 1.3),
            borderRadius: BorderRadius.circular(17),
            boxShadow: const [BoxShadow(
              color: Color(0x27000000), blurRadius: 17, offset: Offset(0, 5),
            )],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.spa_rounded, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF634580), size: 19),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Level ${levelIndex + 1} · ${current.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF382C50),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('$xp XP',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF382C50),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    )),
              ]),
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor: const Color(0xBFFFFFFF),
                  color: const Color(0xFF8060C6),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                snapshot.hasError
                    ? 'XP unavailable — check Firestore access.'
                    : next == null
                        ? 'Highest Gardener Level reached 🌸'
                        : '${next.xp - xp} XP until ${next.name}',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF493660), fontSize: 10,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Effects fill the complete hero background, not only the 3D viewport.
// Disgust has its matching green-grey environment image already; animated
// floating leaves can be added independently in a later weather pass.
Widget _buildFullHeroWeather(String mood) {
  switch (mood.trim().toLowerCase()) {
    case 'sad':
      return const _GentleRainOverlay();
    case 'happy':
      return const _SunnySparkleOverlay();
    case 'surprise':
      return const _RainbowBreezeOverlay();
    case 'angry':
      return const _ThunderstormOverlay();
    case 'fear':
      return const _DriftingFogOverlay();
    default:
      return const SizedBox.expand();
  }
}

// Home Sakura Garden: accumulated bloom pose with horizontal-only rotation.
// A short stationary tap opens Check-in. Horizontal drags are never intercepted.
class _BloomDiagnosticGarden extends StatefulWidget {
  final int firebaseLevel;
  final String mood;
  final VoidCallback onGardenTap;
  const _BloomDiagnosticGarden({
    required this.firebaseLevel,
    required this.mood,
    required this.onGardenTap,
  });

  @override
  State<_BloomDiagnosticGarden> createState() => _BloomDiagnosticGardenState();
}

class _BloomDiagnosticGardenState extends State<_BloomDiagnosticGarden> {
  WebViewController? _web;
  Timer? _poll;
  int _attempts = 0;
  bool _busy = false;
  DateTime? _lastGardenTap;

  void _handleGardenTap(JavaScriptMessage message) {
    if (!mounted || message.message != 'tap') return;
    final now = DateTime.now();
    if (_lastGardenTap != null &&
        now.difference(_lastGardenTap!) < const Duration(milliseconds: 800)) {
      return;
    }
    _lastGardenTap = now;
    widget.onGardenTap();
  }

  int get _requestedLevel => widget.firebaseLevel.clamp(0, 7);

  @override
  void didUpdateWidget(covariant _BloomDiagnosticGarden oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.firebaseLevel != widget.firebaseLevel ||
        oldWidget.mood != widget.mood) {
      _startSync();
    }
  }

  void _onWebViewCreated(WebViewController controller) {
    _web = controller;
    // Receive taps from inside the WebView without covering its drag gestures.
    controller.addJavaScriptChannel(
      'MofuchiGardenTap',
      onMessageReceived: _handleGardenTap,
    );
    _startSync();
  }

  void _startSync() {
    _poll?.cancel();
    if (_web == null) return;
    _attempts = 0;
    // The WebView is first created before the embedded HTML and GLB finish loading.
    _poll = Timer.periodic(const Duration(milliseconds: 700), (_) => _syncPose());
    _syncPose();
  }

  Future<void> _syncPose() async {
    final web = _web;
    if (web == null || !mounted || _busy) return;
    if (_attempts >= 35) {
      _poll?.cancel();
      return; // Keep the last informative status visible.
    }
    _attempts++;
    _busy = true;
    try {
      final level = _requestedLevel;
      // Keep the model-viewer background transparent to reveal the hero sky.
      const sky = 'transparent';
      final result = await web.runJavaScriptReturningResult('''
        (() => {
          try {
            // In some versions, model-viewer is placed in a same-origin frame.
            let model = document.querySelector('model-viewer');
            let location = 'main';
            if (!model) {
              for (const frame of document.querySelectorAll('iframe')) {
                try {
                  const nested = frame.contentDocument?.querySelector('model-viewer');
                  if (nested) { model = nested; location = 'iframe'; break; }
                } catch (e) { /* cross-origin frames are inaccessible */ }
              }
            }
            if (!model) {
              return 'WAIT|NO_ELEMENT|frames=' + document.querySelectorAll('iframe').length;
            }
            // Give model-viewer an actual CSS sky BACKGROUND, not a tint
            // painted over the sakura. Also style the containing document.
            const sky = '$sky';
            model.style.setProperty('background', sky, 'important');
            model.style.setProperty('background-image', 'none', 'important');
            model.style.setProperty('background-color', 'transparent', 'important');
            model.style.setProperty('display', 'block');
            // User can rotate horizontally only. Zoom, vertical tilt and
            // panning are disabled by ModelViewer camera constraints below.
            // After a short idle period, glide back to the original front view.
            // Install listeners only once, even when Flutter re-syncs bloom.
            if (!model.__mofuchiCameraReady) {
              model.__mofuchiCameraReady = true;
              model.addEventListener('camera-change', (event) => {
                if (event.detail?.source !== 'user-interaction') return;
                clearTimeout(model.__mofuchiResetTimer);
                model.__mofuchiResetTimer = setTimeout(() => {
                  if (!model.isConnected) return;
                  const orbit = model.getCameraOrbit();
                  // First store the current camera position so the next
                  // attribute update interpolates smoothly instead of snapping.
                  model.cameraOrbit = orbit.toString();
                  requestAnimationFrame(() => {
                    if (model.isConnected) model.cameraOrbit = '0deg 75deg 108%';
                  });
                }, 2600);
              });
            }
            // Install passive pointer observers on the 3D viewer itself.
            // No preventDefault/stopPropagation: horizontal dragging continues
            // to work. A pointer must be quick and virtually stationary to tap.
            if (!model.__mofuchiTapReady) {
              model.__mofuchiTapReady = true;
              const touch = { active: false, moved: false, multitouch: false,
                              id: null, x: 0, y: 0, started: 0 };
              model.addEventListener('pointerdown', (event) => {
                if (touch.active || !event.isPrimary) {
                  touch.multitouch = true;
                  return;
                }
                touch.active = true;
                touch.moved = false;
                touch.multitouch = false;
                touch.id = event.pointerId;
                touch.x = event.clientX;
                touch.y = event.clientY;
                touch.started = performance.now();
              }, { passive: true, capture: true });
              model.addEventListener('pointermove', (event) => {
                if (!touch.active || event.pointerId !== touch.id) return;
                if (Math.hypot(event.clientX - touch.x,
                               event.clientY - touch.y) > 12) touch.moved = true;
              }, { passive: true, capture: true });
              model.addEventListener('pointerup', (event) => {
                if (!touch.active || event.pointerId !== touch.id) return;
                const distance = Math.hypot(event.clientX - touch.x,
                                            event.clientY - touch.y);
                const tapped = !touch.moved && !touch.multitouch &&
                  distance <= 12 && performance.now() - touch.started <= 450;
                touch.active = false;
                if (!tapped) return;
                try {
                  const bridge = model.ownerDocument?.defaultView?.MofuchiGardenTap ||
                    window.MofuchiGardenTap;
                  bridge?.postMessage('tap');
                } catch (_) { /* gesture should never break 3D viewing */ }
              }, { passive: true, capture: true });
              model.addEventListener('pointercancel', () => {
                touch.active = false;
              }, { passive: true, capture: true });
            }
            if (model.ownerDocument?.body) {
              model.ownerDocument.body.style.background = 'transparent';
            }
            const list = Array.from(model.availableAnimations || []);
            if (!model.loaded) return 'WAIT|NOT_LOADED|' + location;
            if (list.length === 0) return 'WAIT|NO_CLIPS|' + location;

            // The uploaded GLB contains two independent clips: bloom scales
            // and real 3D falling-petal movement. The companion GLB bundles
            // 8 combined clips so the week-stage bloom does not reset while
            // the 3D petals animate.
            const clamped = Math.min(7, Math.max(0, $level));
            const mood = '${widget.mood.trim().toLowerCase()}';
            const negative = ['sad', 'angry', 'fear', 'disgust'].includes(mood);
            const desired = negative
              ? 'Negative_PetalFall_Stage_' + clamped
              : 'Animation';
            if (!list.includes(desired)) {
              return 'ERROR|MISSING_CLIP|' + desired + '|' + list.join(',');
            }
            if (model.animationName !== desired) {
              model.pause();
              model.animationName = desired;
              model.currentTime = 0;
            }
            if (negative) {
              // Genuine 3D petals fall and loop. No Flutter particle overlay.
              model.play({repetitions: Infinity});
              return 'OK|3D_PETAL_FALL|' + clamped + '|' + location;
            }
            const seconds = Number(model.duration);
            if (!Number.isFinite(seconds) || seconds <= 0) {
              return 'WAIT|NO_DURATION|' + list.join(',');
            }
            const target = clamped === 7
              ? Math.max(0, seconds - 0.002)
              : seconds * clamped / 7;
            model.pause();
            model.currentTime = target;
            return 'OK|STATIC_BLOOM|' + clamped + '|' + location;
          } catch (error) {
            return 'ERROR|' + String(error).slice(0, 100);
          }
        })();
      ''');
      // Android WebView returns JS strings with JSON quotes; iOS may not.
      final response = result.toString()
          .replaceAll(RegExp(r'^"|"$'), '')
          .replaceAll(r'\"', '"');
      if (!mounted) return;
      if (response.startsWith('OK|')) {
        _poll?.cancel();
        debugPrint('MOFUCHI BLOOM: $response');
      } else if (response.startsWith('WAIT|') || response.startsWith('ERROR|')) {
        if (response.startsWith('ERROR|')) _poll?.cancel();
        debugPrint('MOFUCHI BLOOM: $response');
      } else {
        debugPrint('MOFUCHI BLOOM unexpected: $response');
      }
    } catch (error) {
      debugPrint('MOFUCHI BLOOM JavaScript error: $error');
    } finally {
      _busy = false;
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModelViewer(
      backgroundColor: Colors.transparent,
      src: 'assets/3D/mofuchi_weekly_bloom_with_petal_fall.glb',
      alt: 'Mofuchi Garden 3D Sakura Island',
      autoRotate: false,
      cameraControls: true,
      disableZoom: true,
      disablePan: true,
      disableTap: true,
      interactionPrompt: InteractionPrompt.none,
      // Default: closer front view, with fixed zoom for steady framing.
      cameraOrbit: '0deg 75deg 108%',
      // Keep elevation and camera distance fixed: left/right rotation only.
      minCameraOrbit: '-180deg 75deg 108%',
      maxCameraOrbit: '180deg 75deg 108%',
      autoPlay: false,
      loading: Loading.eager,
      onWebViewCreated: _onWebViewCreated,
    );
  }

}

// Additional Flutter-only elements within the garden viewport.
// These decorate the 3D garden without changing its GLB or camera gestures.
class _GardenMoodAccent extends StatefulWidget {
  final String mood;
  const _GardenMoodAccent({required this.mood});

  @override
  State<_GardenMoodAccent> createState() => _GardenMoodAccentState();
}

class _GardenMoodAccentState extends State<_GardenMoodAccent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6900),
  )..repeat();

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _GardenAtmospherePainter(
          mood: widget.mood.trim().toLowerCase(),
          progress: _float,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _GardenAtmospherePainter extends CustomPainter {
  final String mood;
  final Animation<double> progress;
  _GardenAtmospherePainter({required this.mood, required this.progress})
      : super(repaint: progress);

  // Soft cloud silhouette rather than a flat Material icon. The subtle gradient,
  // luminous rim, and diffuse shadow match the pastel/low-poly Sakura scenery.
  void _cloud(Canvas canvas, Offset center, double width, double height,
      Color top, Color bottom, double opacity) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(width / 110, height / 68);
    final path = Path()
      ..moveTo(-52, 29)
      ..cubicTo(-61, 24, -60, 10, -48, 6)
      ..cubicTo(-45, -6, -32, -12, -21, -7)
      ..cubicTo(-17, -28, 7, -35, 24, -21)
      ..cubicTo(34, -19, 43, -10, 44, -1)
      ..cubicTo(59, 2, 61, 20, 49, 29)
      ..cubicTo(29, 38, -31, 37, -52, 29)
      ..close();
    canvas.drawPath(path, Paint()
      ..color = bottom.withValues(alpha: opacity * .36)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 11));
    canvas.drawPath(path, Paint()
      ..shader = LinearGradient(
        begin: const Alignment(-.3, -1),
        end: const Alignment(.4, 1),
        colors: [top.withValues(alpha: opacity),
                 bottom.withValues(alpha: opacity * .90)],
      ).createShader(const Rect.fromLTWH(-57, -36, 114, 74)));
    final highlight = Path()
      ..moveTo(-40, 7)
      ..cubicTo(-31, -3, -27, -4, -21, -3)
      ..cubicTo(-14, -23, 7, -27, 19, -18);
    canvas.drawPath(highlight, Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: opacity * .32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round);
    canvas.restore();
  }

  void _rain(Canvas canvas, Offset origin, double scale, double phase) {
    for (var i = 0; i < 5; i++) {
      final x = origin.dx + (i - 2) * 14 * scale;
      final offset = ((phase + i * .19) % 1.0) * 19;
      final y = origin.dy + offset * scale;
      final drop = Paint()
        ..color = const Color(0xFF9ED7FA).withValues(alpha: .42 + .13 * (i % 2))
        ..strokeWidth = 1.65 * scale
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(x + 2 * scale, y),
          Offset(x - 1 * scale, y + 8 * scale), drop);
    }
  }

  void _bolt(Canvas canvas, Offset origin, double scale, double opacity) {
    final path = Path()
      ..moveTo(origin.dx, origin.dy)
      ..relativeLineTo(-11 * scale, 22 * scale)
      ..relativeLineTo(8 * scale, 1 * scale)
      ..relativeLineTo(-13 * scale, 23 * scale)
      ..relativeLineTo(27 * scale, -29 * scale)
      ..relativeLineTo(-9 * scale, -1 * scale)
      ..close();
    canvas.drawPath(path, Paint()
      ..color = const Color(0xFFFFC979).withValues(alpha: opacity * .46)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9));
    canvas.drawPath(path, Paint()
      ..color = const Color(0xFFFFE4A2).withValues(alpha: opacity));
  }

  void _leaf(Canvas canvas, Offset center, double length, double angle,
      Color color, double opacity) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.scale(length / 26);
    final silhouette = Path()
      ..moveTo(0, -15)
      ..cubicTo(17, -8, 16, 6, 0, 15)
      ..cubicTo(-11, 6, -12, -6, 0, -15)
      ..close();
    canvas.drawPath(silhouette, Paint()
      ..color = color.withValues(alpha: opacity * .45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    canvas.drawPath(silhouette, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [const Color(0xFFC4D8A6).withValues(alpha: opacity),
                 color.withValues(alpha: opacity)],
      ).createShader(const Rect.fromLTWH(-13, -16, 27, 32)));
    canvas.drawLine(const Offset(0, -12), const Offset(0, 13),
        Paint()..color = const Color(0x99E9F3D7).withValues(alpha: opacity * .65)
          ..strokeWidth = 1);
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width;
    final h = size.height;
    final t = progress.value * math.pi * 2;
    final sway = math.sin(t) * 5;
    final floatBack = math.cos(t * .8) * 4;

    switch (mood) {
      case 'sad':
        _cloud(canvas, Offset(w * .17 + sway, h * .15), 93, 56,
            const Color(0xFFE7EEF9), const Color(0xFF9DB3D5), .84);
        _cloud(canvas, Offset(w * .83 - sway * .7, h * .17), 79, 49,
            const Color(0xFFF1F3FC), const Color(0xFFA6BAD6), .76);
        _cloud(canvas, Offset(w * .08 + floatBack, h * .40), 49, 31,
            const Color(0xFFDDE8F7), const Color(0xFFA7BAD7), .36);
        _rain(canvas, Offset(w * .17, h * .245), .75, progress.value);
        _rain(canvas, Offset(w * .83, h * .255), .65, progress.value + .37);
        break;
      case 'angry':
        _cloud(canvas, Offset(w * .16 + sway, h * .14), 102, 58,
            const Color(0xFF9C9DB9), const Color(0xFF484C70), .92);
        _cloud(canvas, Offset(w * .84 - sway, h * .16), 116, 64,
            const Color(0xFFA7A5BD), const Color(0xFF50516E), .95);
        _cloud(canvas, Offset(w * .92 + floatBack, h * .40), 52, 35,
            const Color(0xFFA3A3BA), const Color(0xFF66627C), .49);
        _bolt(canvas, Offset(w * .14, h * .23), .57,
            .65 + .22 * math.sin(t * 2).abs());
        _bolt(canvas, Offset(w * .87, h * .25), .75,
            .73 + .23 * math.sin(t * 1.3).abs());
        break;
      case 'fear':
        _cloud(canvas, Offset(w * .13 + sway, h * .18), 89, 58,
            const Color(0xFFF0EDF7), const Color(0xFFB7B6CD), .59);
        _cloud(canvas, Offset(w * .85 - sway, h * .15), 94, 61,
            const Color(0xFFE9EAF4), const Color(0xFFAEB2C8), .60);
        _cloud(canvas, Offset(w * .13 + floatBack, h * .66), 66, 41,
            const Color(0xFFEAEAF4), const Color(0xFFAEB6CF), .28);
        _cloud(canvas, Offset(w * .92 - floatBack, h * .65), 70, 46,
            const Color(0xFFE8E9F2), const Color(0xFFB7B6CE), .27);
        break;
      case 'disgust':
        for (var i = 0; i < 9; i++) {
          final left = i.isEven;
          final x = left ? w * (.06 + (i % 3) * .055)
                         : w * (.88 - (i % 3) * .045);
          final y = h * (.16 + ((i * 29) % 64) / 100);
          _leaf(canvas, Offset(x + math.sin(t + i) * 10,
                    y + math.cos(t * .75 + i) * 6),
                18.0 + i % 4 * 4,
                (left ? -.4 : .6) + math.sin(t + i) * .27,
                i.isEven ? const Color(0xFF739774) : const Color(0xFF8DA97F),
                .53 + (i % 3) * .1);
        }
        break;
      case 'happy':
        final sun = Offset(w * .84, h * .14 + sway * .6);
        canvas.drawCircle(sun, 39, Paint()
          ..color = const Color(0xFFFFE4A3).withValues(alpha: .25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24));
        canvas.drawCircle(sun, 24, Paint()
          ..shader = const RadialGradient(colors: [
            Color(0xFFFFF8CD), Color(0xFFFFD57C), Color(0x00FFD47E),
          ], stops: [0, .56, 1]).createShader(Rect.fromCircle(center: sun, radius: 24)));
        break;
      case 'surprise':
        for (var i = 0; i < 10; i++) {
          final x = w * (i.isEven ? .11 + (i % 3) * .08 : .82 - (i % 3) * .08);
          final y = h * (.12 + ((i * 23) % 63) / 100);
          final r = 3.0 + i % 3 * 1.7;
          final alpha = .34 + .28 * (math.sin(t + i) * .5 + .5);
          final brush = Paint()
            ..color = (i.isEven ? const Color(0xFFFFE1A8)
                               : const Color(0xFFD6C5F9)).withValues(alpha: alpha)
            ..strokeWidth = 1.6
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(Offset(x - r, y), Offset(x + r, y), brush);
          canvas.drawLine(Offset(x, y - r), Offset(x, y + r), brush);
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _GardenAtmospherePainter oldDelegate) =>
      oldDelegate.mood != mood || oldDelegate.progress != progress;
}

// First weather prototype: Sad -> gentle animated rain over the 3D garden.
// The painter is a transparent Flutter overlay; it never edits the GLB or
// interferes with model-viewer gestures and accumulated bloom progress.
class _GentleRainOverlay extends StatefulWidget {
  const _GentleRainOverlay();

  @override
  State<_GentleRainOverlay> createState() => _GentleRainOverlayState();
}

class _GentleRainOverlayState extends State<_GentleRainOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rain = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _rain.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: CustomPaint(
          painter: _GentleRainPainter(animation: _rain),
          child: const SizedBox.expand(),
        ),
      );
}

class _GentleRainPainter extends CustomPainter {
  final Animation<double> animation;
  _GentleRainPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    // Soft blue cloud wash across the top, transparent at the bottom.
    final haze = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x284B76A9), Color(0x114B76A9), Color(0x004B76A9)],
        stops: [0, 0.50, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, haze);

    // Fixed pseudo-random drop positions, animated vertically in a loop.
    // Use normalized coordinates so drops adapt to different screen widths.
    final drop = Paint()
      ..color = const Color(0xAA6599CF)
      ..strokeWidth = 1.25
      ..strokeCap = StrokeCap.round;
    final lightDrop = Paint()
      ..color = const Color(0x99D6EAFF)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    const count = 78;
    for (var i = 0; i < count; i++) {
      final xFraction = ((i * 73 + 19) % 101) / 101.0;
      final offset = ((i * 37 + 11) % 103) / 103.0;
      final speed = 0.62 + (i % 5) * 0.13;
      final travel = (offset + animation.value * speed) % 1.0;
      final x = xFraction * size.width;
      final y = (travel * 1.25 - 0.13) * size.height;
      final length = 7.0 + (i % 5) * 2.0;
      final slant = 2.2 + math.sin(i.toDouble()) * 0.7;
      canvas.drawLine(
        Offset(x, y),
        Offset(x - slant, y + length),
        i.isEven ? drop : lightDrop,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GentleRainPainter oldDelegate) =>
      oldDelegate.animation != animation;
}

// Happy -> a warm sunlight wash and slowly drifting golden sparkles.
// Flutter-only visual layer: bloom animation and 3D interactions remain intact.
class _SunnySparkleOverlay extends StatefulWidget {
  const _SunnySparkleOverlay();

  @override
  State<_SunnySparkleOverlay> createState() => _SunnySparkleOverlayState();
}

class _SunnySparkleOverlayState extends State<_SunnySparkleOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shine = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4400),
  )..repeat();

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: CustomPaint(
          painter: _SunnySparklePainter(animation: _shine),
          child: const SizedBox.expand(),
        ),
      );
}

class _SunnySparklePainter extends CustomPainter {
  final Animation<double> animation;
  _SunnySparklePainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;

    // Gentle sunshine, not an opaque layer covering the garden.
    final sunlight = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.85, -0.83),
        radius: 1.15,
        colors: const [
          Color(0x66FFE8A3),
          Color(0x24FFF1C6),
          Color(0x00FFF7DF),
        ],
        stops: const [0, 0.45, 1],
      ).createShader(rect);
    canvas.drawRect(rect, sunlight);

    // Consistent particle positions, no randomness between frames.
    for (var i = 0; i < 27; i++) {
      final xBase = ((i * 61 + 17) % 101) / 101.0;
      final yBase = ((i * 43 + 29) % 103) / 103.0;
      final phase = (animation.value + i * 0.137) % 1.0;
      final drift = math.sin((phase + i * 0.12) * math.pi * 2) * 5.0;
      final x = xBase * size.width + drift;
      final y = ((yBase - phase * 0.18 + 1.0) % 1.0) * size.height;
      final twinkle = (0.5 + 0.5 * math.sin((animation.value * 2 + i * 0.31) * math.pi * 2));
      final opacity = (0.25 + twinkle * 0.60).clamp(0.0, 1.0);
      final r = 1.4 + (i % 4) * 0.45;
      final glow = Paint()
        ..color = const Color(0xFFFFD56B).withValues(alpha: opacity * 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      final core = Paint()
        ..color = const Color(0xFFFFF0AA).withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), r * 2.4, glow);
      canvas.drawCircle(Offset(x, y), r, core);
      if (i % 5 == 0) {
        final rays = Paint()
          ..color = const Color(0xFFFFF2BB).withValues(alpha: opacity * 0.7)
          ..strokeWidth = 0.9
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(x - r * 2, y), Offset(x + r * 2, y), rays);
        canvas.drawLine(Offset(x, y - r * 2), Offset(x, y + r * 2), rays);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SunnySparklePainter oldDelegate) =>
      oldDelegate.animation != animation;
}

// Surprise (neutral): a soft pastel rainbow and calm drifting breeze.
// This is a 2D overlay; the existing 3D model and bloom poses are untouched.
class _RainbowBreezeOverlay extends StatefulWidget {
  const _RainbowBreezeOverlay();

  @override
  State<_RainbowBreezeOverlay> createState() => _RainbowBreezeOverlayState();
}

class _RainbowBreezeOverlayState extends State<_RainbowBreezeOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breeze = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 7500),
  )..repeat();

  @override
  void dispose() {
    _breeze.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: CustomPaint(
          painter: _RainbowBreezePainter(animation: _breeze),
          child: const SizedBox.expand(),
        ),
      );
}

class _RainbowBreezePainter extends CustomPainter {
  final Animation<double> animation;
  _RainbowBreezePainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = animation.value;
    final w = size.width;
    final h = size.height;

    // Semi-transparent rainbow sits high behind the visible tree crown.
    // Flutter overlays can't be truly behind the GLB; low opacity keeps it soft.
    final rainbowCenter = Offset(w * 0.53, h * 0.55);
    final rainbowColors = <Color>[
      const Color(0xFFFFA9B9),
      const Color(0xFFFFD7A0),
      const Color(0xFFFFF1A1),
      const Color(0xFFB9EAC3),
      const Color(0xFFADDDF7),
      const Color(0xFFD5C1F5),
    ];
    final breathe = 0.8 + 0.2 * math.sin(t * math.pi * 2);
    for (var i = 0; i < rainbowColors.length; i++) {
      final radius = w * (0.46 - i * 0.025);
      final path = Path()
        ..addArc(
          Rect.fromCircle(center: rainbowCenter, radius: radius),
          math.pi * 1.09,
          math.pi * 0.82,
        );
      canvas.drawPath(
        path,
        Paint()
          ..color = rainbowColors[i].withValues(alpha: 0.23 * breathe)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(3.0, w * 0.020)
          ..strokeCap = StrokeCap.round,
      );
    }

    // Little curved wind trails drift sideways, with stable deterministic positions.
    for (var i = 0; i < 12; i++) {
      final phase = (t + i * 0.173) % 1.0;
      final x = -55.0 + phase * (w + 110);
      final y = h * (0.13 + ((i * 29) % 75) / 100.0);
      final sway = math.sin((phase * 2 + i * 0.23) * math.pi) * 5;
      final alpha = math.sin(phase * math.pi).clamp(0.0, 1.0) * 0.42;
      final path = Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(x + 17, y - 7 + sway, x + 40, y - 2)
        ..quadraticBezierTo(x + 49, y + 1, x + 55, y - 4);
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFA1B6D6).withValues(alpha: alpha)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      if (i % 3 == 0) {
        canvas.drawCircle(
          Offset(x + 10, y - 13),
          1.8,
          Paint()..color = const Color(0xFFE4B6EF).withValues(alpha: alpha),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RainbowBreezePainter oldDelegate) =>
      oldDelegate.animation != animation;
}

// Angry -> a dramatic orange-gold thunderstorm, painted above the GLB.
// All effects are visual only; 3D bloom poses and gestures remain untouched.
class _ThunderstormOverlay extends StatefulWidget {
  const _ThunderstormOverlay();

  @override
  State<_ThunderstormOverlay> createState() => _ThunderstormOverlayState();
}

class _ThunderstormOverlayState extends State<_ThunderstormOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _storm = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 7600),
  )..repeat();

  @override
  void dispose() {
    _storm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: CustomPaint(
          painter: _ThunderstormPainter(animation: _storm),
          child: const SizedBox.expand(),
        ),
      );
}

class _ThunderstormPainter extends CustomPainter {
  final Animation<double> animation;
  _ThunderstormPainter({required this.animation}) : super(repaint: animation);

  // A short, smoothly fading warm flash (no rapid strobe).
  double _flash(double t, double center, double halfWidth) {
    final gap = (t - center).abs();
    if (gap >= halfWidth) return 0.0;
    final value = 1.0 - gap / halfWidth;
    return value * value * (3.0 - 2.0 * value);
  }

  void _drawBolt(Canvas canvas, Size size, double x, double y,
      double scale, double opacity, {bool mirror = false}) {
    if (opacity <= 0.0) return;
    canvas.save();
    canvas.translate(size.width * x, size.height * y);
    canvas.scale(mirror ? -scale : scale, scale);

    // Irregular branches rather than icon-like zigzags.
    final trunk = Path()
      ..moveTo(0, 0)
      ..lineTo(-12, 23)
      ..lineTo(-5, 35)
      ..lineTo(-23, 57)
      ..lineTo(-15, 68)
      ..lineTo(-36, 94);
    final branch = Path()
      ..moveTo(-7, 34)
      ..lineTo(13, 47)
      ..lineTo(4, 66);
    final branch2 = Path()
      ..moveTo(-20, 61)
      ..lineTo(-38, 69)
      ..lineTo(-42, 80);

    final outer = Paint()
      ..color = const Color(0xFFFF8C32).withValues(alpha: opacity * 0.58)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 11);
    final inner = Paint()
      ..color = const Color(0xFFFFC165).withValues(alpha: opacity * 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final core = Paint()
      ..color = const Color(0xFFFFF4D9).withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(trunk, outer);
    canvas.drawPath(trunk, inner);
    canvas.drawPath(trunk, core);
    canvas.drawPath(branch, inner..strokeWidth = 2.8);
    canvas.drawPath(branch, core..strokeWidth = 1.2);
    canvas.drawPath(branch2, inner);
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = animation.value;
    final rect = Offset.zero & size;

    // Purple charcoal sky fade: dramatic at the top, transparent near the island.
    canvas.drawRect(rect, Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xA13E394D), Color(0x664D4C63), Color(0x09564E5A)],
        stops: [0, 0.55, 1],
      ).createShader(rect));

    // Moving diffuse cloud banks at the edges, intentionally avoiding full cover.
    for (var i = 0; i < 4; i++) {
      final drift = math.sin((t + i * 0.21) * math.pi * 2) * 15.0;
      final center = Offset(
        size.width * (i.isEven ? 0.12 : 0.89) + drift,
        size.height * (0.04 + 0.067 * i),
      );
      canvas.drawOval(
        Rect.fromCenter(center: center,
            width: size.width * (0.62 + i * 0.04), height: size.height * 0.19),
        Paint()
          ..color = const Color(0xFF302F44).withValues(alpha: 0.14)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
      );
    }

    // Dense wind-driven rain, with staggered depths and speeds.
    final near = Paint()..color = const Color(0xB0ACCEEF)
      ..strokeWidth = 1.65..strokeCap = StrokeCap.round;
    final far = Paint()..color = const Color(0x66DCEAFF)
      ..strokeWidth = 1.0..strokeCap = StrokeCap.round;
    for (var i = 0; i < 165; i++) {
      final fx = ((i * 73 + 19) % 167) / 167.0;
      final offset = ((i * 47 + 9) % 163) / 163.0;
      final speed = 1.9 + (i % 6) * 0.21;
      final progress = (offset + t * speed * 2.7) % 1.0;
      final x = (fx * 1.26 - 0.12) * size.width;
      final y = (progress * 1.28 - 0.14) * size.height;
      final length = 13.0 + (i % 6) * 2.7;
      canvas.drawLine(Offset(x, y), Offset(x - 8.4, y + length),
          i % 3 == 0 ? far : near);
    }

    // Lightning pulses are deliberately spaced, with an orange sky glow.
    final left = math.max(_flash(t, 0.20, 0.061), _flash(t, 0.66, 0.066));
    final right = math.max(_flash(t, 0.39, 0.070), _flash(t, 0.88, 0.057));
    final strength = math.max(left, right);
    if (strength > 0) {
      canvas.drawRect(rect, Paint()
        ..color = const Color(0xFFFFB35F).withValues(alpha: strength * 0.15));
      canvas.drawRect(rect, Paint()
        ..shader = RadialGradient(
          center: Alignment(left > right ? -0.75 : 0.80, -0.78),
          radius: 0.85,
          colors: [
            const Color(0xFFFFC26E).withValues(alpha: strength * 0.28),
            const Color(0x00FFB35F),
          ],
        ).createShader(rect));
      // Position bolts near the upper edges, away from Sakura's center.
      _drawBolt(canvas, size, 0.22, 0.015, 0.76, left);
      _drawBolt(canvas, size, 0.82, 0.02, 0.94, right, mirror: true);
    }

    // Transparent dark vignette at upper corners helps the storm read clearly.
    canvas.drawRect(rect, Paint()
      ..shader = const RadialGradient(
        center: Alignment(0, 0.25),
        radius: 1.0,
        colors: [Color(0x00000000), Color(0x220E1021)],
        stops: [0.36, 1],
      ).createShader(rect));
  }

  @override
  bool shouldRepaint(covariant _ThunderstormPainter oldDelegate) =>
      oldDelegate.animation != animation;
}

// Fear -> soft lavender-grey fog drifting through the garden.
// Transparent, gesture-safe and independent from the Sakura GLB bloom state.
class _DriftingFogOverlay extends StatefulWidget {
  const _DriftingFogOverlay();

  @override
  State<_DriftingFogOverlay> createState() => _DriftingFogOverlayState();
}

class _DriftingFogOverlayState extends State<_DriftingFogOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fog = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  @override
  void dispose() {
    _fog.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: CustomPaint(
          painter: _DriftingFogPainter(animation: _fog),
          child: const SizedBox.expand(),
        ),
      );
}

class _DriftingFogPainter extends CustomPainter {
  final Animation<double> animation;
  _DriftingFogPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = animation.value * math.pi * 2;

    // Reduced fog: gentle lavender atmosphere with a clear Sakura silhouette.
    final softHaze = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x087F82A7), Color(0x119D9FBD), Color(0x22E7E5F2)],
        stops: [0, 0.55, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, softHaze);

    // Fewer, more transparent drifting banks than v10.
    for (var i = 0; i < 6; i++) {
      final x = size.width * (0.11 + i * 0.16) +
          math.sin(t * 0.47 + i * 1.5) * size.width * 0.15;
      final y = size.height * (0.35 + (i % 4) * 0.13) +
          math.cos(t * 0.35 + i) * 8;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: size.width * (0.38 + (i % 3) * 0.09),
          height: size.height * 0.12,
        ),
        Paint()
          ..color = const Color(0xFFE2E0EF).withValues(alpha: 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
      );
    }

    // Soft fog roll below the island, kept away from the main tree canopy.
    for (var i = 0; i < 2; i++) {
      final x = size.width * (0.30 + i * 0.42) +
          math.sin(t * 0.29 + i) * size.width * 0.12;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, size.height * (0.78 + i * 0.06)),
          width: size.width * 0.72,
          height: size.height * 0.16,
        ),
        Paint()
          ..color = const Color(0xFFF3F1FA).withValues(alpha: 0.20)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DriftingFogPainter oldDelegate) =>
      oldDelegate.animation != animation;
}

class _HomeLog {
  final String mood;
  final DateTime timestamp;
  final int? intensity;
  final String category;
  const _HomeLog({required this.mood, required this.timestamp,
    required this.intensity, required this.category});
}

/// Slow, subtle butterfly flutter at the top of the Home Screen.
/// Animates only this widget, without rebuilding the garden's 3D WebView.
class _FloatingHomeButterfly extends StatefulWidget {
  const _FloatingHomeButterfly();

  @override
  State<_FloatingHomeButterfly> createState() => _FloatingHomeButterflyState();
}

class _FloatingHomeButterflyState extends State<_FloatingHomeButterfly>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flutter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  )..repeat();

  @override
  void dispose() {
    _flutter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      width: 44,
      height: 42,
      child: AnimatedBuilder(
        animation: _flutter,
        // Vector-painted from the original Mofuchi butterfly silhouette.
        // No PNG/fallback: both wings always keep the intended shape.
        child: const MofuchiButterflyLogo(size: 36),
        builder: (context, child) {
          if (reduceMotion) return Center(child: child);
          final phase = _flutter.value * math.pi * 2;
          return Center(
            child: Transform.translate(
              offset: Offset(math.sin(phase) * 2.5, -math.cos(phase) * 6),
              child: Transform.rotate(
                angle: math.sin(phase) * 0.065,
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}

class MofuchiButterflyLogo extends StatelessWidget {
  final double size;
  const MofuchiButterflyLogo({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _ExactMofuchiButterflyPainter(),
      ),
    );
  }
}

// Vector silhouette matched to the supplied green/lavender butterfly artwork:
// softly scalloped upper wings, a narrow waist, and long pointed lower tips.
// Painted directly in Flutter, so the silhouette stays crisp at any size.
class _ExactMofuchiButterflyPainter extends CustomPainter {
  const _ExactMofuchiButterflyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // The design was originally drawn within a roughly 48 x 47 canvas.
    final scale = math.min(size.width / 48, size.height / 47);
    canvas.save();
    canvas.translate(
      (size.width - 48 * scale) / 2,
      (size.height - 47 * scale) / 2,
    );
    canvas.scale(scale);

    void drawHalf(Color color, {required bool right}) {
      canvas.save();
      if (right) {
        // Mirror the left wing, preserving the original two-tone symmetry.
        canvas.translate(48, 0);
        canvas.scale(-1, 1);
      }

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      // One connected wing, with a rounded crown at the top, an outward
      // scallop, a tapered middle, and a long teardrop lower wing.
      final wing = Path()
        ..moveTo(18.0, 1.0)
        ..cubicTo(13.8, 0.0, 11.0, 3.4, 12.0, 7.7)
        ..cubicTo(8.1, 6.6, 4.4, 8.3, 2.6, 11.4)
        ..cubicTo(0.0, 16.3, 8.5, 21.2, 19.0, 25.2)
        // Transition at the waist, exactly where the lower wings begin.
        ..cubicTo(15.8, 27.6, 13.5, 30.2, 14.4, 33.2)
        ..cubicTo(15.4, 37.9, 19.4, 41.8, 21.4, 43.7)
        ..cubicTo(22.4, 44.4, 22.8, 40.6, 22.9, 36.3)
        ..lineTo(23.0, 15.8)
        ..cubicTo(23.0, 12.0, 22.7, 10.0, 20.3, 7.9)
        ..cubicTo(21.2, 5.0, 20.8, 2.0, 18.0, 1.0)
        ..close();
      canvas.drawPath(wing, paint);

      // Slender inward antenna from the original shape, not a bulky body.
      final antenna = Path()
        ..moveTo(20.4, 2.1)
        ..quadraticBezierTo(21.4, 5.6, 23.0, 8.1)
        ..lineTo(22.2, 9.0)
        ..quadraticBezierTo(20.3, 5.8, 19.7, 2.4)
        ..close();
      canvas.drawPath(antenna, paint);
      canvas.restore();
    }

    drawHalf(const Color(0xFF6E7F68), right: false); // sage green
    drawHalf(const Color(0xFFB8AAC7), right: true);  // lilac
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ExactMofuchiButterflyPainter oldDelegate) =>
      false;
}
