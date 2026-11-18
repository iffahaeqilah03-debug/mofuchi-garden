// ignore_for_file: unused_element_parameter

import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import '../widgets/mofuchi_gradient_surface.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import '../services/reminder_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _butterflyController;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _emotionStream;
  bool _dailyReminder = false;
  bool _showAllAchievements = false;
  int _reminderHour = 20;
  int _reminderMinute = 0;
  String _reminderFrequency = 'Daily';
  bool _savingReminder = false;
  String _selectedAvatar = 'default';
  static const _avatarChoices = <String, String>{
    'default': 'Mofuchi',
    'sakura': '🌸',
    'sprout': '🌱',
    'flower': '🌼',
    'heart': '💜',
    'sun': '☀️',
    'star': '⭐',
  };

  String get _avatarKey =>
      'mofuchi_profile_avatar_${FirebaseAuth.instance.currentUser?.uid ?? 'guest'}';

  @override
  void initState() {
    super.initState();
    _butterflyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _emotionStream = FirebaseFirestore.instance
        .collection('emotion_logs')
        .where('userId', isEqualTo: uid)
        .snapshots();
    _loadReminder();
    _loadAvatar();
  }

  @override
  void dispose() {
    _butterflyController.dispose();
    super.dispose();
  }

  Future<void> _loadAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_avatarKey) ?? 'default';
    if (mounted) {
      setState(() => _selectedAvatar =
        _avatarChoices.containsKey(saved) ? saved : 'default');
    }
  }

  Future<void> _selectAvatar() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Choose your Mofuchi avatar 🌸',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 17,
                fontWeight: FontWeight.w700, color: _ink)),
            const SizedBox(height: 6),
            Text('Pick a picture that feels like you',
              style: TextStyle(fontSize: 12, color: _muted)),
            const SizedBox(height: 18),
            Wrap(spacing: 13, runSpacing: 13, alignment: WrapAlignment.center,
              children: _avatarChoices.entries.map((item) {
                final isSelected = item.key == _selectedAvatar;
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.of(sheetContext).pop(item.key),
                  child: Container(
                    width: 84, height: 100,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _innerSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? _accent : _border,
                        width: isSelected ? 2.5 : 1),
                    ),
                    child: Column(children: [
                      Expanded(child: ClipOval(child: _avatarView(item.key))),
                      const SizedBox(height: 4),
                      Text(item.key == 'default' ? 'Mofuchi' : 'Select',
                        style: TextStyle(fontSize: 10, color: _ink)),
                    ]),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ]),
        ),
      ),
    );
    if (selected == null || !mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_avatarKey, selected);
      if (mounted) setState(() => _selectedAvatar = selected);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save avatar: $e')));
      }
    }
  }

  Widget _avatarView(String avatar) {
    if (avatar == 'default') {
      return Image.asset('assets/images/mofuchi_avatar.png',
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Center(
          child: Text('🌱', style: TextStyle(fontSize: 34))));
    }
    return ColoredBox(
      color: _dark ? const Color(0xFF453654) : const Color(0xFFF7EEFC),
      child: Center(child: Text(_avatarChoices[avatar] ?? '🌸',
        style: const TextStyle(fontSize: 36))),
    );
  }

  Future<void> _loadReminder() async {
    try {
      final settings = await MofuchiReminderService.instance.load();
      if (!mounted) return;
      setState(() {
        _dailyReminder = settings.enabled;
        _reminderHour = settings.hour;
        _reminderMinute = settings.minute;
        _reminderFrequency = settings.frequency;
      });
    } catch (e) {
      debugPrint('Reminder settings load failed: $e');
    }
  }

  Future<void> _applyReminder(ReminderPreferences desired) async {
    if (_savingReminder) return;
    setState(() => _savingReminder = true);
    try {
      await MofuchiReminderService.instance.save(desired);
      if (!mounted) return;
      setState(() {
        _dailyReminder = desired.enabled;
        _reminderHour = desired.hour;
        _reminderMinute = desired.minute;
        _reminderFrequency = desired.frequency;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
        desired.enabled ? 'Your gentle reminder is scheduled 🌸' : 'Reminders turned off',
      )));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
        'Could not update reminder: $e',
      )));
    } finally {
      if (mounted) setState(() => _savingReminder = false);
    }
  }

  ReminderPreferences get _reminderSettings => ReminderPreferences(
    enabled: _dailyReminder,
    hour: _reminderHour,
    minute: _reminderMinute,
    frequency: _reminderFrequency,
  );

  Future<void> _pickReminderTime() async {
    final chosen = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderHour, minute: _reminderMinute),
      initialEntryMode: TimePickerEntryMode.input,
      helpText: 'SET YOUR REMINDER TIME',
      hourLabelText: 'Hour',
      minuteLabelText: 'Minute',
      confirmText: 'Save Time',
      builder: (pickerContext, child) => MediaQuery(
        data: MediaQuery.of(pickerContext).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (chosen == null || !mounted) return;
    await _applyReminder(_reminderSettings.copyWith(
      hour: chosen.hour, minute: chosen.minute));
  }

  Future<void> _pickReminderFrequency() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final value in ['Daily', 'Weekdays', 'Weekends'])
            ListTile(
              title: Text(value),
              subtitle: Text(value == 'Daily' ? 'Every day'
                  : value == 'Weekdays' ? 'Monday to Friday' : 'Saturday and Sunday'),
              trailing: _reminderFrequency == value
                  ? const Icon(Icons.check_rounded) : null,
              onTap: () => Navigator.pop(sheetContext, value),
            ),
        ]),
      ),
    );
    if (choice == null || !mounted) return;
    await _applyReminder(_reminderSettings.copyWith(frequency: choice));
  }

  String get _reminderTimeLabel {
    final hour = _reminderHour % 12 == 0 ? 12 : _reminderHour % 12;
    final minute = _reminderMinute.toString().padLeft(2, '0');
    final period = _reminderHour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }


  // Uses the saved app-wide MaterialApp theme from main.dart.
  bool get _dark => Theme.of(context).brightness == Brightness.dark;
  Color get _ink => _dark ? const Color(0xFFF5F1FC) : const Color(0xFF2D2430);
  Color get _muted => _dark ? const Color(0xFFB9B0C9) : const Color(0xFF7A7288);
  Color get _faint => _dark ? const Color(0xFFAA9EBB) : const Color(0xFF9E94A7);
  Color get _accent => _dark ? const Color(0xFFC5ABF4) : const Color(0xFF7E57C2);
  Color get _sage => _dark ? const Color(0xFFA9D4AE) : const Color(0xFF3F5E38);
  Color get _surface => _dark ? const Color(0xFF292437) : Colors.white;
  Color get _innerSurface => _dark ? const Color(0xFF342C45) : const Color(0xFFF6F1FC);
  Color get _border => _dark ? const Color(0xFF746286) : const Color(0xCFFFFFFF);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to view your profile.'));
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _emotionStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Could not load profile insights.\n${snapshot.error}',
              textAlign: TextAlign.center));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final insights = _ProfileInsights.fromSnapshot(snapshot.data!, DateTime.now());
        final displayName = user.displayName?.trim();
        final profileName = displayName != null && displayName.isNotEmpty
            ? displayName : 'Garden Friend';
        final profileEmail = user.email ?? '';
        final totalEntries = insights.total;
        final dominant = insights.mostLogged;
        final dominantPct = insights.dominantPercent;
        final otherPct = insights.last7.isEmpty ? 0 : 100 - dominantPct;

        return _ProfileLavenderBackground(
          isDark: _dark,
          child: SafeArea(
            child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Floating hand-drawn sage + lavender butterfly, same as Dashboard.
              Center(
                child: SizedBox(
                  height: 48,
                  width: 58,
                  child: AnimatedBuilder(
                    animation: _butterflyController,
                    child: const _ProfileButterflyLogo(size: 36),
                    builder: (context, child) {
                      if (MediaQuery.disableAnimationsOf(context)) {
                        return Center(child: child);
                      }
                      final phase = _butterflyController.value * 2 * math.pi;
                      return Transform.translate(
                        offset: Offset(math.sin(phase + math.pi / 2) * 2.5,
                            math.sin(phase) * 6.0),
                        child: Transform.rotate(
                          angle: math.sin(phase) * .075,
                          child: Center(child: child),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('My little garden', textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Poppins', fontSize: 25,
                  fontWeight: FontWeight.w700, color: _ink)),
              const SizedBox(height: 4),
              Text('Your space, your growth, your journey.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: _muted)),
              const SizedBox(height: 20),
              // 1. Top Bar: Profile title & Edit Profile button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your profile',
                    
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: _dark ? 0.13 : 0.35),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _dark ? _border : Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextButton(
                      onPressed: _selectAvatar,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Change Avatar',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _accent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Avatar & User Info
              Row(
                children: [
                  GestureDetector(
                    onTap: _selectAvatar,
                    behavior: HitTestBehavior.opaque,
                    child: Stack(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: _surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: _dark ? _border : Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(child: _avatarView(_selectedAvatar)),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: _border, width: 1.5),
                          ),
                          child: Icon(
                            Icons.camera_alt_outlined,
                            size: 13,
                            color: _accent,
                          ),
                        ),
                      ),
                    ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profileName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        profileEmail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: _muted,
                        ),
                      ),
                    ],
                  ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. Mood Summary Card
              _buildGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      icon: Icons.person_outline_rounded,
                      title: 'Mood Summary · Last 7 Days',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Last 7 days: most logged mood',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: _muted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dominant,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: _ink,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              '$dominantPct%',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              dominant == 'Happy' ? '☀️' : '😌',
                              style: TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: dominantPct / 100,
                        minHeight: 8,
                        backgroundColor: _dark ? const Color(0xFF4A3C60) : _border,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        insights.last7.isEmpty ? 'No mood data yet' : '$otherPct% other moods',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: _faint,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Garden Statistics Card
              _buildGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      icon: Icons.person_outline_rounded,
                      title: 'Your Garden Statistics',
                    ),
                    const SizedBox(height: 16),
                    // Two tidy rows give long labels and values room to breathe.
                    Row(
                      children: [
                        Expanded(child: _buildStatTile(
                          icon: Icons.auto_stories_outlined,
                          label: 'Total Reflections',
                          value: '$totalEntries',
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: _buildStatTile(
                          icon: Icons.spa_outlined,
                          label: 'Most Logged (7d)',
                          value: dominant,
                        )),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildStatTile(
                          icon: Icons.local_fire_department_outlined,
                          label: 'Current Streak',
                          value: '${insights.currentStreak} Days',
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: _buildStatTile(
                          icon: Icons.emoji_events_outlined,
                          label: 'Longest Streak',
                          value: '${insights.longestStreak} Days',
                        )),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Live insights match Dashboard's default 7-day reporting window.
              _buildGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      icon: Icons.insights_rounded,
                      title: 'Your Emotion Insights · Last 7 Days',
                    ),
                    const SizedBox(height: 7),
                    Text('A gentle look at your recent feelings.',
                        style: TextStyle(fontSize: 11, color: _muted)),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: _buildStatTile(
                        icon: Icons.edit_calendar_outlined,
                        label: 'Check-ins (7d)',
                        value: '${insights.last7.length}',
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: _buildStatTile(
                        icon: Icons.graphic_eq_rounded,
                        label: 'Average Intensity',
                        value: insights.averageIntensity,
                      )),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: _buildStatTile(
                        icon: Icons.wb_sunny_outlined,
                        label: 'Uplifting Check-ins',
                        value: '${insights.uplifting}',
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: _buildStatTile(
                        icon: Icons.category_outlined,
                        label: 'Top Event Category',
                        value: insights.topCategory,
                      )),
                    ]),
                    if (insights.last7.isEmpty) ...[
                      const SizedBox(height: 12),
                      Text('No reflections in the last 7 days yet.',
                          style: TextStyle(fontSize: 11, color: _muted)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 5. Achievement collection: real check-in history + live XP.
              _buildAchievementCollection(user.uid, snapshot.data!.docs, insights),
              const SizedBox(height: 16),

              // 6. Reminder Settings Card — functioning local notifications
              _buildGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      icon: Icons.notifications_none_rounded,
                      title: 'Reminder Settings',
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Daily Reminder', style: TextStyle(
                              fontFamily: 'Poppins', fontSize: 12,
                              fontWeight: FontWeight.w600, color: _ink,
                            )),
                            Text('Get reminded to reflect on your day',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 10.5, color: _muted)),
                          ],
                        )),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: _dailyReminder,
                            activeThumbColor: Colors.white,
                            activeTrackColor: const Color(0xFF48A14D),
                            onChanged: _savingReminder ? null : (value) =>
                                _applyReminder(_reminderSettings.copyWith(enabled: value)),
                          ),
                        ),
                      ],
                    ),
                    Divider(color: _border, height: 22),
                    Row(children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reminder Time', style: TextStyle(
                            fontFamily: 'Poppins', fontSize: 12,
                            fontWeight: FontWeight.w600, color: _ink,
                          )),
                          Text('Choose the time you want to be reminded',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 10.5, color: _muted)),
                        ],
                      )),
                      InkWell(
                        onTap: _savingReminder ? null : _pickReminderTime,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: _dark ? _innerSurface : Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _border),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.alarm_rounded, size: 14, color: _muted),
                            const SizedBox(width: 4),
                            Text(_reminderTimeLabel, style: TextStyle(
                              fontFamily: 'Poppins', fontSize: 11,
                              fontWeight: FontWeight.w500, color: _ink,
                            )),
                          ]),
                        ),
                      ),
                    ]),
                    Divider(color: _border, height: 22),
                    Row(children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reminder Frequency', style: TextStyle(
                            fontFamily: 'Poppins', fontSize: 12,
                            fontWeight: FontWeight.w600, color: _ink,
                          )),
                          Text('How often would you like to receive reminders?',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 10.5, color: _muted)),
                        ],
                      )),
                      InkWell(
                        onTap: _savingReminder ? null : _pickReminderFrequency,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: _dark ? _innerSurface : Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _border),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.calendar_today_outlined, size: 13, color: _muted),
                            const SizedBox(width: 4),
                            Text(_reminderFrequency, style: TextStyle(
                              fontFamily: 'Poppins', fontSize: 11,
                              fontWeight: FontWeight.w500, color: _ink,
                            )),
                          ]),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 7. Account Options Card
              _buildGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      icon: Icons.person_outline_rounded,
                      title: 'Account',
                    ),
                    const SizedBox(height: 14),
                    _buildAccountRow(
                      icon: Icons.lock_outline_rounded,
                      label: 'Change Password',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const _ChangePasswordPage()),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildAccountRow(
                      icon: Icons.info_outline_rounded,
                      label: 'About Mofuchi',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const _AboutMofuchiPage()),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildAccountRow(
                      icon: Icons.shield_outlined,
                      label: 'Privacy Policy',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const _PrivacyPolicyPage()),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildAccountRow(
                      icon: Icons.logout_rounded,
                      label: 'Logout',
                      isDestructive: true,
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
              ),
          ),
        );
      },
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _dark
                  ? const [Color(0x665D4C78), Color(0x44362B4F)]
                  : const [Color(0xBFFFFFFF), Color(0x72F4EDFF)],
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: _dark ? const Color(0x66F1E8FF) : const Color(0xDDFFFFFF),
              width: 1.4,
            ),
            boxShadow: [BoxShadow(
              color: const Color(0xFF9275C5).withValues(alpha: _dark ? .12 : .10),
              blurRadius: 21,
              offset: const Offset(0, 8),
            )],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _sage),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: _sage,
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 106),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: _dark ? .09 : .34),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: _dark ? const Color(0x70EBDDFF) : const Color(0xE6FFFFFF),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: _accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                    color: _muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCollection(
    String uid,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> logs,
    _ProfileInsights insights,
  ) {
    // Count only real, user-written reflections. A generated fallback note
    // ("Felt ... today") should not unlock journaling achievements.
    var writtenReflections = 0;
    var mediaEntries = 0;
    final checkInDays = <DateTime>{};
    for (final doc in logs) {
      final data = doc.data();
      final mood = (data['emotion'] as String? ?? '').toLowerCase().trim();
      final stamp = data['createdAt'];
      if (stamp is! Timestamp ||
          !const ['happy', 'surprise', 'sad', 'angry', 'fear', 'disgust'].contains(mood)) {
        continue;
      }
      final local = stamp.toDate().toLocal();
      checkInDays.add(DateTime(local.year, local.month, local.day));
      final thought = (data['shortThought'] as String? ?? '').trim();
      if (thought.isNotEmpty &&
          !RegExp(r'^Felt .+ today \(\d/5\) about .+\.$', caseSensitive: false)
              .hasMatch(thought)) {
        writtenReflections++;
      }
      if (data['attachmentType'] == 'image' || data['attachmentType'] == 'video') {
        mediaEntries++;
      }
    }

    // One full Monday-Sunday set of distinct days unlocks Weekly Bloomer.
    final weeks = <DateTime, int>{};
    for (final day in checkInDays) {
      final monday = day.subtract(Duration(days: day.weekday - 1));
      weeks[monday] = (weeks[monday] ?? 0) + 1;
    }
    final bestWeek = weeks.values.fold<int>(0, (best, n) => n > best ? n : best);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('gamification_progress').doc(uid).snapshots(),
      builder: (context, xpSnapshot) {
        final rawXp = xpSnapshot.data?.data()?['totalXp'];
        final xpAvailable = !xpSnapshot.hasError && xpSnapshot.hasData;
        final xp = (rawXp is num ? rawXp.toInt() : 0).clamp(0, 9999999).toInt();
        final badges = <_MofuchiBadge>[
          _MofuchiBadge('First Bloom', 'first_bloom',
              'Complete your first emotion check-in.', insights.total, 1),
          _MofuchiBadge('Reflection Star', 'reflection_star',
              'Write 5 personal reflections.', writtenReflections, 5),
          _MofuchiBadge('7-Day Sakura', '7_day_sakura',
              'Check in on 7 consecutive days.', insights.longestStreak, 7),
          _MofuchiBadge('Garden Guardian', 'garden_guardian',
              'Reach 350 lifetime XP (Level 5).', xp, 350,
              available: xpAvailable),
          _MofuchiBadge('Growing Bud', 'growing_bud',
              'Earn 50 lifetime XP (Level 2).', xp, 50,
              available: xpAvailable),
          _MofuchiBadge('3-Day Streak', '3_day_streak',
              'Check in on 3 consecutive days.', insights.longestStreak, 3),
          _MofuchiBadge('Weekly Bloomer', 'weekly_bloomer',
              'Check in on all 7 days of one Monday–Sunday week.', bestWeek, 7),
          _MofuchiBadge('Open Heart', 'open_heart',
              'Write your first personal reflection.', writtenReflections, 1),
          _MofuchiBadge('Deep Reflection', 'deep_reflection',
              'Write 10 personal reflections.', writtenReflections, 10),
          _MofuchiBadge('Story Keeper', 'story_keeper',
              'Save a check-in with a photo or video.', mediaEntries, 1),
        ];
        final unlocked = badges.where((b) => b.unlocked).length;
        // Preview earned badges first; users can expand to see the full collection.
        final preview = [...badges.where((b) => b.unlocked),
          ...badges.where((b) => !b.unlocked)].take(3).toList();
        final visibleBadges = _showAllAchievements ? badges : preview;
        return _buildGlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildSectionHeader(icon: Icons.workspace_premium_outlined,
                title: 'My Achievement Collection'),
            const SizedBox(height: 7),
            Text('$unlocked of ${badges.length} badges unlocked',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                    fontWeight: FontWeight.w600, color: _ink)),
            const SizedBox(height: 9),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: unlocked / badges.length,
                minHeight: 7,
                color: const Color(0xFF8C69D3),
                backgroundColor: _dark
                    ? const Color(0xFF4A415B) : const Color(0xFFEDE5F7),
              ),
            ),
            const SizedBox(height: 7),
            Text('Every emotion counts. Tap a badge to see its goal.',
                style: TextStyle(fontSize: 10.5, color: _muted)),
            if (xpSnapshot.hasError) ...[
              const SizedBox(height: 8),
              Text('XP badges unavailable — check Firestore access.',
                  style: TextStyle(color: _muted, fontSize: 10)),
            ],
            const SizedBox(height: 16),
            LayoutBuilder(builder: (context, constraints) {
              final columns = constraints.maxWidth >= 500 ? 3 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visibleBadges.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.86,
                ),
                itemBuilder: (context, index) => _buildBadgeTile(visibleBadges[index]),
              );
            }),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => setState(() =>
                    _showAllAchievements = !_showAllAchievements),
                icon: Icon(_showAllAchievements
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded),
                label: Text(_showAllAchievements
                    ? 'Show Less' : 'More · View All 10 Badges'),
                style: TextButton.styleFrom(
                  foregroundColor: _accent,
                  backgroundColor: _innerSurface,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildBadgeTile(_MofuchiBadge badge) {
    final unlocked = badge.unlocked;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: Text(badge.title, textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700, fontSize: 17)),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(height: 150, child: Image.asset(badge.asset,
                  fit: BoxFit.contain)),
              const SizedBox(height: 14),
              Text(badge.description, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(badge.available
                  ? (unlocked ? 'Unlocked! ✨' : '${badge.progress} / ${badge.goal}')
                  : 'XP progress unavailable',
                  style: const TextStyle(fontWeight: FontWeight.w700,
                      color: Color(0xFF8060C6))),
            ]),
            actions: [TextButton(onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close'))],
          ),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 9, 8, 10),
          decoration: BoxDecoration(
            color: unlocked
                ? (_dark ? const Color(0xFF443452) : const Color(0xFFF9F0FF))
                : (_dark ? const Color(0xFF302B3A) : const Color(0xFFF4F1F7)),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: unlocked
                  ? const Color(0xFFCC9CE9) : _border,
              width: unlocked ? 1.4 : 1,
            ),
            boxShadow: unlocked ? [BoxShadow(
              color: const Color(0xFFBB88DB).withValues(alpha: 0.16),
              blurRadius: 12,
            )] : null,
          ),
          child: Column(children: [
            Expanded(child: Stack(alignment: Alignment.center, children: [
              Positioned.fill(child: Image.asset(
                badge.asset,
                fit: BoxFit.contain,
                color: unlocked ? null : Colors.grey,
                colorBlendMode: unlocked ? null : BlendMode.saturation,
                errorBuilder: (_, _, _) => Icon(Icons.military_tech_outlined,
                    size: 55, color: _accent),
              )),
              if (!unlocked)
                Positioned(bottom: 0, right: 0,
                  child: Container(padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: _surface,
                        shape: BoxShape.circle),
                    child: Icon(Icons.lock_rounded, color: _muted, size: 14)),
                ),
            ])),
            const SizedBox(height: 4),
            Text(badge.title,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Poppins', fontSize: 10.5,
                    fontWeight: FontWeight.w700, color: _ink)),
            const SizedBox(height: 3),
            Text(unlocked ? 'UNLOCKED ✨' : badge.available
                    ? '${badge.progress} / ${badge.goal}' : 'Unavailable',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                    color: unlocked ? _sage : _muted)),
          ]),
        ),
      ),
    );
  }

  Widget _buildAccountRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? (_dark ? const Color(0xFFFF858A) : const Color(0xFFC93B3B)) : _ink;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
          Icon(Icons.chevron_right_rounded, size: 18, color: color.withValues(alpha: 0.6)),
        ],
      ),
    );
  }
}

class _MofuchiBadge {
  const _MofuchiBadge(this.title, this.file, this.description,
      this.progress, this.goal, {this.available = true});
  final String title;
  final String file;
  final String description;
  final int progress;
  final int goal;
  final bool available;
  bool get unlocked => available && progress >= goal;
  String get asset => 'assets/images/badges/$file.png';
}

// Profile subpages are kept in this file to avoid new route imports or
// changing the existing navigation / reminder implementation.
class _ProfileDetailShell extends StatelessWidget {
  const _ProfileDetailShell({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = dark ? const Color(0xFFF5F1FC) : const Color(0xFF30273B);
    final background = dark ? const Color(0xFF151321) : const Color(0xFFF9F5FF);
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        backgroundColor: background,
        foregroundColor: foreground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF292437) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: dark ? const Color(0xFF53465F) : const Color(0xFFF1EDF8)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangePasswordPage extends StatefulWidget {
  const _ChangePasswordPage();
  @override
  State<_ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<_ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _hideCurrent = true;
  bool _hideNext = true;
  bool _hideConfirm = true;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _notice(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _changePassword() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      _notice('Please sign in with your email account first.');
      return;
    }
    setState(() => _busy = true);
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: _current.text),
      );
      await user.updatePassword(_next.text);
      if (!mounted) return;
      _current.clear();
      _next.clear();
      _confirm.clear();
      _notice('Password changed successfully 🌸');
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      final message = switch (error.code) {
        'wrong-password' || 'invalid-credential' => 'Your current password is incorrect.',
        'weak-password' => 'Please choose a stronger password.',
        'requires-recent-login' => 'Please log out and log in again, then retry.',
        'too-many-requests' => 'Too many attempts. Try again later.',
        'network-request-failed' => 'Check your internet connection.',
        'user-mismatch' || 'user-not-found' => 'Please sign in again.',
        _ => 'Could not update password. Please try again.',
      };
      _notice(message);
    } catch (_) {
      if (mounted) _notice('Could not update password. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendResetEmail() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null || email.isEmpty) {
      _notice('No email address is linked to this account.');
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) _notice('If eligible, a password reset email will arrive shortly.');
    } on FirebaseAuthException catch (_) {
      if (mounted) _notice('Could not send the reset email. Try again later.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? const Color(0xFFF5F1FC) : const Color(0xFF30273B);
    final muted = dark ? const Color(0xFFB9B0C9) : const Color(0xFF7A7288);
    final fill = dark ? const Color(0xFF342C45) : const Color(0xFFF8F5FF);
    InputDecoration deco(String label, bool hidden, VoidCallback toggle) => InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: muted),
      filled: true,
      fillColor: fill,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      suffixIcon: IconButton(
        onPressed: toggle,
        tooltip: hidden ? 'Show password' : 'Hide password',
        icon: Icon(hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined),
      ),
    );
    Widget field(TextEditingController controller, String label, bool hidden, VoidCallback toggle,
        {String? Function(String?)? validator}) => TextFormField(
      controller: controller,
      obscureText: hidden,
      autocorrect: false,
      enableSuggestions: false,
      style: TextStyle(color: ink),
      cursorColor: const Color(0xFF8B5CF6),
      decoration: deco(label, hidden, toggle),
      validator: validator,
    );

    return _ProfileDetailShell(title: 'Change Password', children: [
      const Icon(Icons.lock_reset_rounded, color: Color(0xFF9A79D7), size: 44),
      const SizedBox(height: 12),
      Text('Protect your little garden', textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 17, color: ink)),
      const SizedBox(height: 8),
      Text('Enter your current password before choosing a new one.', textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: muted)),
      const SizedBox(height: 20),
      Form(key: _formKey, child: Column(children: [
        field(_current, 'Current password', _hideCurrent,
            () => setState(() => _hideCurrent = !_hideCurrent),
            validator: (v) => (v == null || v.isEmpty) ? 'Enter your current password' : null),
        const SizedBox(height: 14),
        field(_next, 'New password', _hideNext,
            () => setState(() => _hideNext = !_hideNext),
            validator: (v) => (v == null || v.length < 8) ? 'Use at least 8 characters' : null),
        const SizedBox(height: 14),
        field(_confirm, 'Confirm new password', _hideConfirm,
            () => setState(() => _hideConfirm = !_hideConfirm),
            validator: (v) => v != _next.text ? 'Passwords do not match' : null),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 50, child: MofuchiGradientSurface(child: FilledButton(
          onPressed: _busy ? null : _changePassword,
          style: (FilledButton.styleFrom(backgroundColor: const Color(0xFF8062C8))).copyWith(backgroundColor: const WidgetStatePropertyAll<Color>(Colors.transparent), shadowColor: const WidgetStatePropertyAll<Color>(Colors.transparent), surfaceTintColor: const WidgetStatePropertyAll<Color>(Colors.transparent)),
          child: _busy ? const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save New Password', style: TextStyle(color: Colors.white)),
        ))),
      ])),
      const SizedBox(height: 10),
      TextButton(
        onPressed: _busy ? null : _sendResetEmail,
        child: const Text('Forgot current password? Send reset email'),
      ),
      Text('Password changes require an email/password Firebase account.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: muted)),
    ]);
  }
}

class _AboutMofuchiPage extends StatelessWidget {
  const _AboutMofuchiPage();
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? const Color(0xFFF5F1FC) : const Color(0xFF30273B);
    final muted = dark ? const Color(0xFFB9B0C9) : const Color(0xFF7A7288);
    return _ProfileDetailShell(title: 'About Mofuchi', children: [
      const Icon(Icons.local_florist_rounded, size: 52, color: Color(0xFF9A79D7)),
      const SizedBox(height: 12),
      Text('Welcome to Mofuchi Garden 🌸',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Poppins', color: ink,
              fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      Text('Mofuchi Garden is a multimedia emotional check-in experience. '
          'It offers a gentle space to acknowledge your feelings and reflect on each day.',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13, height: 1.6, color: muted)),
      const SizedBox(height: 18),
      _DetailHeading('A little garden for every feeling', color: ink),
      _DetailParagraph('Record your emotions, express yourself through reflections and media, '
          'explore your mood history, and watch your weekly Sakura garden grow.', color: muted),
      const SizedBox(height: 12),
      _DetailHeading('Your progress, at your pace', color: ink),
      _DetailParagraph('Every feeling matters. Your garden is here to support reflection, '
          'not to judge whether a day was good or bad.', color: muted),
      const SizedBox(height: 12),
      _DetailHeading('Final Year Project', color: ink),
      _DetailParagraph('Mofuchi Garden is being developed as a multimedia technology '
          'Final Year Project. Features may continue to be refined during testing.', color: muted),
      const SizedBox(height: 12),
      _DetailParagraph('Mofuchi Garden is a self-reflection tool, not a substitute '
          'for professional mental health care.', color: muted),
    ]);
  }
}

class _PrivacyPolicyPage extends StatelessWidget {
  const _PrivacyPolicyPage();
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? const Color(0xFFF5F1FC) : const Color(0xFF30273B);
    final muted = dark ? const Color(0xFFB9B0C9) : const Color(0xFF7A7288);
    return _ProfileDetailShell(title: 'Privacy Policy', children: [
      const Icon(Icons.privacy_tip_outlined, size: 48, color: Color(0xFF9A79D7)),
      const SizedBox(height: 10),
      Text('Your privacy matters 🌷', textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Poppins', fontSize: 18,
              fontWeight: FontWeight.w700, color: ink)),
      const SizedBox(height: 8),
      Text('Draft privacy information • FYP testing version',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: muted)),
      const SizedBox(height: 18),
      _DetailHeading('1. Account information', color: ink),
      _DetailParagraph('Mofuchi Garden uses Firebase Authentication for email/password '
          'accounts. Your registered email and display name are used to identify and '
          'personalize your experience.', color: muted),
      const SizedBox(height: 12),
      _DetailHeading('2. Reflections and media', color: ink),
      _DetailParagraph('Your check-ins can include emotions, written reflections, '
          'photos, or videos. Please avoid recording or sharing sensitive details '
          'that you do not want included in your test data.', color: muted),
      const SizedBox(height: 12),
      _DetailHeading('3. Reminders', color: ink),
      _DetailParagraph('Reminder preferences are saved on your device and local '
          'notifications are scheduled according to the options you choose. '
          'You can turn reminders off in Profile.', color: muted),
      const SizedBox(height: 12),
      _DetailHeading('4. Permissions', color: ink),
      _DetailParagraph('The app may request camera, microphone and notification '
          'permissions when relevant features are used. You can manage permissions '
          'in your phone Settings.', color: muted),
      const SizedBox(height: 12),
      _DetailHeading('5. Important testing notice', color: ink),
      _DetailParagraph('This is a draft for the development/testing build, '
          'not a finalized legal privacy policy. Before a public release, the '
          'project developer must verify exactly where reflections and media '
          'are stored, who can access them, retention/deletion procedures, '
          'third-party services and contact details.', color: muted),
    ]);
  }
}

class _DetailHeading extends StatelessWidget {
  const _DetailHeading(this.label, {required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Text(label,
      style: TextStyle(fontFamily: 'Poppins', fontSize: 13,
          fontWeight: FontWeight.w700, color: color));
}

class _DetailParagraph extends StatelessWidget {
  const _DetailParagraph(this.label, {required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 5),
    child: Text(label, style: TextStyle(fontFamily: 'Poppins',
        fontSize: 12, height: 1.6, color: color)),
  );
}


/// Mirrors Dashboard's Firestore source, 7-day window and valid mood rules.
/// Do not use demonstration values in Profile statistics or achievements.
class _ProfileInsights {
  const _ProfileInsights({
    required this.total,
    required this.last7,
    required this.mostLogged,
    required this.dominantPercent,
    required this.currentStreak,
    required this.longestStreak,
    required this.averageIntensity,
    required this.uplifting,
    required this.topCategory,
  });

  final int total;
  final List<_InsightEntry> last7;
  final String mostLogged;
  final int dominantPercent;
  final int currentStreak;
  final int longestStreak;
  final String averageIntensity;
  final int uplifting;
  final String topCategory;

  static const _moods = ['happy', 'surprise', 'sad', 'angry', 'disgust', 'fear'];

  static _ProfileInsights fromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    DateTime now,
  ) {
    final entries = <_InsightEntry>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final stamp = data['createdAt'];
      final mood = (data['emotion'] as String? ?? '').trim().toLowerCase();
      if (stamp is! Timestamp || !_moods.contains(mood)) continue;
      final date = stamp.toDate().toLocal();
      if (date.year <= 1970) continue;
      entries.add(_InsightEntry(
        mood: mood,
        date: date,
        intensity: (data['intensity'] as num?)?.toInt() ?? 0,
        category: (data['eventCategory'] as String?) ??
            (data['category'] as String?) ?? 'General',
      ));
    }

    final today = DateUtils.dateOnly(now);
    final from = today.subtract(const Duration(days: 6));
    final tomorrow = today.add(const Duration(days: 1));
    final last7 = entries.where((e) =>
        !e.date.isBefore(from) && e.date.isBefore(tomorrow)).toList();

    final moodCounts = <String, int>{};
    final categoryCounts = <String, int>{};
    int uplifting = 0;
    int intensitySum = 0;
    int validIntensityCount = 0;
    for (final e in last7) {
      moodCounts[e.mood] = (moodCounts[e.mood] ?? 0) + 1;
      if (e.mood == 'happy' || e.mood == 'surprise') uplifting++;
      if (e.intensity >= 1 && e.intensity <= 5) {
        intensitySum += e.intensity;
        validIntensityCount++;
      }
      final category = e.category.trim();
      if (category.isNotEmpty) {
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }
    }
    // Use the same frequency ranking approach as Dashboard.
    final sortedMoods = moodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final winningMood = sortedMoods.isEmpty ? '' : sortedMoods.first.key;
    final mostCount = sortedMoods.isEmpty ? 0 : sortedMoods.first.value;
    final sortedCategories = categoryCounts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });

    // One check-in day counts once, even when there are multiple reflections.
    final dates = entries.map((e) => DateUtils.dateOnly(e.date)).toSet().toList()
      ..sort((a, b) => a.compareTo(b));
    int longest = 0;
    int run = 0;
    DateTime? previous;
    for (final day in dates) {
      run = previous != null && day.difference(previous).inDays == 1
          ? run + 1 : 1;
      if (run > longest) longest = run;
      previous = day;
    }
    int current = 0;
    if (dates.isNotEmpty) {
      final lastDay = dates.last;
      if (lastDay == today || lastDay == today.subtract(const Duration(days: 1))) {
        current = 1;
        for (var i = dates.length - 2; i >= 0; i--) {
          if (dates[i + 1].difference(dates[i]).inDays != 1) break;
          current++;
        }
      }
    }
    return _ProfileInsights(
      total: entries.length,
      last7: last7,
      mostLogged: winningMood.isEmpty
          ? '—' : '${winningMood[0].toUpperCase()}${winningMood.substring(1)}',
      dominantPercent: last7.isEmpty ? 0 : (mostCount * 100 / last7.length).round(),
      currentStreak: current,
      longestStreak: longest,
      averageIntensity: validIntensityCount == 0
          ? '—' : '${(intensitySum / validIntensityCount).toStringAsFixed(1)}/5',
      uplifting: uplifting,
      topCategory: sortedCategories.isEmpty ? '—' : sortedCategories.first.key,
    );
  }
}

class _InsightEntry {
  const _InsightEntry({
    required this.mood,
    required this.date,
    required this.intensity,
    required this.category,
  });
  final String mood;
  final DateTime date;
  final int intensity;
  final String category;
}

// Magical Lavender Glass Garden: softly moving light behind frosted-glass cards.
// Decoration only: does not handle gestures, navigation, or Firebase data.
class _ProfileLavenderBackground extends StatefulWidget {
  final bool isDark;
  final Widget child;
  const _ProfileLavenderBackground({
    required this.isDark,
    required this.child,
  });

  @override
  State<_ProfileLavenderBackground> createState() => _ProfileLavenderBackgroundState();
}

class _ProfileLavenderBackgroundState extends State<_ProfileLavenderBackground>
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
                  painter: _ProfileLavenderPainter(
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

class _ProfileLavenderPainter extends CustomPainter {
  final bool isDark;
  final Animation<double> animation;

  _ProfileLavenderPainter({
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

    // Tiny, slow glimmers: understated so search text and reflections stay clear.
    for (var i = 0; i < 26; i++) {
      final fx = ((i * 41 + 17) % 101) / 101.0;
      final fy = ((i * 73 + 29) % 103) / 103.0;
      final phase = t + i * 0.79;
      final x = fx * w + math.sin(phase * 0.55) * 5.0;
      final y = fy * size.height + math.cos(phase * 0.4) * 7.0;
      final pulse = (0.45 + math.sin(phase) * 0.25).clamp(0.12, 0.70);
      final radius = 1.6 + (i % 3) * 0.65;
      final c = isDark
          ? const Color(0xFFDCD1FF)
          : const Color(0xFFFFFFFF);
      canvas.drawCircle(
        Offset(x, y), radius * 4,
        Paint()
          ..color = c.withValues(alpha: pulse * 0.14)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(
        Offset(x, y), radius,
        Paint()..color = c.withValues(alpha: pulse * 0.40),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProfileLavenderPainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.animation != animation;
}

class _ProfileButterflyLogo extends StatelessWidget {
  final double size;
  const _ProfileButterflyLogo({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _ProfileButterflyPainter(),
      ),
    );
  }
}

// Vector silhouette matched to the supplied green/lavender butterfly artwork:
// softly scalloped upper wings, a narrow waist, and long pointed lower tips.
// Painted directly in Flutter, so the silhouette stays crisp at any size.
class _ProfileButterflyPainter extends CustomPainter {
  const _ProfileButterflyPainter();

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
  bool shouldRepaint(covariant _ProfileButterflyPainter oldDelegate) =>
      false;
}
