// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../widgets/mofuchi_background.dart';
import 'checkin_imagevideo.dart';

class CheckInAboutScreen extends StatefulWidget {
  final String selectedMood;
  final String moodEmoji;
  final String? moodImageAsset;
  final int intensity;

  const CheckInAboutScreen({
    super.key,
    required this.selectedMood,
    required this.moodEmoji,
    this.moodImageAsset,
    required this.intensity,
  });

  @override
  State<CheckInAboutScreen> createState() => _CheckInAboutScreenState();
}

class _CheckInAboutScreenState extends State<CheckInAboutScreen> {
  // Theme-aware palette. UI changes only; check-in data flow is untouched.
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _fg => _isDark ? const Color(0xFFF8F4FF) : const Color(0xFF2D2430);
  Color get _sub => _isDark ? const Color(0xFFC5BBD3) : const Color(0xFF7A7288);
  Color get _panel => _isDark
    ? const Color(0xE5292538)
    : Colors.white.withValues(alpha: 0.85);
  Color get _sage => _isDark ? const Color(0xFFB8CDB8) : const Color(0xFF6E7F68);
  Color get _accent => _isDark ? const Color(0xFFC6AEF5) : const Color(0xFF7E57C2);
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

  String _selectedCategory = 'Academic';

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Academic', 'icon': Icons.school_rounded},
    {'name': 'Achievement', 'icon': Icons.emoji_events_rounded},
    {'name': 'Health', 'icon': Icons.favorite_border_rounded},
    {'name': 'Friends & Social', 'icon': Icons.groups_rounded},
    {'name': 'Financial', 'icon': Icons.account_balance_wallet_rounded},
    {'name': 'Relationship', 'icon': Icons.favorite_rounded},
    {'name': 'Leisure & Hobbies', 'icon': Icons.palette_outlined},
    {'name': 'Daily Life', 'icon': Icons.today_rounded},
    {'name': 'Family', 'icon': Icons.family_restroom_rounded},
    {'name': 'Other', 'icon': Icons.more_horiz_rounded},
  ];
  @override
  Widget build(BuildContext context) {
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
                    'What is it about?',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: _fg,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Choose the area of life that brought this weather to your day.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: _sub,
                    ),
                  ),
                  SizedBox(height: 20),

                  // Borderless Mofuchi 3D preview, placed directly over
                  // the check-in screen background.
                  const SizedBox(
                    height: 222,
                    width: double.infinity,
                    child: ModelViewer(
                      key: ValueKey('mofuchi-about-upright'),
                      src: 'assets/3D/mofuchi.glb',
                      alt: '3D Mofuchi mascot',
                      // Roll the model 180 degrees to correct an upside-down export.
                      orientation: '0deg 0deg 180deg',
                      cameraControls: false,
                      disableZoom: true,
                      autoRotate: false,
                      autoPlay: false,
                      backgroundColor: Colors.transparent,
                      shadowIntensity: 0,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Choose the main area of your day',
                    style: TextStyle(fontSize: 12, color: _sub, fontFamily: 'Poppins')),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat['name'];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat['name']),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (_isDark ? const Color(0xFF5F4798) : const Color(0xFF9C7AF1))
                                : _panel,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF9C7AF1) : _panelBorder,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? const Color(0xFF7E57C2).withValues(alpha: 0.3)
                                    : Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                cat['icon'],
                                size: 18,
                                color: isSelected ? Colors.white : _sage,
                              ),
                              SizedBox(width: 8),
                              Text(
                                cat['name'],
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? Colors.white : _fg,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 40),

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
                            builder: (_) => CheckInImageVideoScreen(
                              selectedMood: widget.selectedMood,
                              moodEmoji: widget.moodEmoji,
                              moodImageAsset: widget.moodImageAsset,
                              intensity: widget.intensity,
                              selectedCategory: _selectedCategory,
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
                  SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
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