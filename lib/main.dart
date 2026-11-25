import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:async';

import 'onboarding_video.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final showOnboarding = await shouldShowOnboarding();
  runApp(CatchItApp(showOnboarding: showOnboarding));
}

class CatchItApp extends StatelessWidget {
  const CatchItApp({super.key, this.showOnboarding = false});

  /// True only on the first launch after install.
  final bool showOnboarding;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.light,
      ),
      home: showOnboarding
          ? const FirstLaunchGate(home: CatchItHome())
          : const CatchItHome(),
    );
  }
}

class CatchItHome extends StatefulWidget {
  const CatchItHome({super.key});

  @override
  State<CatchItHome> createState() => _CatchItHomeState();
}

class _CatchItHomeState extends State<CatchItHome> {
  // Use nullable to prevent LateInitializationError
  StreamSubscription? _intentDataStreamSubscription;
  String _sharedText = "";
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // Listen to shared content while app is in memory
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedMedia(value);
      }
    }, onError: (err) {
      debugPrint("getMediaStream error: $err");
    });

    // Handle shared content when app is opened from a closed state
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedMedia(value);
      }
      // Reset initial media so it doesn't trigger again on reload/orientation change
      // ReceiveSharingIntent.instance.resetInitialMedia();
    });
  }

  void _handleSharedMedia(List<SharedMediaFile> media) {
    if (!mounted) return;
    // For text/links shared via this plugin, the content is in the 'path' property
    final sharedValue = media.first.path;
    setState(() {
      _sharedText = sharedValue;
      _controller.text = sharedValue;
    });
  }

  void _copyToClipboard() {
    if (_sharedText.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _sharedText));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Copied to clipboard"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _intentDataStreamSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("CATCH IT", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_sharedText.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _sharedText = "";
                  _controller.clear();
                });
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _controller,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: "Enter location or link...",
                  prefixIcon: const Icon(Icons.link),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.all(20),
                ),
                onChanged: (v) => setState(() => _sharedText = v),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _sharedText.isEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code_scanner, size: 80, color: Colors.blue[100]),
                              const SizedBox(height: 16),
                              const Text(
                                "Waiting for a link...",
                                style: TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              QrImageView(
                                data: _sharedText,
                                version: QrVersions.auto,
                                size: 240.0,
                                backgroundColor: Colors.white,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "Scan to Catch!",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _sharedText.isEmpty ? null : _copyToClipboard,
                icon: const Icon(Icons.copy),
                label: const Text("COPY TO CLIPBOARD"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                key: const Key('watch_tutorial'),
                onPressed: () => showTutorialVideo(context),
                icon: const Icon(Icons.play_circle_outline),
                label: const Text("Watch tutorial"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
