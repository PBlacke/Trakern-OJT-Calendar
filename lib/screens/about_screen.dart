import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${info.version}+${info.buildNumber}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'OJT Calendar',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Version $_appVersion',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'About this App',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This application is designed for OJT (On-the-Job Training) trainees to track their daily work hours, compute allowances, and generate Daily Time Record (DTR) reports. It works fully offline, storing all data on your device.',
            ),
            const SizedBox(height: 24),
            const Text(
              'Terms & Conditions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'By using this app, you agree that:'
              '\n• The app is provided "as is" without any warranties.'
              '\n• You are responsible for the accuracy of the data you enter.'
              '\n• The app does not share your data with any third party.'
              '\n• The developer is not liable for any damages arising from use of this app.'
              '\n• You may use the app for personal OJT record‑keeping only.'
              '\n• Exporting data via Excel or PDF is your responsibility to ensure compliance with your organization’s requirements.'
            ),
            const SizedBox(height: 24),
            const Text(
              'Privacy Policy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This app does not collect, store, or transmit any personal information outside your device. All data remains on your device and is never sent to any server. No analytics or tracking is used.',
            ),
            const SizedBox(height: 24),
            const Text(
              'Contact',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final Uri emailUri = Uri(
                  scheme: 'mailto',
                  path: 'phantomblack82@gmail.com',
                );
                if (await canLaunchUrl(emailUri)) {
                  await launchUrl(emailUri);
                }
              },
              child: const Text(
                'your-email@example.com',
                style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
              ),
            ),
            const SizedBox(height: 16),
            const Text('© 2026 pblacke. All rights reserved.'),
          ],
        ),
      ),
    );
  }
}