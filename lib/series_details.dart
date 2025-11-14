// series_details.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'full_screen_player.dart';

class SeriesDetails extends StatefulWidget {
  final String? videoId;
  const SeriesDetails({Key? key, this.videoId}) : super(key: key);

  @override
  _SeriesDetailsState createState() => _SeriesDetailsState();
}

class _SeriesDetailsState extends State<SeriesDetails>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<Map<String, dynamic>> _dataFuture;

  // Map to hold per-episode download state
  final Map<String, EpisodeDownloadState> _downloads = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _dataFuture = _fetchVideoAndEpisodes();
  }

  Future<Map<String, dynamic>> _fetchVideoAndEpisodes() async {
    final videoDocRef =
    FirebaseFirestore.instance.collection('videos').doc(widget.videoId);

    final docSnap = await videoDocRef.get();
    if (!docSnap.exists) throw Exception("Video not found");

    final videoData = docSnap.data() ?? {};

    final epSnap = await videoDocRef
        .collection('episodes')
        .orderBy('episodeNumber')
        .get();

    final episodes = epSnap.docs.map((e) {
      final d = e.data();
      return {
        'id': e.id,
        'title': d['title'] ?? '',
        'description': d['description'] ?? '',
        'videoURL': d['videoURL'] ?? '',
        'episodeNumber': d['episodeNumber']?.toString() ?? '',
        'runtimeSeconds': d['runtimeSeconds']?.toString() ?? '',
        'coverURL': d['coverURL'] ?? '',
      };
    }).toList();

    String releaseYear = '';
    if (videoData['releaseYear'] != null) {
      releaseYear = videoData['releaseYear'].toString();
    } else if (videoData['createdAt'] is Timestamp) {
      releaseYear =
          (videoData['createdAt'] as Timestamp).toDate().year.toString();
    }

    return {
      'video': videoData,
      'episodes': episodes,
      'releaseYear': releaseYear,
    };
  }

  // ---------- Files & Permissions ----------
  Future<bool> _ensureStoragePermission() async {
    if (Platform.isAndroid) {
      // For Android 11+ we may need manageExternalStorage
      final ManageExternalStorageStatus = await Permission.manageExternalStorage.status;
      if (ManageExternalStorageStatus.isDenied) {
        await Permission.manageExternalStorage.request();
      }
      final storageStatus = await Permission.storage.status;
      if (storageStatus.isDenied) {
        await Permission.storage.request();
      }
      // Return true if any granted
      final finalStorage = await Permission.storage.isGranted;
      final finalManage = await Permission.manageExternalStorage.isGranted;
      return finalStorage || finalManage;
    }
    // iOS will use application documents - no extra permission
    return true;
  }

  Future<Directory> _getSeriesRootDir() async {
    if (Platform.isAndroid) {
      // Primary external storage
      final root = Directory('/storage/emulated/0/Series');
      if (!await root.exists()) {
        try {
          await root.create(recursive: true);
          return root;
        } catch (_) {
          // fallback to external storage dir provided by path_provider
          final alt = await getExternalStorageDirectory();
          final altDir = Directory('${alt!.path}/Series');
          if (!await altDir.exists()) await altDir.create(recursive: true);
          return altDir;
        }
      }
      return root;
    } else {
      final appDoc = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDoc.path}/Series');
      if (!await dir.exists()) await dir.create(recursive: true);
      return dir;
    }
  }

  // ---------- Download logic ----------
  Future<void> _startOrResumeEpisodeDownload({
    required String episodeId,
    required String url,
    required String seriesTitle,
    required String episodeNumber,
    required String episodeTitle,
  }) async {
    // initialize state if not present
    _downloads.putIfAbsent(episodeId, () => EpisodeDownloadState());

    final state = _downloads[episodeId]!;

    if (state.isDownloading) return; // already downloading

    // ensure permission
    final ok = await _ensureStoragePermission();
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Storage permission is required to download.")),
      );
      return;
    }

    final root = await _getSeriesRootDir();
    final safeSeries = seriesTitle.isNotEmpty ? seriesTitle : 'Series';
    final seriesDir = Directory('${root.path}/$safeSeries');
    if (!await seriesDir.exists()) await seriesDir.create(recursive: true);

    final safeEpTitle = episodeTitle.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final safeFileName = '${episodeNumber.isNotEmpty ? "$episodeNumber - " : ""}$safeEpTitle.mp4';
    final filePath = '${seriesDir.path}/$safeFileName';

    state.savePath = filePath;
    state.cancelToken = CancelToken();

    final file = File(filePath);

    int existing = 0;
    if (await file.exists()) {
      existing = await file.length();
    }

    final dio = Dio();
    Options options;

    if (existing > 0) {
      // Resume
      state.isPaused = false;
      state.isDownloading = true;
      options = Options(
        headers: {
          'range': 'bytes=$existing-',
        },
      );
    } else {
      // Fresh download
      state.isPaused = false;
      state.isDownloading = true;
      options = Options();
    }

    // Update UI
    setState(() {});

    try {
      // Use download with onReceiveProgress.
      // If resuming, we open file in append mode.
      final tempFile = file;
      IOSink? sink;
      if (existing > 0) {
        sink = tempFile.openWrite(mode: FileMode.append);
      } else {
        sink = tempFile.openWrite(mode: FileMode.write);
      }

      // We will not pass savePath to dio.download directly for resumable append handling,
      // instead perform a request and write stream ourselves to better manage progress/resume.
      final response = await dio.get<ResponseBody>(
        url,
        options: Options(
          responseType: ResponseType.stream,
          headers: options.headers,
        ),
        cancelToken: state.cancelToken,
      );

      // total bytes: try to derive
      int? contentLength;
      // Check content-length header
      final headers = response.headers.map;
      if (headers.containsKey('content-length')) {
        contentLength = int.tryParse(headers['content-length']!.first);
      } else if (headers.containsKey('Content-Length')) {
        contentLength = int.tryParse(headers['Content-Length']!.first);
      }

      // If server returns 'content-range' with total, parse it
      if (headers.containsKey('content-range')) {
        // format example: bytes 100-999/1000
        final cr = headers['content-range']!.first;
        final parts = cr.split('/');
        if (parts.length == 2) {
          final total = int.tryParse(parts[1]);
          if (total != null) {
            contentLength = (contentLength ?? 0) + (existing > 0 ? existing : 0);
            // Be careful: contentLength from headers here might represent remaining bytes.
            // We'll handle progress calculation below with existing + received.
          }
        }
      }

      // totalBytesExpected = existing + contentLength (if contentLength is remaining)
      int? totalExpected;
      if (contentLength != null) {
        // If we sent a Range header, server might send only remaining bytes in content-length.
        // Assume contentLength is the remaining portion when resuming.
        totalExpected = existing + contentLength;
      }
      state.expectedTotalBytes = totalExpected;


      // Stream and write
      int received = 0;
      final stream = response.data!.stream;
      await for (final chunk in stream) {
        // If cancellation occurred via token it will throw and be caught below.
        if (chunk == null) break;
        sink.add(chunk);
        received += chunk.length;
        // compute progress
        if (totalExpected != null && totalExpected > 0) {
          state.progress = (existing + received) / totalExpected;
        } else {
          // fallback: cannot compute total; use -1 or approximate with 0 -> show indeterminate
          state.progress = -1.0;
        }
        // update UI
        setState(() {});
        // If paused was requested (we cancelled to pause), we break here
        if (state.cancelToken.isCancelled) break;
      }

      await sink.flush();
      await sink.close();

      // If cancelled by token, we need to distinguish between pause vs cancel.
      if (state.cancelToken.isCancelled) {
        // If user explicitly paused, mark paused; otherwise, if cancelled and not paused, mark not downloading.
        if (state.isPaused) {
          // paused: leave partial file intact
          state.isDownloading = false;
        } else {
          // cancelled: user requested cancel -> delete partial file
          state.isDownloading = false;
          state.progress = 0.0;
          try {
            if (await file.exists()) await file.delete();
          } catch (_) {}
        }
        setState(() {});
        return;
      }

      // On successful finish, verify file size vs expected if possible
      final finalSize = await file.length();
      if (totalExpected != null && finalSize >= totalExpected) {
        state.isCompleted = true;
        state.progress = 1.0;
        state.isDownloading = false;
        state.isPaused = false;
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloaded: ${file.path}')),
        );
      } else {
        // server didn't provide totalExpected; mark complete anyway
        state.isCompleted = true;
        state.progress = 1.0;
        state.isDownloading = false;
        state.isPaused = false;
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloaded: ${file.path}')),
        );
      }
    } catch (e) {
      // If cancellation via token happens, Dio throws a cancellation exception.
      if (e is DioException && e.type == DioExceptionType.cancel) {
        // This branch already handled above by checking token, but keep defensive.
        if (state.isPaused) {
          state.isDownloading = false;
        } else {
          state.isDownloading = false;
          state.progress = 0.0;
        }
      } else {
        state.isDownloading = false;
        state.progress = 0.0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
      setState(() {});
    }
  }

  void _pauseEpisodeDownload(String episodeId) {
    final state = _downloads[episodeId];
    if (state == null) return;
    if (!state.isDownloading) return;
    state.isPaused = true;
    state.isDownloading = false;
    // Cancel current request (will keep partial file)
    try {
      state.cancelToken.cancel('paused');
    } catch (_) {}
    // Keep cancelToken cancelled; on resume we'll create a new one
    setState(() {});
  }

  void _cancelEpisodeDownload(String episodeId) async {
    final state = _downloads[episodeId];
    if (state == null) return;
    try {
      state.isPaused = false;
      state.isDownloading = false;
      state.cancelToken.cancel('cancelled');
    } catch (_) {}
    // Delete partial file if exists
    if (state.savePath != null) {
      final f = File(state.savePath!);
      if (await f.exists()) {
        try {
          await f.delete();
        } catch (_) {}
      }
    }
    // reset state
    _downloads.remove(episodeId);
    setState(() {});
  }

  // ---------- UI helpers ----------
  String _formatDuration(dynamic seconds) {
    try {
      final s = int.parse(seconds.toString());
      final minutes = s ~/ 60;
      if (minutes >= 60) {
        final h = minutes ~/ 60;
        final m = minutes % 60;
        if (m > 0) return '${h}h ${m}m';
        return '${h}h';
      }
      return '${minutes} min';
    } catch (_) {
      return "—";
    }
  }

  void _openFullScreen(String videoUrl, String title, String videoId) {
    if (videoUrl.isEmpty) return;
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dataFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snap.hasError) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text(
                "Error: ${snap.error}",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        final data = snap.data!;
        final video = data['video'];
        final episodes = data['episodes'] as List<dynamic>;
        final releaseYear = data['releaseYear'] as String;
        final seriesTitle = (video['title'] ?? 'Series').toString();

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(child: _buildTopCard(video['coverURL'] ?? '')),
                  SliverToBoxAdapter(
                    child: _buildTitleSection(
                      video['title'] ?? '',
                      releaseYear,
                      video['description'] ?? '',
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        controller: _tabController,
                        indicatorColor: Colors.greenAccent,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.grey,
                        tabs: const [
                          Tab(text: "Episodes"),
                          Tab(text: "Collection"),
                          Tab(text: "More Like This"),
                          Tab(text: "Trailers & More"),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildEpisodesList(episodes, seriesTitle),
                  const Center(child: Text("Collection", style: TextStyle(color: Colors.white70))),
                  const Center(child: Text("More Like This", style: TextStyle(color: Colors.white70))),
                  const Center(child: Text("Trailers & More", style: TextStyle(color: Colors.white70))),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopCard(String coverURL) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: coverURL.isNotEmpty
              ? Image.network(coverURL, fit: BoxFit.cover)
              : Container(color: Colors.grey.shade900),
        ),
        Positioned(
          top: 10,
          left: 10,
          child: CircleAvatar(
            backgroundColor: Colors.black54,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleSection(String title, String year, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              _badge(year),
              const SizedBox(width: 8),
              _pill("HD"),
            ],
          )
        ],
      ),
    );
  }

  Widget _badge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(3)),
    child: Text(text, style: const TextStyle(color: Colors.white70)),
  );

  Widget _pill(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: Colors.grey[850], borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: const TextStyle(color: Colors.white70)),
  );

  Widget _buildEpisodesList(List episodes, String seriesTitle) {
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: episodes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 18),
      itemBuilder: (context, i) {
        final ep = episodes[i] as Map<String, dynamic>;
        final epId = ep['id'] ?? '';
        final videoUrl = ep['videoURL'] ?? '';
        final thumb = ep['coverURL'] ?? '';
        final title = ep['title'] ?? '';
        final duration = _formatDuration(ep['runtimeSeconds']);
        final description = ep['description'] ?? '';
        final episodeNumber = ep['episodeNumber'] ?? '';

        final state = _downloads.putIfAbsent(epId, () => EpisodeDownloadState());  // ------------------ CORRECT FILE-COMPLETION CHECK ------------------
        // ------------------ SAFE 100% COMPLETION CHECK ------------------
        try {
          final safeSeries = seriesTitle.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
          final safeTitle = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
          final safeFileName =
              '${episodeNumber.isNotEmpty ? "$episodeNumber - " : ""}$safeTitle.mp4';

          final filePath = '/storage/emulated/0/Series/$safeSeries/$safeFileName';
          final file = File(filePath);

          if (state.isCompleted) {
            state.progress = 1.0;
            state.isDownloading = false;
            state.isPaused = false;
            state.savePath ??= filePath;
          }
          else if (file.existsSync()) {
            final size = file.lengthSync();

            if (state.expectedTotalBytes != null) {
              // COMPLETE ONLY when size >= expected bytes
              if (size >= state.expectedTotalBytes!) {
                state.isCompleted = true;
                state.progress = 1.0;
                state.isDownloading = false;
                state.isPaused = false;
                state.savePath ??= filePath;
              } else {
                // file exists but not full
                state.isCompleted = false;
                if (state.expectedTotalBytes! > 0) {
                  state.progress = size / state.expectedTotalBytes!;
                }
              }
            }
          }
        } catch (_) {}



        // --- EPISODE UI ITEM ---
        // --- EPISODE UI ITEM ---
        return Column(
          children: [
            GestureDetector(
              onTap: () {
                if ((videoUrl ?? '').toString().isNotEmpty) {
                  _openFullScreen(videoUrl, title, epId);
                }
              },
              behavior: HitTestBehavior.opaque,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- THUMBNAIL ----
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          width: 110,
                          height: 64,
                          color: Colors.grey[900],
                          child: thumb.isNotEmpty
                              ? Image.network(thumb, fit: BoxFit.cover)
                              : Container(color: Colors.grey[800]),
                        ),
                      ),
                      Positioned.fill(
                        child: Center(
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.greenAccent, width: 2),
                              color: Colors.black38,
                            ),
                            child: const Icon(Icons.play_arrow, size: 16, color: Colors.white),
                          ),
                        ),
                      )
                    ],
                  ),

                  const SizedBox(width: 10),

                  // ---- TEXT CONTENT ----
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            // ---------- DOWNLOAD / CHECK ICON ----------
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),

                              icon: state.isCompleted
                                  ? const Icon(        // ✔ COMPLETED
                                Icons.check,
                                size: 22,
                                color: Color(0xFFB6FF3B),   // LIME GREEN
                              )
                                  : Icon(             // ⬇ DOWNLOAD
                                Icons.download_outlined,
                                size: 20,
                                color: Colors.white70,
                              ),

                              onPressed: state.isCompleted
                                  ? null  // disable when completed
                                  : () {
                                if ((videoUrl ?? '').toString().isNotEmpty) {
                                  if (state.isPaused) {
                                    state.cancelToken = CancelToken();
                                    _startOrResumeEpisodeDownload(
                                      episodeId: epId,
                                      url: videoUrl,
                                      seriesTitle: seriesTitle,
                                      episodeNumber: episodeNumber.toString(),
                                      episodeTitle: title,
                                    );
                                  } else if (!state.isDownloading) {
                                    _startOrResumeEpisodeDownload(
                                      episodeId: epId,
                                      url: videoUrl,
                                      seriesTitle: seriesTitle,
                                      episodeNumber: episodeNumber.toString(),
                                      episodeTitle: title,
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),

                        // ---- Duration ----
                        Transform.translate(
                          offset: const Offset(0, -2),
                          child: Text(
                            duration,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                              height: 1,
                            ),
                          ),
                        ),

                        // ---- Description ----
                        Text(
                          description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            height: 1.2,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ---------- DOWNLOAD PROGRESS + BUTTONS ----------
                        if ((state.isDownloading || state.isPaused) && !state.isCompleted)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  minHeight: 6,
                                  value: state.progress < 0 ? null : state.progress,
                                  backgroundColor: Colors.white10,
                                  valueColor: const AlwaysStoppedAnimation(Colors.greenAccent),
                                ),
                              ),

                              const SizedBox(height: 6),

                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      state.progress < 0
                                          ? (state.isPaused ? "Paused" : "Downloading...")
                                          : "${(state.progress * 100).toStringAsFixed(0)}%",
                                      style:
                                      const TextStyle(color: Colors.white60, fontSize: 12),
                                    ),
                                  ),

                                  // Pause Button
                                  if (state.isDownloading)
                                    IconButton(
                                      icon: const Icon(Icons.pause_circle_outline,
                                          color: Colors.white70),
                                      onPressed: () => _pauseEpisodeDownload(epId),
                                    ),

                                  // Resume Button
                                  if (state.isPaused)
                                    IconButton(
                                      icon: const Icon(Icons.play_circle_outline,
                                          color: Colors.white70),
                                      onPressed: () {
                                        state.cancelToken = CancelToken();
                                        _startOrResumeEpisodeDownload(
                                          episodeId: epId,
                                          url: videoUrl,
                                          seriesTitle: seriesTitle,
                                          episodeNumber: episodeNumber.toString(),
                                          episodeTitle: title,
                                        );
                                      },
                                    ),

                                  // Cancel Button
                                  IconButton(
                                    icon: const Icon(Icons.cancel_outlined,
                                        color: Colors.white70),
                                    onPressed: () => _cancelEpisodeDownload(epId),
                                  ),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        ;

      },
    );
  }
}

// Simple container for per-episode download state
class EpisodeDownloadState {
  bool isDownloading = false;
  bool isPaused = false;
  bool isCompleted = false;
  double progress = 0.0;
  CancelToken cancelToken = CancelToken();
  String? savePath;

  // ADD THIS FIELD ↓↓↓
  int? expectedTotalBytes;

  EpisodeDownloadState();
}


class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _SliverAppBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(context, shrinkOffset, overlaps) {
    return Container(color: Colors.black, child: tabBar);
  }

  @override
  bool shouldRebuild(oldDelegate) => false;
}
