import 'package:flutter/material.dart';

class DownloadPage extends StatelessWidget {
  const DownloadPage({super.key});

  @override
  Widget build(BuildContext context) {
    final episodes = [
      {
        'title': 'Episode 1',
        'duration': '58m',
        'description':
        'Sgt. David Budd is promoted to a protection detail for UK Home Secretary Julia Montague, but he quickly clashes with the hawkish politician.',
        'thumb': 'assets/thumb_1.jpg'
      },
      {
        'title': 'Episode 2',
        'duration': '56m',
        'description':
        'After an attempted attack on the school Budd’s kids attend, Montague worries about leaks in the department. But she may be in the line of fire herself.',
        'thumb': 'assets/thumb_2.jpg'
      },
      {
        'title': 'Episode 3',
        'duration': '57m',
        'description':
        'Montague’s public standing soars further. As Budd feels mounting pressure to spy on her, investigators question his statement about the shooting.',
        'thumb': 'assets/thumb_3.jpg'
      },
      {
        'title': 'Episode 4',
        'duration': '47m',
        'description':
        'In the wake of another attack, suspicions of Budd grow as he finds himself under intense scrutiny from his superiors and the media.',
        'thumb': 'assets/thumb_4.jpg'
      },
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Download',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
            ),

            // Season Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'Season 1',
                style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),

            // Episodes List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: episodes.length,
                itemBuilder: (context, index) {
                  final ep = episodes[index];
                  return _EpisodeTile(
                    index: index + 1,
                    title: ep['title']!,
                    duration: ep['duration']!,
                    description: ep['description']!,
                    thumb: ep['thumb']!,
                    isDownloaded: index == 1, // Highlight one as downloaded
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  final int index;
  final String title;
  final String duration;
  final String description;
  final String thumb;
  final bool isDownloaded;

  const _EpisodeTile({
    required this.index,
    required this.title,
    required this.duration,
    required this.description,
    required this.thumb,
    this.isDownloaded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFF333333),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.asset(
                        thumb,
                        width: 100,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black54,
                        border: Border.all(color: Colors.white30),
                      ),
                      child: const Icon(Icons.play_arrow,
                          color: Colors.white, size: 20),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$index. $title',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        duration,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isDownloaded
                      ? Icons.check_box_rounded
                      : Icons.download_outlined,
                  color: isDownloaded
                      ? Colors.greenAccent
                      : Colors.white70,
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
