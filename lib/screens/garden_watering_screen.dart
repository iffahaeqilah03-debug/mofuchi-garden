import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'sakura_bloom_screen.dart';

/// Optional self-care moment shown after a saved negative-emotion check-in.
/// No additional Firestore writes or bloom increments occur on this screen.
class GardenWateringScreen extends StatefulWidget {
  final String emotion;
  final bool showBloomAfter;
  final int previousLevel;
  final int currentLevel;

  const GardenWateringScreen({
    super.key,
    required this.emotion,
    required this.showBloomAfter,
    required this.previousLevel,
    required this.currentLevel,
  });

  @override
  State<GardenWateringScreen> createState() => _GardenWateringScreenState();
}

class _GardenWateringScreenState extends State<GardenWateringScreen> {
  int _waters = 0;
  bool _navigating = false;
  bool _splash = false;
  Timer? _splashTimer;

  static const _purple = Color(0xFF8060C6);
  static const _sage = Color(0xFF67866A);

  bool get _dark => Theme.of(context).brightness == Brightness.dark;
  Color get _ink => _dark ? const Color(0xFFF5F0FF) : const Color(0xFF30273C);
  Color get _muted => _dark ? const Color(0xFFC9C0D7) : const Color(0xFF746B7C);
  Color get _card => _dark ? const Color(0xFF2B253B) : Colors.white;
  Color get _soft => _dark ? const Color(0xFF3B304D) : const Color(0xFFF7F0FC);

  String get _supportMessage {
    switch (widget.emotion.trim().toLowerCase()) {
      case 'sad':
        return 'You don’t have to feel happy every day. A little kindness is enough for now.';
      case 'angry':
        return 'Strong feelings need space, too. Give yourself a gentle moment.';
      case 'fear':
        return 'It’s okay to feel uncertain. You can take things one step at a time.';
      case 'disgust':
        return 'Difficult experiences deserve care, too. Your feelings are welcome here.';
      default:
        return 'Every feeling deserves care. Take a gentle moment for yourself.';
    }
  }

  void _waterGarden() {
    if (_waters >= 3 || _navigating) return;
    _splashTimer?.cancel();
    setState(() {
      _waters++;
      _splash = true;
    });
    _splashTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _splash = false);
    });
  }

  void _continue() {
    if (_navigating) return;
    _navigating = true;
    if (widget.showBloomAfter) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => SakuraBloomScreen(
            previousLevel: widget.previousLevel,
            currentLevel: widget.currentLevel,
            emotion: widget.emotion,
          ),
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = _waters >= 3;
    return Scaffold(
      backgroundColor: _dark ? const Color(0xFF171421) : const Color(0xFFF7F2FC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('MOFUCHI GARDEN', style: TextStyle(
                        color: _dark ? const Color(0xFFC5AFF1) : _purple,
                        fontSize: 11, letterSpacing: 1.8, fontWeight: FontWeight.w700,
                      )),
                      TextButton(
                        onPressed: _continue,
                        child: Text('Skip', style: TextStyle(color: _muted)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Nurture Your Garden',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700,
                      fontSize: 24, color: _ink),
                  ),
                  const SizedBox(height: 8),
                  Text('Every feeling deserves a little care. 💜',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: _muted),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _card, borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _dark ? const Color(0xFF554768) : const Color(0xFFEADCF5)),
                    ),
                    child: Text(_supportMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(height: 1.55, fontSize: 13, color: _ink),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: _dark
                              ? [const Color(0xFF38304E), const Color(0xFF25382F)]
                              : [const Color(0xFFF3E5FA), const Color(0xFFE3F1E7)],
                        ),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: DragTarget<String>(
                              // ignore: unrelated_type_equality_checks
                              onWillAcceptWithDetails: (value) => value == 'water' && !done,
                              onAcceptWithDetails: (_) => _waterGarden(),
                              builder: (context, candidates, rejected) => AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(26),
                                  border: Border.all(
                                    color: candidates.isNotEmpty ? _purple : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: 190,
                                      width: 230,
                                      child: CustomPaint(painter: _SakuraCarePainter()),
                                    ),
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 250),
                                      child: _splash
                                          ? const Text('💧  💦  💧', key: ValueKey('splash'),
                                              style: TextStyle(fontSize: 29))
                                          : Text(done ? 'Thank you for caring!' : 'Drop water here',
                                              key: ValueKey(done),
                                              style: TextStyle(color: _dark
                                                  ? const Color(0xFFDAF1D9) : _sage,
                                                fontSize: 12, fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (!done)
                            Positioned(
                              bottom: 14,
                              left: 16,
                              child: Draggable<String>(
                                data: 'water',
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: _wateringCan(dragging: true),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.25,
                                  child: _wateringCan(),
                                ),
                                child: _wateringCan(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(done
                      ? 'Your garden has been cared for. Your feelings still matter.'
                      : 'Drag the watering can onto your Sakura tree',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: _muted),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Garden care', style: TextStyle(color: _ink,
                          fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('$_waters / 3', style: TextStyle(color: _muted, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      minHeight: 8, value: _waters / 3,
                      backgroundColor: _soft,
                      color: const Color(0xFF8BBF98),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity, height: 49,
                    child: FilledButton(
                      onPressed: _continue,
                      style: FilledButton.styleFrom(
                        backgroundColor: _purple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: Text(done ? 'Continue to My Garden' : 'Continue without watering'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _wateringCan({bool dragging = false}) => Container(
    width: 92, height: 85,
    decoration: BoxDecoration(
      color: _dark ? const Color(0xFF524368) : Colors.white.withValues(alpha: .92),
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFB99DDF)),
      boxShadow: dragging ? [const BoxShadow(color: Color(0x33000000), blurRadius: 12)] : null,
    ),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const SizedBox(width: 54, height: 43, child: CustomPaint(painter: _WateringCanPainter())),
      Text('DRAG WATER', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold,
        color: _dark ? Colors.white : _purple)),
    ]),
  );
}

// A lightweight, package-free garden illustration for the watering mini-game.
// The actual 3D GLB on Home and Sakura Bloom remains completely unchanged.
class _SakuraCarePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final ground = size.height * .85;
    final trunk = Paint()..color = const Color(0xFF97735F)..strokeWidth = 15
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, ground), Offset(cx, ground * .35), trunk);
    for (final item in <(double, double, double)>[
      (-48, 70, 34), (0, 48, 44), (48, 70, 35),
      (-23, 98, 39), (25, 100, 36), (0, 78, 42),
    ]) {
      canvas.drawCircle(Offset(cx + item.$1, item.$2), item.$3,
        Paint()..color = const Color(0xFFF4A9CE).withValues(alpha: .92));
    }
    final petals = Paint()..color = const Color(0xFFFFD7EB).withValues(alpha: .7);
    for (var i = 0; i < 23; i++) {
      final theta = i * 2.39996;
      final r = math.sqrt(i.toDouble()) * 10;
      canvas.drawCircle(Offset(cx + math.cos(theta) * r, 80 + math.sin(theta) * r),
        2.7, petals);
    }
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, ground + 9),
      width: 190, height: 25), Paint()..color = const Color(0xFF8CB897));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// A simple watering-can silhouette; avoids adding image assets or dependencies.
class _WateringCanPainter extends CustomPainter {
  const _WateringCanPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = const Color(0xFF9B80CC);
    final outline = Paint()
      ..color = const Color(0xFF6A539E)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(10, 12, 32, 26), const Radius.circular(7));
    canvas.drawRRect(body, fill);
    canvas.drawRRect(body, outline);
    canvas.drawArc(Rect.fromLTWH(0, 7, 23, 24),
      math.pi * .5, math.pi * 1.3, false, outline);
    final spout = Path()
      ..moveTo(38, 18)
      ..lineTo(51, 8)
      ..lineTo(55, 12)
      ..lineTo(43, 26);
    canvas.drawPath(spout, outline);
    canvas.drawLine(const Offset(19, 10), const Offset(34, 10), outline);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
