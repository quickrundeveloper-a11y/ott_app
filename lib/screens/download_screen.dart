// downloads_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as p;

class DownloadsPage extends StatefulWidget {
  const DownloadsPage({Key? key}) : super(key: key);

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  List<FileSystemEntity> movieFiles = [];
  List<FileSystemEntity> seriesFiles = [];

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    final moviesDir = Directory('/storage/emulated/0/Movies');
    final seriesDir = Directory('/storage/emulated/0/Series');

    if (await moviesDir.exists()) {
      final list = moviesDir.listSync(recursive: false).where((f) {
        return f.path.toLowerCase().endsWith(".mp4");
      }).toList();
      movieFiles = list;
    }

    if (await seriesDir.exists()) {
      final list = seriesDir.listSync(recursive: true).where((f) {
        return f.path.toLowerCase().endsWith(".mp4");
      }).toList();
      seriesFiles = list;
    }

    setState(() {});
  }

  void _playOfflineVideo(File file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OfflinePlayerPage(file: file),
      ),
    );
  }

  Future<void> _deleteFile(File file) async {
    try {
      await file.delete();
      _loadDownloads();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Deleted")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting: $e")),
      );
    }
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDownloadTile(FileSystemEntity file, {required bool isSeries}) {
    final f = File(file.path);
    final fileName = p.basename(file.path);
    final folder = p.basename(p.dirname(file.path));
    final sizeMB = (f.lengthSync() / (1024 * 1024)).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Text(
          fileName.replaceAll(".mp4", ""),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          isSeries ? "Series • $folder • $sizeMB MB" : "Movie • $sizeMB MB",
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.redAccent),
          onPressed: () => _deleteFile(f),
        ),
        onTap: () => _playOfflineVideo(f),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Downloads", style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDownloads,
        color: Colors.greenAccent,
        child: ListView(
          children: [
            // Movies Section
            if (movieFiles.isNotEmpty) _buildSectionTitle("Movies"),
            for (var f in movieFiles) _buildDownloadTile(f, isSeries: false),

            // Series Section
            if (seriesFiles.isNotEmpty) _buildSectionTitle("Series"),
            for (var f in seriesFiles) _buildDownloadTile(f, isSeries: true),

            if (movieFiles.isEmpty && seriesFiles.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 100),
                  child: Text(
                    "No downloads yet",
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}

// ---------------------------
// OFFLINE VIDEO PLAYER
// ---------------------------
class OfflinePlayerPage extends StatefulWidget {
  final File file;
  const OfflinePlayerPage({Key? key, required this.file}) : super(key: key);

  @override
  State<OfflinePlayerPage> createState() => _OfflinePlayerPageState();
}

class _OfflinePlayerPageState extends State<OfflinePlayerPage> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
