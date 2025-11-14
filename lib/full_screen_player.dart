// full_screen_netflix_player.dart
// Final, self-contained Netflix-style fullscreen player with:
// - double-tap left/right skip (+10 / -10s) with overlay
// - single-tap toggles controls
// - center play/pause button
// - mute button + playback speed menu
// - vertical drag for brightness (left) and volume (right)
// - uses VideoProgressIndicator from video_player (default widget)
// - safe seeking (pause -> seek -> resume state) to avoid restart
// - avoids red flicker by showing a solid black background until video is ready
// - persists resume position every 5s
// - performance-minded: avoids rebuilding controller; minimal setState during frequent events

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:screen_brightness/screen_brightness.dart';

class FullScreenNetflixPlayer extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String videoId;

  const FullScreenNetflixPlayer({
    super.key,
    required this.videoUrl,
    required this.title,
    required this.videoId,
  });

  @override
  State<FullScreenNetflixPlayer> createState() =>
      _FullScreenNetflixPlayerState();
}

class _FullScreenNetflixPlayerState extends State<FullScreenNetflixPlayer>
    with SingleTickerProviderStateMixin {
  static const Color limeColor = Color(0xFFB6FF3B);

  VideoPlayerController? _controller;
  bool _controlsVisible = true;
  bool _isBuffering = false;
  bool _muted = false;
  double _playbackSpeed = 1.0;

  // double-tap / skip overlays
  double? _lastDoubleDx;
  Offset? _lastDoubleGlobalPos;
  bool _showLeftSkip = false;
  bool _showRightSkip = false;
  bool _showRipple = false;
  late AnimationController _rippleAnim;

  // vertical drag (volume/brightness)
  double _startDragDy = 0.0;
  double _startDragVal = 0.0;
  bool _isDraggingVolumeOrBrightness = false;
  bool _draggingSideRight = false;

  // autohide timer
  Timer? _hideTimer;

  // resume/persist
  Duration? _resumePosition;
  int _lastSavedSec = -1;

  // avoid races during seeking
  bool _isSeeking = false;

  @override
  void initState() {
    super.initState();
    _rippleAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _enterFullScreen();
    _initialize();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _rippleAnim.dispose();
    if (_controller != null) {
      _controller!.removeListener(_playerListener);
      if (_controller!.value.isInitialized) {
        _saveResumePosition(_controller!.value.position);
      }
      _controller!.dispose();
    }
    _exitFullScreen();
    super.dispose();
  }

  // --- fullscreen helpers -------------------------------------------------
  Future<void> _enterFullScreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  }

  Future<void> _exitFullScreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  }

  // --- resume storage ----------------------------------------------------
  Future<void> _loadResumePosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ms = prefs.getInt('resume_${widget.videoId}');
      if (ms != null && ms > 0) _resumePosition = Duration(milliseconds: ms);
    } catch (_) {
      _resumePosition = null;
    }
  }

  Future<void> _saveResumePosition(Duration pos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('resume_${widget.videoId}', pos.inMilliseconds);
    } catch (_) {}
  }

  // --- initialization ---------------------------------------------------
  Future<void> _initialize() async {
    await _loadResumePosition();

    _controller = VideoPlayerController.network(
      widget.videoUrl,
      videoPlayerOptions:  VideoPlayerOptions(mixWithOthers: true),
    );

    // add listener once
    _controller!.addListener(_playerListener);

    try {
      // show buffering until fully initialized
      setState(() => _isBuffering = true);

      await _controller!.initialize();

      // apply resume pos if available and >1s
      if (_resumePosition != null && _resumePosition!.inSeconds > 1) {
        // use safe seek to position
        await _safeSeek(_resumePosition!);
      }

      await _controller!.setPlaybackSpeed(_playbackSpeed);
      await _controller!.setVolume(1.0);
      await _controller!.play();

      setState(() {
        _isBuffering = false;
        _controlsVisible = true;
      });

      _startHideTimer();
    } catch (e) {
      setState(() => _isBuffering = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error playing video: $e')));
        Navigator.of(context).maybePop();
      }
    }
  }

  // --- listener ---------------------------------------------------------
  void _playerListener() {
    if (!mounted) return;
    final v = _controller!.value;

    // buffering state change
    final buffering = v.isBuffering;
    if (buffering != _isBuffering) {
      setState(() => _isBuffering = buffering);
    }

    // persist every 5 seconds when not seeking
    if (!_isSeeking && v.isInitialized) {
      final sec = v.position.inSeconds;
      if (sec != _lastSavedSec && sec % 5 == 0) {
        _lastSavedSec = sec;
        _saveResumePosition(v.position);
      }
    }
  }

  // --- safe seek (pause -> seek -> restore play state) -----------------
  Future<void> _safeSeek(Duration pos) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    _isSeeking = true;
    final wasPlaying = _controller!.value.isPlaying;
    try {
      await _controller!.pause();
      await _controller!.seekTo(pos);
    } catch (_) {
      // ignore
    } finally {
      _isSeeking = false;
    }
    if (wasPlaying) {
      await _controller!.play();
    } else {
      await _controller!.pause();
    }
    if (mounted) setState(() {});
  }

  Future<void> _safeSeekBySeconds(int seconds) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final curr = _controller!.value.position;
    final dur = _controller!.value.duration;
    final target = curr + Duration(seconds: seconds);
    final clamped = Duration(
        milliseconds: target.inMilliseconds.clamp(0, dur.inMilliseconds));
    await _safeSeek(clamped);
  }

  // --- UI helpers ------------------------------------------------------
  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _startHideTimer();
  }

  // show ripple and center skip icons
  void _showSkipOverlay(Offset globalPos, bool left) {
    _lastDoubleGlobalPos = globalPos;
    _showRipple = true;
    _showLeftSkip = left;
    _showRightSkip = !left;
    _rippleAnim.forward(from: 0.0);
    setState(() {});
    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      setState(() {
        _showRipple = false;
        _showLeftSkip = false;
        _showRightSkip = false;
      });
    });
  }

  // --- double-tap handling --------------------------------------------
  void _onDoubleTap() {
    final dx = _lastDoubleDx;
    if (dx == null) return;
    final w = MediaQuery.of(context).size.width;
    final localPos = _lastDoubleGlobalPos ?? Offset(w / 2, MediaQuery.of(context).size.height / 2);

    if (dx < w * 0.33) {
      // left third -> rewind
      _showSkipOverlay(localPos, true);
      _safeSeekBySeconds(-10);
    } else if (dx > w * 0.66) {
      // right third -> forward
      _showSkipOverlay(localPos, false);
      _safeSeekBySeconds(10);
    } else {
      // center -> toggle controls
      _toggleControls();
    }
  }

  // --- vertical drag (volume/brightness) ------------------------------
  Future<double> _getBrightness() async {
    try {
      return await ScreenBrightness().current;
    } catch (_) {
      return 0.5;
    }
  }

  Future<void> _setBrightness(double v) async {
    try {
      await ScreenBrightness().setScreenBrightness(v.clamp(0.0, 1.0));
    } catch (_) {}
  }

  double _getVolume() => _controller?.value.volume ?? 1.0;

  Future<void> _setVolume(double v) async {
    _controller?.setVolume(v.clamp(0.0, 1.0));
    if (mounted) setState(() {});
  }

  void _onVerticalDragStart(DragStartDetails d) async {
    if (_controller == null) return;
    _isDraggingVolumeOrBrightness = true;
    _startDragDy = d.localPosition.dy;
    final width = MediaQuery.of(context).size.width;
    _draggingSideRight = d.localPosition.dx > width / 2;
    if (_draggingSideRight) {
      _startDragVal = _getVolume();
    } else {
      _startDragVal = await _getBrightness();
    }
    _hideTimer?.cancel();
    setState(() {}); // show overlay
  }

  void _onVerticalDragUpdate(DragUpdateDetails d) {
    if (!_isDraggingVolumeOrBrightness) return;
    final delta = _startDragDy - d.localPosition.dy;
    final height = MediaQuery.of(context).size.height;
    final fraction = (delta / height).clamp(-1.0, 1.0);
    final newVal = (_startDragVal + fraction).clamp(0.0, 1.0);
    if (_draggingSideRight) {
      _setVolume(newVal);
    } else {
      _setBrightness(newVal);
    }
  }

  void _onVerticalDragEnd(DragEndDetails d) {
    _isDraggingVolumeOrBrightness = false;
    _startDragDy = 0.0;
    _startDragVal = 0.0;
    _startHideTimer();
    setState(() {});
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    final two = (int n) => n.toString().padLeft(2, '0');
    if (h > 0) return '$h:${two(m)}:${two(s)}';
    return '${m}:${two(s)}';
  }

  // --- build ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final initialized = _controller?.value.isInitialized == true;
    final pos = initialized ? _controller!.value.position : Duration.zero;
    final total = initialized ? _controller!.value.duration : Duration.zero;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleControls,
        onDoubleTapDown: (details) {
          _lastDoubleDx = details.localPosition.dx;
          _lastDoubleGlobalPos = details.globalPosition;
        },
        onDoubleTap: _onDoubleTap,
        onVerticalDragStart: _onVerticalDragStart,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Black background always present (avoids flicker / surface issue)
            Container(color: Colors.black),

            // Video surface (only when initialized) - wrapped in AspectRatio
            if (initialized)
              Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              )
            else
            // while initializing, still show a loader but keep black background
              const Center(
                child: CircularProgressIndicator(color: limeColor),
              ),

            // Buffering overlay spinner (keeps showing when buffer)
            if (_isBuffering)
              const Center(
                child: CircularProgressIndicator(color: limeColor, strokeWidth: 3),
              ),

            // Ripple circle overlay at double-tap spot (text + scale)
            if (_showRipple && _lastDoubleGlobalPos != null)
              Positioned(
                left: _lastDoubleGlobalPos!.dx - 60,
                top: _lastDoubleGlobalPos!.dy - 60 - MediaQuery.of(context).padding.top,
                child: FadeTransition(
                  opacity: CurvedAnimation(parent: _rippleAnim, curve: Curves.easeOut),
                  child: ScaleTransition(
                    scale: Tween(begin: 0.6, end: 1.05).animate(
                        CurvedAnimation(parent: _rippleAnim, curve: Curves.easeOutBack)),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black54,
                      ),
                      child: Center(
                        child: Text(
                          _showLeftSkip ? '-10s' : '+10s',
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // big skip icons (left / right)
            if (_showLeftSkip)
              Positioned(
                left: 36,
                top: MediaQuery.of(context).size.height / 2 - 40,
                child: _skipIcon('-10'),
              ),
            if (_showRightSkip)
              Positioned(
                right: 36,
                top: MediaQuery.of(context).size.height / 2 - 40,
                child: _skipIcon('+10'),
              ),

            // drag overlay for brightness / volume
            if (_isDraggingVolumeOrBrightness)
              Positioned(
                right: _draggingSideRight ? 36 : null,
                left: _draggingSideRight ? null : 36,
                top: MediaQuery.of(context).size.height / 2 - 60,
                child: _dragIndicator(),
              ),

            // Controls (top title, center play/pause, bottom progress)
            if (_controlsVisible) _buildControls(pos, total, initialized),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(Duration pos, Duration total, bool initialized) {
    return Column(
      children: [
        // top bar
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                // mute button
                IconButton(
                  icon: Icon(_muted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white),
                  onPressed: () {
                    _muted = !_muted;
                    _controller?.setVolume(_muted ? 0.0 : 1.0);
                    setState(() {});
                  },
                ),

                // speed menu (playback speed)
                PopupMenuButton<double>(
                  color: Colors.black87,
                  initialValue: _playbackSpeed,
                  onSelected: (v) {
                    _playbackSpeed = v;
                    _controller?.setPlaybackSpeed(v);
                    setState(() {});
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 0.5, child: Text("0.5x")),
                    PopupMenuItem(value: 1.0, child: Text("1.0x")),
                    PopupMenuItem(value: 1.25, child: Text("1.25x")),
                    PopupMenuItem(value: 1.5, child: Text("1.5x")),
                    PopupMenuItem(value: 2.0, child: Text("2.0x")),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      "${_playbackSpeed}x",
                      style: const TextStyle(
                          color: limeColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // center big play/pause button
        Expanded(
          child: Center(
            child: GestureDetector(
              onTap: () async {
                if (_controller == null || !_controller!.value.isInitialized) return;
                if (_controller!.value.isPlaying) {
                  await _controller!.pause();
                } else {
                  await _controller!.play();
                  _startHideTimer();
                }
                setState(() {});
              },
              child: Container(
                decoration: const BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                padding: const EdgeInsets.all(12),
                child: Icon(
                  (_controller?.value.isPlaying ?? false) ? Icons.pause : Icons.play_arrow,
                  color: limeColor,
                  size: 56,
                ),
              ),
            ),
          ),
        ),

        // bottom progress bar + times
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (initialized)
                  VideoProgressIndicator(
                    _controller!,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      playedColor: limeColor,
                      bufferedColor: Colors.white30,
                      backgroundColor: Colors.white12,
                    ),
                  )
                else
                  const SizedBox(height: 6),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fmt(pos), style: const TextStyle(color: Colors.white70)),
                    Text(_fmt(total), style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dragIndicator() {
    final value = _draggingSideRight ? _getVolume().clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Icon(_draggingSideRight ? Icons.volume_up : Icons.wb_sunny, color: Colors.white),
          const SizedBox(height: 6),
          SizedBox(
            width: 80,
            child: LinearProgressIndicator(
              value: _draggingSideRight ? value : null,
              backgroundColor: Colors.white12,
              color: limeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _skipIcon(String text) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black45,
        border: Border.all(color: Colors.white24),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (text.startsWith("-"))
              Transform.rotate(angle: pi, child: const Icon(Icons.forward_10, color: Colors.white, size: 24))
            else
              const Icon(Icons.forward_10, color: Colors.white, size: 24),
            const SizedBox(width: 4),
            Text(text.replaceAll("+", ""), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
