// full_screen_player.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FullScreenPlayer extends StatefulWidget {
  final String videoUrl;
  final String videoId;
  final String title;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;

  const FullScreenPlayer({
    super.key,
    required this.videoUrl,
    required this.videoId,
    required this.title,
    this.onNext,
    this.onPrevious,
  });

  @override
  State<FullScreenPlayer> createState() => _FullScreenPlayerState();
}

class _FullScreenPlayerState extends State<FullScreenPlayer>
    with SingleTickerProviderStateMixin {
  static const Color green = Color(0xFF00FF66);

  VideoPlayerController? _controller;
  bool _controlsVisible = true;
  Timer? _hideTimer;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _playbackSpeed = 1.0;
  bool _isMuted = false;
  bool _isBuffering = false;

  // double-tap detection
  double? _lastDoubleDx;
  Offset? _lastDoubleGlobalPos;

  // scrubbing & gestures
  bool _isScrubbing = false;
  double _scrubStartDx = 0.0;
  Duration _scrubStartPos = Duration.zero;

  bool _isVerticalDrag = false;
  bool _verticalRight = false;
  double _dragStartDy = 0.0;
  double _startVal = 0.0;

  // resume save throttle
  int _lastSavedSec = -1;

  @override
  void initState() {
    super.initState();
    _enterFullscreen();
    _initController();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller?.removeListener(_listener);
    _controller?.dispose();
    _exitFullscreen();
    super.dispose();
  }

  Future<void> _enterFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  }

  Future<void> _exitFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  }

  Future<Duration?> _loadResume() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ms = prefs.getInt('resume_${widget.videoId}');
      if (ms != null && ms > 0) return Duration(milliseconds: ms);
    } catch (_) {}
    return null;
  }

  Future<void> _saveResume(Duration d) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('resume_${widget.videoId}', d.inMilliseconds);
    } catch (_) {}
  }



  void _debugVideoStatus() {
    if (_controller == null) return;

    final val = _controller!.value;

    // Log when an error appears
    if (val.hasError) {
      print("🔥 VIDEO ERROR: ${val.errorDescription}");
    }

    // Log duration change
    if (val.duration.inMilliseconds == 0) {
      print("⚠ Duration still ZERO — maybe metadata/cors issue");
    }

    // Log position changes
    print("▶ position=${val.position.inMilliseconds}, "
        "duration=${val.duration.inMilliseconds}, "
        "isPlaying=${val.isPlaying}, "
        "isBuffering=${val.isBuffering}");

    // Log initialization
    if (val.isInitialized) {
      print("🎉 VIDEO INITIALIZED — aspectRatio=${val.aspectRatio}");
    }

    // Log buffering issues
    if (val.isBuffering) {
      print("⏳ BUFFERING...");
    }
  }






  Future<void> _initController() async {

    final resume = await _loadResume();
    _controller = VideoPlayerController.network(widget.videoUrl);
    _controller!.addListener(_debugVideoStatus);

    _controller!.addListener(_listener);

    try {
      await _controller!.initialize();
    } catch (e) {
      // failed to init
    }

    if (resume != null && _controller!.value.isInitialized && resume.inSeconds > 1) {
      try {
        await _controller!.seekTo(resume);
      } catch (_) {}
    }

    if (_controller!.value.isInitialized) {
      await _controller!.setPlaybackSpeed(1.0);
      await _controller!.setVolume(1.0);
      _playbackSpeed = 1.0;
      _isMuted = (_controller!.value.volume == 0);
      await _controller!.play();
    }

    _startHideTimer();
    setState(() {});
  }

  void _listener() {
    if (!mounted) return;
    final v = _controller!.value;

    // buffering state
    final buffering = v.isBuffering;
    if (buffering != _isBuffering) {
      _isBuffering = buffering;
    }

    if (v.isInitialized) {
      _position = v.position;
      _duration = v.duration ?? Duration.zero;
      _playbackSpeed = v.playbackSpeed;
      _isMuted = (v.volume <= 0.001);
    }

    // save every 5s
    final sec = _position.inSeconds;
    if (sec > 1 && sec % 5 == 0 && sec != _lastSavedSec) {
      _lastSavedSec = sec;
      _saveResume(_position);
    }

    setState(() {});
  }

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

  // double-tap handling: determine side on down event
  void _onDoubleTapDown(TapDownDetails details) {
    _lastDoubleDx = details.localPosition.dx;
    _lastDoubleGlobalPos = details.globalPosition;
  }

  void _onDoubleTap() {
    final w = MediaQuery.of(context).size.width;
    final dx = _lastDoubleDx ?? w / 2;
    if (dx < w * 0.33) {
      _safeSeekBy(-10);
    } else if (dx > w * 0.66) {
      _safeSeekBy(10);
    } else {
      _toggleControls();
    }
  }

  Future<void> _safeSeekBy(int sec) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final pos = _controller!.value.position;
    final dur = _controller!.value.duration ?? Duration.zero;
    final target = pos + Duration(seconds: sec);
    final clamped = Duration(milliseconds: target.inMilliseconds.clamp(0, dur.inMilliseconds));
    await _controller!.seekTo(clamped);
  }

  Future<void> _setPlaybackSpeed(double v) async {
    if (_controller == null) return;
    try {
      await _controller!.setPlaybackSpeed(v);
      setState(() => _playbackSpeed = v);
    } catch (_) {}
  }

  Future<double> _getBrightness() async {
    try {
      return await ScreenBrightness().current;
    } catch (_) {
      return 0.5;
    }
  }

  Future<void> _setBrightness(double v) async {
    try {
      await ScreenBrightness().setScreenBrightness(v.clamp(0, 1));
    } catch (_) {}
  }

  double _getVolume() => _controller?.value.volume ?? 1.0;

  void _setVolume(double v) {
    if (_controller == null) return;
    final vol = v.clamp(0.0, 1.0);
    try {
      _controller!.setVolume(vol);
    } catch (_) {}
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '$h:${m.toString().padLeft(2, "0")}:${s.toString().padLeft(2, "0")}';
    return '${m}:${s.toString().padLeft(2, "0")}';
  }

  @override
  Widget build(BuildContext context) {
    final initialized = _controller?.value.isInitialized == true;
    final pos = initialized ? _position : Duration.zero;
    final total = initialized ? _duration : Duration.zero;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTapDown: _onDoubleTapDown,
        onDoubleTap: _onDoubleTap,
        onTap: _toggleControls,

        // horizontal drag -> scrub
        onHorizontalDragStart: (d) {
          if (!initialized) return;
          _isScrubbing = true;
          _scrubStartDx = d.localPosition.dx;
          _scrubStartPos = _position;
          _hideTimer?.cancel();
        },
        onHorizontalDragUpdate: (d) {
          if (!_isScrubbing || !initialized) return;
          final w = MediaQuery.of(context).size.width;
          final dx = d.localPosition.dx - _scrubStartDx;
          final fraction = dx / w;
          final dur = _duration.inMilliseconds;
          final baseMs = _scrubStartPos.inMilliseconds;
          final offset = (fraction * dur).toInt();
          final newMs = (baseMs + offset).clamp(0, dur);
          _controller!.seekTo(Duration(milliseconds: newMs));
        },
        onHorizontalDragEnd: (_) {
          _isScrubbing = false;
          _startHideTimer();
        },

        // vertical drag -> brightness / volume
        onVerticalDragStart: (d) async {
          if (_controller == null) return;
          final w = MediaQuery.of(context).size.width;
          _verticalRight = d.localPosition.dx > w / 2;
          _dragStartDy = d.localPosition.dy;
          _startVal = _verticalRight ? _getVolume() : await _getBrightness();
          _hideTimer?.cancel();
        },
        onVerticalDragUpdate: (d) async {
          final h = MediaQuery.of(context).size.height;
          final diff = (_dragStartDy - d.localPosition.dy) / h;
          if (_verticalRight) {
            _setVolume(_startVal + diff);
          } else {
            await _setBrightness(_startVal + diff);
          }
        },
        onVerticalDragEnd: (_) {
          _startHideTimer();
        },

        child: Stack(
          children: [
            // Video surface
            if (initialized)
              Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              )
            else
              const Center(child: CircularProgressIndicator(color: green)),

            // Controls overlay
            if (_controlsVisible) _buildControls(initialized),

            // Title top-left
            if (_controlsVisible)
              Positioned(
                top: 16,
                left: 12,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 8),
                    Text(widget.title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(bool initialized) {
    final pos = initialized ? _position : Duration.zero;
    final total = initialized ? _duration : Duration.zero;
    final sliderValue = initialized ? pos.inMilliseconds.clamp(0, total.inMilliseconds).toDouble() : 0.0;
    final sliderMax = (initialized && total.inMilliseconds > 0) ? total.inMilliseconds.toDouble() : 1.0;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: _controlsVisible ? 1 : 0,
      child: Column(
        children: [
          const SizedBox(height: 36),
          // top-right controls (mute + speed)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                const Spacer(),
                IconButton(
                  icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up, color: green),
                  onPressed: () {
                    final newMuted = !_isMuted;
                    _setVolume(newMuted ? 0.0 : 1.0);
                    // _isMuted will update via listener
                  },
                ),
                PopupMenuButton<double>(
                  color: Colors.black87,
                  onSelected: (v) => _setPlaybackSpeed(v),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 0.5, child: Text("0.5x")),
                    PopupMenuItem(value: 1.0, child: Text("1.0x")),
                    PopupMenuItem(value: 1.25, child: Text("1.25x")),
                    PopupMenuItem(value: 1.5, child: Text("1.5x")),
                    PopupMenuItem(value: 2.0, child: Text("2.0x")),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("${_playbackSpeed.toStringAsFixed(2)}x",
                        style: const TextStyle(color: green, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // center play/pause
          GestureDetector(
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black38,
                border: Border.all(color: Colors.white30),
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(
                (_controller?.value.isPlaying ?? false) ? Icons.pause : Icons.play_arrow,
                color: green,
                size: 48,
              ),
            ),
          ),

          const Spacer(),

          // bottom: thin slider + times + next/prev
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              children: [
                // thin bar: placeholder until initialized
                if (!initialized || total.inMilliseconds == 0)
                  Container(height: 3, color: Colors.white12, width: double.infinity)
                else
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      min: 0,
                      max: sliderMax,
                      value: sliderValue,
                      activeColor: green,
                      inactiveColor: Colors.white24,
                      onChanged: (v) {
                        // live seek while dragging slider
                        if (_controller == null) return;
                        _controller!.seekTo(Duration(milliseconds: v.toInt()));
                        setState(() {});
                      },
                    ),
                  ),

                const SizedBox(height: 6),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fmt(pos), style: const TextStyle(color: Colors.white70)),
                    Text(_fmt(total), style: const TextStyle(color: Colors.white70)),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.onPrevious != null)
                      IconButton(
                        icon: const Icon(Icons.skip_previous, color: green, size: 32),
                        onPressed: widget.onPrevious,
                      ),
                    const SizedBox(width: 24),
                    if (widget.onNext != null)
                      IconButton(
                        icon: const Icon(Icons.skip_next, color: green, size: 32),
                        onPressed: widget.onNext,
                      ),
                  ],
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
