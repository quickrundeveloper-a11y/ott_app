import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    const limeColor = Color(0xFFB6FF3B); // NEW LIME COLOR

    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: limeColor),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Notification",
          style: TextStyle(
            color: limeColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        children: [
          buildNotificationItem("assets/nt1.jpg"),
          buildNotificationItem("assets/nt2.jpg"),
          buildNotificationItem("assets/nt3.jpg"),
          buildNotificationItem("assets/nt4.jpg"),
          buildNotificationItem("assets/nt5.jpg"),
        ],
      ),
    );
  }

  Widget buildNotificationItem(String image) {
    const limeColor = Color(0xFFB6FF3B); // NEW LIME COLOR

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Circular Image with border
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: limeColor, width: 2),
            ),
            child: CircleAvatar(
              radius: 35,
              backgroundImage: AssetImage(image),
            ),
          ),

          const SizedBox(width: 12),

          // Text content
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                SizedBox(height: 4),
                Text(
                  "1m ago.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Lime Badge (Changed)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: limeColor,
              shape: BoxShape.circle,
            ),
            child: const Text(
              "2",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
