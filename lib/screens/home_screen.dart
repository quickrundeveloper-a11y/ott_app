import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../movie_details.dart';
import '../theme/theme.dart';
import '../series_details.dart';
import '../screens/profile_screen.dart';
import '../screens/download_screen.dart';

class HomeScreen extends StatefulWidget {
  static const String route = '/home';

  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;
  String searchQuery = "";

  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    const greenAccent = AppTheme.greenAccent;

    final List<Widget> pages = [
      HomeScreenBody(), // now stateful
      const DownloadsPage(),
      SearchResultsPage(query: searchQuery),
      const ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            if (selectedIndex == 2) buildSearchBar(),
            Expanded(child: pages[selectedIndex]),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        color: AppTheme.cardDarker,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            navItem(Icons.home, "Home", 0, greenAccent),
            navItem(Icons.download, "Downloads", 1, greenAccent),
            navItem(Icons.search, "Search", 2, greenAccent),
            navItem(Icons.person, "Profile", 3, greenAccent),
          ],
        ),
      ),
    );
  }

  // 🔍 FIXED SEARCH BAR (no green outline + full width)
  Widget buildSearchBar() {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.borderColor,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.white70, size: 22),
              const SizedBox(width: 10),

              Expanded(
                child: TextFormField(
                  controller: searchController,
                  cursorColor: Colors.white,
                  style: Theme.of(context)
                      .textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textWhite,
                        fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily, // Use theme font
                      ),
                  decoration: AppTheme.inputDecoration(
                    hint: "Search movies or series...",
                  ),
                  onChanged: (value) {
                    setState(() => searchQuery = value.trim());
                  },
                ),
              ),

              if (searchQuery.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    searchController.clear();
                    setState(() => searchQuery = "");
                  },
                  child: const Icon(Icons.close, color: AppTheme.textLight, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget navItem(IconData icon, String label, int index, Color greenAccent) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isSelected ? greenAccent : Colors.transparent,
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              color: isSelected ? AppTheme.background : AppTheme.textGrey,
              size: 24,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isSelected ? greenAccent : AppTheme.textGrey,
              fontSize: 12,
              fontFamily: Theme.of(context).textTheme.bodySmall?.fontFamily, // Use theme font
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SEARCH RESULTS PAGE — WRAP GRID + LEFT ALIGNED + WORKING SEARCH
// -----------------------------------------------------------------------------

class SearchResultsPage extends StatelessWidget {
  final String query;

  const SearchResultsPage({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text(
          "Search for movies or series...",
          style: TextStyle(color: AppTheme.textLight, fontFamily: "Poppins"), // Use theme font
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("videos").snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final docs = snapshot.data!.docs;

        // Case-insensitive local filter (Option A)
        final results = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final title = (data["title"] ?? "").toString().toLowerCase();
          return title.contains(query.toLowerCase());
        }).toList();

        if (results.isEmpty) {
          return Center(
            child: Text("No results found",
                style: TextStyle(color: AppTheme.textLight, fontFamily: "Poppins")), // Use theme font
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // LEFT ALIGN
            children: [
              Text(
                "Search Results",
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                  color: AppTheme.greenAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: Theme.of(context).textTheme.headlineSmall?.fontFamily, // Use theme font
                ),
              ),
              const SizedBox(height: 10),

              Wrap(
                spacing: 12,
                runSpacing: 14,
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.start,
                children: results.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final id = doc.id;

                  final img = data["coverURL"] ?? "";
                  final title = data["title"] ?? "";
                  final type = (data["type"] ?? "").toString().toLowerCase();

                  return GestureDetector(
                    onTap: () {
                      if (type.contains("series")) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => SeriesDetails(videoId: id)),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => MovieDetailPage(videoId: id)),
                        );
                      }
                    },
                    child: SizedBox(
                      width: 100,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              img,
                              width: 100,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 100,
                                height: 120,
                                color: AppTheme.cardDark,
                                child: const Icon(Icons.broken_image,
                                    color: AppTheme.textWhite),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textLight,
                                fontFamily:
                                    Theme.of(context).textTheme.bodySmall?.fontFamily, // Use theme font
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// HOME SCREEN BODY (NOW STATEFUL) — includes filters & latest banner
// -----------------------------------------------------------------------------

class HomeScreenBody extends StatefulWidget {
  const HomeScreenBody({Key? key}) : super(key: key);

  @override
  State<HomeScreenBody> createState() => _HomeScreenBodyState();
}

class _HomeScreenBodyState extends State<HomeScreenBody> {
  String selectedFilter = "All";

  final List<String> filterLabels = [
    "All",
    "Movie",
    "Drama",
    "Thriller",
    "Romance"
  ];

  @override
  Widget build(BuildContext context) {
    const greenAccent = AppTheme.greenAccent;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FEATURED: Most recently added item
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('videos')
                  .orderBy('createdAt', descending: true)
                  .limit(1)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  // fallback placeholder
                  return Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppTheme.cardDarker,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  );
                }

                final data =
                snapshot.data!.docs.first.data() as Map<String, dynamic>;

                final title = data['title'] ?? '';
                final coverURL = data['coverURL'] ?? '';
                final genre = data['genre'] ?? '';
                final releaseYear = data['releaseYear'] ?? '';

                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      coverURL.toString().isNotEmpty
                          ? Image.network(
                        coverURL,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: double.infinity,
                          height: 200,
                          color: AppTheme.cardDarker,
                        ),
                      )
                          : Container(
                        width: double.infinity,
                        height: 200, // keep the same height for consistency
                        color: Colors.grey.shade900,
                      ),
                      Positioned(
                        bottom: 10,
                        left: 10,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                    color: Colors.white,
                                    fontSize: 18, // Use theme font
                                    fontWeight: FontWeight.bold,
                                    fontFamily: Theme.of(context).textTheme.headlineMedium?.fontFamily)),
                            Text("⭐ • $genre • $releaseYear",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppTheme.textLight,
                                    fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily)), // Use theme font
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: CircleAvatar(
                          backgroundColor: AppTheme.greenAccent,
                          child: Icon(Icons.play_arrow, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // 🔥 Trending Now
            sectionHeader("Trending Now", greenAccent),
            const SizedBox(height: 10),
            buildMovieList(),

            const SizedBox(height: 20),

            // 🔥 Latest Shows (with filter chips)
            sectionHeader("Latest Shows", greenAccent),
            const SizedBox(height: 10),
            filterChips(filterLabels, greenAccent),
            const SizedBox(height: 10),
            buildMovieList(),
          ],
        ),
      ),
    );
  }

  // Build horizontal movie list (applies selectedFilter)
  Widget buildMovieList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('videos').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        List<QueryDocumentSnapshot> videos = snapshot.data!.docs;

        // Apply category filter (Option A: contains)
        if (selectedFilter != "All") {
          final filt = selectedFilter.toLowerCase();
          videos = videos.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final type = (data['type'] ?? "").toString().toLowerCase();
            final genre = (data['genre'] ?? "").toString().toLowerCase();
            return type.contains(filt) || genre.contains(filt);
          }).toList();
        }

        if (videos.isEmpty) {
          return Text("No videos found for this category",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textLight,
                  fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily, // Use theme font
              ));
        }

        return SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: videos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final doc = videos[index];
              final data = doc.data() as Map<String, dynamic>;

              final coverURL = data['coverURL'] ?? data['videoURL'] ?? '';
              final title = data['title'] ?? 'Untitled';
              final type = (data['type'] ?? '').toString().toLowerCase();
              final id = doc.id;

              return GestureDetector(
                onTap: () {
                  if (type.contains("series")) {
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
                      child: coverURL.toString().isNotEmpty
                          ? Image.network(
                        coverURL,
                        width: 100,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 100,
                          height: 120,
                          color: AppTheme.cardDark,
                          child: const Icon(Icons.broken_image,
                              color: AppTheme.textWhite),
                        ),
                      )
                          : Container(
                        width: 100,
                        height: 120,
                        color: AppTheme.cardDark,
                        child: const Icon(Icons.broken_image,
                            color: AppTheme.textWhite),
                      ),
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      width: 100,
                      child: Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall?.copyWith(color: AppTheme.textLight,
                            fontFamily: Theme.of(context).textTheme.bodySmall?.fontFamily, // Use theme font
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget sectionHeader(String title, Color greenAccent) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16, // Use theme font
                  fontFamily: Theme.of(context).textTheme.titleLarge?.fontFamily,
                )),
        Text("Show all",
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.textLight, fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily)), // Use theme font
      ],
    );
  }

  Widget filterChips(List<String> labels, Color greenAccent) {
    return SizedBox(
      height: 35,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final label = labels[index];
          final isSelected = selectedFilter == label;
          return GestureDetector(
            onTap: () => setState(() => selectedFilter = label),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? greenAccent : AppTheme.cardDark,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(
                  color: isSelected ? AppTheme.background : AppTheme.textLight,
                  fontSize: 14, // Use theme font
                  fontFamily: Theme.of(context).textTheme.labelLarge?.fontFamily,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
