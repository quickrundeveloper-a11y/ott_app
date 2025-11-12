import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FullScreenPlayerPage extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String videoId;
  const FullScreenPlayerPage({
    super.key,
    required this.videoUrl,
    required this.title,
    required this.videoId,
  });

  @override
  State<FullScreenPlayerPage> createState() => _FullScreenPlayerPageState();
}

class _FullScreenPlayerPageState extends State<FullScreenPlayerPage>
    with SingleTickerProviderStateMixin {
  static const Color limeColor = Color(0xFFB6FF3B);

  VideoPlayerController? _controller;
  bool _controlsVisible = true;
  bool _isBuffering = true;
  bool _muted = false;
  Timer? _hideTimer;
  Duration? _resumePosition;
  double _volume = 1.0;
  double _speed = 1.0;
  bool _showSkipLeft = false;
  bool _showSkipRight = false;

  @override
  void initState() {
    super.initState();
    _enterFullScreen();
    _initializePlayer();
  }

  Future<void> _enterFullScreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight
    ]);
  }

  Future<void> _exitFullScreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  }

  Future<void> _loadResumePosition() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt('resume_${widget.videoId}');
    if (millis != null && millis > 0) {
      _resumePosition = Duration(milliseconds: millis);
    }
  }

  Future<void> _saveResumePosition(Duration p) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('resume_${widget.videoId}', p.inMilliseconds);
  }

  Future<void> _initializePlayer() async {
    try {
      await _loadResumePosition();

      _controller = VideoPlayerController.network(
        widget.videoUrl,
        videoPlayerOptions:
        VideoPlayerOptions(mixWithOthers: true, allowBackgroundPlayback: false),
      );

      await _controller!.initialize();
      _controller!.setLooping(false);
      _controller!.setVolume(_muted ? 0 : _volume);
      _controller!.setPlaybackSpeed(_speed);

      if (_resumePosition != null && _resumePosition!.inSeconds > 2) {
        await _controller!.seekTo(_resumePosition!);
      }

      _controller!.addListener(() {
        if (!mounted) return;
        final v = _controller!.value;
        if (v.isBuffering != _isBuffering) {
          setState(() => _isBuffering = v.isBuffering);
        }
        if (v.isInitialized && v.position.inSeconds % 5 == 0) {
          _saveResumePosition(v.position);
        }
      });

      _controller!.play();
      setState(() => _isBuffering = false);
      _startHideTimer();
    } catch (e) {
      debugPrint("Video error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error playing video: $e")));
      Navigator.pop(context);
    }
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

  Future<void> _skip(int seconds) async {
    if (_controller == null) return;
    final pos = await _controller!.position ?? Duration.zero;
    final dur = _controller!.value.duration;
    final newPos =
    Duration(seconds: (pos.inSeconds + seconds).clamp(0, dur.inSeconds));
    await _controller!.seekTo(newPos);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    if (_controller != null) {
      if (_controller!.value.isInitialized) {
        _saveResumePosition(_controller!.value.position);
      }
      _controller!.dispose();
    }
    _exitFullScreen();
    super.dispose();
  }

  String _format(Duration dur) {
    final h = dur.inHours;
    final m = dur.inMinutes % 60;
    final s = dur.inSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final initialized = c?.value.isInitialized == true;
    final pos = initialized ? c!.value.position : Duration.zero;
    final total = initialized ? c!.value.duration : Duration.zero;
    final played = total.inMilliseconds > 0
        ? pos.inMilliseconds / total.inMilliseconds
        : 0.0;
    final buffered = c?.value.buffered.isNotEmpty == true
        ? c!.value.buffered.last.end.inMilliseconds /
        total.inMilliseconds
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        onDoubleTapDown: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.localPosition.dx < width / 2) {
            _showSkipLeft = true;
            _skip(-10);
            Future.delayed(const Duration(milliseconds: 600),
                    () => setState(() => _showSkipLeft = false));
          } else {
            _showSkipRight = true;
            _skip(10);
            Future.delayed(const Duration(milliseconds: 600),
                    () => setState(() => _showSkipRight = false));
          }
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (initialized)
              Center(
                child: AspectRatio(
                  aspectRatio: c!.value.aspectRatio,
                  child: VideoPlayer(c),
                ),
              )
            else
              const Center(
                  child: CircularProgressIndicator(color: limeColor)),

            if (_isBuffering)
              const Center(
                child: CircularProgressIndicator(
                  color: limeColor,
                  strokeWidth: 3,
                ),
              ),

            if (_showSkipLeft)
              const Positioned(
                  left: 80,
                  child: Icon(Icons.replay_10,
                      color: limeColor, size: 60)),

            if (_showSkipRight)
              const Positioned(
                  right: 80,
                  child: Icon(Icons.forward_10,
                      color: limeColor, size: 60)),

            AnimatedOpacity(
              opacity: _controlsVisible ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: _controlsVisible && initialized
                  ? _buildControls(pos, total, played, buffered)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(
      Duration pos, Duration total, double played, double buffered) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // top bar
        SafeArea(
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(widget.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16)),
              ),
              IconButton(
                icon: Icon(_muted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white),
                onPressed: () {
                  if (_controller == null) return;
                  _muted = !_muted;
                  _controller!.setVolume(_muted ? 0 : _volume);
                  setState(() {});
                },
              ),
              PopupMenuButton<double>(
                color: Colors.black87,
                initialValue: _speed,
                onSelected: (value) {
                  setState(() => _speed = value);
                  _controller?.setPlaybackSpeed(value);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 0.5,
                    child: Text("0.5x",
                        style: TextStyle(color: Colors.white)),
                  ),
                  const PopupMenuItem(
                    value: 1.0,
                    child: Text("1.0x",
                        style: TextStyle(color: Colors.white)),
                  ),
                  const PopupMenuItem(
                    value: 1.25,
                    child: Text("1.25x",
                        style: TextStyle(color: Colors.white)),
                  ),
                  const PopupMenuItem(
                    value: 1.5,
                    child: Text("1.5x",
                        style: TextStyle(color: Colors.white)),
                  ),
                  const PopupMenuItem(
                    value: 2.0,
                    child: Text("2.0x",
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: Text(
                    "${_speed.toStringAsFixed(2)}x",
                    style: const TextStyle(
                        color: limeColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),

        // middle play/pause
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              iconSize: 48,
              color: Colors.white70,
              icon: const Icon(Icons.replay_10),
              onPressed: () => _skip(-10),
            ),
            IconButton(
              iconSize: 64,
              color: limeColor,
              icon: Icon(
                _controller!.value.isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_fill,
              ),
              onPressed: () {
                if (_controller!.value.isPlaying) {
                  _controller!.pause();
                } else {
                  _controller!.play();
                  _startHideTimer();
                }
                setState(() {});
              },
            ),
            IconButton(
              iconSize: 48,
              color: Colors.white70,
              icon: const Icon(Icons.forward_10),
              onPressed: () => _skip(10),
            ),
          ],
        ),

        // bottom progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    height: 5,
                    decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(3)),
                  ),
                  FractionallySizedBox(
                    widthFactor: buffered.clamp(0.0, 1.0),
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                          color: Colors.white30,
                          borderRadius: BorderRadius.circular(3)),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: played.clamp(0.0, 1.0),
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Colors.black, limeColor]),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_format(pos),
                      style:
                      const TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(_format(total),
                      style:
                      const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
