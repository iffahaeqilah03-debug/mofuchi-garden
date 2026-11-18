import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show ImageFilter;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../models/mood_entry.dart';
import '../services/emotion_service.dart';

// Colors follow the current MaterialApp theme; no separate screen toggle.

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _ink => _isDark ? const Color(0xFFF6F1FC) : const Color(0xFF30273C);
  Color get _muted => _isDark ? const Color(0xFFC2B8CE) : const Color(0xFF847A91);
  Color get _purple => _isDark ? const Color(0xFFC1A5F7) : const Color(0xFF8060C6);
  Color get _surface => _isDark ? const Color(0xFF282333) : Colors.white;
  Color get _subtle => _isDark ? const Color(0xFF383048) : const Color(0xFFF1EAFD);

  final _search = TextEditingController();
  final _service = EmotionService();
  String? _mood;
  String _order = 'Newest';
  bool _mediaOnly = false;
  DateTimeRange? _dates;

  static const _moods = <String, String>{
    'happy': 'assets/images/mood_icons/happy.png',
    'surprise': 'assets/images/mood_icons/surprise.png',
    'sad': 'assets/images/mood_icons/sad.png',
    'angry': 'assets/images/mood_icons/angry.png',
    'disgust': 'assets/images/mood_icons/disgust.png',
    'fear': 'assets/images/mood_icons/fear.png',
  };

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _inRange(DateTime date) {
    if (_dates == null) return true;
    final day = DateUtils.dateOnly(date);
    return !day.isBefore(_dates!.start) && !day.isAfter(_dates!.end);
  }

  void _resetFilters() => setState(() {
    _mood = null;
    _mediaOnly = false;
    _order = 'Newest';
    _dates = null;
    _search.clear();
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(child: Text('Please log in to see your memories.'));
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('emotion_logs')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Could not load your memories.\n${snapshot.error}',
                textAlign: TextAlign.center),
          ));
        }
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final all = snapshot.data!.docs.map((doc) {
          final data = doc.data();
          final stamp = data['createdAt'];
          return MoodEntry(
            id: doc.id,
            mood: (data['emotion'] as String? ?? 'unknown').toLowerCase(),
            intensity: (data['intensity'] as num?)?.toInt() ?? 0,
            category: (data['eventCategory'] as String?) ??
                (data['category'] as String?) ?? 'General',
            note: (data['shortThought'] as String?) ?? '',
            mediaPath: data['localMediaPath'] as String?,
            mediaType: data['attachmentType'] as String?,
            timestamp: stamp is Timestamp
                ? stamp.toDate()
                : DateTime.fromMillisecondsSinceEpoch(0),
          );
        }).toList();

        final query = _search.text.trim().toLowerCase();
        final filtered = all.where((e) {
          return (_mood == null || e.mood == _mood) &&
              (!_mediaOnly || e.mediaPath != null) &&
              _inRange(e.timestamp) &&
              (query.isEmpty ||
                  e.mood.contains(query) ||
                  e.note.toLowerCase().contains(query) ||
                  e.category.toLowerCase().contains(query));
        }).toList()
          ..sort((a, b) => _order == 'Newest'
              ? b.timestamp.compareTo(a.timestamp)
              : a.timestamp.compareTo(b.timestamp));

        final positive = all.where((e) =>
            e.mood == 'happy' || e.mood == 'surprise').length;
        final historyContent = ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
            children: [
              Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My memory garden', style: TextStyle(
                      fontFamily: 'Poppins', fontSize: 25,
                      fontWeight: FontWeight.w700, color: _ink)),
                    SizedBox(height: 3),
                    Text('Every feeling has a place to grow.',
                        style: TextStyle(fontSize: 12, color: _muted)),
                  ],
                )),
                _circleAction(Icons.calendar_month_outlined, () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                    initialDateRange: _dates,
                  );
                  if (picked != null && mounted) setState(() => _dates = picked);
                }),
              ]),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: _isDark
                      ? [const Color(0xFF3E3156), const Color(0xFF292336)]
                      : [const Color(0xFFF1E8FF), const Color(0xFFFFF6EF)]),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _isDark ? const Color(0xFF5B4B70) : Colors.white, width: 1.5),
                ),
                child: Row(children: [
                  Text('🌷', style: TextStyle(fontSize: 34)),
                  const SizedBox(width: 13),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${all.length} moments collected',
                        style: TextStyle(fontSize: 17,
                            fontWeight: FontWeight.w700, color: _ink)),
                      const SizedBox(height: 4),
                      Text('$positive uplifting • ${all.length - positive} other feelings',
                        style: TextStyle(fontSize: 11, color: _muted)),
                    ],
                  )),
                ]),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search notes, moods, categories...',
                  prefixIcon: Icon(Icons.search, color: _purple),
                  suffixIcon: _search.text.isEmpty ? null : IconButton(
                    onPressed: () => setState(_search.clear),
                    icon: Icon(Icons.close, size: 18)),
                  filled: true,
                  fillColor: _isDark ? const Color(0xFF30283E) : Colors.white.withValues(alpha: 0.86),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(17),
                    borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
              const SizedBox(height: 13),
              SizedBox(height: 38, child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _chip('All', null, _mood == null,
                      () => setState(() => _mood = null)),
                  ..._moods.entries.map((e) => _chip(
                    _capital(e.key), e.value, _mood == e.key,
                    () => setState(() => _mood = e.key),
                  )),
                ],
              )),
              const SizedBox(height: 12),
              Row(children: [
                FilterChip(
                  label: Text('With memories', style: TextStyle(fontSize: 11)),
                  avatar: Icon(Icons.perm_media_outlined, size: 16),
                  selected: _mediaOnly,
                  onSelected: (v) => setState(() => _mediaOnly = v),
                  selectedColor: _isDark ? const Color(0xFF685089) : const Color(0xFFE4D6FC),
                  backgroundColor: _surface,
                  side: BorderSide.none,
                ),
                const Spacer(),
                DropdownButton<String>(
                  value: _order,
                  underline: const SizedBox.shrink(),
                  icon: Icon(Icons.swap_vert, size: 18),
                  items: ['Newest', 'Oldest'].map((v) =>
                    DropdownMenuItem(value: v, child: Text(v,
                      style: TextStyle(fontSize: 12, color: _ink)))).toList(),
                  onChanged: (v) { if (v != null) setState(() => _order = v); },
                ),
              ]),
              if (_dates != null) Align(
                alignment: Alignment.centerLeft,
                child: ActionChip(
                  label: Text('Date filter ×'),
                  onPressed: () => setState(() => _dates = null),
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Text('Your reflections', style: TextStyle(
                    color: _ink, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 8),
                Text('(${filtered.length})', style: TextStyle(color: _muted)),
              ]),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: _isDark ? _surface : Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(24)),
                  child: Column(children: [
                    Text('🌱', style: TextStyle(fontSize: 38)),
                    const SizedBox(height: 10),
                    Text('No memories here yet',
                      style: TextStyle(fontWeight: FontWeight.bold, color: _ink)),
                    const SizedBox(height: 8),
                    TextButton(onPressed: _resetFilters,
                      child: Text('Clear filters')),
                  ]),
                )
              else
                ...filtered.map((entry) => Padding(
                  key: ValueKey(entry.id),
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _memoryCard(entry),
                )),
            ],
          );
        return _HistoryLavenderBackground(
          isDark: _isDark,
          child: SafeArea(child: historyContent),
        );
      },
    );
  }

  Widget _circleAction(IconData icon, VoidCallback callback) =>
      Material(color: _isDark ? _surface : Colors.white.withValues(alpha: 0.9),
        shape: const CircleBorder(),
        child: IconButton(onPressed: callback, icon: Icon(icon, color: _purple)));

  // Same translucent glass treatment as the Dashboard mood selector.
  // The icon viewport stays 36px while the artwork is enlarged within it.
  Widget _chip(String label, String? assetPath, bool selected, VoidCallback onTap) {
    final largeMood = assetPath == _moods['happy'] ||
        assetPath == _moods['sad'] || assetPath == _moods['angry'];
    final iconSize = largeMood ? 64.0 : 56.0;
    final radius = BorderRadius.circular(15);

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
              onTap: onTap,
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
                        ? _purple.withValues(alpha: _isDark ? .82 : .72)
                        : (_isDark
                            ? const Color(0x55FFFFFF)
                            : const Color(0xAAFFFFFF)),
                    width: selected ? 1.6 : 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(
                          alpha: _isDark ? 0.03 : 0.16),
                      blurRadius: 2,
                      offset: const Offset(0, -1),
                    ),
                    BoxShadow(
                      color: _purple.withValues(
                          alpha: selected ? (_isDark ? .22 : .18) : .04),
                      blurRadius: selected ? 16 : 12,
                      spreadRadius: selected ? .5 : 0,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (assetPath == null)
                      Icon(Icons.auto_awesome_rounded,
                          size: 20, color: _purple)
                    else
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: ClipRect(
                          child: OverflowBox(
                            alignment: Alignment.center,
                            minWidth: 0,
                            minHeight: 0,
                            maxWidth: iconSize,
                            maxHeight: iconSize,
                            child: Image.asset(
                              assetPath,
                              width: iconSize,
                              height: iconSize,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.spa_rounded,
                                size: 24,
                                color: _purple,
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 3),
                    Text(
                      label,
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

  Widget _memoryCard(MoodEntry entry) {
    return Material(
      color: _isDark ? _surface : Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(23),
      child: InkWell(
        borderRadius: BorderRadius.circular(23),
        onTap: () => _details(entry),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 45, height: 45, alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _subtle,
                    borderRadius: BorderRadius.circular(16)),
                  child: Text(entry.emoji, style: TextStyle(fontSize: 23)),
                ),
                const SizedBox(width: 11),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_capital(entry.mood), style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15, color: _ink)),
                    const SizedBox(height: 2),
                    Text(entry.intensity == 0 ? 'Earlier check-in' :
                        'Intensity ${entry.intensity}/5',
                      style: TextStyle(color: _muted, fontSize: 11)),
                  ],
                )),
                Icon(Icons.chevron_right_rounded, color: _purple),
              ]),
              const SizedBox(height: 12),
              Text(_format(entry.timestamp), style: TextStyle(
                color: Color(0xFF73906F), fontSize: 11)),
              if (entry.note.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(entry.note, maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _ink, fontSize: 13, height: 1.45)),
              ],
              if (entry.mediaPath != null) ...[
                const SizedBox(height: 11),
                _attachmentPreview(entry, height: 155),
              ],
              const SizedBox(height: 11),
              Row(children: [
                Icon(Icons.sell_outlined, size: 14, color: _purple),
                const SizedBox(width: 5),
                Expanded(child: Text(entry.category,
                  style: TextStyle(color: _muted, fontSize: 11))),
                Text('View memory', style: TextStyle(
                    color: _purple, fontWeight: FontWeight.w600, fontSize: 11)),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attachmentPreview(MoodEntry entry, {required double height}) {
    return FutureBuilder<File?>(
      future: _service.localAttachment({'localMediaPath': entry.mediaPath}),
      builder: (context, snap) {
        final file = snap.data;
        if (file == null) {
          return Container(
            height: 65, alignment: Alignment.centerLeft,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _subtle,
                borderRadius: BorderRadius.circular(14)),
            child: Text(snap.connectionState == ConnectionState.waiting
              ? 'Loading memory...' : 'Media unavailable on this device',
              style: TextStyle(color: _muted, fontSize: 11)),
          );
        }
        return GestureDetector(
          onTap: () => _openMedia(file, entry.mediaType),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(alignment: Alignment.center, children: [
              if (entry.mediaType == 'video')
                _VideoStill(file: file, height: height)
              else
                Image.file(file, width: double.infinity, height: height,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _mediaFallback(height)),
              if (entry.mediaType == 'video')
                Container(
                  decoration: BoxDecoration(color: Colors.black45,
                      borderRadius: BorderRadius.circular(100)),
                  child: Icon(Icons.play_circle_fill_rounded,
                    color: Colors.white, size: 51),
                ),
            ]),
          ),
        );
      },
    );
  }

  Widget _mediaFallback(double height) => Container(
    width: double.infinity, height: height,
    color: _subtle,
    child: Icon(Icons.perm_media_outlined, color: _purple),
  );

  void _openMedia(File file, String? type) {
    if (type == 'video') {
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => _LocalVideoScreen(file: file)));
    } else {
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(title: Text('Photo memory')),
          body: Center(child: InteractiveViewer(child: Image.file(file))),
        ),
      ));
    }
  }

  void _details(MoodEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
          child: SingleChildScrollView(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 42, height: 5,
                decoration: BoxDecoration(color: _isDark ? const Color(0xFF665674) : const Color(0xFFD5C8E9),
                    borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 22),
              Text('${entry.emoji}  ${_capital(entry.mood)} memory',
                style: TextStyle(fontSize: 22,
                    fontWeight: FontWeight.bold, color: _ink)),
              const SizedBox(height: 8),
              Text('${_format(entry.timestamp)}  ·  ${entry.category}',
                style: TextStyle(color: _muted, fontSize: 12)),
              const SizedBox(height: 5),
              Text(entry.intensity == 0 ? 'Earlier check-in' :
                  'Intensity ${entry.intensity}/5',
                  style: TextStyle(color: _purple)),
              const SizedBox(height: 17),
              Text(entry.note.isEmpty ? 'No written reflection.' : entry.note,
                style: TextStyle(fontSize: 14, height: 1.6, color: _ink)),
              if (entry.mediaPath != null) ...[
                const SizedBox(height: 19),
                _attachmentPreview(entry, height: 215),
                const SizedBox(height: 8),
                Text(entry.mediaType == 'video'
                    ? 'Tap to play video' : 'Tap to view photo',
                  style: TextStyle(color: _muted, fontSize: 11)),
              ],
            ],
          )),
        ),
      ),
    );
  }

  static String _capital(String text) => text.isEmpty ? text :
      '${text[0].toUpperCase()}${text.substring(1)}';

  static String _format(DateTime date) {
    if (date.year == 1970) return 'Date pending';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    return '${date.day} ${months[date.month - 1]} ${date.year} • '
        '$hour:${date.minute.toString().padLeft(2, '0')} '
        '${date.hour >= 12 ? 'PM' : 'AM'}';
  }
}


// Shared visual language with Dashboard: animated lavender/blue/pink ambient
// light, tiny glimmers, and the same light/dark gradient palette.
class _HistoryLavenderBackground extends StatefulWidget {
  final bool isDark;
  final Widget child;
  const _HistoryLavenderBackground({
    required this.isDark,
    required this.child,
  });

  @override
  State<_HistoryLavenderBackground> createState() =>
      _HistoryLavenderBackgroundState();
}

class _HistoryLavenderBackgroundState
    extends State<_HistoryLavenderBackground>
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
                  painter: _HistoryLavenderPainter(
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

class _HistoryLavenderPainter extends CustomPainter {
  final bool isDark;
  final Animation<double> animation;

  _HistoryLavenderPainter({required this.isDark, required this.animation})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = animation.value * math.pi * 2;
    void orb(double x, double y, double radius, Color center, double phase) {
      final driftX = math.sin(t + phase) * size.width * .035;
      final driftY = math.cos(t * .7 + phase) * size.height * .018;
      final c = Offset(size.width * x + driftX, size.height * y + driftY);
      final rect = Rect.fromCircle(center: c, radius: radius);
      canvas.drawCircle(
        c,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [center, center.withValues(alpha: 0)],
            stops: const [0, 1],
          ).createShader(rect),
      );
    }

    final w = size.width;
    orb(-.03, .13, w * .73,
        isDark ? const Color(0x776D52AD) : const Color(0x88C2A5F3), 0);
    orb(.98, .35, w * .75,
        isDark ? const Color(0x665A77C1) : const Color(0x88AED5FA), 1.5);
    orb(.21, .68, w * .63,
        isDark ? const Color(0x555B477D) : const Color(0x88F7CBE4), 3.1);
    orb(.90, .91, w * .68,
        isDark ? const Color(0x5554819E) : const Color(0x77C9D6FF), 4.6);

    for (var i = 0; i < 26; i++) {
      final fx = ((i * 41 + 17) % 101) / 101.0;
      final fy = ((i * 73 + 29) % 103) / 103.0;
      final phase = t + i * .79;
      final x = fx * w + math.sin(phase * .55) * 5;
      final y = fy * size.height + math.cos(phase * .4) * 7;
      final pulse = (0.45 + math.sin(phase) * .25).clamp(.12, .70);
      final radius = 1.6 + (i % 3) * .65;
      final c = isDark ? const Color(0xFFDCD1FF) : const Color(0xFFFFFFFF);
      canvas.drawCircle(
        Offset(x, y), radius * 4,
        Paint()
          ..color = c.withValues(alpha: pulse * .14)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(Offset(x, y), radius,
          Paint()..color = c.withValues(alpha: pulse * .40));
    }
  }

  @override
  bool shouldRepaint(covariant _HistoryLavenderPainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.animation != animation;
}

class _VideoStill extends StatefulWidget {
  final File file;
  final double height;
  const _VideoStill({required this.file, required this.height});

  @override
  State<_VideoStill> createState() => _VideoStillState();
}

class _VideoStillState extends State<_VideoStill> {
  late Future<Uint8List?> _image;
  @override
  void initState() {
    super.initState();
    _image = _load();
  }

  @override
  void didUpdateWidget(covariant _VideoStill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path) _image = _load();
  }

  Future<Uint8List?> _load() async {
    try {
      return await VideoThumbnail.thumbnailData(
        video: widget.file.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 500,
        quality: 75,
        timeMs: 1000,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
    future: _image,
    builder: (context, snap) => snap.data == null
      ? Container(width: double.infinity, height: widget.height,
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF383048) : const Color(0xFFEDE4FB))
      : Image.memory(snap.data!, width: double.infinity,
          height: widget.height, fit: BoxFit.cover),
  );
}

class _LocalVideoScreen extends StatefulWidget {
  final File file;
  const _LocalVideoScreen({required this.file});
  @override
  State<_LocalVideoScreen> createState() => _LocalVideoScreenState();
}

class _LocalVideoScreenState extends State<_LocalVideoScreen> {
  late final VideoPlayerController _player;
  late final Future<void> _ready;

  @override
  void initState() {
    super.initState();
    _player = VideoPlayerController.file(widget.file);
    _ready = _player.initialize().then((_) => _player.setVolume(1.0));
    // Avoid rebuilding the whole video page on every playback-position tick.
  }

  Future<void> _togglePlayback() async {
    if (!_player.value.isInitialized) return;
    if (_player.value.isPlaying) {
      await _player.pause();
    } else {
      if (_player.value.position >= _player.value.duration &&
          _player.value.duration > Duration.zero) {
        await _player.seekTo(Duration.zero);
      }
      await _player.play();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Video memory'),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF282333) : const Color(0xFFFAF5FF),
        foregroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFFF6F1FC) : const Color(0xFF30273C),
      ),
      body: SafeArea(
        child: FutureBuilder<void>(
          future: _ready,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Unable to play video.',
                    style: TextStyle(color: Colors.white)),
              );
            }
            if (snapshot.connectionState != ConnectionState.done) {
              return Center(
                child: CircularProgressIndicator(color: Color(0xFFB99AEE)),
              );
            }

            final aspect = _player.value.aspectRatio > 0
                ? _player.value.aspectRatio
                : 9 / 16;

            return Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final availableWidth = constraints.maxWidth;
                      final availableHeight = constraints.maxHeight;
                      final width = availableWidth < availableHeight * aspect
                          ? availableWidth
                          : availableHeight * aspect;
                      final height = width / aspect;
                      return Center(
                        child: SizedBox(
                          width: width,
                          height: height,
                          child: VideoPlayer(_player),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: ValueListenableBuilder<VideoPlayerValue>(
                    valueListenable: _player,
                    builder: (context, value, _) => IconButton(
                      tooltip: value.isPlaying ? 'Pause' : 'Play',
                      onPressed: _togglePlayback,
                      iconSize: 52,
                      color: const Color(0xFFD1B7FF),
                      icon: Icon(value.isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
