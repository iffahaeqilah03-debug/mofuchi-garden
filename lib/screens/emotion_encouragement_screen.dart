import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../widgets/mofuchi_background.dart';

/// Shown after a saved check-in, before the existing bloom/watering flow.
/// Optional reflection details can be supplied by the check-in screen.
class EmotionEncouragementScreen extends StatefulWidget {
  const EmotionEncouragementScreen({
    super.key,
    required this.emotion,
    required this.earnedXp,
    required this.onContinue,
    this.previousXp,
    this.totalXp,
    this.unlockedBadges = const [],
    this.intensity,
    this.reflection,
    this.checkInTime,
  });

  final String emotion;
  final int earnedXp;
  final int? previousXp;
  final int? totalXp;
  final List<String> unlockedBadges;
  final void Function(BuildContext context) onContinue;
  final int? intensity; // Expected range: 1–5.
  final String? reflection;
  final DateTime? checkInTime;

  @override
  State<EmotionEncouragementScreen> createState() =>
      _EmotionEncouragementScreenState();
}

class _EmotionEncouragementScreenState extends State<EmotionEncouragementScreen> {
  bool _continued = false;

  static const _levelXp = [0, 50, 120, 220, 350];
  static const _levelNames = [
    'Little Sprout', 'Growing Bud', 'Blooming Heart',
    'Sakura Keeper', 'Garden Guardian',
  ];

  int _level(int xp) {
    var level = 0;
    for (var i = 1; i < _levelXp.length; i++) {
      if (xp >= _levelXp[i]) level = i;
    }
    return level;
  }

  String? get _firstName {
    final name = FirebaseAuth.instance.currentUser?.displayName?.trim();
    if (name == null || name.isEmpty) return null;
    return name.split(RegExp(r'\s+')).first;
  }

  ({String emoji, String name, String heading, String message,
    String gentleTitle, String gentleTip, Color accent}) get _mood {
    switch (widget.emotion.trim().toLowerCase()) {
      case 'happy':
        return (emoji: '☀️', name: 'Happy', heading: 'A little care, saved.',
          message: 'Your joy has a place in your garden. Enjoy this little moment.',
          gentleTitle: 'Let the good settle in',
          gentleTip: 'Take one slow breath and enjoy this little win.',
          accent: const Color(0xFFE4A63A));
      case 'sad':
        return (emoji: '🌧️', name: 'Sad', heading: 'Your feelings have a place.',
          message: 'You do not have to bloom every day. Thank you for checking in.',
          gentleTitle: 'A soft moment is enough',
          gentleTip: 'Give yourself permission to rest and take things slowly.',
          accent: const Color(0xFF628BC0));
      case 'angry':
        return (emoji: '🍂', name: 'Angry', heading: 'You deserve a gentle pause.',
          message: 'Big feelings deserve room and care, too.',
          gentleTitle: 'Make room to breathe',
          gentleTip: 'Unclench your shoulders and pause before your next step.',
          accent: const Color(0xFFCB785D));
      case 'fear':
        return (emoji: '🌙', name: 'Fear', heading: 'One step at a time.',
          message: 'You do not have to figure everything out today.',
          gentleTitle: 'Take it at your pace',
          gentleTip: 'Notice one thing around you that helps you feel grounded.',
          accent: const Color(0xFF807BCB));
      case 'disgust':
        return (emoji: '🍃', name: 'Disgust', heading: 'Your boundaries matter.',
          message: 'Uncomfortable feelings deserve compassion, too.',
          gentleTitle: 'Give yourself some space',
          gentleTip: 'It is okay to step away from what feels uncomfortable.',
          accent: const Color(0xFF67967C));
      case 'surprise':
        return (emoji: '🌈', name: 'Surprise', heading: 'A moment to take it in.',
          message: 'Unexpected moments can bring all sorts of feelings.',
          gentleTitle: 'Let yourself process it',
          gentleTip: 'You do not have to make sense of everything at once.',
          accent: const Color(0xFF8A7AD1));
      default:
        return (emoji: '🌸', name: widget.emotion.trim().isEmpty
            ? 'Feeling' : widget.emotion.trim(),
          heading: 'A little care, saved.',
          message: 'Thank you for checking in. Every feeling has a place here.',
          gentleTitle: 'Care begins with noticing',
          gentleTip: 'Take a gentle breath and return when you are ready.',
          accent: const Color(0xFF8E76C3));
    }
  }

  // The custom emotion icon appears in the saved-moment card; the hero uses Mofuchi.
  String? get _moodIconAsset {
    switch (widget.emotion.trim().toLowerCase()) {
      case 'happy':
      case 'sad':
      case 'angry':
      case 'fear':
      case 'disgust':
      case 'surprise':
        return 'assets/images/mood_icons/${widget.emotion.trim().toLowerCase()}.png';
      default:
        return null;
    }
  }

  Widget _savedMoodIcon() {
    final asset = _moodIconAsset;
    if (asset == null) {
      return const Icon(Icons.spa_rounded, color: Color(0xFF9471D6), size: 27);
    }
    return Image.asset(
      asset,
      width: 44,
      height: 44,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.spa_rounded, color: Color(0xFF9471D6), size: 27),
    );
  }

  void _continue() {
    if (_continued) return;
    _continued = true;
    widget.onContinue(context);
  }

  String _dateLabel(DateTime? value) {
    if (value == null) return 'Your latest check-in';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final meridiem = value.hour < 12 ? 'AM' : 'PM';
    return '${months[value.month - 1]} ${value.day} · $hour:$minute $meridiem';
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mood = _mood;
    final firstName = _firstName;
    final ink = dark ? const Color(0xFFF8F5FF) : const Color(0xFF362B45);
    final muted = dark ? const Color(0xFFC9C0D5) : const Color(0xFF82798D);
    final panel = dark ? const Color(0xFF302A40) : Colors.white;
    final oldLevel = widget.previousXp == null ? null : _level(widget.previousXp!);
    final newLevel = widget.totalXp == null ? null : _level(widget.totalXp!);
    final leveledUp = oldLevel != null && newLevel != null && newLevel > oldLevel;
    final reflection = widget.reflection?.trim();
    final intensity = widget.intensity;

    final content = SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.spa_rounded, size: 19, color: mood.accent),
                    const SizedBox(width: 8),
                    Text('MOFUCHI GARDEN', style: TextStyle(
                      color: ink, fontFamily: 'Poppins', fontSize: 11,
                      fontWeight: FontWeight.w700, letterSpacing: 1.4)),
                    const Spacer(),
                    Text('Daily check-in', style: TextStyle(
                      color: muted, fontFamily: 'Poppins', fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('CHECK-IN COMPLETE', style: TextStyle(
                          fontFamily: 'Poppins', fontWeight: FontWeight.w700,
                          letterSpacing: 1.4, fontSize: 10,
                          color: dark ? const Color(0xFFD4BAFF) : const Color(0xFF8060C6))),
                        const SizedBox(height: 12),
                        Text(mood.heading, style: TextStyle(
                          fontFamily: 'Poppins', fontSize: 26, height: 1.2,
                          fontWeight: FontWeight.w700, color: ink)),
                        const SizedBox(height: 9),
                        Text(firstName == null
                            ? 'Thank you for checking in. ${mood.message}'
                            : 'Thank you for checking in, $firstName. ${mood.message}',
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 12.5, height: 1.65, color: muted)),
                        const SizedBox(height: 22),
                         // Same transparent, upright 3D Mofuchi as the About screen.
                         const SizedBox(
                           height: 188,
                           width: double.infinity,
                           child: ModelViewer(
                             key: ValueKey('mofuchi-encouragement-upright'),
                             src: 'assets/3D/mofuchi.glb',
                             alt: 'Mofuchi celebrating your check-in',
                             orientation: '0deg 0deg 180deg',
                             cameraControls: false,
                             disableZoom: true,
                             autoRotate: false,
                             autoPlay: false,
                             backgroundColor: Colors.transparent,
                             shadowIntensity: 0,
                           ),
                         ),
                        const SizedBox(height: 10),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: dark ? const Color(0xFF403554) : const Color(0xFFF4EEFF),
                              borderRadius: BorderRadius.circular(24)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.check_circle_outline_rounded,
                                color: Color(0xFF9169D4), size: 15),
                              const SizedBox(width: 6),
                              Text('Check-in saved', style: TextStyle(
                                fontFamily: 'Poppins', fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: dark ? const Color(0xFFE1D0FF) : const Color(0xFF8060C6))),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 25),
                        Text("TODAY'S LITTLE MOMENT", style: TextStyle(
                          color: muted, fontSize: 10, fontWeight: FontWeight.w700,
                          letterSpacing: 1.3, fontFamily: 'Poppins')),
                        const SizedBox(height: 9),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: panel,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: dark
                                ? const Color(0xFF4C435A) : const Color(0xFFF0EAF4)),
                            boxShadow: [BoxShadow(
                              color: const Color(0xFF62517F).withValues(alpha: dark ? .12 : .07),
                              blurRadius: 22, offset: const Offset(0, 8))]),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                _savedMoodIcon(),
                                const SizedBox(width: 10),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(mood.name, style: TextStyle(fontFamily: 'Poppins',
                                      fontSize: 15, fontWeight: FontWeight.w700, color: ink)),
                                    Text(_dateLabel(widget.checkInTime), style: TextStyle(
                                      fontSize: 10.5, color: muted, fontFamily: 'Poppins')),
                                  ],
                                )),
                                Text('Saved', style: TextStyle(
                                  color: mood.accent, fontFamily: 'Poppins', fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                              ]),
                              if (intensity != null && intensity >= 1 && intensity <= 5) ...[
                                const SizedBox(height: 14),
                                Text('Intensity · $intensity of 5', style: TextStyle(
                                  color: ink, fontSize: 12, fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600)),
                              ],
                              if (reflection != null && reflection.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(reflection, style: TextStyle(
                                  fontFamily: 'Poppins', fontSize: 12,
                                  color: muted, height: 1.6)),
                              ],
                              const SizedBox(height: 15),
                              Divider(color: dark ? const Color(0xFF544B64)
                                  : const Color(0xFFEFEAF3), height: 1),
                              const SizedBox(height: 13),
                              Text(mood.gentleTitle, style: TextStyle(
                                color: dark ? const Color(0xFFC0D6BA) : const Color(0xFF6D8A72),
                                fontFamily: 'Poppins', fontSize: 12,
                                fontWeight: FontWeight.w600)),
                              const SizedBox(height: 5),
                              Text(mood.gentleTip, style: TextStyle(
                                color: muted, fontFamily: 'Poppins',
                                fontSize: 11.5, height: 1.5)),
                            ],
                          ),
                        ),
                        if (widget.earnedXp > 0 || leveledUp || widget.unlockedBadges.isNotEmpty) ...[
                          const SizedBox(height: 13),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: dark ? const Color(0xFF352E48)
                                  : const Color(0xFFF4F0FF),
                              borderRadius: BorderRadius.circular(18)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.earnedXp > 0)
                                  Text('✨ +${widget.earnedXp} XP earned',
                                    style: const TextStyle(color: Color(0xFF9471D6),
                                      fontWeight: FontWeight.w700, fontFamily: 'Poppins',
                                      fontSize: 13)),
                                // ignore: unnecessary_null_comparison
                                if (leveledUp && newLevel != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text('🎉 Level up · ${_levelNames[newLevel]}',
                                      style: TextStyle(color: ink, fontFamily: 'Poppins',
                                        fontSize: 12, fontWeight: FontWeight.w600)),
                                  ),
                                for (final badge in widget.unlockedBadges)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text('🏅 Achievement unlocked: $badge',
                                      style: TextStyle(color: ink, fontFamily: 'Poppins',
                                        fontSize: 11.5)),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text('Come back whenever your weather changes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, fontFamily: 'Poppins', fontSize: 10.5)),
                const SizedBox(height: 11),
                 Container(
                   height: 52,
                   decoration: BoxDecoration(
                     gradient: const LinearGradient(
                       begin: Alignment.centerLeft,
                       end: Alignment.centerRight,
                       colors: [Color(0xFFA485F8), Color(0xFF7135CD)],
                     ),
                     borderRadius: BorderRadius.circular(16),
                     boxShadow: [
                       BoxShadow(
                         color: const Color(0xFF7135CD).withValues(alpha: 0.22),
                         blurRadius: 14,
                         offset: const Offset(0, 5),
                       ),
                     ],
                   ),
                   child: Material(
                     color: Colors.transparent,
                     child: InkWell(
                       onTap: _continue,
                       borderRadius: BorderRadius.circular(16),
                       child: const Row(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           Icon(Icons.spa_rounded, color: Colors.white, size: 18),
                           SizedBox(width: 9),
                           Text(
                             'Continue to My Garden',
                             style: TextStyle(
                               fontFamily: 'Poppins',
                               fontWeight: FontWeight.w700,
                               fontSize: 12.5,
                               color: Colors.white,
                             ),
                           ),
                         ],
                       ),
                     ),
                   ),
                 ),
              ],
            ),
          ),
        ),
      ),
    );

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: dark ? const Color(0xFF171421)
            : const Color(0xFFF9F5FB),
        body: dark ? content : MofuchiBackground(child: content),
      ),
    );
  }
}
