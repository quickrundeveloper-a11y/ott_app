import 'package:flutter/material.dart';

class DownloadPage extends StatelessWidget {
  const DownloadPage({super.key});

  @override
  Widget build(BuildContext context) {
    const limeColor = Color(0xFFB6FF3B); // NEW LIME COLOR

    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,

        title: const Text(
          "Download",
          style: TextStyle(
            color: limeColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: limeColor), // CHANGED
          )
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 10),

              const Text(
                "Season 1",
                style: TextStyle(
                  color: limeColor,          // CHANGED
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              buildEpisodeItem(
                image: "assets/ep1.jpg",
                title: "1. Episode 1",
                duration: "58m",
                description:
                "Sgt. David Budd is promoted to a protection detail for UK Home Secretary Julia Montague, but he quickly clashes with the hawkish politician.",
                isDownloaded: false,
              ),

              buildEpisodeItem(
                image: "assets/ep2.jpg",
                title: "2. Episode 2",
                duration: "58m",
                description:
                "After an attempted attack on the school Budd's kids attend, Montague worries about leaks in the department. But she may be in the line of fire herself.",
                isDownloaded: true,
              ),

              buildEpisodeItem(
                image: "assets/ep3.jpg",
                title: "3. Episode 3",
                duration: "57m",
                description:
                "Montague's public standing sours further. As Budd feels mounting pressure to spy on her, investigators question his statement about the shooting.",
                isDownloaded: false,
              ),

              buildEpisodeItem(
                image: "assets/ep4.jpg",
                title: "4. Episode 4",
                duration: "57m",
                description:
                "In the wake of another attack, investigators grow increasingly suspicious of Budd.",
                isDownloaded: false,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildEpisodeItem({
    required String image,
    required String title,
    required String duration,
    required String description,
    required bool isDownloaded,
  }) {
    const limeColor = Color(0xFFB6FF3B); // NEW LIME COLOR

    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      image,
                      width: 130,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const Icon(
                    Icons.play_circle_fill,
                    color: Colors.white70,
                    size: 38,
                  ),
                ],
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      duration,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                isDownloaded ? Icons.download_done : Icons.download,
                color: limeColor, // UPDATED
                size: 28,
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
