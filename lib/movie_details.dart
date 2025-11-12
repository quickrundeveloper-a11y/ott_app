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

  Future<DocumentSnapshot<Map<String, dynamic>>> getMovieDetails() async {
    return FirebaseFirestore.instance.collection('videos').doc(widget.videoId).get();
  }

  Future<void> _downloadVideo(String url, String title) async {
    try {
      // Request storage permissions
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

      // Choose best directory
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
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      setState(() {
        _isDownloading = false;
        _downloadProgress = 0.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Downloaded successfully to: $savePath')),
      );
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _downloadProgress = 0.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Download failed: $e')),
      );
    }
  }

  void _openFullScreenPlayer(String videoUrl, String title, String videoId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullScreenPlayerPage(
          videoUrl: videoUrl,
          title: title,
          videoId: videoId,
        ),
      ),
    );
  }

  Widget _gradientPlayButton(VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Colors.black, limeColor],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.play_arrow, color: Colors.black),
        label: const Text(
          "Play",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        onPressed: onPressed,
      ),
    );
  }

  // ✅ Download button with progress bar BELOW it
  Widget _downloadSection(String videoUrl, String title) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _isDownloading ? null : () => _downloadVideo(videoUrl, title),
            icon: const Icon(Icons.download, color: limeColor),
            label: const Text(
              'Download',
              style: TextStyle(color: limeColor, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: limeColor, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),

        // ✅ Progress bar displayed below button
        if (_isDownloading) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _downloadProgress,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(limeColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Downloading: ${(_downloadProgress * 100).toStringAsFixed(0)}%',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ],
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  Widget _section(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          text: "$label: ",
          style: const TextStyle(color: limeColor, fontSize: 16, fontWeight: FontWeight.w600),
          children: [
            TextSpan(
              text: value.isNotEmpty ? value : "N/A",
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ],
        ),
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: limeColor));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Movie not found", style: TextStyle(color: Colors.white70)));
          }

          final data = snapshot.data!.data()!;
          final String title = data['title'] ?? 'Untitled';
          final String coverURL = data['coverURL'] ?? '';
          final String videoURL = data['videoURL'] ?? '';
          final String description = data['description'] ?? '';
          final String genre = data['genre'] ?? '';
          final String language = data['language'] ?? '';
          final String cast = data['cast'] ?? '';
          final String releaseYear = data['releaseYear'] ?? '';
          final String runtime = data['runtime']?.toString() ?? '';

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.black,
                expandedHeight: 250,
                floating: false,
                pinned: true,
                systemOverlayStyle: SystemUiOverlayStyle.light,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: limeColor),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    alignment: Alignment.center,
                    children: [
                      coverURL.isNotEmpty
                          ? Image.network(coverURL, fit: BoxFit.cover, width: double.infinity)
                          : Container(color: Colors.grey.shade900),
                      Positioned(
                        child: InkWell(
                          onTap: () {
                            if (videoURL.isNotEmpty) _openFullScreenPlayer(videoURL, title, widget.videoId);
                          },
                          child: Container(
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black54),
                            padding: const EdgeInsets.all(12),
                            child: const Icon(Icons.play_arrow, color: limeColor, size: 48),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(title,
                          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Text(releaseYear, style: const TextStyle(color: Colors.white70)),
                        const SizedBox(width: 8),
                        _tag("U/A"),
                        const SizedBox(width: 8),
                        _tag("HD")
                      ]),
                      const SizedBox(height: 20),

                      _gradientPlayButton(() {
                        if (videoURL.isNotEmpty) {
                          _openFullScreenPlayer(videoURL, title, widget.videoId);
                        } else {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text("No video URL found")));
                        }
                      }),
                      const SizedBox(height: 12),

                      _downloadSection(videoURL, title),
                      const SizedBox(height: 20),

                      _section("Description", description),
                      _section("Genre", genre),
                      _section("Language", language),
                      _section("Cast", cast),
                      _section("Runtime", runtime),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
