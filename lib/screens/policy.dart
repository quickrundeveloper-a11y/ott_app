import 'package:flutter/material.dart';
import '../theme/theme.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,

      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.greenAccent, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Privacy Policy",
          style: TextStyle(
            color: AppTheme.greenAccent,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ---------------- HEADER ----------------
            sectionTitle("Privacy Policy for OTT App"),
            sectionText("Effective Date: November 15, 2025"),

            const SizedBox(height: 20),
            sectionText(
              "This Privacy Policy describes how Quick Run (referred to as "
                  "“we,” “us,” or “our”), the operator of the OTT streaming application, "
                  "website, and related services, collects, uses, protects, and shares your "
                  "personal information. By accessing or using our Service, you agree to the "
                  "collection and use of your information in accordance with this Privacy Policy.",
            ),

            const SizedBox(height: 25),

            // ---------------- 1. Information We Collect ----------------
            sectionTitle("1. Information We Collect"),
            sectionText(
              "We collect information that identifies, relates to, describes, or could "
                  "reasonably be linked to a particular consumer or household (“Personal Data”).",
            ),

            const SizedBox(height: 20),
            sectionSubtitle("1.1 Information You Provide Directly to Us"),

            bulletTitle("Account / Registration Data"),
            bulletText("Name, email address, password, phone number, date of birth, address."),
            bulletText("Purpose: To create and manage your account and communicate with you."),

            bulletTitle("Payment Data"),
            bulletText("Last 4 digits of card, billing address, transaction history."),
            bulletText("Purpose: To process subscription payments (full card details stored by payment processors only)."),

            bulletTitle("Communications"),
            bulletText("Emails, chat messages, customer support content."),
            bulletText("Purpose: To provide customer support and improve services."),

            const SizedBox(height: 25),

            // ---------------- Auto Collected ----------------
            sectionSubtitle("1.2 Information Collected Automatically"),
            bulletTitle("Viewing History & Preferences"),
            bulletText("Content watched, search queries, playlists, interaction data."),

            bulletTitle("Device & Software Information"),
            bulletText("Device type, OS, device identifiers, browser type."),

            bulletTitle("Network & Location Data"),
            bulletText("IP address, ISP, region, connection speed."),

            bulletTitle("Technical Logs"),
            bulletText("Crash reports, performance logs, timestamps."),

            const SizedBox(height: 25),

            sectionSubtitle("1.3 Tracking Technologies"),
            bulletTitle("Authentication Cookies"),
            bulletText("To keep you signed in."),
            bulletTitle("Preferences Cookies"),
            bulletText("To store playback & language settings."),
            bulletTitle("Analytics Tools"),
            bulletText("To analyze user behavior and improve the app."),

            const SizedBox(height: 30),

            // ---------------- 2. How We Use Data ----------------
            sectionTitle("2. How We Use Your Personal Data"),
            bulletTitle("Service Provision"),
            bulletText("Streaming content, managing subscriptions, processing payments."),

            bulletTitle("Personalization"),
            bulletText("Recommending content and customizing UI based on watch history."),

            bulletTitle("Analytics & Improvement"),
            bulletText("Tracking usage patterns to improve features."),

            bulletTitle("Security & Safety"),
            bulletText("Detecting fraud, preventing unauthorized access."),

            bulletTitle("Communication"),
            bulletText("Sending service updates, alerts, and responses."),

            bulletTitle("Marketing"),
            bulletText("Sending promotional offers (where permitted)."),

            const SizedBox(height: 30),

            // ---------------- 3. Sharing Data ----------------
            sectionTitle("3. Sharing and Disclosure of Personal Data"),
            sectionText(
              "We do not sell your personal data for monetary gain. However, we may share "
                  "your data with service providers, advertising partners, and law enforcement "
                  "when necessary.",
            ),

            const SizedBox(height: 15),
            sectionSubtitle("3.1 Service Providers"),
            bulletText("Payment processors (Stripe, PayPal)."),
            bulletText("Cloud storage & CDNs (AWS, Google Cloud)."),
            bulletText("Analytics tools (Google Analytics, Mixpanel)."),
            bulletText("Customer support platforms."),

            const SizedBox(height: 15),
            sectionSubtitle("3.2 Advertising Partners"),
            bulletText(
              "For ad-supported plans, we may share device identifiers but not personal identity data.",
            ),

            const SizedBox(height: 15),
            sectionSubtitle("3.3 Legal Obligations"),
            bulletText("We may disclose data to comply with legal or safety requirements."),

            const SizedBox(height: 30),

            // ---------------- 4. Security ----------------
            sectionTitle("4. Data Security and Retention"),
            sectionText(
              "We use encryption, firewalls, access controls, and audits to protect data. "
                  "However, no method is 100% secure. We retain your data only as long as required "
                  "for legal or operational purposes.",
            ),

            const SizedBox(height: 30),

            // ---------------- 5. Children ----------------
            sectionTitle("5. Children's Privacy"),
            sectionText(
              "Our service is not intended for users under 13. We do not knowingly collect "
                  "data from children. If discovered, such data will be deleted immediately.",
            ),

            const SizedBox(height: 30),

            // ---------------- 6. Rights ----------------
            sectionTitle("6. Your Data Rights and Choices"),
            sectionText(
              "Depending on your jurisdiction, you may have rights such as access, deletion, "
                  "correction, opt-out of marketing, or object to processing.",
            ),

            const SizedBox(height: 30),

            // ---------------- 7. International Transfers ----------------
            sectionTitle("7. International Data Transfers"),
            sectionText(
              "Your data may be stored or processed in countries outside your region. "
                  "We ensure legal safeguards where applicable.",
            ),

            const SizedBox(height: 30),

            // ---------------- 8. Contact ----------------
            sectionTitle("8. Contact Information"),
            sectionText("Quick Run"),
            sectionText("Address: 123 Stream Lane, Digital City, CA 90210"),
            sectionText("Email: privacy@quickrun.com"),
            sectionText("Phone: +1 (800) 555-0199"),

            const SizedBox(height: 30),

            // ---------------- 9. Changes ----------------
            sectionTitle("9. Changes to This Privacy Policy"),
            sectionText(
              "We may update this Privacy Policy from time to time. Continued use of the "
                  "service means acceptance of the updated policy.",
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // ---------- REUSABLE UI ----------

  Widget sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.greenAccent,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget sectionSubtitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textWhite,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget sectionText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.textLight,
          fontSize: 15,
          height: 1.5,
        ),
      ),
    );
  }

  Widget bulletTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.greenAccent,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget bulletText(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        "• $text",
        style: const TextStyle(
          color: AppTheme.textLight,
          fontSize: 14,
          height: 1.4,
        ),
      ),
    );
  }
}
