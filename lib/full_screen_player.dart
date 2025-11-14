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

  double? _lastDoubleDx;

  bool _isScrubbing = false;
  double _scrubStartDx = 0.0;
  Duration _scrubStartPos = Duration.zero;

  bool _verticalRight = false;
  double _dragStartDy = 0.0;
  double _startVal = 0.0;

  int _lastSavedSec = -1;

  // ================= NEW VARIABLES =================
  double _uiVolumeLevel = 1.0;
  double _uiBrightnessLevel = 1.0;
  bool _showVolumeBar = false;
  bool _showBrightnessBar = false;

  double _zoom = 1.0;
  double _baseZoom = 1.0;
  // ==================================================

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

  void _listener() {
    if (!mounted) return;

    final v = _controller!.value;
    _isBuffering = v.isBuffering;

    if (v.isInitialized) {
      _position = v.position;
      _duration = v.duration;
      _playbackSpeed = v.playbackSpeed;
      _isMuted = (v.volume <= 0.001);
    }

    final sec = _position.inSeconds;
    if (sec > 1 && sec % 5 == 0 && sec != _lastSavedSec) {
      _lastSavedSec = sec;
      _saveResume(_position);
    }

    setState(() {});
  }

  Future<void> _initController() async {
    final resume = await _loadResume();

    _controller = VideoPlayerController.network(widget.videoUrl);
    _controller!.addListener(_listener);

    try {
      await _controller!.initialize();
    } catch (_) {}

    if (resume != null &&
        _controller!.value.isInitialized &&
        resume.inSeconds > 1) {
      await _controller!.seekTo(resume);
    }

    if (_controller!.value.isInitialized) {
      await _controller!.setPlaybackSpeed(1.0);
      await _controller!.setVolume(1.0);
      _isMuted = false;
      await _controller!.play();
    }

    _startHideTimer();
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

  void _onDoubleTapDown(TapDownDetails d) {
    _lastDoubleDx = d.localPosition.dx;
  }

  void _onDoubleTap() {
    final w = MediaQuery.of(context).size.width;
    final dx = _lastDoubleDx ?? w / 2;

    if (dx < w * 0.33) {
      _safeSeek(-10);
    } else if (dx > w * 0.66) {
      _safeSeek(10);
    } else {
      _toggleControls();
    }
  }

  Future<void> _safeSeek(int sec) async {
    if (_controller == null) return;

    final pos = _controller!.value.position;
    final dur = _controller!.value.duration;
    final target = pos + Duration(seconds: sec);

    final clamped = Duration(
        milliseconds: target.inMilliseconds.clamp(0, dur.inMilliseconds));

    await _controller!.seekTo(clamped);
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
    _controller!.setVolume(v.clamp(0.0, 1.0));
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return "$m:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final initialized = _controller?.value.isInitialized == true;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleControls,
        onDoubleTapDown: _onDoubleTapDown,
        onDoubleTap: _onDoubleTap,

        // ============== PINCH ZOOM ===============
        onScaleStart: (d) => _baseZoom = _zoom,
        onScaleUpdate: (d) {
          setState(() {
            _zoom = (_baseZoom * d.scale).clamp(1.0, 3.0);
          });
        },
        // =========================================

        // ============== BRIGHTNESS / VOLUME =============
        onVerticalDragStart: (d) async {
          final w = MediaQuery.of(context).size.width;
          _verticalRight = d.localPosition.dx > w / 2;
          _dragStartDy = d.localPosition.dy;

          if (_verticalRight) {
            _uiVolumeLevel = _getVolume();
            _showVolumeBar = true;
          } else {
            _uiBrightnessLevel = await _getBrightness();
            _showBrightnessBar = true;
          }

          _startVal = _verticalRight ? _uiVolumeLevel : _uiBrightnessLevel;
          setState(() {});
        },

        onVerticalDragUpdate: (d) async {
          final h = MediaQuery.of(context).size.height;
          final diff = (_dragStartDy - d.localPosition.dy) / h;

          if (_verticalRight) {
            final newVol = (_startVal + diff).clamp(0.0, 1.0);
            _uiVolumeLevel = newVol;
            _setVolume(newVol);
          } else {
            final newB = (_startVal + diff).clamp(0.0, 1.0);
            _uiBrightnessLevel = newB;
            await _setBrightness(newB);
          }

          setState(() {});
        },

        onVerticalDragEnd: (_) {
          _showBrightnessBar = false;
          _showVolumeBar = false;
          setState(() {});
        },
        // =================================================

        child: Stack(
          children: [
            // ===================== VIDEO ======================
            if (initialized)
              Center(
                child: Transform.scale(
                  scale: _zoom, // zoom applied
                  child: AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  ),
                ),
              )
            else
              const Center(child: CircularProgressIndicator(color: green)),

            // ================= VOLUME BAR ==================
            if (_showVolumeBar)
              Positioned(
                right: 30,
                top: MediaQuery.of(context).size.height * 0.25,
                child: Container(
                  width: 36,
                  height: MediaQuery.of(context).size.height * 0.45,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: RotatedBox(
                    quarterTurns: -1,
                    child: LinearProgressIndicator(
                      value: _uiVolumeLevel,
                      color: green,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                ),
              ),

            // =============== BRIGHTNESS BAR ==================
            if (_showBrightnessBar)
              Positioned(
                left: 30,
                top: MediaQuery.of(context).size.height * 0.25,
                child: Container(
                  width: 36,
                  height: MediaQuery.of(context).size.height * 0.45,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: RotatedBox(
                    quarterTurns: -1,
                    child: LinearProgressIndicator(
                      value: _uiBrightnessLevel,
                      color: Colors.yellowAccent,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                ),
              ),

            // ===================== CONTROLS ====================
            if (_controlsVisible) ...[
              _buildTopBar(),
              _buildCenterPlayPause(),
              _buildBottomBar(initialized),
            ]
          ],
        ),
      ),
    );
  }

  // ---------------- TOP BAR ----------------
  Widget _buildTopBar() {
    return Positioned(
      top: 16,
      left: 12,
      right: 12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon:
                Icon(_isMuted ? Icons.volume_off : Icons.volume_up, color: green),
                onPressed: () => _setVolume(_isMuted ? 1.0 : 0.0),
              ),
              PopupMenuButton<double>(
                color: Colors.black87,
                onSelected: (v) {
                  _controller!.setPlaybackSpeed(v);
                  setState(() => _playbackSpeed = v);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 0.5, child: Text("0.5x")),
                  PopupMenuItem(value: 1.0, child: Text("1.0x")),
                  PopupMenuItem(value: 1.5, child: Text("1.5x")),
                  PopupMenuItem(value: 2.0, child: Text("2.0x")),
                ],
                child: Text(
                  "${_playbackSpeed.toStringAsFixed(2)}x",
                  style: const TextStyle(
                      color: green, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- CENTER PLAY BUTTON ----------------
  Widget _buildCenterPlayPause() {
    return Center(
      child: GestureDetector(
        onTap: () {
          if (_controller!.value.isPlaying) {
            _controller!.pause();
          } else {
            _controller!.play();
            _startHideTimer();
          }
          setState(() {});
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black38,
            border: Border.all(color: Colors.white30),
          ),
          child: Icon(
            _controller?.value.isPlaying ?? false
                ? Icons.pause
                : Icons.play_arrow,
            color: green,
            size: 34,
          ),
        ),
      ),
    );
  }

  // ---------------- BOTTOM BAR ----------------
  Widget _buildBottomBar(bool initialized) {
    final pos = initialized ? _position : Duration.zero;
    final dur = initialized ? _duration : Duration.zero;

    return Positioned(
      bottom: 18,
      left: 12,
      right: 12,
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              min: 0,
              max: dur.inMilliseconds.toDouble().clamp(1, double.infinity),
              value:
              pos.inMilliseconds.clamp(0, dur.inMilliseconds).toDouble(),
              activeColor: green,
              inactiveColor: Colors.white24,
              onChanged: (v) =>
                  _controller!.seekTo(Duration(milliseconds: v.toInt())),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_fmt(pos), style: const TextStyle(color: Colors.white70)),
              Text(_fmt(dur), style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }
}
