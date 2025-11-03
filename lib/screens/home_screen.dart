import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
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
    const Center(child: Icon(Icons.folder_open, color: Colors.white)),
    const Center(child: Icon(Icons.person, color: Colors.white)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: pages[selectedIndex],
      bottomNavigationBar: Container(
        color: const Color(0xFF1A1A1A),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            navItem(Icons.home, "Home", 0),
            navItem(Icons.download, "Downloads", 1),
            navItem(Icons.search, "Search", 2),
            navItem(Icons.folder_open, "Library", 3),
            navItem(Icons.person, "Profile", 4),
          ],
        ),
      ),
    );
  }

  Widget navItem(IconData icon, String label, int index) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.red : Colors.transparent,
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(icon,
                color: isSelected ? Colors.white : Colors.grey, size: 24),
          ),
          Text(label,
              style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey, fontSize: 12))
        ],
      ),
    );
  }
}

class MovieHomePage extends StatelessWidget {
  const MovieHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  Image.asset("assets/topgun.jpg",
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
                      backgroundColor: Colors.red,
                      child: Icon(Icons.play_arrow, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Trending Now
            sectionHeader("Trending Now"),
            const SizedBox(height: 10),
            movieRow([
              "assets/midway.jpg",
              "assets/action.jpg",
              "assets/agilan.jpg",
              "assets/pushpa.jpg",
            ], [
              "Midway",
              "Action",
              "Agilan",
              "Pushpa",
            ]),
            const SizedBox(height: 20),

            // Latest Shows
            sectionHeader("Latest Shows"),
            const SizedBox(height: 10),
            filterChips(["All", "Movies", "Drama", "Thriller", "Romance"]),
            const SizedBox(height: 10),
            movieRow([
              "assets/pushpa.jpg",
              "assets/action.jpg",
              "assets/agilan.jpg",
              "assets/midway.jpg",
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

  Widget sectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
        const Text("Show all", style: TextStyle(color: Colors.white70)),
      ],
    );
  }

  Widget filterChips(List<String> labels) {
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
              color: isSelected ? Colors.red : const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(labels[index],
                style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
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
