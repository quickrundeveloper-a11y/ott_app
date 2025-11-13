// movie_detail_page.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'full_screen_player.dart';

class MovieDetailPage extends StatefulWidget {
  final String videoId;
  const MovieDetailPage({super.key, required this.videoId});

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  static const Color limeColor = Color(0xFFB6FF3B);
  static const double horizontalPadding = 18.0;

  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  bool _showDescription = false;

  Future<DocumentSnapshot<Map<String, dynamic>>> getMovieDetails() async {
    return FirebaseFirestore.instance.collection('videos').doc(widget.videoId).get();
  }

  // Format runtime from seconds → hr/min
  String formatSeconds(int seconds) {
    if (seconds <= 0) return "N/A";

    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0 && minutes > 0) return "$hours hr $minutes min";
    if (hours > 0) return "$hours hr";
    return "$minutes min";
  }

  // DOWNLOAD LOGIC
  Future<void> _downloadVideo(String url, String title) async {
    try {
      if (Platform.isAndroid) {
        if (await Permission.manageExternalStorage.isDenied) {
          await Permission.manageExternalStorage.request();
        }
        if (await Permission.storage.isDenied) {
          await Permission.storage.request();
        }
      }

      setState(() {
        _isDownloading = true;
        _downloadProgress = 0.0;
      });

      final dio = Dio();
      Directory? targetDir;

      if (Platform.isAndroid) {
        targetDir = Directory('/storage/emulated/0/Movies');
        if (!await targetDir.exists()) {
          try {
            await targetDir.create(recursive: true);
          } catch (_) {
            targetDir = await getExternalStorageDirectory();
          }
        }
      } else {
        targetDir = await getApplicationDocumentsDirectory();
      }

      final safeTitle = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final savePath = '${targetDir!.path}/$safeTitle.mp4';

      await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() => _downloadProgress = received / total);
          }
        },
      );

      setState(() {
        _isDownloading = false;
        _downloadProgress = 0.0;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Downloaded to: $savePath')));
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _downloadProgress = 0.0;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Download failed: $e')));
    }
  }

  void _openFullScreenPlayer(String videoUrl, String title, String videoId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenNetflixPlayer(
          videoUrl: videoUrl,
          title: title,
          videoId: videoId,
        ),
      ),
    );
  }

  // ⭐ THIN PLAY BUTTON
  Widget _playButton(VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: limeColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        icon: const Icon(Icons.play_arrow, color: Colors.black),
        label: const Text("Play", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ⭐ THIN DOWNLOAD BUTTON
  Widget _downloadButton(String videoUrl, String title) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: _isDownloading ? null : () => _downloadVideo(videoUrl, title),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade900,
              side: const BorderSide(color: Colors.white24, width: 1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            icon: const Icon(Icons.download, color: Colors.white),
            label: Text("Download", style: TextStyle(color: Colors.white.withOpacity(0.9))),
          ),
        ),

        if (_isDownloading) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: _downloadProgress,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation(limeColor),
            ),
          ),
          const SizedBox(height: 6),
          Text("${(_downloadProgress * 100).toStringAsFixed(0)}%", style: const TextStyle(color: Colors.white60)),
        ]
      ],
    );
  }

  // ⭐ SINGLE LINE SECTION: "Genre: Action, Thriller"
  Widget _inlineRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          Expanded(
            child: Text(
              value.isNotEmpty ? value : "N/A",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: getMovieDetails(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator(color: limeColor));
          }

          final data = snapshot.data!.data()!;
          final title = data['title'] ?? "Untitled";
          final cover = data['coverURL'] ?? "";
          final videoUrl = data['videoURL'] ?? "";
          final summary = data['summary'] ?? "";
          final description = data['description'] ?? "";
          final genre = data['genre'] ?? "";
          final language = data['language'] ?? "";
          final cast = data['cast'] ?? "";
          final releaseYear = data['releaseYear'] ?? "";
          final runtimeSeconds = data['runtimeSeconds'] ?? 0;
          final runtimeFormatted = formatSeconds(runtimeSeconds);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.black,
                expandedHeight: 250,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: limeColor),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: cover.isNotEmpty
                      ? Image.network(cover, fit: BoxFit.cover)
                      : Container(color: Colors.grey.shade900),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(releaseYear, style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 20),

                      _playButton(() {
                        if (videoUrl.isNotEmpty) {
                          _openFullScreenPlayer(videoUrl, title, widget.videoId);
                        }
                      }),
                      const SizedBox(height: 14),

                      _downloadButton(videoUrl, title),
                      const SizedBox(height: 24),

                      // Summary
                      const Text(
                        "Summary:",
                        style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        summary,
                        style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                      ),
                      const SizedBox(height: 10),

                      // Show description toggle
                      GestureDetector(
                        onTap: () => setState(() => _showDescription = !_showDescription),
                        child: Text(
                          _showDescription ? "Hide description" : "Show description",
                          style: const TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 10),

                      if (_showDescription)
                        Text(
                          description,
                          style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
                        ),

                      // ⭐ INLINE FIELDS
                      _inlineRow("Genre", genre),
                      _inlineRow("Language", language),
                      _inlineRow("Cast", cast),
                      _inlineRow("Runtime", runtimeFormatted),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
