import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MovieDetailPage extends StatefulWidget {
  final String videoId;
  const MovieDetailPage({super.key, required this.videoId});

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  static const Color limeColor = Color(0xFFB6FF3B);
  static const double horizontalPadding = 18.0;

  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isPlaying = false;
  bool _isBuffering = false;
  Duration? _resumePosition;

  Future<DocumentSnapshot<Map<String, dynamic>>> getMovieDetails() async {
    return FirebaseFirestore.instance.collection('videos').doc(widget.videoId).get();
  }

  // ✅ Load last saved playback time from SharedPreferences
  Future<void> _loadResumePosition() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt('resume_${widget.videoId}');
    if (millis != null && millis > 0) {
      _resumePosition = Duration(milliseconds: millis);
    }
  }

  // ✅ Save playback position periodically
  Future<void> _savePlaybackPosition(Duration position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('resume_${widget.videoId}', position.inMilliseconds);
  }

  Future<void> _playFirebaseVideo(String url) async {
    try {
      await _loadResumePosition();

      final controller = VideoPlayerController.networkUrl(Uri.parse(url));

      controller.addListener(() {
        final val = controller.value;
        if (val.isBuffering != _isBuffering) {
          setState(() => _isBuffering = val.isBuffering);
        }

        // Save position every 5 seconds
        if (val.isInitialized && val.position.inSeconds % 5 == 0) {
          _savePlaybackPosition(val.position);
        }
      });

      await controller.initialize();

      // ✅ Seek to last saved position if available
      if (_resumePosition != null && _resumePosition!.inSeconds > 5) {
        await controller.seekTo(_resumePosition!);
      }

      controller.play();

      final chewie = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowPlaybackSpeedChanging: true,
        allowMuting: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: limeColor,
          handleColor: limeColor,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white38,
        ),
      );

      setState(() {
        _videoController = controller;
        _chewieController = chewie;
        _isPlaying = true;
      });
    } catch (e) {
      debugPrint("Video playback error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error playing video: $e")),
      );
    }
  }

  @override
  void dispose() {
    // ✅ Save final position on exit
    if (_videoController != null && _videoController!.value.isInitialized) {
      _savePlaybackPosition(_videoController!.value.position);
    }
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: limeColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Movie Details",
          style: TextStyle(
            color: limeColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: getMovieDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: limeColor));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                "No movie found.",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final data = snapshot.data!.data()!;
          final String videoURL = data['videoURL'] ?? '';
          final String coverURL = data['coverURL'] ?? '';
          final String title = data['title'] ?? 'Untitled';
          final String genre = data['genre'] ?? 'Unknown';
          final String description = data['description'] ?? 'No description available.';
          final String language = data['language'] ?? '';
          final String cast = data['cast'] ?? '';
          final String director = data['director'] ?? '';
          final String releaseYear = data['releaseYear'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Movie Poster or Video Player
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_isPlaying && _chewieController != null)
                          Chewie(controller: _chewieController!)
                        else if (coverURL.isNotEmpty)
                          Image.network(
                            coverURL,
                            width: double.infinity,
                            height: 250,
                            fit: BoxFit.cover,
                          )
                        else
                          Container(
                            color: Colors.grey[900],
                            alignment: Alignment.center,
                            child: const Text(
                              "No Image",
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),

                        // 🔄 Buffering Indicator
                        if (_isBuffering)
                          Container(
                            color: Colors.black26,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: limeColor,
                                strokeWidth: 3,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Movie Title
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                // Director and Year Row
                Row(
                  children: [
                    const Icon(Icons.movie, color: limeColor, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      director.isNotEmpty ? director : "Unknown Director",
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.calendar_month, color: limeColor, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      releaseYear.isNotEmpty ? releaseYear : "N/A",
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Play Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (videoURL.isNotEmpty) {
                        _playFirebaseVideo(videoURL);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("No video URL found!")),
                        );
                      }
                    },
                    icon: const Icon(Icons.play_arrow, color: Colors.black),
                    label: const Text(
                      "Play / Resume",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: limeColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Download Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download, color: limeColor),
                    label: const Text(
                      "Download",
                      style: TextStyle(
                        color: limeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: limeColor, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Genre
                const Text(
                  "Genre",
                  style: TextStyle(
                    color: limeColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  genre,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),

                const SizedBox(height: 20),

                // Language
                const Text(
                  "Language",
                  style: TextStyle(
                    color: limeColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  language.isNotEmpty ? language : "N/A",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),

                const SizedBox(height: 20),

                // Description
                const Text(
                  "Description",
                  style: TextStyle(
                    color: limeColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 30),

                // Cast
                const Text(
                  "Cast",
                  style: TextStyle(
                    color: limeColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  cast.isNotEmpty ? cast : "No cast information available.",
                  style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.6),
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}
