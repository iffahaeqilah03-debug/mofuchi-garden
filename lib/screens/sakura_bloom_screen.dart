// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../utils/garden_emotion.dart';
import '../widgets/mofuchi_background.dart';

/// Visual celebration for a new daily check-in.
/// Weekly progress is calculated by the caller; this screen never changes it.
class SakuraBloomScreen extends StatefulWidget {
  final int previousLevel;
  final int currentLevel;
  final String emotion;

  const SakuraBloomScreen({
    super.key,
    required this.previousLevel,
    required this.currentLevel,
    required this.emotion,
  });

  @override
  State<SakuraBloomScreen> createState() => _SakuraBloomScreenState();
}

class _SakuraBloomScreenState extends State<SakuraBloomScreen>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _complete = false;
  bool _loading = true;
  String? _error;
  int _generation = 0;

  int get _to => widget.currentLevel.clamp(0, 7);
  int get _from => widget.previousLevel.clamp(0, 7);
  bool get _hasNewGrowth => _to > _from;
  GardenEmotionCategory get _category => gardenEmotionCategory(widget.emotion);
  bool get _negative => const {'sad', 'angry', 'fear', 'disgust'}
      .contains(widget.emotion.trim().toLowerCase());

  String get _assetPath {
    if (_negative) {
      return 'assets/videos/mofuchi_falling_petals/negative_petal_fall.MP4';
    }
    final day = _to.clamp(1, 7).toString().padLeft(2, '0');
    return 'assets/videos/mofuchi_bloom_day_01_to_07/bloom_day_$day.mp4';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    final generation = ++_generation;
    final previous = _controller;
    if (mounted) {
      setState(() {
        _loading = true;
        _complete = false;
        _error = null;
        _controller = null;
      });
    }
    if (previous != null) {
      previous.removeListener(_onVideoUpdate);
      await previous.dispose();
    }

    final player = VideoPlayerController.asset(_assetPath);
    try {
      await player.initialize();
      if (!mounted || generation != _generation) {
        await player.dispose();
        return;
      }
      player.setLooping(false);
      player.addListener(_onVideoUpdate);
      setState(() {
        _controller = player;
        _loading = false;
      });
      await player.play();
    } catch (e) {
      await player.dispose();
      if (mounted && generation == _generation) {
        setState(() {
          _error = 'Video could not be loaded. Check its asset path and filename.';
          _loading = false;
          _complete = true;
        });
        debugPrint('Mofuchi video asset failed: $_assetPath ($e)');
      }
    }
  }

  void _onVideoUpdate() {
    final player = _controller;
    if (!mounted || player == null || !player.value.isInitialized) return;
    if (player.value.hasError) {
      if (_error == null) {
        setState(() {
          _error = player.value.errorDescription ?? 'Video playback failed.';
          _complete = true;
        });
      }
      return;
    }
    final value = player.value;
    if (!_complete && value.duration > Duration.zero &&
        value.position >= value.duration - const Duration(milliseconds: 120) &&
        !value.isPlaying) {
      setState(() => _complete = true);
    }
  }

  Future<void> _replay() async {
    final player = _controller;
    if (player == null || !player.value.isInitialized || _loading) return;
    setState(() => _complete = false);
    await player.seekTo(Duration.zero);
    await player.play();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _controller?.pause();
    }
  }

  @override
  void dispose() {
    ++_generation;
    WidgetsBinding.instance.removeObserver(this);
    _controller?.removeListener(_onVideoUpdate);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final positive = _category == GardenEmotionCategory.positive;
    final neutral = _category == GardenEmotionCategory.neutral;
    final heading = positive
        ? 'A little joy is blooming!'
        : neutral
            ? 'A gentle surprise in your garden'
            : 'Every feeling belongs here';
    final description = positive
        ? 'Your happy moment helps your Sakura grow.'
        : neutral
            ? 'Your surprise is part of your story, too.'
            : 'Your check-in matters. Your garden grows without judging your feelings.';

    final player = _controller;
    final ready = player != null && player.value.isInitialized;

    return Scaffold(
      body: MofuchiBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              children: [
                const Text(
                  'MOFUCHI GARDEN',
                  style: TextStyle(
                    color: Color(0xFF7E57C2),
                    fontSize: 12,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  heading,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF30273C),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Color(0xFF7A7288),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: ColoredBox(
                      color: const Color(0xFFF7EFF8),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (ready)
                            FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: player.value.size.width,
                                height: player.value.size.height,
                                child: VideoPlayer(player),
                              ),
                            ),
                          if (_loading)
                            const Center(child: CircularProgressIndicator()),
                          if (_error != null)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.videocam_off_outlined,
                                        size: 44, color: Color(0xFF7E57C2)),
                                    const SizedBox(height: 12),
                                    Text(_error!, textAlign: TextAlign.center),
                                    const SizedBox(height: 12),
                                    OutlinedButton(
                                      onPressed: _loadVideo,
                                      child: const Text('Try again'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Weekly bloom: $_to / 7 days',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7E57C2),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _error != null
                      ? 'Your check-in and garden progress are safe.'
                      : _loading
                          ? 'Preparing your Sakura Garden...'
                          : _complete
                              ? (_negative
                                  ? 'Let the petals drift. Every feeling is welcome. 🍃'
                                  : 'Your Sakura is blooming beautifully!')
                              : (_negative
                                  ? 'A gentle moment for your garden 🍃'
                                  : 'Watch your Sakura bloom'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF67866A)),
                ),
                const SizedBox(height: 16),
                if (ready && _error == null) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: _complete ? _replay : null,
                      icon: const Icon(Icons.replay_rounded, size: 19),
                      label: Text(_negative
                          ? 'Replay Falling Petals'
                          : 'Replay Bloom Animation'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF7E57C2),
                        side: const BorderSide(color: Color(0xFFB99AE6)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7E57C2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                    child: Text(_complete
                        ? 'Return to My Garden'
                        : 'Skip animation & return'),
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
