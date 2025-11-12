// movie_detail_page.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Download to public Movies folder: /storage/emulated/0/Movies
  Future<void> _requestStorageAndDownload(String url, String title) async {
    // Android 13+ needs different permissions; we request generic storage permissions first.
    try {
      // request storage permissions
      final status = await Permission.storage.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        // Try manage external storage (Android 11+)
        if (await Permission.manageExternalStorage.isDenied) {
          final m = await Permission.manageExternalStorage.request();
          if (!m.isGranted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Storage permission is required to download.')),
            );
            return;
          }
        }
      }
      // Now proceed
      await _downloadToMovies(url, title);
    } catch (e) {
      debugPrint('Permission / download error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: $e')));
    }
  }

  Future<void> _downloadToMovies(String url, String title) async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    final dio = Dio();

    try {
      // target path: /storage/emulated/0/Movies
      Directory moviesDir;
      if (Platform.isAndroid) {
        final externalRoot = Directory('/storage/emulated/0');
        moviesDir = Directory('${externalRoot.path}/Movies');
      } else {
        final temp = Directory.systemTemp;
        moviesDir = Directory('${temp.path}/Movies');
      }

      if (!await moviesDir.exists()) {
        await moviesDir.create(recursive: true);
      }

      final safeName = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final savePath = '${moviesDir.path}/$safeName.mp4';

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
        _downloadProgress = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloaded to: $savePath')),
      );
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _downloadProgress = 0;
      });
      debugPrint('Download error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    }
  }

  // Open full-screen player page (it will start playing immediately)
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

  Widget _downloadButton(String videoUrl, String title) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _isDownloading ? null : () => _requestStorageAndDownload(videoUrl, title),
        icon: _isDownloading
            ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: limeColor, strokeWidth: 2))
            : const Icon(Icons.download, color: limeColor),
        label: _isDownloading
            ? Text('${(_downloadProgress * 100).toStringAsFixed(0)}%')
            : const Text('Download', style: TextStyle(color: limeColor, fontWeight: FontWeight.bold, fontSize: 16)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: limeColor, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
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
                      Row(children: [Text(releaseYear, style: const TextStyle(color: Colors.white70)), const SizedBox(width: 8), _tag("U/A"), const SizedBox(width: 8), _tag("HD")]),
                      const SizedBox(height: 20),

                      // gradient play (both play button and poster icon do the same)
                      _gradientPlayButton(() {
                        if (videoURL.isNotEmpty) _openFullScreenPlayer(videoURL, title, widget.videoId);
                        else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No video URL found")));
                      }),
                      const SizedBox(height: 12),

                      // download
                      _downloadButton(videoURL, title),
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
