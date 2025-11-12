import 'package:flutter/material.dart';

// NOTE: This file intentionally does NOT include void main().
// Class requested by user: seriesdetails
// Add the images used here to your pubspec.yaml under assets and provide the correct paths.

class seriesdetails extends StatefulWidget {
  final String? videoId;
  const seriesdetails({Key? key,this.videoId}) : super(key: key);

  @override
  _seriesdetailsState createState() => _seriesdetailsState();
}

class _seriesdetailsState extends State<seriesdetails>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late final List<Map<String, String>> episodes;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    episodes = List.generate(8, (index) {
    final titles = [
      'Chapter One: The Vanishing of Will Byers',
      'Chapter Two: The Weirdo on Maple Street',
      'Chapter Three: Holly, Jolly',
      'Chapter Four: The Body',
      'Chapter Five: The Flea and the Acrobat',
      'Chapter Six: The Monster',
      'Chapter Seven: The Bathtub',
      'Chapter Eight: The Upside Down',
    ];
    final descriptions = [
      'On his way home from a friend\'s house, young Will sees something terrifying. Nearby, a sinister secret lurks in the depths of a government lab.',
      'Mike hides the mysterious girl in his house. Joyce gets a strange phone call.',
      'An increasingly concerned Nancy looks for Barb and finds out what Jonathan\'s been up to. Joyce is convinced Will is trying to talk to her.',
      'Refusing to believe Will is dead, Joyce tries to connect with her son. The boys give Eleven a makeover. Jonathan and Nancy form an unlikely alliance.',
      'Hopper breaks into the lab to find the truth about Will\'s death. The boys try to locate the \"gate\" that will take them to Will.',
      'Hopper and Joyce find the truth about the lab\'s experiments. After their fight, the boys look for the missing Eleven.',
      'The government comes searching for Eleven. Eleven looks for Will and Barb in the Upside Down.',
      'Joyce and Hopper are taken in for questioning. Nancy and Jonathan prepare to fight the monster and save Will.'
    ];

    return {
      'title': titles[index],
      'duration': '49 mins'.trim(),
      'description': descriptions[index],
      'thumb': 'assets/thumb_${(index % 4) + 1}.jpg', // placeholder
    };
  });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: DefaultTabController(
          length: 4,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(child: _buildTopCard(context)),
                SliverToBoxAdapter(child: _buildTitleSection(context)),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      indicatorColor: Colors.greenAccent,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey[400],
                      tabs: const [
                        Tab(text: 'Episodes'),
                        Tab(text: 'Collection'),
                        Tab(text: 'More Like This'),
                        Tab(text: 'Trailers & More'),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildEpisodesTab(),
                _buildCollectionTab(),
                _buildMoreLikeThisTab(),
                _buildTrailersTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            // Big hero image
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/hero.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            // top-left close button
            Positioned(
              top: 12,
              left: 12,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
            // cast icon top-right
            Positioned(
              top: 12,
              right: 12,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.cast, color: Colors.white),
                  onPressed: () {},
                ),
              ),
            ),
            // center play button overlay
            Positioned.fill(
              child: Center(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.greenAccent, width: 3),
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
                ),
              ),
            ),
            // Preview text bottom-left in the image
            Positioned(
              left: 16,
              bottom: 12,
              child: const Text('Preview',
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTitleSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Stranger Things ${widget.videoId ?? ''}",
            style: const TextStyle(
                color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _badge('2025'),
              const SizedBox(width: 8),
              _pill('U/A'),
              const SizedBox(width: 8),
              _pill('4 Seasons'),
              const SizedBox(width: 8),
              _pill('HD'),
            ],
          ),
          const SizedBox(height: 12),
          // Play and download buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.play_arrow),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text('Play', style: TextStyle(fontSize: 16)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download_outlined),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text('Download S1:E1', style: TextStyle(fontSize: 14)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[800]!),
                    backgroundColor: Colors.grey[900],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'S1:E1 Chapter One: The Vanishing of Will Byers',
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'On his way home from a friend\'s house, young Will sees something terrifying. Nearby, a sinister secret lurks in the depths of a government lab.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              Icon(Icons.check, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('My List', style: TextStyle(color: Colors.white70)),
              SizedBox(width: 24),
              Icon(Icons.thumb_up_outlined, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Rate', style: TextStyle(color: Colors.white70)),
              SizedBox(width: 24),
              Icon(Icons.share, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Share', style: TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildEpisodesTab() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      itemCount: episodes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final ep = episodes[index];
        return _EpisodeRow(
          thumb: ep['thumb']!,
          title: ep['title']!,
          duration: ep['duration']!,
          description: ep['description']!,
        );
      },
    );
  }

  Widget _buildCollectionTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text('Collection tab (placeholder)', style: TextStyle(color: Colors.white70)),
      ),
    );
  }

  Widget _buildMoreLikeThisTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text('More like this (placeholder)', style: TextStyle(color: Colors.white70)),
      ),
    );
  }

  Widget _buildTrailersTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text('Trailers & more (placeholder)', style: TextStyle(color: Colors.white70)),
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white70)),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white70)),
    );
  }
}

class _EpisodeRow extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 110,
                height: 64,
                color: Colors.grey[900],
                child: Image.asset(
                  thumb,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, _, __) => Container(
                    color: Colors.grey[800],
                    child: const Center(child: Icon(Icons.image, color: Colors.white30)),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black54,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  Column(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.download_outlined, color: Colors.white70),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 6),
              Text(duration, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 6),
              Text(
                description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        )
      ],
    );
  }
}

// A small helper used to create a pinned TabBar inside NestedScrollView
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.black,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
