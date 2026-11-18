import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navAccent = isDark ? const Color(0xFFE1CFFF) : const Color(0xFF7045B2);
    final navInactive = isDark ? const Color(0xFFB6ACC6) : const Color(0xFF736780);
    final screens = <Widget>[
      HomeScreen(onOpenDashboard: () => setState(() => _currentIndex = 1)),
      const DashboardScreen(),
      const HistoryScreen(),
      const ProfileScreen(),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? const SystemUiOverlayStyle(
              statusBarColor: Color(0xFF171420),
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
              systemNavigationBarColor: Color(0xFF171420),
              systemNavigationBarIconBrightness: Brightness.light,
              systemNavigationBarDividerColor: Color(0xFF171420),
            )
          : const SystemUiOverlayStyle(
              statusBarColor: Color(0xFFF7F4FB),
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
              systemNavigationBarColor: Color(0xFFF7F4FB),
              systemNavigationBarIconBrightness: Brightness.dark,
              systemNavigationBarDividerColor: Color(0xFFF7F4FB),
            ),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF171420) : const Color(0xFFF7F4FB),
        body: Stack(
          fit: StackFit.expand,
          children: [
            screens[_currentIndex],
            Positioned(
              left: 30,
              right: 30,
              bottom: MediaQuery.viewPaddingOf(context).bottom + 16,
              child: Container(
                // Shadow lives OUTSIDE ClipRRect, so Light Mode stays visible.
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? const Color(0xFF080512).withValues(alpha: 0.48)
                          : const Color(0xFF483366).withValues(alpha: 0.22),
                      blurRadius: isDark ? 24 : 27,
                      spreadRadius: isDark ? 0 : 1,
                      offset: const Offset(0, 10),
                    ),
                    if (!isDark)
                      BoxShadow(
                        color: const Color(0xFF9D78D6).withValues(alpha: 0.12),
                        blurRadius: 9,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF282235).withValues(alpha: 0.54)
                            : Colors.white.withValues(alpha: 0.62),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.20)
                              : Colors.white.withValues(alpha: 0.96),
                          width: 1.3,
                        ),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final itemWidth = constraints.maxWidth / 4;
                          return Stack(
                            children: [
                              // A second, independently blurred glass lens glides
                              // across the frosted base, like a liquid-glass tab.
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeInOutCubicEmphasized,
                                left: itemWidth * _currentIndex + 3,
                                top: 3,
                                bottom: 3,
                                width: itemWidth - 6,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDark
                                            ? const Color(0xFFA47ADE).withValues(alpha: 0.21)
                                            : const Color(0xFF695080).withValues(alpha: 0.18),
                                        blurRadius: 13,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(999),
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: isDark
                                                ? [
                                                    const Color(0xFFE1CDFF).withValues(alpha: 0.28),
                                                    const Color(0xFFAF89E5).withValues(alpha: 0.14),
                                                    const Color(0xFFCDB3FC).withValues(alpha: 0.24),
                                                  ]
                                                : [
                                                    Colors.white.withValues(alpha: 0.80),
                                                    const Color(0xFFECE5F8).withValues(alpha: 0.53),
                                                    Colors.white.withValues(alpha: 0.73),
                                                  ],
                                          ),
                                          border: Border.all(
                                            color: isDark
                                                ? Colors.white.withValues(alpha: 0.48)
                                                : Colors.white.withValues(alpha: 0.93),
                                            width: 1.2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  _navItem(0, Icons.yard_outlined, Icons.yard_rounded,
                                      'Home', navAccent, navInactive),
                                  _navItem(1, Icons.bar_chart_rounded, Icons.insert_chart_rounded,
                                      'Dashboard', navAccent, navInactive),
                                  _navItem(2, Icons.history_rounded, Icons.history_rounded,
                                      'History', navAccent, navInactive),
                                  _navItem(3, Icons.person_outline_rounded, Icons.person_rounded,
                                      'Profile', navAccent, navInactive),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
    int index,
    IconData outline,
    IconData filled,
    String label,
    Color activeColor,
    Color inactiveColor,
  ) {
    final selected = _currentIndex == index;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: '$label tab',
        child: InkWell(
          onTap: () {
            if (_currentIndex != index) setState(() => _currentIndex = index);
          },
          borderRadius: BorderRadius.circular(999),
          child: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    selected ? filled : outline,
                    key: ValueKey('$index-$selected'),
                    size: 20,
                    color: selected ? activeColor : inactiveColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? activeColor : inactiveColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
