// ignore_for_file: duplicate_ignore, unnecessary_underscores, avoid_types_as_parameter_names, unused_element_parameter

import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/mood_entry.dart';

const _moods = <String>['happy', 'surprise', 'sad', 'angry', 'disgust', 'fear'];
const _weatherAssets = <String, String>{
  'happy': 'assets/images/weather_img/weather_sun.png',
  'surprise': 'assets/images/weather_img/weather_surprised_rainbow.png',
  'sad': 'assets/images/weather_img/weather_rain.png',
  'angry': 'assets/images/weather_img/weather_thunder.png',
  'disgust': 'assets/images/weather_img/weather_gloomy.png',
  'fear': 'assets/images/weather_img/weather_foggy.png',
};
// Matches the six existing check-in mood PNGs. Keep the folder in pubspec.yaml.
const _moodIconAssets = <String, String>{
  'happy': 'assets/images/mood_icons/happy.png',
  'surprise': 'assets/images/mood_icons/surprise.png',
  'sad': 'assets/images/mood_icons/sad.png',
  'angry': 'assets/images/mood_icons/angry.png',
  'disgust': 'assets/images/mood_icons/disgust.png',
  'fear': 'assets/images/mood_icons/fear.png',
};

const _moodColors = <String, Color>{
  'happy': Color(0xFFE5A249),
  'surprise': Color(0xFFB388E8),
  'sad': Color(0xFF719ED8),
  'angry': Color(0xFFE27F83),
  'disgust': Color(0xFF78B69D),
  'fear': Color(0xFF9292BE),
};

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  // Reads the global MaterialApp brightness supplied by main.dart.
  // No local toggle/state: one setting controls every screen.
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _ink => _isDark ? const Color(0xFFF5F0FA) : const Color(0xFF30273C);
  Color get _purple => _isDark ? const Color(0xFFC4ADF4) : const Color(0xFF8060C6);
  Color get _muted => _isDark ? const Color(0xFFC3B7D0) : const Color(0xFF847A91);
  Color get _cardSurface => _isDark ? const Color(0xFF282233) : Colors.white;
  Color get _lineSurface => _isDark ? const Color(0xFF4A4057) : const Color(0xFFECE6F2);
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _emotionStream;
  String? _selectedMood;
  String _period = '7 days';
  int _weekOffset = 0;
  bool _showIntensityDetails = false;

  // Gentle, continuously looping movement for the butterfly in the header.
  late final AnimationController _butterflyController;

  @override
  void initState() {
    super.initState();
    _butterflyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
    final user = FirebaseAuth.instance.currentUser;
    _emotionStream = FirebaseFirestore.instance
        .collection('emotion_logs')
        .where('userId', isEqualTo: user?.uid ?? '')
        .snapshots();
  }

  @override
  void dispose() {
    _butterflyController.dispose();
    super.dispose();
  }

  String _name(String mood) =>
      mood.isEmpty ? mood : '${mood[0].toUpperCase()}${mood.substring(1)}';

  DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

  DateTime _weekStart(DateTime date) {
    final d = _day(date);
    return d.subtract(Duration(days: d.weekday - DateTime.monday));
  }

  List<MoodEntry> _convert(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          final createdAt = data['createdAt'];
          return MoodEntry(
            id: doc.id,
            mood: (data['emotion'] as String? ?? '').trim().toLowerCase(),
            intensity: (data['intensity'] as num?)?.toInt() ?? 0,
            category: (data['eventCategory'] as String?) ??
                (data['category'] as String?) ??
                'General',
            note: (data['shortThought'] as String?) ?? '',
            timestamp: createdAt is Timestamp
                ? createdAt.toDate()
                : DateTime.fromMillisecondsSinceEpoch(0),
          );
        })
        .where((e) => _moods.contains(e.mood) && e.timestamp.year > 1970)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<MoodEntry> _inPeriod(List<MoodEntry> entries, DateTime now) {
    if (_period == 'All time') return entries;
    final cutoff =
        _day(now).subtract(Duration(days: _period == '7 days' ? 6 : 29));
    return entries
        .where((e) =>
            !e.timestamp.isBefore(cutoff) &&
            e.timestamp.isBefore(_day(now).add(const Duration(days: 1))))
        .toList();
  }

  List<MoodEntry> _inWeek(List<MoodEntry> entries, DateTime weekStart) {
    final end = weekStart.add(const Duration(days: 7));
    return entries
        .where((e) => !e.timestamp.isBefore(weekStart) && e.timestamp.isBefore(end))
        .toList();
  }

  double _average(List<MoodEntry> entries) {
    final valid =
        entries.where((e) => e.intensity >= 1 && e.intensity <= 5).toList();
    if (valid.isEmpty) return 0;
    return valid.fold<int>(0, (sum, e) => sum + e.intensity) / valid.length;
  }

  String _dominant(List<MoodEntry> entries) {
    if (entries.isEmpty) return '—';
    final counts = <String, int>{};
    for (final entry in entries) {
      counts[entry.mood] = (counts[entry.mood] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return _name(sorted.first.key);
  }

  String _topCategory(List<MoodEntry> entries) {
    if (entries.isEmpty) return '—';
    final counts = <String, int>{};
    for (final entry in entries) {
      final value = entry.category.trim();
      if (value.isNotEmpty) counts[value] = (counts[value] ?? 0) + 1;
    }
    if (counts.isEmpty) return '—';
    return (counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
        .first
        .key;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to see your dashboard.'));
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _emotionStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Could not load your dashboard.\n${snapshot.error}',
                  textAlign: TextAlign.center),
            ),
          );
        }
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: _purple));
        }
        final all = _convert(snapshot.data!);
        final now = DateTime.now();
        final range = _inPeriod(all, now);
        final focused = _selectedMood == null
            ? range
            : range.where((e) => e.mood == _selectedMood).toList();
        // Recent check-ins explicitly use both the selected period and mood.
        final recentCheckIns = focused.take(4).toList();
        final dominant = _dominant(range);
        final avg = _average(focused);
        final hasValidIntensity =
            focused.any((e) => e.intensity >= 1 && e.intensity <= 5);
        final currentWeekStart =
            _weekStart(now).add(Duration(days: 7 * _weekOffset));
        final weekEntries = _inWeek(all, currentWeekStart);
        // Weekly reflection always covers all emotions, regardless of graph filter.
        final selectedWeekEntries = weekEntries;

        return _DashboardLavenderBackground(
          isDark: _isDark,
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 104),
              children: [
                Center(
                  child: SizedBox(
                    width: 58,
                    height: 48,
                    child: AnimatedBuilder(
                      animation: _butterflyController,
                      child: const _DashboardButterflyLogo(size: 36),
                      builder: (context, child) {
                        if (MediaQuery.disableAnimationsOf(context)) {
                          return Center(child: child);
                        }
                        final phase = _butterflyController.value * 2 * math.pi;
                        // Slow hover (6px vertical), small tilt and subtle sway.
                        return Transform.translate(
                          offset: Offset(
                            math.sin(phase + math.pi / 2) * 2.5,
                            math.sin(phase) * 6.0,
                          ),
                          child: Transform.rotate(
                            angle: math.sin(phase) * 0.075,
                            child: Center(child: child),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text('My emotion garden',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                    textAlign: TextAlign.center),
                const SizedBox(height: 3),
                Text('A gentle look at your emotional weather.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _muted, fontSize: 12)),
                const SizedBox(height: 17),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Your emotion cloud',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: _ink,
                                    fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(
                              _period == '7 days'
                                  ? 'Your check-ins from the last 7 days.'
                                  : _period == '30 days'
                                      ? 'Your check-ins from the last 30 days.'
                                      : 'All your recorded check-ins.',
                              style: TextStyle(fontSize: 11.5, color: _muted),
                            ),
                            const SizedBox(height: 10),
                            Row(children: [
                              Text('Show data for:',
                                  style: TextStyle(color: _muted, fontSize: 11.5)),
                              const SizedBox(width: 10),
                              DropdownButton<String>(
                                dropdownColor: _cardSurface,
                                value: _period,
                                underline: const SizedBox.shrink(),
                                isDense: true,
                                items: ['7 days', '30 days', 'All time']
                                    .map((value) => DropdownMenuItem(
                                        value: value,
                                        child: Text(value,
                                            style: TextStyle(
                                                fontSize: 12, color: _purple))))
                                    .toList(),
                                onChanged: (value) => setState(() {
                                  if (value != null) _period = value;
                                }),
                              ),
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 11),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          _chip(null),
                          ..._moods.map((m) => _chip(m)),
                        ]),
                      ),
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _selectedMood == null
                            ? _weeklyCloud(range)
                            : _selectedWeatherCard(_selectedMood!, range),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text('Your mood overview',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: _ink))),
                        Text(_period,
                            style: TextStyle(fontSize: 11, color: _purple)),
                      ]),
                      const SizedBox(height: 14),
                      Row(children: [
                        _metric('Total check-ins', '${range.length}',
                            Icons.edit_calendar_rounded),
                        const SizedBox(width: 9),
                        _metric('Most recorded feeling', dominant,
                            Icons.spa_outlined),
                      ]),
                      const SizedBox(height: 10),
                      Text('Each check-in is one recorded feeling.',
                          style: TextStyle(fontSize: 13, color: _muted)),
                      if (all.isEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                            'No check-ins yet. Your garden story starts with one feeling.',
                            style: TextStyle(color: _muted, fontSize: 12)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text('Your feelings over time',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: _ink))),
                        Text(
                            _selectedMood == null
                                ? 'All moods'
                                : _name(_selectedMood!),
                            style: TextStyle(color: _purple, fontSize: 12)),
                      ]),
                      const SizedBox(height: 8),
                      Text(
                          'How strongly did you feel each emotion when you checked in?',
                          style: TextStyle(
                              color: _muted, fontSize: 14, height: 1.4)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: _purple.withValues(alpha: _isDark ? .14 : .07),
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: _purple.withValues(alpha: .16)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Feeling strength: 1–5',
                                style: TextStyle(
                                    color: _ink,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('1 · Very mild',
                                    style:
                                        TextStyle(color: _muted, fontSize: 12)),
                                Text('3 · Moderate',
                                    style:
                                        TextStyle(color: _muted, fontSize: 12)),
                                Text('5 · Very strong',
                                    style:
                                        TextStyle(color: _muted, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                          'Average feeling strength: ${hasValidIntensity ? '${avg.toStringAsFixed(1)}/5' : 'No data'}',
                          style: TextStyle(
                              color: _purple,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      _intensityChart(focused, now),
                      const SizedBox(height: 10),
                      Text(
                          'Each bar shows average feeling strength. No bar means no recorded rating.',
                          style: TextStyle(
                              color: _muted, fontSize: 12.5, height: 1.35)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(
                            () => _showIntensityDetails = !_showIntensityDetails),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(children: [
                            Expanded(
                                child: Text('Average feeling strength',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: _ink))),
                            Text(
                                _showIntensityDetails
                                    ? 'Hide details'
                                    : 'View details',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: _purple,
                                    fontWeight: FontWeight.w700)),
                            Icon(
                                _showIntensityDetails
                                    ? Icons.expand_less_rounded
                                    : Icons.expand_more_rounded,
                                color: _purple),
                          ]),
                        ),
                      ),
                      if (_showIntensityDetails) ...[
                        const SizedBox(height: 9),
                        Text('Average strength you recorded for each feeling (1–5).',
                            style: TextStyle(color: _muted, fontSize: 13)),
                        const SizedBox(height: 14),
                        ..._moods.map((m) => _emotionProgress(m, range)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text('🌷 Your weekly reflection',
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: _ink))),
                        IconButton(
                          tooltip: 'Previous week',
                          visualDensity: VisualDensity.compact,
                          icon: Icon(Icons.chevron_left_rounded, color: _purple),
                          onPressed: () => setState(() => _weekOffset--),
                        ),
                        IconButton(
                          tooltip: 'Next week',
                          visualDensity: VisualDensity.compact,
                          icon:
                              Icon(Icons.chevron_right_rounded, color: _purple),
                          onPressed: _weekOffset >= 0
                              ? null
                              : () => setState(() => _weekOffset++),
                        ),
                      ]),
                      Text(
                          '${_dateText(currentWeekStart)} – ${_dateText(currentWeekStart.add(const Duration(days: 6)))}',
                          style: TextStyle(
                              color: _purple,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 15),
                      Text(_weeklyReflection(selectedWeekEntries),
                          style:
                              TextStyle(fontSize: 15, color: _ink, height: 1.55)),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 14),
                        decoration: BoxDecoration(
                          color: _isDark
                              ? const Color(0x554C3B67)
                              : const Color(0x99F0E8FB),
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(
                              color: _isDark
                                  ? const Color(0x55E3D4FC)
                                  : const Color(0xCCFFFFFF)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('💜 A little encouragement',
                                style: TextStyle(
                                    color: _purple,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text(_weeklyEncouragement(selectedWeekEntries),
                                style: TextStyle(
                                    fontSize: 15, height: 1.5, color: _ink)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 11),
                      Text('A reflection on your check-ins, not a health assessment.',
                          style: TextStyle(
                              fontSize: 11.5, color: _muted, height: 1.4)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text('Your recent check-ins',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: _ink))),
                        Text(
                            _selectedMood == null
                                ? 'All moods'
                                : _name(_selectedMood!),
                            style: TextStyle(
                                color: _purple,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ]),
                      const SizedBox(height: 10),
                      if (recentCheckIns.isEmpty)
                        Text(
                            _selectedMood == null
                                ? 'No check-ins in this period yet.'
                                : 'No ${_name(_selectedMood!).toLowerCase()} check-ins in this period yet.',
                            style: TextStyle(color: _muted, fontSize: 12)),
                      ...recentCheckIns.map((e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            child: Row(children: [
                              _moodIcon(e.mood, size: 35),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_name(e.mood),
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: _ink)),
                                    Text(_dateText(e.timestamp),
                                        style: TextStyle(
                                            fontSize: 12, color: _muted)),
                                  ],
                                ),
                              ),
                              Text(
                                  e.intensity >= 1 && e.intensity <= 5
                                      ? '${e.intensity}/5'
                                      : '—',
                                  style: TextStyle(
                                      color: _purple,
                                      fontWeight: FontWeight.w600)),
                            ]),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _card({required Widget child}) => ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isDark
                    ? const [Color(0x88453959), Color(0x77302A3E)]
                    : const [Color(0xD8FFFFFF), Color(0xB0F7EEFF)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color:
                    _isDark ? const Color(0x66F2E6FF) : const Color(0xDDFFFFFF),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _purple.withValues(alpha: _isDark ? 0.14 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 7),
                )
              ],
            ),
            child: child,
          ),
        ),
      );

  Widget _metric(String title, String value, IconData icon) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: _isDark ? const Color(0x334C3B68) : const Color(0xB8FFFFFF),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: _isDark ? const Color(0x80E8D9FF) : const Color(0xFFFFFFFF),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: _purple.withValues(alpha: _isDark ? 0.10 : 0.07),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: _isDark ? 0.03 : 0.32),
                blurRadius: 2,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: _purple, size: 19),
              const SizedBox(height: 7),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _ink)),
              ),
              Text(title, style: TextStyle(fontSize: 11, color: _muted)),
            ],
          ),
        ),
      );

  Widget _moodIcon(String mood, {double size = 30}) => Image.asset(
        _moodIconAssets[mood]!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        // ignore: unnecessary_underscores
        errorBuilder: (_, __, ___) => Icon(
          Icons.spa_rounded,
          size: size * .8,
          color: _purple,
        ),
      );

  // Every filter uses the SAME frosted-glass frame. Only a subtle outline
  // indicates selection. The PNG is enlarged inside its viewport so the
  // transparent file margins do not make the artwork look tiny.
  Widget _chip(String? mood) {
    final selected = _selectedMood == mood;
    final radius = BorderRadius.circular(15);
    final largeMood = mood == 'happy' || mood == 'sad' || mood == 'angry';
    final mediumLargeMood =
        mood == 'surprise' || mood == 'fear' || mood == 'disgust';
    final iconSize = largeMood ? 64.0 : (mediumLargeMood ? 56.0 : 38.0);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: radius,
              onTap: () => setState(() => _selectedMood = mood),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 230),
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 7),
                decoration: BoxDecoration(
                  borderRadius: radius,
                  color: selected
                      ? (_isDark
                          ? const Color(0x38FFFFFF)
                          : const Color(0x7AFFFFFF))
                      : (_isDark
                          ? const Color(0x1CFFFFFF)
                          : const Color(0x42FFFFFF)),
                  border: Border.all(
                    color: selected
                        ? (_isDark
                            ? const Color(0xA8EAD8FF)
                            : const Color(0xE6FFFFFF))
                        : (_isDark
                            ? const Color(0x55FFFFFF)
                            : const Color(0xAAFFFFFF)),
                    width: selected ? 1.6 : 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white
                          .withValues(alpha: _isDark ? 0.03 : 0.16),
                      blurRadius: 2,
                      offset: const Offset(0, -1),
                    ),
                    BoxShadow(
                      color: _purple.withValues(alpha: selected ? .10 : .04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (mood == null)
                      Icon(Icons.auto_awesome_rounded, size: 20, color: _purple)
                    else
                      SizedBox(
                        width: 36,
                        height: 36,
                        // Clip the transparent outer padding rather than
                        // making the button taller to fit a bigger PNG.
                        child: ClipRect(
                          child: OverflowBox(
                            alignment: Alignment.center,
                            minWidth: 0,
                            minHeight: 0,
                            maxWidth: iconSize,
                            maxHeight: iconSize,
                            child: _moodIcon(mood, size: iconSize),
                          ),
                        ),
                      ),
                    const SizedBox(width: 3),
                    Text(
                      mood == null ? 'All moods' : _name(mood),
                      style: TextStyle(
                        color: _ink,
                        fontSize: 11,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectedWeatherCard(String mood, List<MoodEntry> entries) {
    final matches = entries.where((e) => e.mood == mood).toList();
    return Container(
      key: ValueKey(mood),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      child: Row(children: [
        SizedBox(
          width: 132,
          height: 140,
          child: Image.asset(
            _weatherAssets[mood]!,
            fit: BoxFit.contain,
            // ignore: unnecessary_underscores
            errorBuilder: (_, __, ___) =>
                Center(child: _moodIcon(mood, size: 75)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_name(mood),
                  style: TextStyle(
                      fontSize: 19, fontWeight: FontWeight.bold, color: _ink)),
              const SizedBox(height: 8),
              Text(
                  '${matches.length} ${matches.length == 1 ? 'check-in' : 'check-ins'}',
                  style: TextStyle(
                      color: _purple,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              const SizedBox(height: 5),
              Text(
                  _average(matches) == 0
                      ? 'No intensity data yet'
                      : 'Average intensity: ${_average(matches).toStringAsFixed(1)}/5',
                  style: TextStyle(color: _muted, fontSize: 11)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _intensityChart(List<MoodEntry> entries, DateTime now) {
    final periodEnd = _day(now).add(const Duration(days: 1));
    final List<DateTime> starts;
    final List<String> labels;
    final int slotDays;
    if (_period == '7 days') {
      slotDays = 1;
      starts =
          List.generate(7, (i) => _day(now).subtract(Duration(days: 6 - i)));
      labels = starts.map((d) => _weekday(d.weekday)).toList();
    } else if (_period == '30 days') {
      // Six five-day buckets keep labels readable on narrow phones.
      slotDays = 5;
      starts = List.generate(
          6, (i) => _day(now).subtract(Duration(days: 29 - i * 5)));
      labels = starts.map((d) => '${d.day}/${d.month}').toList();
    } else {
      // All-time chart covers the complete data range in up to eight buckets.
      final oldest = entries.isEmpty ? _day(now) : _day(entries.last.timestamp);
      final totalDays = math.max(1, _day(now).difference(oldest).inDays + 1);
      slotDays = math.max(1, (totalDays / 8).ceil());
      starts = List.generate((totalDays / slotDays).ceil(),
          (i) => oldest.add(Duration(days: i * slotDays)));
      labels = starts.map((d) => '${d.day}/${d.month}').toList();
    }
    final series = List.generate(starts.length, (i) {
      final from = starts[i];
      final to = from.add(Duration(days: slotDays));
      final subset = entries
          .where((e) =>
              !e.timestamp.isBefore(from) &&
              e.timestamp.isBefore(to) &&
              e.timestamp.isBefore(periodEnd) &&
              e.intensity >= 1 &&
              e.intensity <= 5)
          .toList();
      return (date: from, average: _average(subset), count: subset.length);
    });
    final color = _selectedMood == null ? _purple : _moodColors[_selectedMood!]!;
    final hasData = series.any((s) => s.count > 0);
    return Column(children: [
      if (!hasData)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text('No feeling strength ratings for this selection yet.',
              style: TextStyle(color: _muted, fontSize: 12)),
        ),
      SizedBox(
        height: 185,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(series.length, (index) {
            final item = series[index];
            final filled = item.count > 0;
            final average = item.average;
            final end = item.date.add(Duration(days: slotDays - 1));
            return Expanded(
              child: Tooltip(
                message:
                    '${_dateText(item.date)}${slotDays > 1 ? ' – ${_dateText(end)}' : ''}: '
                    '${filled ? '${average.toStringAsFixed(1)}/5 (${item.count} logs)' : 'No records'}',
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(filled ? average.toStringAsFixed(1) : '',
                          style: TextStyle(color: _muted, fontSize: 10)),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 450),
                        curve: Curves.easeOutCubic,
                        height: filled ? 125 * average / 5 : 4,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: filled ? color : _lineSurface,
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(labels[index],
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                              color: _muted,
                              fontSize: series.length > 8 ? 8 : 10)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
      if (_period == 'All time')
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text('Each bar shows average feeling strength for a date range.',
              style: TextStyle(color: _muted, fontSize: 10)),
        ),
    ]);
  }

  /// Emotion cloud: frequency determines size; the stickers drift and gently bounce.
  Widget _weeklyCloud(List<MoodEntry> entries) {
    final moods = _moods.map((mood) {
      final matches = entries.where((entry) => entry.mood == mood).toList();
      return _CloudData(mood, matches.length, _average(matches));
    }).toList(); // Keep all six weather moods visible, including 0 check-ins.

    moods.sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      return byCount != 0
          ? byCount
          : _moods.indexOf(a.mood).compareTo(_moods.indexOf(b.mood));
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BouncingWeatherCloud(
          key: ValueKey('bouncing-cloud-$_period'),
          moods: moods,
          isDark: _isDark,
          onSelected: (mood) => setState(() => _selectedMood = mood),
        ),
        const SizedBox(height: 7),
        Text(
          'Tap a weather image to see that feeling.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: 12.5),
        ),
      ],
    );
  }

  Widget _emotionProgress(String mood, List<MoodEntry> entries) {
    final matches = entries
        .where((e) => e.mood == mood && e.intensity >= 1 && e.intensity <= 5)
        .toList();
    final avg = _average(matches);
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(children: [
        SizedBox(
          width: 133,
          child: Row(children: [
            // Show the weather illustration rather than the small mood-face icon.
            SizedBox(
              width: 50,
              height: 50,
              child: Image.asset(
                _weatherAssets[mood]!,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => _moodIcon(mood, size: 43),
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
                child: Text(_name(mood),
                    style: TextStyle(fontSize: 12.5, color: _ink),
                    overflow: TextOverflow.ellipsis)),
          ]),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: avg / 5,
              minHeight: 9,
              backgroundColor: _lineSurface,
              valueColor: AlwaysStoppedAnimation(_moodColors[mood]!),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(matches.isEmpty ? '—' : avg.toStringAsFixed(1),
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 12.5, color: _ink)),
        ),
      ]),
    );
  }

  // Short reflection based only on the emotions and situations that users logged.
  // No assumptions about causes or mental health are made from free-text notes.
  String _weeklyReflection(List<MoodEntry> entries) {
    if (entries.isEmpty) {
      return 'No feelings recorded this week yet. Your next check-in can start your story.';
    }
    final counts = <String, int>{};
    for (final entry in entries) {
      counts[entry.mood] = (counts[entry.mood] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) {
        final diff = b.value.compareTo(a.value);
        return diff != 0 ? diff : a.key.compareTo(b.key);
      });
    final most = sorted.first;
    final tied = sorted.length > 1 && sorted[1].value == most.value;
    final frequency = tied
        ? '${_name(most.key)} was one of your most recorded feelings.'
        : 'You recorded ${_name(most.key).toLowerCase()} most often.';
    final category = _topCategory(entries).trim();
    final situation = category.isEmpty ||
            category == '—' ||
            category.toLowerCase() == 'general'
        ? ''
        : ' You often chose $category as the situation.';
    return 'You checked in ${entries.length} ${entries.length == 1 ? 'time' : 'times'} this week. '
        '$frequency$situation';
  }

  String _weeklyEncouragement(List<MoodEntry> entries) {
    if (entries.isEmpty) {
      return 'Start small. Every feeling matters. 🌱';
    }
    final counts = <String, int>{};
    for (final entry in entries) {
      counts[entry.mood] = (counts[entry.mood] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) {
        final diff = b.value.compareTo(a.value);
        return diff != 0 ? diff : a.key.compareTo(b.key);
      });
    if (sorted.length > 1 && sorted[0].value == sorted[1].value) {
      return 'You felt different emotions this week. It is okay to feel them all. 🌷';
    }
    switch (sorted.first.key) {
      case 'happy':
        return 'Hold on to the little things that made you smile. 🌼';
      case 'surprise':
        return 'New moments can bring new feelings. Stay curious. 🌈';
      case 'sad':
        return 'Some days feel heavy. Be kind to yourself. 💜';
      case 'angry':
        return 'Your feelings matter. Take a pause when you need one. 🌿';
      case 'fear':
        return 'One small step is enough. You can take your time. 🌱';
      case 'disgust':
        return 'It is okay to set boundaries and care for yourself. 🌸';
      default:
        return 'Thank you for checking in with yourself this week. 💜';
    }
  }

  String _dateText(DateTime date) => '${date.day}/${date.month}/${date.year}';

  String _weekday(int day) => ['M', 'T', 'W', 'T', 'F', 'S', 'S'][day - 1];
}

class _CloudData {
  final String mood;
  final int count;
  final double average;
  const _CloudData(this.mood, this.count, this.average);
}

// A gently animated emotion cloud. Stickers move autonomously inside the
// panel, separate softly when they touch, and remain tappable (not draggable).
// No Firestore writes or extra dependencies.
class _BouncingWeatherCloud extends StatefulWidget {
  final List<_CloudData> moods;
  final bool isDark;
  final ValueChanged<String> onSelected;

  const _BouncingWeatherCloud({
    super.key,
    required this.moods,
    required this.isDark,
    required this.onSelected,
  });

  @override
  State<_BouncingWeatherCloud> createState() => _BouncingWeatherCloudState();
}

class _BouncingWeatherCloudState extends State<_BouncingWeatherCloud>
    with SingleTickerProviderStateMixin {
  static const double _height = 430.0;
  static const double _loopSeconds = 16.0;
  static const List<Offset> _satellites = [
    Offset(.18, .18),
    Offset(.82, .19),
    Offset(.18, .79),
    Offset(.82, .79),
    Offset(.50, .91),
  ];

  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  )..repeat();

  // Normalized centers ensure the composition adapts to different phones.
  final Map<String, Offset> _centers = {};
  final Map<String, Offset> _velocity = {};
  double? _lastValue;

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  void _ensureStickers() {
    final active = widget.moods.map((e) => e.mood).toSet();
    _centers.removeWhere((mood, _) => !active.contains(mood));
    _velocity.removeWhere((mood, _) => !active.contains(mood));
    for (var i = 0; i < widget.moods.length; i++) {
      final mood = widget.moods[i].mood;
      _centers.putIfAbsent(
        mood,
        () => i == 0
            ? const Offset(.50, .48)
            : _satellites[(i - 1) % _satellites.length],
      );
      _velocity.putIfAbsent(
        mood,
        () => Offset(
          math.cos(1.9 * i + .6) * (17.0 + i * 1.5),
          math.sin(1.9 * i + .6) * (15.0 + i * 1.5),
        ),
      );
    }
  }

  double _imageSize(int index, double width) {
    final mood = widget.moods[index];
    // Unrecorded moods remain small and the same size, even if the selected
    // period contains no check-ins at all. This also avoids division by zero.
    if (mood.count == 0) return math.min(66.0, width * .24);

    final dominant = index == 0;
    // Recorded moods keep their frequency-weighted sizing, capped against the
    // available width for smaller phone screens.
    final base = dominant
        ? 166.0
        : 70.0 + 42.0 * mood.count / widget.moods.first.count;
    return math.min(base, width * (dominant ? .53 : .35));
  }

  // Positions and velocities are advanced in tiny frame steps. When two
  // circles approach one another, their closing speed is reduced and reversed,
  // while positional correction prevents stickers getting stuck overlapping.
  void _advance(double width) {
    final now = _float.value;
    if (_lastValue == null) {
      _lastValue = now;
      return;
    }
    var fraction = now - _lastValue!;
    if (fraction < 0) fraction += 1.0; // AnimationController repeat wrap.
    _lastValue = now;
    final dt = (fraction * _loopSeconds).clamp(0.0, .045).toDouble();
    if (dt <= 0 || width <= 0) return;

    final items = widget.moods;
    final centers = <Offset>[];
    final velocities = <Offset>[];
    final radii = <double>[];
    final boxWidths = <double>[];
    final boxHeights = <double>[];
    for (var i = 0; i < items.length; i++) {
      final mood = items[i].mood;
      final size = _imageSize(i, width);
      final bw = size + 12.0;
      final bh = size + 52.0;
      boxWidths.add(bw);
      boxHeights.add(bh);
      radii.add(size * .53 + 7.0);
      final old = _centers[mood]!;
      final point = Offset(old.dx * width, old.dy * _height);
      final v = _velocity[mood]!;
      // Gentle meandering plus weak spring toward each sticker's home region.
      final anchor = i == 0
          ? const Offset(.50, .48)
          : _satellites[(i - 1) % _satellites.length];
      final spring = Offset(
        (anchor.dx * width - point.dx) * .18,
        (anchor.dy * _height - point.dy) * .18,
      );
      final phase = now * 2 * math.pi;
      final breeze = Offset(
        math.sin(phase + i * 2.17) * 5.0,
        math.cos(phase * .8 + i * 1.73) * 5.0,
      );
      var newV = v + (spring + breeze) * dt;
      final speed = newV.distance;
      if (speed > 28.0) newV = newV * (28.0 / speed);
      centers.add(point + newV * dt);
      velocities.add(newV);
    }

    // Two gentle collision-resolution passes handle simultaneous nearby clouds.
    for (var pass = 0; pass < 2; pass++) {
      for (var i = 0; i < centers.length; i++) {
        for (var j = i + 1; j < centers.length; j++) {
          final delta = centers[j] - centers[i];
          final distance = delta.distance;
          final minDistance = radii[i] + radii[j];
          if (distance >= minDistance) continue;
          final normal = distance > .001
              ? delta / distance
              : Offset(math.cos(i + j.toDouble()), math.sin(i + j.toDouble()));
          final overlap = minDistance - distance;
          // Dominant (larger) emotion moves less than the small satellites.
          final weightI = i == 0 ? .25 : .50;
          final weightJ = j == 0 ? .25 : .50;
          final total = weightI + weightJ;
          centers[i] -= normal * (overlap * weightI / total);
          centers[j] += normal * (overlap * weightJ / total);

          final closingSpeed = (velocities[j] - velocities[i]).dx * normal.dx +
              (velocities[j] - velocities[i]).dy * normal.dy;
          if (closingSpeed < 0) {
            // Low restitution: a soft bounce rather than a sharp ricochet.
            final impulse = -closingSpeed * .78;
            velocities[i] -= normal * (impulse * weightI / total);
            velocities[j] += normal * (impulse * weightJ / total);
          }
        }
      }
    }

    for (var i = 0; i < items.length; i++) {
      final minX = boxWidths[i] / 2;
      final maxX = math.max(minX, width - minX);
      final minY = boxHeights[i] / 2;
      final maxY = math.max(minY, _height - minY);
      var x = centers[i].dx;
      var y = centers[i].dy;
      var vx = velocities[i].dx;
      var vy = velocities[i].dy;
      if (x < minX || x > maxX) {
        x = x.clamp(minX, maxX).toDouble();
        vx = -vx * .7;
      }
      if (y < minY || y > maxY) {
        y = y.clamp(minY, maxY).toDouble();
        vy = -vy * .7;
      }
      final mood = items[i].mood;
      _centers[mood] = Offset(x / width, y / _height);
      _velocity[mood] = Offset(vx, vy);
    }
  }

  @override
  Widget build(BuildContext context) {
    _ensureStickers();
    final ink =
        widget.isDark ? const Color(0xFFF5F0FA) : const Color(0xFF30273C);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      height: _height,
      child: LayoutBuilder(
        builder: (context, bounds) {
          final width = bounds.maxWidth;
          return AnimatedBuilder(
            animation: _float,
            builder: (context, _) {
              if (!reduceMotion) {
                _advance(width);
              } else {
                _lastValue = _float.value;
              }
              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // The dominant weather image is painted last, above others.
                  for (var i = widget.moods.length - 1; i >= 0; i--)
                    _sticker(widget.moods[i], i, width, ink),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _sticker(_CloudData item, int index, double width, Color ink) {
    final dominant = index == 0 && item.count > 0;
    final imageSize = _imageSize(index, width);
    final boxWidth = imageSize + 12.0;
    final boxHeight = imageSize + 52.0;
    final center = _centers[item.mood]!;
    final x = (center.dx * width - boxWidth / 2)
        .clamp(0.0, math.max(0.0, width - boxWidth))
        .toDouble();
    final y = (center.dy * _height - boxHeight / 2)
        .clamp(0.0, math.max(0.0, _height - boxHeight))
        .toDouble();

    return Positioned(
      key: ValueKey('floating-weather-${item.mood}'),
      left: x,
      top: y,
      width: boxWidth,
      height: boxHeight,
      child: Semantics(
        button: true,
        label: '${item.mood}, ${item.count} check-ins. Tap to filter.',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onSelected(item.mood),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                _weatherAssets[item.mood]!,
                width: imageSize,
                height: imageSize,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => Image.asset(
                  _moodIconAssets[item.mood]!,
                  width: imageSize * .75,
                  height: imageSize * .75,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.cloud_outlined,
                    size: imageSize * .65,
                    color: ink,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${item.mood[0].toUpperCase()}${item.mood.substring(1)}',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ink,
                  fontSize: dominant ? 13 : 11,
                  fontWeight: dominant ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${item.count} ${item.count == 1 ? 'check-in' : 'check-ins'}',
                textAlign: TextAlign.center,
                maxLines: 1,
                style: TextStyle(
                  color: widget.isDark
                      ? const Color(0xFFE3D6F6)
                      : const Color(0xFF70568C),
                  fontSize: dominant ? 11 : 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Magical Lavender Glass Garden: softly moving light behind frosted-glass cards.
// Decoration only: does not handle gestures, navigation, or Firebase data.
class _DashboardLavenderBackground extends StatefulWidget {
  final bool isDark;
  final Widget child;
  const _DashboardLavenderBackground({
    required this.isDark,
    required this.child,
  });

  @override
  State<_DashboardLavenderBackground> createState() =>
      _DashboardLavenderBackgroundState();
}

class _DashboardLavenderBackgroundState
    extends State<_DashboardLavenderBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  )..repeat();

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isDark
              ? const [
                  Color(0xFF151125),
                  Color(0xFF27203C),
                  Color(0xFF1D1D36),
                ]
              : const [
                  Color(0xFFF3EEFF),
                  Color(0xFFF8F1FD),
                  Color(0xFFECF5FF),
                  Color(0xFFFFF7FB),
                ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _DashboardLavenderPainter(
                    isDark: widget.isDark,
                    animation: _glow,
                  ),
                ),
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _DashboardLavenderPainter extends CustomPainter {
  final bool isDark;
  final Animation<double> animation;

  _DashboardLavenderPainter({
    required this.isDark,
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = animation.value * math.pi * 2;

    // Large ambient lavender/pink/blue glows give frosted frames something
    // to refract. All fades are painted directly; no image assets required.
    void orb(double x, double y, double radius, Color center, double phase) {
      final driftX = math.sin(t + phase) * size.width * 0.035;
      final driftY = math.cos(t * 0.7 + phase) * size.height * 0.018;
      final c = Offset(size.width * x + driftX, size.height * y + driftY);
      final rect = Rect.fromCircle(center: c, radius: radius);
      canvas.drawCircle(
        c,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [center, center.withValues(alpha: 0)],
            stops: const [0.0, 1.0],
          ).createShader(rect),
      );
    }

    final w = size.width;
    orb(-0.03, 0.13, w * 0.73,
        isDark ? const Color(0x776D52AD) : const Color(0x88C2A5F3), 0.0);
    orb(0.98, 0.35, w * 0.75,
        isDark ? const Color(0x665A77C1) : const Color(0x88AED5FA), 1.5);
    orb(0.21, 0.68, w * 0.63,
        isDark ? const Color(0x555B477D) : const Color(0x88F7CBE4), 3.1);
    orb(0.90, 0.91, w * 0.68,
        isDark ? const Color(0x5554819E) : const Color(0x77C9D6FF), 4.6);

    // Tiny, slow glimmers: understated so text and reflections stay clear.
    for (var i = 0; i < 26; i++) {
      final fx = ((i * 41 + 17) % 101) / 101.0;
      final fy = ((i * 73 + 29) % 103) / 103.0;
      final phase = t + i * 0.79;
      final x = fx * w + math.sin(phase * 0.55) * 5.0;
      final y = fy * size.height + math.cos(phase * 0.4) * 7.0;
      final pulse = (0.45 + math.sin(phase) * 0.25).clamp(0.12, 0.70);
      final radius = 1.6 + (i % 3) * 0.65;
      final c = isDark ? const Color(0xFFDCD1FF) : const Color(0xFFFFFFFF);
      canvas.drawCircle(
        Offset(x, y),
        radius * 4,
        Paint()
          ..color = c.withValues(alpha: pulse * 0.14)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()..color = c.withValues(alpha: pulse * 0.40),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashboardLavenderPainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.animation != animation;
}

class _DashboardButterflyLogo extends StatelessWidget {
  final double size;
  const _DashboardButterflyLogo({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: const _DashboardButterflyPainter(),
      ),
    );
  }
}

// Vector silhouette matched to the supplied green/lavender butterfly artwork:
// softly scalloped upper wings, a narrow waist, and long pointed lower tips.
// Painted directly in Flutter, so the silhouette stays crisp at any size.
class _DashboardButterflyPainter extends CustomPainter {
  const _DashboardButterflyPainter();

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
    drawHalf(const Color(0xFFB8AAC7), right: true); // lilac
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DashboardButterflyPainter oldDelegate) => false;
}