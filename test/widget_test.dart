import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'package:catch_it/main.dart';
import 'package:catch_it/onboarding_video.dart';

/// Minimal fake so the player "initializes" in widget tests.
class FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  final List<String> calls = [];

  @override
  Future<void> init() async {}
  @override
  Future<int?> create(DataSource dataSource) async => 1;
  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async => 1;
  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => Stream.value(
    VideoEvent(
      eventType: VideoEventType.initialized,
      duration: const Duration(seconds: 19),
      size: const Size(720, 1280),
    ),
  );
  @override
  Future<void> dispose(int playerId) async => calls.add('dispose');
  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> play(int playerId) async => calls.add('play');
  @override
  Future<void> pause(int playerId) async {}
  @override
  Future<void> setVolume(int playerId, double volume) async =>
      calls.add('volume:$volume');
  @override
  Future<void> seekTo(int playerId, Duration position) async {}
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;
  @override
  Widget buildView(int playerId) => const SizedBox.expand();
  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      const SizedBox.expand();
  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async =>
      calls.add('mix:$mixWithOthers');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeVideoPlayerPlatform fakePlayer;

  setUp(() {
    fakePlayer = FakeVideoPlayerPlatform();
    VideoPlayerPlatform.instance = fakePlayer;
    // receive_sharing_intent has no implementation in tests; stub it.
    const methodChannel = MethodChannel('receive_sharing_intent/messages');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, (call) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          const EventChannel('receive_sharing_intent/events-media'),
          MockStreamHandler.inline(onListen: (args, sink) {}),
        );
  });

  test('onboarding flag: shown once, then never again', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await shouldShowOnboarding(), isTrue);
    await markOnboardingSeen();
    expect(await shouldShowOnboarding(), isFalse);
  });

  testWidgets('home screen shows Watch tutorial button', (tester) async {
    await tester.pumpWidget(const CatchItApp());
    expect(find.text('CATCH IT'), findsOneWidget);
    expect(find.text('Watch tutorial'), findsOneWidget);
  });

  testWidgets('first launch shows Skip, Skip goes to home and saves flag', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const CatchItApp(showOnboarding: true));
    await tester.pump();
    expect(find.text('Skip'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding_skip')));
    await tester.pumpAndSettle();
    expect(find.text('CATCH IT'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
    expect(await shouldShowOnboarding(), isFalse);
    expect(fakePlayer.calls, containsAll(['mix:true', 'volume:0.0', 'play']));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    expect(fakePlayer.calls, contains('dispose'));
  });

  testWidgets('Watch tutorial opens the player and Close returns home', (
    tester,
  ) async {
    await tester.pumpWidget(const CatchItApp());
    await tester.tap(find.byKey(const Key('watch_tutorial')));
    await tester.pumpAndSettle();
    expect(find.text('Close'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding_skip')));
    await tester.pumpAndSettle();
    expect(find.text('Close'), findsNothing);
    expect(find.text('Watch tutorial'), findsOneWidget);
  });
}
