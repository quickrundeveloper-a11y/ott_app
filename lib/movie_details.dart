import 'package:flutter/material.dart';

class MovieDetailPage extends StatelessWidget {
  const MovieDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Movie Poster
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/img/croods.jpg', // Change to your image path
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 10),

            const Text(
              "The Croods",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Row(
              children: const [
                Icon(Icons.star, color: Colors.green, size: 18),
                SizedBox(width: 4),
                Text("8.8",
                    style: TextStyle(color: Colors.green, fontSize: 16)),
                SizedBox(width: 8),
                Text(
                  "2023",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    label: const Text(
                      "Play",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.add_circle_outline,
                      color: Colors.green, size: 30),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Center(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download, color: Colors.green),
                label: const Text(
                  "Download",
                  style: TextStyle(color: Colors.green),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.green),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 110, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Genre: Animation, Cartoon",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              "A general animated cartoon is a film or series made by sequencing "
                  "still images — such as drawings — or computer-generated models to create "
                  "the illusion of movement.",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("Cast",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text("See more",
                    style: TextStyle(color: Colors.green, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 10),

            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: List.generate(4, (index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage:
                          AssetImage('assets/person${index + 1}.jpg'),
                        ),
                        const SizedBox(height: 6),
                        const Text("XYZ",
                            style:
                            TextStyle(color: Colors.white, fontSize: 14)),
                        const Text("XYZ",
                            style: TextStyle(
                                color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
