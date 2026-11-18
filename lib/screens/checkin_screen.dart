import 'package:flutter/material.dart';
import '../widgets/mofuchi_background.dart';
import 'checkin_intensity_screen.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  String _selectedMood = 'Happy';

  final List<Map<String, dynamic>> _moods = [
    {
      'name': 'Happy',
      'emoji': '☀️',
      'asset': 'assets/mood_icons/happy.png',
      'desc': 'Warm & sunny inside',
      'color': const Color(0xFFEEA849),
      'bg': const Color(0xFFFFF9ED),
    },
    {
      'name': 'Surprise',
      'emoji': '⚡',
      'asset': 'assets/mood_icons/surprise.png',
      'desc': 'Sudden spark of energy',
      'color': const Color(0xFFF59E0B),
      'bg': const Color(0xFFFFFBEB),
    },
    {
      'name': 'Sad',
      'emoji': '🌧️',
      'asset': 'assets/mood_icons/sad.png',
      'desc': 'Gentle rainy day',
      'color': const Color(0xFF194CB1),
      'bg': const Color(0xFFF0F5FD),
    },
    {
      'name': 'Angry',
      'emoji': '⛈️',
      'asset': 'assets/mood_icons/angry.png',
      'desc': 'Thunderstorm brewing',
      'color': const Color(0xFFDC2626),
      'bg': const Color(0xFFFEF2F2),
    },
    {
      'name': 'Disgust',
      'emoji': '🍃',
      'asset': 'assets/mood_icons/disgust.png',
      'desc': 'Uncomfortable & averse',
      'color': const Color(0xFF059669),
      'bg': const Color(0xFFECFDF5),
    },
    {
      'name': 'Fear',
      'emoji': '🌫️',
      'asset': 'assets/mood_icons/fear.png',
      'desc': 'Misty & uncertain',
      'color': const Color(0xFF7C3AED),
      'bg': const Color(0xFFF5F3FF),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final currentMood = _moods.firstWhere((m) => m['name'] == _selectedMood);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? const Color(0xFFF8F5FF) : const Color(0xFF2D2430);
    final muted = dark ? const Color(0xFFC2B9D0) : const Color(0xFF7A7288);
    final accent = dark ? const Color(0xFFC3A9F5) : const Color(0xFF7E57C2);

    return Scaffold(
      body: dark
          ? DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF151321), Color(0xFF242033), Color(0xFF171422)],
                ),
              ),
              child: _checkInContent(currentMood, dark, ink, muted, accent),
            )
          : MofuchiBackground(
              child: _checkInContent(currentMood, dark, ink, muted, accent),
            ),
    );
  }

  Widget _checkInContent(Map<String, dynamic> currentMood, bool dark,
      Color ink, Color muted, Color accent) {
    return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _circleBtn(
                      icon: Icons.chevron_left_rounded,
                      onTap: () => Navigator.maybePop(context),
                    ),
                    Text(
                      'Daily check-in',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: dark ? const Color(0xFFD7C9E8) : const Color(0xFF5A6B53),
                      ),
                    ),
                    _circleBtn(
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'STEP 1 OF 4',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: accent,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Today',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _stepBar(active: true, label: 'Mood'),
                        const SizedBox(width: 6),
                        _stepBar(active: false, label: 'Intensity'),
                        const SizedBox(width: 6),
                        _stepBar(active: false, label: 'About'),
                        const SizedBox(width: 6),
                        _stepBar(active: false, label: 'Reflection'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'How did your day feel?',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Choose the feeling that best fits today.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12.5,
                        color: muted,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(child: Container(
                      width: 86, height: 86,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                        color: dark ? const Color(0xFF403452) : const Color(0xFFF1EAF9),
                        border: Border.all(color: Colors.white.withValues(alpha: .75), width: 3)),
                      alignment: Alignment.center,
                      child: ClipOval(
                        child: Image.asset(
                          currentMood['asset'] as String,
                          width: 80,
                          height: 80,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => Text(
                            currentMood['emoji'] as String,
                            style: const TextStyle(fontSize: 42),
                          ),
                        ),
                      ),
                    )),
                    const SizedBox(height: 16),
                    // Reference-inspired stacked emotion cards.
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _moods.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 9),
                      itemBuilder: (context, index) {
                        final mood = _moods[index];
                        final selected = mood['name'] == _selectedMood;
                        return Semantics(
                          button: true,
                          selected: selected,
                          label: "${mood['name']} mood",
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => setState(() => _selectedMood = mood['name']),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: selected
                                    ? (dark ? const Color(0xFF3B3055) : const Color(0xFFF0E9FF))
                                    : (dark ? const Color(0xFF292438) : Colors.white.withValues(alpha: .85)),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: selected ? const Color(0xFFA485F8) :
                                      (dark ? const Color(0xFF514661) : Colors.white),
                                  width: selected ? 1.7 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 42,
                                    height: 42,
                                    child: Image.asset(
                                      mood['asset'] as String,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, _, _) => Center(
                                        child: Text(mood['emoji'] as String,
                                            style: const TextStyle(fontSize: 26)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 13),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(mood['name'], style: TextStyle(
                                        fontFamily: 'Poppins', fontWeight: FontWeight.w700,
                                        color: ink, fontSize: 13.5)),
                                      Text(mood['desc'], style: TextStyle(
                                        fontFamily: 'Poppins', fontSize: 11, color: muted)),
                                    ],
                                  )),
                                  if (selected) const Icon(Icons.check_rounded,
                                      size: 20, color: Color(0xFF9164E9)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 36),
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0xFFA485F8), Color(0xFF7135CD)],
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
                              builder: (_) => CheckInIntensityScreen(
                                selectedMood: _selectedMood,
                                moodEmoji: currentMood['emoji'],
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        child: const Row(
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
                 
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
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
              color: active ? const Color(0xFF9F7CF3) :
                  (Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF4A4159) : const Color(0xFFE5DFEC)),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 9.5,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? const Color(0xFF9F7CF3) :
                  (Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFC2B9D0) : const Color(0xFF7A7288)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF332C42) : Colors.white.withValues(alpha: 0.85),
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF665778) : Colors.white, width: 1),
        ),
        child: Icon(icon, size: 18, color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFF8F5FF) : const Color(0xFF2D2430)),
      ),
    );
  }
}