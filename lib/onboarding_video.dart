import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

/// Bundled tutorial video (silent, 720x1280).
const String kOnboardingVideoAsset = 'assets/videos/onboarding.mp4';

/// SharedPreferences key set once the intro video has been shown on first launch.
const String kOnboardingSeenKey = 'onboarding_video_seen';

/// Returns true when the intro video has not been shown yet on this install.
Future<bool> shouldShowOnboarding() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(kOnboardingSeenKey) ?? false);
  } catch (e) {
    debugPrint('Onboarding flag read failed: $e');
    return false;
  }
}

/// Marks the intro video as seen so it never autoplays again.
Future<void> markOnboardingSeen() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kOnboardingSeenKey, true);
  } catch (e) {
    debugPrint('Onboarding flag write failed: $e');
  }
}

/// Full-screen, muted, inline video player used both for the first-launch
/// intro and for the "Watch tutorial" replay.
///
/// [onFinished] is called exactly once, when the video ends, when the user
/// taps Skip/Close, or if the video can't be played.
class OnboardingVideoScreen extends StatefulWidget {
  const OnboardingVideoScreen({
    super.key,
    required this.onFinished,
    this.dismissLabel = 'Skip',
  });

  final VoidCallback onFinished;
  final String dismissLabel;

  @override
  State<OnboardingVideoScreen> createState() => _OnboardingVideoScreenState();
}

class _OnboardingVideoScreenState extends State<OnboardingVideoScreen> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.asset(
      kOnboardingVideoAsset,
      // Silent video: mix with other audio so we never interrupt the user's
      // music or take over the audio session.
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted || _finished) return;
      await controller.setVolume(0);
      await controller.setLooping(false);
      controller.addListener(_onTick);
      setState(() => _ready = true);
      await controller.play();
    } catch (e) {
      debugPrint('Onboarding video failed to play: $e');
      _finish();
    }
  }

  void _onTick() {
    final controller = _controller;
    if (controller == null) return;
    final value = controller.value;
    if (value.hasError) {
      _finish();
      return;
    }
    if (value.isInitialized &&
        value.duration > Duration.zero &&
        !value.isPlaying &&
        value.position >= value.duration - const Duration(milliseconds: 200)) {
      _finish();
    }
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    _controller?.removeListener(_onTick);
    _controller?.pause();
    widget.onFinished();
  }

  @override
  void dispose() {
    final controller = _controller;
    _controller = null;
    controller?.removeListener(_onTick);
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: _ready && controller != null
                ? AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: VideoPlayer(controller),
                  )
                : const CircularProgressIndicator(color: Colors.white),
          ),
          SafeArea(
            child: Align(
              alignment: AlignmentDirectional.topEnd,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TextButton(
                  key: const Key('onboarding_skip'),
                  onPressed: _finish,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black54,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    widget.dismissLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// First-launch gate: plays the intro once, saves the flag, then replaces
/// itself with [home].
class FirstLaunchGate extends StatefulWidget {
  const FirstLaunchGate({super.key, required this.home});

  final Widget home;

  @override
  State<FirstLaunchGate> createState() => _FirstLaunchGateState();
}

class _FirstLaunchGateState extends State<FirstLaunchGate> {
  bool _done = false;

  @override
  void initState() {
    super.initState();
    // Save the flag as soon as the intro is shown, so it never autoplays
    // again even if the user closes the app mid-video.
    unawaited(markOnboardingSeen());
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.home;
    return OnboardingVideoScreen(
      onFinished: () {
        if (mounted) setState(() => _done = true);
      },
    );
  }
}

/// Opens the tutorial video full-screen on demand ("Watch tutorial").
Future<void> showTutorialVideo(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (routeContext) => OnboardingVideoScreen(
        dismissLabel: 'Close',
        onFinished: () {
          if (Navigator.of(routeContext).canPop()) {
            Navigator.of(routeContext).pop();
          }
        },
      ),
    ),
  );
}
