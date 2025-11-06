import 'package:flutter/material.dart';
import 'package:ott_app/screens/profile_screen.dart';

import '../movie_details.dart';

// ✅ Import MovieDetailPage

class HomeScreen extends StatefulWidget {
  static const String route = '/home';

  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  final List<Widget> pages = [
    const MovieHomePage(),
    const Center(child: Icon(Icons.download, color: Colors.white)),
    const Center(child: Icon(Icons.search, color: Colors.white)),
    const MovieDetailPage(), // ✅ Show MovieDetailPage when "Library" icon is tapped
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
            navItem(Icons.folder_open, "Library", 3, lime), // ✅ opens MovieDetailPage
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

class MovieHomePage extends StatelessWidget {
  const MovieHomePage({Key? key}) : super(key: key);

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

            // Trending Now
            sectionHeader("Trending Now", lime),
            const SizedBox(height: 10),
            movieRow([
              "assets/img/midway.jpg",
              "assets/img/action.jpg",
              "assets/img/agilan.jpg",
              "assets/img/pushpa.jpg",
            ], [
              "Midway",
              "Action",
              "Agilan",
              "Pushpa",
            ]),
            const SizedBox(height: 20),

            // Latest Shows
            sectionHeader("Latest Shows", lime),
            const SizedBox(height: 10),
            filterChips(["All", "Movies", "Drama", "Thriller", "Romance"], lime),
            const SizedBox(height: 10),
            movieRow([
              "assets/img/pushpa.jpg",
              "assets/img/action.jpg",
              "assets/img/agilan.jpg",
              "assets/img/midway.jpg",
            ], [
              "Pushpa",
              "Action",
              "Agilan",
              "Midway",
            ]),
          ],
        ),
      ),
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

  Widget movieRow(List<String> imagePaths, List<String> titles) {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: imagePaths.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(imagePaths[index],
                  width: 100, height: 120, fit: BoxFit.cover),
            ),
            const SizedBox(height: 5),
            Text(titles[index],
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
