
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:window_manager/window_manager.dart';
import 'package:video_player_win/video_player_win.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      title: '月薪貓2',
      backgroundColor: Colors.white,
      center: true,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const VideoApp());
}

class VideoApp extends StatelessWidget {
  const VideoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: VideoScreen(),
    );
  }
}

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  late final VideoPlayerController _controller;

  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset(
      'assets/videos/video.mp4',
    );

    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      await _controller.initialize();
      await _controller.setLooping(true);
      await _controller.play();

      if (mounted) {
        setState(() {
          _ready = true;
        });
      }
    } catch (error) {
      debugPrint('Video yüklenemedi: $error');

      if (mounted) {
        setState(() {
          _failed = true;
        });
      }
    }
  }

  Future<void> _toggleFullscreen() async {
    if (!Platform.isWindows) return;

    final isFullscreen = await windowManager.isFullScreen();

    await windowManager.setFullScreen(!isFullscreen);
  }

  KeyEventResult _handleKey(
    FocusNode node,
    KeyEvent event,
  ) {
    if (Platform.isWindows &&
        event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.f11) {
      unawaited(_toggleFullscreen());
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Focus(
        autofocus: true,
        onKeyEvent: _handleKey,
        child: SizedBox.expand(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (!_ready || _failed) {
                // Video yüklenirken veya hata oluştuğunda
                // arka plan beyaz kalır.
                return const SizedBox.expand();
              }

              final videoSize = _controller.value.size;

              if (videoSize.width <= 0 || videoSize.height <= 0) {
                return const SizedBox.expand();
              }

              final scale = math.min(
                constraints.maxWidth / videoSize.width,
                constraints.maxHeight / videoSize.height,
              );

              final width = videoSize.width * scale;
              final height = videoSize.height * scale;

              return Center(
                child: SizedBox(
                  width: width,
                  height: height,
                  child: IgnorePointer(
                    child: VideoPlayer(_controller),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
