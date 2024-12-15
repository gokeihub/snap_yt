// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../provider/theme_provider.dart';
import '../widgets/snapyt_ads.dart';
import 'snapyt_about.dart';
import 'app_information_page.dart';
import 'change_log_page.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Setting"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              child: ListTile(
                title: const Text('Theme'),
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme(value);
                  },
                ),
              ),
            ),
            Card(
              child: ListTile(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (b) => const AppInformationPage(),
                    ),
                  );
                },
                title: const Text('App Information'),
                trailing: const Icon(Icons.info_rounded),
              ),
            ),
            const BookifyAds(
              apiUrl:
                  'https://gokeihub.github.io/bookify_api/ads/setting_1.json',
            ),
            Card(
              child: ListTile(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (b) => const ChangeLogPage(),
                    ),
                  );
                },
                title: const Text('Changelog'),
                trailing: const Icon(Icons.history),
              ),
            ),
            Card(
              child: ListTile(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (b) => const SnapYTAbout(),
                    ),
                  );
                },
                title: const Text('About SnapYT'),
                trailing: const Icon(Icons.info_rounded),
              ),
            ),
            Card(
              child: ListTile(
                onTap: () async {
                  String privacyUrl =
                      'https://sites.google.com/view/snapyt-privacy/home';
                  final Uri url = Uri.parse(privacyUrl);
                  if (await canLaunch(url.toString())) {
                    await launch(url.toString());
                  } else {
                    await launch(url.toString());
                  }
                },
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.privacy_tip),
              ),
            ),
            const BookifyAds(
              apiUrl:
                  'https://gokeihub.github.io/bookify_api/ads/setting_2.json',
            ),
            Card(
              child: ListTile(
                onTap: () async {
                  String privacyUrl = 'https://t.me/gokeihub';
                  final Uri url = Uri.parse(privacyUrl);
                  if (await canLaunch(url.toString())) {
                    await launch(url.toString());
                  } else {
                    await launch(url.toString());
                  }
                },
                title: const Text('Telegram Group'),
                trailing: const Icon(Icons.telegram),
              ),
            ),
            Card(
              child: ListTile(
                onTap: () async {
                  String termCondition =
                      'https://sites.google.com/view/snapyt-term/home';
                  final Uri url = Uri.parse(termCondition);
                  if (await canLaunch(url.toString())) {
                    await launch(url.toString());
                  } else {
                    await launch(url.toString());
                  }
                },
                title: const Text('Terms & Conditions'),
                trailing: const Icon(Icons.assignment),
              ),
            ),
            const BookifyAds(
              apiUrl:
                  'https://gokeihub.github.io/bookify_api/ads/setting_3.json',
            ),
            Card(
              child: ListTile(
                onTap: () async {
                  String githubUrl = 'https://github.com/gokeihub';
                  final Uri url = Uri.parse(githubUrl);
                  if (await canLaunch(url.toString())) {
                    await launch(url.toString());
                  } else {
                    await launch(url.toString());
                  }
                },
                title: const Text('Github'),
                trailing: const Icon(FontAwesomeIcons.github),
              ),
            ),
            Card(
              child: ListTile(
                onTap: () async {
                  String issuesUrl =
                      'https://github.com/gokeihub/snap_yt/issues';
                  final Uri url = Uri.parse(issuesUrl);
                  if (await canLaunch(url.toString())) {
                    await launch(url.toString());
                  } else {
                    await launch(url.toString());
                  }
                },
                title: const Text('Any Issues'),
                trailing: const Icon(Icons.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
