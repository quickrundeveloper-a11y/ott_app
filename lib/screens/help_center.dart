import 'package:flutter/material.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  int tabIndex = 0;

  static const Color limeColor = Color(0xFFB6FF3B); // NEW LIME COLOR

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Help Center",
          style: TextStyle(color: limeColor, fontSize: 18),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 10),

              // ------------------ TABS ------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  buildTab("FAQ", 0),
                  buildTab("Contact Us", 1),
                ],
              ),

              const SizedBox(height: 15),

              // ------------------ CHIPS ------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  buildChip("General"),
                  buildChip("Account"),
                  buildChip("Service"),
                  buildChip("Videos"),
                ],
              ),

              const SizedBox(height: 20),

              // ------------------ SEARCH BOX ------------------
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: limeColor, width: 1),
                      ),
                      child: const TextField(
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search, color: limeColor),
                          hintText: "Search",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey.shade800,
                      border: Border.all(color: limeColor),
                    ),
                    child: const Icon(Icons.tune, color: limeColor),
                  )
                ],
              ),

              const SizedBox(height: 20),

              // ------------------ HELP ITEMS ------------------
              buildHelpItem(Icons.support_agent, "Customer Services"),
              buildHelpItem(Icons.public, "Website"),
              buildHelpItem(Icons.facebook, "Facebook"),
              buildHelpItem(Icons.alternate_email, "Twitter"),
              buildHelpItem(Icons.camera_alt, "Instagram"),

              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------ TAB ------------------
  Widget buildTab(String text, int index) {
    return GestureDetector(
      onTap: () => setState(() => tabIndex = index),
      child: Column(
        children: [
          Text(
            text,
            style: TextStyle(
              color: tabIndex == index ? limeColor : Colors.white70,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 90,
            color: tabIndex == index ? limeColor : Colors.white24,
          ),
        ],
      ),
    );
  }

  // ------------------ CHIP ------------------
  Widget buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: limeColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ------------------ HELP ITEM ------------------
  Widget buildHelpItem(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: limeColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: limeColor, size: 26),
          const SizedBox(width: 14),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
