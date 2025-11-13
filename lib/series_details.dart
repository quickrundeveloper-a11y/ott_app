import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SeriesDetails extends StatefulWidget {
  final String? videoId;
  const SeriesDetails({Key? key, this.videoId}) : super(key: key);

  @override
  _SeriesDetailsState createState() => _SeriesDetailsState();
}

class _SeriesDetailsState extends State<SeriesDetails>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool showFullDescription = false;

  late Future<Map<String, dynamic>> _dataFuture;

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

    // Fetch episodes
    final epSnap = await videoDocRef
        .collection('episodes')
        .orderBy('episodeNumber')
        .get();

    final episodes = epSnap.docs.map((e) {
      final d = e.data();
      return {
        'title': d['title'] ?? '',
        'description': d['description'] ?? '',
        'episodeNumber': d['episodeNumber']?.toString() ?? '',
        'runtimeSeconds': d['runtimeSeconds']?.toString() ?? '',
        'coverURL': d['coverURL'] ?? '',
      };
    }).toList();

    // Release Year
    String releaseYear = '';
    if (videoData['releaseYear'] != null) {
      releaseYear = videoData['releaseYear'].toString();
    } else if (videoData['createdAt'] is Timestamp) {
      releaseYear = (videoData['createdAt'] as Timestamp).toDate().year.toString();
    }

    return {
      'video': videoData,
      'episodes': episodes,
      'releaseYear': releaseYear,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
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
        final episodes = data['episodes'];
        final releaseYear = data['releaseYear'];

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: DefaultTabController(
              length: 4,
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: _buildTopCard(video['coverURL'] ?? ''),
                    ),
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
                          unselectedLabelColor: Colors.grey[500],
                          tabs: const [
                            Tab(text: "Episodes"),
                            Tab(text: "Collection"),
                            Tab(text: "More Like This"),
                            Tab(text: "Trailers & More"),
                          ],
                        ),
                      ),
                    )
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEpisodes(episodes),
                    const Center(child: Text("Collection", style: TextStyle(color: Colors.white70))),
                    const Center(child: Text("More Like This", style: TextStyle(color: Colors.white70))),
                    const Center(child: Text("Trailers & More", style: TextStyle(color: Colors.white70))),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // -------------------------------
  // HERO IMAGE (with coverURL)
  // -------------------------------
  Widget _buildTopCard(String coverURL) {
    return Column(
      children: [
        Stack(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: coverURL.isNotEmpty
                  ? Image.network(coverURL, fit: BoxFit.cover)
                  : Image.asset("assets/hero.jpg", fit: BoxFit.cover),
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
        ),
      ],
    );
  }

  // -------------------------------
  // TITLE + YEAR + PLAY BUTTONS
  // -------------------------------
  Widget _buildTitleSection(String title, String year, String description) {
    final videoData =
    (_dataFuture as Future<Map<String, dynamic>>)
    as dynamic; // Not used directly; just for context.

    return FutureBuilder(
      future: _dataFuture,
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();

        final video = snap.data!['video'];
        final summary = video['summary'] ?? '';
        final fullDescription = video['description'] ?? '';
        final cast = video['cast'] ?? '';
        final director = video['director'] ?? '';
        final producer = video['producer'] ?? '';
        final writer = video['writer'] ?? '';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: StatefulBuilder(
            builder: (context, setInner) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      _badge(year),
                      const SizedBox(width: 8),
                      _pill("HD"),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ------------------------------------------
                  // SUMMARY (default visible)
                  // ------------------------------------------
                  GestureDetector(
                    onTap: () => setInner(() {}),
                    child: Text(
                      summary,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.4,
                        fontSize: 15,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Tap to Expand
                  GestureDetector(
                    onTap: () => setInner(() {
                      showFullDescription = !showFullDescription;
                    }),
                    child: Text(
                      showFullDescription ? "Hide Details" : "Show Details",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // ------------------------------------------
                  // EXPANDED AREA (DESCRIPTION + DETAILS)
                  // ------------------------------------------
                  if (showFullDescription) ...[
                    const SizedBox(height: 12),

                    // Description
                    Text(
                      fullDescription,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.4,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // CAST
                    if (cast.isNotEmpty) ...[
                      Text(
                        "Cast:",
                        style: TextStyle(
                          color: Colors.grey[200],
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cast,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // DIRECTOR
                    if (director.isNotEmpty) ...[
                      Text(
                        "Director:",
                        style: TextStyle(
                          color: Colors.grey[200],
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        director,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // PRODUCER
                    if (producer.isNotEmpty) ...[
                      Text(
                        "Producer:",
                        style: TextStyle(
                          color: Colors.grey[200],
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        producer,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // WRITER
                    if (writer.isNotEmpty) ...[
                      Text(
                        "Writer:",
                        style: TextStyle(
                          color: Colors.grey[200],
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        writer,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }


  Widget _badge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
        color: Colors.grey[900], borderRadius: BorderRadius.circular(3)),
    child: Text(text, style: const TextStyle(color: Colors.white70)),
  );

  Widget _pill(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
        color: Colors.grey[850], borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: const TextStyle(color: Colors.white70)),
  );

  // -------------------------------
  // EPISODES LIST
  // -------------------------------
  Widget _buildEpisodes(List episodes) {
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: episodes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 18),
      itemBuilder: (context, i) {
        final ep = episodes[i];
        return _EpisodeRow(
          thumb: ep['coverURL'] ?? '',
          title: ep['title'] ?? '',
          duration: _formatDuration(ep['runtimeSeconds']),
          description: ep['description'] ?? '',
        );
      },
    );
  }

  String _formatDuration(dynamic seconds) {
    try {
      int s = int.parse(seconds.toString());
      return "${s ~/ 60} mins";
    } catch (_) {
      return "—";
    }
  }
}

// -------------------------------------------------------
// EPISODE ROW (no download button)
// -------------------------------------------------------
class _EpisodeRow extends StatefulWidget {
  final String thumb;
  final String title;
  final String duration;
  final String description;

  const _EpisodeRow({
    Key? key,
    required this.thumb,
    required this.title,
    required this.duration,
    required this.description,
  }) : super(key: key);

  @override
  State<_EpisodeRow> createState() => _EpisodeRowState();
}

class _EpisodeRowState extends State<_EpisodeRow> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          expanded = !expanded;
        });
      },
      behavior: HitTestBehavior.opaque,

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -------------------------------------
          // Thumbnail + Green Play Icon
          // -------------------------------------
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 110,
                  height: 64,
                  color: Colors.grey[900],
                  child: widget.thumb.isNotEmpty
                      ? Image.network(widget.thumb, fit: BoxFit.cover)
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
                    child: const Icon(
                      Icons.play_arrow,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 10),

          // -------------------------------------
          // Right Text Area (tight Netflix layout)
          // -------------------------------------
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // -------------------------------------
                  // TITLE + DOWNLOAD ICON (same line)
                  // -------------------------------------
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // Download icon (compact Netflix style)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        onPressed: () {},
                        icon: const Icon(
                          Icons.download_outlined,
                          size: 20,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),

                  // -------------------------------------
                  // RUNTIME — No spacing above or below
                  // -------------------------------------
                  Transform.translate(
                    offset: const Offset(0, -2), // pulls runtime closer to title
                    child: Text(
                      widget.duration,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        height: 1.0,
                      ),
                    ),
                  ),

                  // -------------------------------------
                  // DESCRIPTION (expands inline)
                  // -------------------------------------
                  AnimatedCrossFade(
                    firstChild: Text(
                      widget.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.1,
                      ),
                    ),
                    secondChild: Text(
                      widget.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                    crossFadeState: expanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 160),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}







// -------------------------------------------------------
// TabBar Header
// -------------------------------------------------------
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _SliverAppBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(context, shrinkOffset, overlapsContent) {
    return Container(color: Colors.black, child: tabBar);
  }

  @override
  bool shouldRebuild(oldDelegate) => false;
}
