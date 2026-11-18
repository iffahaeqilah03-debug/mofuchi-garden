// ignore_for_file: unused_element

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/garden_emotion.dart';
import 'sakura_bloom_screen.dart';
import 'garden_watering_screen.dart';
import 'emotion_encouragement_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../services/emotion_service.dart';
import '../widgets/mofuchi_background.dart';
import '../services/app_state.dart';

class CheckInImageVideoScreen extends StatefulWidget {
  final String selectedMood;
  final String moodEmoji;
  final String? moodImageAsset;
  final int intensity;
  final String selectedCategory;

  const CheckInImageVideoScreen({
    super.key,
    required this.selectedMood,
    required this.moodEmoji,
    this.moodImageAsset,
    required this.intensity,
    required this.selectedCategory,
  });

  @override
  State<CheckInImageVideoScreen> createState() => _CheckInImageVideoScreenState();
}

class _CheckInImageVideoScreenState extends State<CheckInImageVideoScreen> {
  // Theme-aware palette. UI changes only; check-in data flow is untouched.
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _fg => _isDark ? const Color(0xFFF8F4FF) : const Color(0xFF2D2430);
  Color get _sub => _isDark ? const Color(0xFFC5BBD3) : const Color(0xFF7A7288);
  Color get _sage => _isDark ? const Color(0xFFB8CDB8) : const Color(0xFF6E7F68);
  Color get _accent => _isDark ? const Color(0xFFC6AEF5) : const Color(0xFF7E57C2);
  Color get _panel => _isDark ? const Color(0xE5292538) : Colors.white.withValues(alpha: 0.85);
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

  final TextEditingController _noteController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  XFile? _attachment;
  String? _attachmentType;
  VideoPlayerController? _videoController;
  bool _saving = false;

  Future<void> _chooseMedia({required String type, required ImageSource source}) async {
    if (_saving) return;
    try {
      final XFile? picked = type == 'image'
          ? await _picker.pickImage(source: source, imageQuality: 85)
          : await _picker.pickVideo(
              source: source,
              maxDuration: const Duration(seconds: 30),
            );
      if (picked == null) return;
      // Reject oversized media, especially long gallery videos.
      if (await picked.length() > 50 * 1024 * 1024) {
        if (!mounted) return;
        _message('Please choose a file smaller than 50 MB.');
        return;
      }
      VideoPlayerController? nextController;
      if (type == 'video') {
        nextController = VideoPlayerController.file(File(picked.path));
        await nextController.initialize();
        // Camera apps may encode a few extra frames at the 30s cutoff.
        // Allow up to one second of container/encoder rounding.
        if (nextController.value.duration > const Duration(seconds: 31)) {
          await nextController.dispose();
          if (!mounted) return;
          _message('Choose a video up to 30 seconds long.');
          return;
        }
      }
      if (!mounted) {
        await nextController?.dispose();
        return;
      }
      final previous = _videoController;
      setState(() {
        _attachment = picked;
        _attachmentType = type;
        _videoController = nextController;
      });
      await previous?.dispose();
    } catch (error) {
      if (mounted) _message('Could not open media. Please try again.');
      debugPrint('Media picker failed: $error');
    }
  }

  void _showMediaChoices(String type) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: Icon(Icons.photo_library_outlined),
            title: Text('Choose from gallery'),
            onTap: () {
              Navigator.pop(sheetContext);
              _chooseMedia(type: type, source: ImageSource.gallery);
            },
          ),
          ListTile(
            leading: Icon(Icons.camera_alt_outlined),
            title: Text(type == 'image' ? 'Take photo' : 'Record video'),
            onTap: () {
              Navigator.pop(sheetContext);
              _chooseMedia(type: type, source: ImageSource.camera);
            },
          ),
        ]),
      ),
    );
  }

  Future<void> _removeAttachment() async {
    final old = _videoController;
    setState(() {
      _attachment = null;
      _attachmentType = null;
      _videoController = null;
    });
    await old?.dispose();
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // Count distinct check-in dates in the current local Monday–Sunday week.
  // Use the same userId and createdAt fields as HomeScreen.
  Future<int> _weeklyBloomLevelBeforeSave() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Please sign in before checking in.');
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final nextMonday = monday.add(const Duration(days: 7));
    final snapshot = await FirebaseFirestore.instance
        .collection('emotion_logs')
        .where('userId', isEqualTo: uid)
        .get();
    final uniqueDays = <DateTime>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final timestamp = data['createdAt'];
      final mood = (data['emotion'] as String? ?? '').trim();
      if (timestamp is! Timestamp || !countsForWeeklyBloom(mood)) continue;
      final date = timestamp.toDate().toLocal();
      if (!date.isBefore(monday) && date.isBefore(nextMonday)) {
        uniqueDays.add(DateTime(date.year, date.month, date.day));
      }
    }
    return uniqueDays.length.clamp(0, 7);
  }

  // XP and garden coins are claimed together in one Firestore transaction.
  // Distinct claim keys protect XP and coins independently, including existing
  // users who already claimed XP before the coin feature was introduced.
  Future<({int earned, int before, int after, int coinsEarned})> _awardSakuraXp({
    required String uid,
    required DateTime localDay,
    required bool firstCheckInToday,
    required bool hasWrittenReflection,
    required bool completedWeek,
    required int weeklyCheckInDays,
  }) async {
    String dateKey(DateTime value) =>
        '${value.year.toString().padLeft(4, '0')}'
        '${value.month.toString().padLeft(2, '0')}'
        '${value.day.toString().padLeft(2, '0')}';

    final dayKey = dateKey(localDay);
    final monday = DateTime(localDay.year, localDay.month, localDay.day)
        .subtract(Duration(days: localDay.weekday - 1));
    final weekKey = dateKey(monday);
    final progressRef = FirebaseFirestore.instance
        .collection('gamification_progress')
        .doc(uid);

    return FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(progressRef);
      final data = snapshot.data() ?? <String, dynamic>{};
      final claimed = Map<String, dynamic>.from(
        (data['rewardClaims'] as Map?) ?? <String, dynamic>{},
      );
      var earned = 0;
      var coinsEarned = 0;

      void claimXp(String key, int xp, bool eligible) {
        if (eligible && claimed[key] != true) {
          claimed[key] = true;
          earned += xp;
        }
      }

      void claimCoins(String key, int coins, bool eligible) {
        if (eligible && claimed[key] != true) {
          claimed[key] = true;
          coinsEarned += coins;
        }
      }

      // Preserve the XP policy used by the existing application.
      claimXp('checkin_$dayKey', 10, firstCheckInToday);
      claimXp('reflection_$dayKey', 5, hasWrittenReflection);
      claimXp('weekly_$weekKey', 30, completedWeek);

      // Garden Shop currency; all emotions earn the same rewards.
      // After a successful save, today's daily coin reward may be claimed
      // once if not already claimed. This also supports existing users who
      // checked in before coins were introduced; XP eligibility is unchanged.
      // An optional written reflection earns three more once per day.
      claimCoins('coin_checkin_$dayKey', 5, true);
      claimCoins('coin_reflection_$dayKey', 3, hasWrittenReflection);
      claimCoins('coin_week3_$weekKey', 10, weeklyCheckInDays >= 3);
      claimCoins('coin_week7_$weekKey', 20, weeklyCheckInDays >= 7);

      final existingXp = (data['totalXp'] as num?)?.toInt() ?? 0;
      final existingCoins = (data['coinBalance'] as num?)?.toInt() ?? 0;
      if (earned == 0 && coinsEarned == 0) {
        return (earned: 0, before: existingXp, after: existingXp, coinsEarned: 0);
      }
      transaction.set(progressRef, <String, dynamic>{
        'totalXp': existingXp + earned,
        'coinBalance': existingCoins + coinsEarned,
        'rewardClaims': claimed,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return (
        earned: earned,
        before: existingXp,
        after: existingXp + earned,
        coinsEarned: coinsEarned,
      );
    });
  }

  Future<void> _saveCheckIn() async {
    if (_saving) return;
    setState(() => _saving = true);
    final noteText = _noteController.text.trim().isEmpty
        ? 'Felt ${widget.selectedMood} today (${widget.intensity}/5) about ${widget.selectedCategory}.'
        : _noteController.text.trim();
    try {
      final previousLevel = await _weeklyBloomLevelBeforeSave();
      final today = DateTime.now();
      final uid = FirebaseAuth.instance.currentUser!.uid;
      // Needed to distinguish a first check-in today from later ones.
      final logs = await FirebaseFirestore.instance
          .collection('emotion_logs')
          .where('userId', isEqualTo: uid)
          .get();
      final checkedToday = logs.docs.any((doc) {
        final data = doc.data();
        final timestamp = data['createdAt'];
        if (timestamp is! Timestamp ||
            !countsForWeeklyBloom((data['emotion'] as String? ?? ''))) {
          return false;
        }
        final day = timestamp.toDate().toLocal();
        return day.year == today.year &&
            day.month == today.month && day.day == today.day;
      });

      // Preserve the existing Firestore/media save operation.
      await EmotionService().saveCheckIn(
        mood: widget.selectedMood,
        intensity: widget.intensity,
        eventCategory: widget.selectedCategory,
        note: noteText,
        attachment: _attachment == null ? null : File(_attachment!.path),
        attachmentType: _attachmentType,
      );
      AppState.instance.addEntry(
        mood: widget.selectedMood,
        intensity: widget.intensity,
        category: widget.selectedCategory,
        note: noteText,
      );

      final nextLevel = (previousLevel + (checkedToday ? 0 : 1)).clamp(0, 7);
      final bloomToday = !checkedToday && nextLevel > previousLevel;
      // Only show the XP actually committed in Firestore, never an estimated value.
      int earnedXp = 0;
      int? beforeXp;
      int? afterXp;
      try {
        final reward = await _awardSakuraXp(
          uid: uid,
          localDay: today,
          firstCheckInToday: !checkedToday,
          hasWrittenReflection: _noteController.text.trim().isNotEmpty,
          completedWeek: nextLevel == 7,
          weeklyCheckInDays: nextLevel,
        );
        earnedXp = reward.earned;
        beforeXp = reward.before;
        afterXp = reward.after;
        debugPrint('Mofuchi Garden Coins earned: ${reward.coinsEarned}');
      } catch (xpError) {
        debugPrint('Mofuchi XP/coin award failed (check-in still saved): $xpError');
      }
      if (!mounted) return;
      final needsCare = const {'sad', 'angry', 'fear', 'disgust'}
          .contains(widget.selectedMood.trim().toLowerCase());
      final unlockedBadges = <String>[];
      if (logs.docs.isEmpty) unlockedBadges.add('First Bloom');
      if (!checkedToday && nextLevel == 7) unlockedBadges.add('7-Day Sakura');
      if (beforeXp != null && afterXp != null) {
        if (beforeXp < 50 && afterXp >= 50) unlockedBadges.add('Growing Bud');
        if (beforeXp < 350 && afterXp >= 350) unlockedBadges.add('Garden Guardian');
      }

      final savedMood = widget.selectedMood;
      // Clear the intermediate check-in pages, retaining the app's root.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => EmotionEncouragementScreen(
            emotion: savedMood,
            earnedXp: earnedXp,
            previousXp: beforeXp,
            totalXp: afterXp,
            unlockedBadges: unlockedBadges,
            onContinue: (screenContext) {
              if (needsCare) {
                Navigator.of(screenContext).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => GardenWateringScreen(
                      emotion: savedMood,
                      showBloomAfter: bloomToday,
                      previousLevel: previousLevel,
                      currentLevel: nextLevel,
                    ),
                  ),
                );
              } else if (bloomToday) {
                Navigator.of(screenContext).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => SakuraBloomScreen(
                      previousLevel: previousLevel,
                      currentLevel: nextLevel,
                      emotion: savedMood,
                    ),
                  ),
                );
              } else {
                Navigator.of(screenContext).popUntil((route) => route.isFirst);
              }
            },
          ),
        ),
        (route) => route.isFirst,
      );
    } catch (error) {
      debugPrint('Check-in save failed: $error');
      if (mounted) _message('Could not save. Check your connection and Firestore rules.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _mediaPreview() {
    if (_attachment == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(children: [
        if (_attachmentType == 'image')
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(File(_attachment!.path), height: 170, fit: BoxFit.contain),
          )
        else if (_videoController != null && _videoController!.value.isInitialized)
          Column(children: [
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
            TextButton.icon(
              onPressed: () {
                if (_videoController!.value.isPlaying) {
                  _videoController!.pause();
                } else {
                  _videoController!.play();
                }
                setState(() {});
              },
              icon: Icon(_videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow),
              label: Text('Play / Pause'),
            ),
          ]),
        TextButton.icon(
          onPressed: _removeAttachment,
          icon: Icon(Icons.delete_outline),
          label: Text('Remove attachment'),
        ),
      ]),
    );
  }


  @override
  void dispose() {
    _videoController?.dispose();
    _noteController.dispose();
    super.dispose();
  }

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
                    'Tell me more about it',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: _fg,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'A few words about your day (optional).',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: _sub,
                    ),
                  ),
                  SizedBox(height: 18),

                  // The same borderless, upright 3D Mofuchi preview used
                  // on the About screen. The background comes from the page.
                  const SizedBox(
                    width: double.infinity,
                    height: 190,
                    child: ModelViewer(
                      key: ValueKey('mofuchi-journal-upright'),
                      src: 'assets/3D/mofuchi.glb',
                      alt: '3D Mofuchi mascot',
                      orientation: '0deg 0deg 180deg',
                      cameraControls: false,
                      disableZoom: true,
                      autoRotate: false,
                      autoPlay: false,
                      backgroundColor: Colors.transparent,
                      shadowIntensity: 0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _panel,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: _panelBorder, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _noteController,
                      minLines: 6,
                      maxLines: 8,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13.5,
                        color: _fg,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Write a few words about what happened today...',
                        hintStyle: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12.5,
                          color: _sub,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text('Capture a moment (optional)',
                      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                  SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: OutlinedButton.icon(
                      onPressed: _saving ? null : () => _showMediaChoices('image'),
                      icon: Icon(Icons.image_outlined),
                      label: Text('Add Photo'),
                    )),
                    SizedBox(width: 10),
                    Expanded(child: OutlinedButton.icon(
                      onPressed: _saving ? null : () => _showMediaChoices('video'),
                      icon: Icon(Icons.videocam_outlined),
                      label: Text('Add Video'),
                    )),
                  ]),
                  Text('One photo or video, up to 30 seconds and 50 MB. Saved only on this device.',
                      style: TextStyle(fontSize: 11, color: _sub)),
                  _mediaPreview(),
                  SizedBox(height: 32),

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
                      onPressed: _saving ? null : _saveCheckIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _saving ? 'Saving...' : 'Save Entry',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.spa_rounded, size: 18, color: Colors.white),
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