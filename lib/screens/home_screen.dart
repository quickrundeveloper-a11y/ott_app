import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../movie_details.dart';
import '../series_details.dart';
import '../search_page.dart';
import '../screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  static const String route = '/home';

  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  final List<Widget> pages = [
    const HomeScreenBody(),
    // Placeholder for Downloads page
    const Center(
        child: Text("Downloads Page", style: TextStyle(color: Colors.white))),
    const MovieSearchScreen(),
    // Placeholder for Library page. MovieDetailPage requires a videoId,
    // so it cannot be instantiated here directly. You would navigate to it
    // from a list on a dedicated Library screen.
    const Center(
        child: Text("Library Page", style: TextStyle(color: Colors.white))),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    const lime = Color(0xFFB6FF3B);

    return Scaffold(
      backgroundColor: Colors.black,
      body: pages[selectedIndex],
      bottomNavigationBar: Container(
        color: const Color(0xFF1A1A1A),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            navItem(Icons.home, "Home", 0, lime),
            navItem(Icons.download, "Downloads", 1, lime),
            navItem(Icons.search, "Search", 2, lime),
            navItem(Icons.folder_open, "Library", 3, lime),
            navItem(Icons.person, "Profile", 4, lime),
          ],
        ),
      ),
    );
  }

  Widget navItem(IconData icon, String label, int index, Color lime) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isSelected ? lime : Colors.transparent,
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              color: isSelected ? Colors.black : Colors.grey,
              size: 24,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? lime : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------- Home Screen Body -------------------

class HomeScreenBody extends StatelessWidget {
  const HomeScreenBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const lime = Color(0xFFB6FF3B);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured Movie
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Image.asset("assets/img/topgun.jpg",
                      width: double.infinity, height: 200, fit: BoxFit.cover),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("Top Gun",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        Text("⭐ 8.4 | Thriller | 2022",
                            style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                  const Positioned(
                    bottom: 10,
                    right: 10,
                    child: CircleAvatar(
                      backgroundColor: Color(0xFFB6FF3B),
                      child: Icon(Icons.play_arrow, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 🔥 Trending Now (Dynamic from Firebase)
            sectionHeader("Trending Now", lime),
            const SizedBox(height: 10),
            buildMovieList(context),

            const SizedBox(height: 20),

            // 🔥 Latest Shows (Dynamic from Firebase)
            sectionHeader("Latest Shows", lime),
            const SizedBox(height: 10),
            filterChips(["All", "Movies", "Drama", "Thriller", "Romance"], lime),
            const SizedBox(height: 10),
            buildMovieList(context),
          ],
        ),
      ),
    );
  }

  Widget buildMovieList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('videos').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text("No videos found",
              style: TextStyle(color: Colors.white70));
        }

        final videos = snapshot.data!.docs;

        return SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: videos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final doc = videos[index];
              final video = doc.data() as Map<String, dynamic>;
              final coverURL = video['coverURL'] ?? video['videoURL'] ?? '';
              final title = video['title'] ?? 'Untitled';
              final type = (video['type'] ?? '').toString().toLowerCase();

              return GestureDetector(
                onTap: () {
                  final id = doc.id;
                  if (type == 'web series' || type == 'series') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SeriesDetails(videoId: id),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MovieDetailPage(videoId: id),
                      ),
                    );
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        coverURL,
                        width: 100,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 100,
                          height: 120,
                          color: Colors.grey.shade800,
                          child: const Icon(Icons.broken_image,
                              color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(title,
                        style:
                        const TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget sectionHeader(String title, Color lime) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: TextStyle(
                color: lime, fontWeight: FontWeight.bold, fontSize: 16)),
        const Text("Show all", style: TextStyle(color: Colors.white70)),
      ],
    );
  }

  Widget filterChips(List<String> labels, Color lime) {
    return SizedBox(
      height: 35,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final isSelected = index == 0;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? lime : const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(labels[index],
                style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontSize: 14)),
          );
        },
      ),
    );
  }
}
