import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const Color limeColor = Color(0xFFB6FF3B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: limeColor, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Privacy Policy",
          style: TextStyle(
            color: limeColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "1. Type of data we collect",
              style: TextStyle(
                color: limeColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              "The types of data collected can be broadly categorized as primary (newly collected for a specific purpose) "
                  "or secondary (already existing data) and can be qualitative (descriptive, non-numerical) or quantitative "
                  "(numerical, measurable). Methods for collecting data include surveys, interviews, observations, focus groups, "
                  "experiments, and digital tracking.",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "2. Use of your personal data",
              style: TextStyle(
                color: limeColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              "Personal data is used for various purposes including targeted marketing, service delivery, and "
                  "decision-making. It may also be vulnerable to misuse or identity theft.",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "3. Discourse your personal data",
              style: TextStyle(
                color: limeColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              "‘Discourse your personal data’ refers to how personal data is handled within the Discourse software platform. "
                  "It includes stored data like IP addresses, cookies, and user interaction analytics, focusing on privacy and ownership.",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
