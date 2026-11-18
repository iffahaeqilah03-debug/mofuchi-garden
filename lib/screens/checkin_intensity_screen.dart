// ignore_for_file: recursive_getters, unused_element

import 'package:flutter/material.dart';
import '../widgets/mofuchi_background.dart';
import 'checkin_about_screen.dart';

class CheckInIntensityScreen extends StatefulWidget {
  final String selectedMood;
  final String moodEmoji;
  final String? moodImageAsset;

  const CheckInIntensityScreen({
    super.key,
    this.selectedMood = 'Happy',
    this.moodEmoji = '☀️',
    this.moodImageAsset,
  });

  @override
  State<CheckInIntensityScreen> createState() => _CheckInIntensityScreenState();
}

class _CheckInIntensityScreenState extends State<CheckInIntensityScreen> {
  // Theme-aware palette. UI changes only; check-in data flow is untouched.
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _fg => _isDark ? const Color(0xFFF8F4FF) : const Color(0xFF2D2430);
  Color get _sub => _isDark ? const Color(0xFFC5BBD3) : const Color(0xFF7A7288);
  Color get _sage => _isDark ? const Color(0xFFB8CDB8) : const Color(0xFF6E7F68);
  Color get _accent => _isDark ? const Color(0xFFC6AEF5) : const Color(0xFF7E57C2);
  Color get _panel => _isDark
    ? const Color(0xE5292538)
    : Colors.white.withValues(alpha: 0.85);
  Color get _panelBorder => _isDark ? const Color(0xFF514662) : Colors.white;
  Color get _softPanel => _isDark ? const Color(0xFF352D43) : const Color(0xFFF3EFF9);
  Color get _track => _isDark ? const Color(0xFF5A506A) : const Color(0xFFE5DFEC);

  Widget _themeBackdrop({required Widget child}) {
    if (!_isDark) return MofuchiBackground(child: child);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF171421), Color(0xFF251D36), Color(0xFF1A192A)],
        ),
      ),
      child: SafeArea(child: child),
    );
  }

  int _intensity = 3;

  final Map<int, Map<String, String>> _intensityDetails = {
    1: {
      'title': 'Very Gentle',
      'desc': 'A soft, quiet whisper in the background.',
    },
    2: {
      'title': 'Mild',
      'desc': 'Present and felt, but easily carried.',
    },
    3: {
      'title': 'Moderate',
      'desc': 'Clearly there, with room for other feelings too.',
    },
    4: {
      'title': 'Noticeable',
      'desc': 'Taking up significant space in your thoughts.',
    },
    5: {
      'title': 'Intense',
      'desc': 'Full and overwhelming, deeply filling your day.',
    },
  };

  @override
  Widget build(BuildContext context) {
    final currentDetail = _intensityDetails[_intensity]!;

    return Scaffold(
      backgroundColor: _isDark ? const Color(0xFF171421) : const Color(0xFFF7F4FB),
      body: _themeBackdrop(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _circleNavButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => Navigator.maybePop(context),
                  ),
                  Text(
                    'Daily check-in',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _sage,
                    ),
                  ),
                  _circleNavButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'How strong did you feel this way?',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: _fg,
                      height: 1.25,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'There is no right or wrong intensity. Choose what feels true.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: _sub,
                      height: 1.45,
                    ),
                  ),
                  SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _panel,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _panelBorder, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        if (widget.moodImageAsset != null)
                          Image.asset(
                            widget.moodImageAsset!,
                            width: 32,
                            height: 32,
                            errorBuilder: (_, _, _) => Text(widget.moodEmoji, style: TextStyle(fontSize: 26)),
                          )
                        else
                          Text(widget.moodEmoji, style: TextStyle(fontSize: 26)),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.selectedMood,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _fg,
                                ),
                              ),
                              Text(
                                'Your weather today',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  color: _sub,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.check_rounded,
                          color: _accent,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    decoration: BoxDecoration(
                      color: _panel,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: _panelBorder, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.10),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '$_intensity',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 58,
                                  fontWeight: FontWeight.w700,
                                  color: _accent,
                                ),
                              ),
                              TextSpan(
                                text: ' / 5',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: _sub,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          currentDetail['title']!,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _fg,
                          ),
                        ),
                        SizedBox(height: 18),
                        _buildEmotionVisual(),
                        SizedBox(height: 20),
                        _buildStepTrack(),
                        SizedBox(height: 12),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Low', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: _sage)),
                              Text('Strong', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: _sage)),
                            ],
                          ),
                        ),
                        SizedBox(height: 18),
                        Text(
                          currentDetail['desc']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: _sub,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),

                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _panel,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text('• ᴗ •', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'A little noticing is already a little care.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11.5,
                            color: _sage,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  Center(
                    child: Text(
                      "There's no right amount to feel.",
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: _sage),
                    ),
                  ),
                  SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFA485F8), Color(0xFF7135CD)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7135CD).withValues(alpha: 0.22),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CheckInAboutScreen(
                              selectedMood: widget.selectedMood,
                              moodEmoji: widget.moodEmoji,
                              moodImageAsset: widget.moodImageAsset,
                              intensity: _intensity,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Next',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _monthName(int month) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][month - 1];

  // The display reacts to both the selected emotion and its intensity.
  Widget _buildEmotionVisual() {
    final mood = widget.selectedMood.trim().toLowerCase();
    final color = switch (mood) {
      'happy' => const Color(0xFFF3B64C),
      'surprise' => const Color(0xFFBC91F1),
      'sad' => const Color(0xFF78A8D8),
      'angry' => const Color(0xFFE88281),
      'fear' => const Color(0xFF9B9DC8),
      'disgust' => const Color(0xFF83B59A),
      _ => const Color(0xFFAA91D6),
    };
    final symbol = switch (mood) {
      'happy' => '☀️',
      'surprise' => '✨',
      'sad' => '💧',
      'angry' => '⚡',
      'fear' => '🌫️',
      'disgust' => '🍃',
      _ => widget.moodEmoji,
    };
    final description = switch (mood) {
      'happy' => 'Sunshine grows brighter',
      'surprise' => 'More sparkles appear',
      'sad' => 'Raindrops become stronger',
      'angry' => 'The storm grows stronger',
      'fear' => 'The mist grows thicker',
      'disgust' => 'The breeze grows stronger',
      _ => 'Your feeling becomes stronger',
    };

    return Semantics(
      label: '${widget.selectedMood} visual intensity $_intensity out of 5',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 15, 12, 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Column(
          children: [
            Text(description, style: TextStyle(
              fontFamily: 'Poppins', fontSize: 11,
              color: _sub, fontWeight: FontWeight.w500,
            )),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final visible = index < _intensity;
                return Expanded(
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: visible ? 1 : 0.18,
                      duration: const Duration(milliseconds: 280),
                      child: AnimatedScale(
                        scale: visible ? 1 : 0.70,
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutBack,
                        child: Text(symbol, style: TextStyle(fontSize: 25)),
                      ),
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: 12),
            Row(
              children: List.generate(5, (index) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeInOut,
                      height: 8 + (index * 5).toDouble(),
                      decoration: BoxDecoration(
                        color: index < _intensity
                            ? color
                            : const Color(0xFFE5DFEC),
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: 8),
            Text('Tap a number below to change the intensity',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 10,
                color: _sub)),
          ],
        ),
      ),
    );
  }

  Widget _buildStepTrack() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        const circleSize = 36.0;
        final spacing = (totalWidth - (circleSize * 5)) / 4;

        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: circleSize / 2,
              right: circleSize / 2,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: _track,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Positioned(
              left: circleSize / 2,
              width: (_intensity - 1) * (circleSize + spacing),
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF7E57C2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (index) {
                final value = index + 1;
                final isSelected = value == _intensity;
                final isPassed = value < _intensity;

                return GestureDetector(
                  onTap: () => setState(() => _intensity = value),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isSelected ? 40 : 34,
                    height: isSelected ? 40 : 34,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF7E57C2) : _panel,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? Colors.white
                            : (isPassed ? _accent : _track),
                        width: isSelected ? 3 : 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF7135CD).withValues(alpha: 0.22),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                    ),
                    child: Center(
                      child: Text(
                        '$value',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: isSelected ? 14 : 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isPassed ? _accent : _sub),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _stepBar({required bool active, required String label}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: active ? const Color(0xFF9F7CF3) : const Color(0xFFE5DFEC),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 9.5,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? const Color(0xFF7E57C2) : const Color(0xFF7A7288),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleNavButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _panel,
          shape: BoxShape.circle,
          border: Border.all(color: _panelBorder, width: 1),
        ),
        child: Icon(icon, size: 18, color: _fg),
      ),
    );
  }
}