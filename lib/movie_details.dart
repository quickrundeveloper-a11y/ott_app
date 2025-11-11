import 'package:flutter/material.dart';


class MovieDetailPage extends StatelessWidget {
  final String? videoId;
  const MovieDetailPage({super.key, this.videoId});


  static const Color limeColor = Color(0xFFB6FF3B);
  static const double horizontalPadding = 18.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: limeColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Movie Details ${videoId}",
          style: const TextStyle(
            color: limeColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Movie Poster
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/img/croods.jpg',
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 20),

            // Movie Title
            const Text(
              "The Croods",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Rating and Year Row
            Row(
              children: const [
                Icon(Icons.star, color: limeColor, size: 20),
                SizedBox(width: 4),
                Text("8.8", style: TextStyle(color: limeColor, fontSize: 16)),
                SizedBox(width: 10),
                Icon(Icons.calendar_month, color: limeColor, size: 18),
                SizedBox(width: 4),
                Text("2023", style: TextStyle(color: Colors.white70, fontSize: 16)),
              ],
            ),

            const SizedBox(height: 24),

            // Play Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.play_arrow, color: Colors.black),
                label: const Text(
                  "Play",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: limeColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Download Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download, color: limeColor),
                label: const Text(
                  "Download",
                  style: TextStyle(
                    color: limeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: limeColor, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Genre Section
            const Text(
              "Genre",
              style: TextStyle(
                color: limeColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Animation, Cartoon",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),

            const SizedBox(height: 20),

            // Description Section
            const Text(
              "Description",
              style: TextStyle(
                color: limeColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "A fun animated adventure following the prehistoric Crood family as they explore "
                  "a dangerous new world filled with strange creatures and new discoveries. "
                  "Full of humor, heart, and beautiful animation, it's a must-watch for families.",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 30),

            // Cast Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "Cast",
                  style: TextStyle(
                    color: limeColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "See more",
                  style: TextStyle(
                    color: limeColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Cast List
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      CircleAvatar(
                        radius: 38,
                        backgroundImage: AssetImage('assets/person${index + 1}.jpg'),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "XYZ",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Text(
                        "Role",
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
