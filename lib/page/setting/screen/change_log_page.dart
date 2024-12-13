import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../widgets/bookify_ads.dart';
// import 'package:startapp_sdk/startapp.dart';

class ChangeLogPage extends StatefulWidget {
  const ChangeLogPage({super.key});

  @override
  ChangeLogPageState createState() => ChangeLogPageState();
}

class ChangeLogPageState extends State<ChangeLogPage> {
  String markdownData = '';

  // var startApp = StartAppSdk();
  // StartAppBannerAd? bannerAds;

  // loadBannerAds() {
  //   //! startApp.setTestAdsEnabled(true);
  //   startApp.loadBannerAd(StartAppBannerType.BANNER).then((value) {
  //     setState(() {
  //       bannerAds = value;
  //     });
  //   });
  // }

  @override
  void initState() {
    super.initState();
    // loadBannerAds();
    loadMarkdown();
  }

  void loadMarkdown() async {
    String data = await rootBundle.loadString('CHANGELOG.md');
    setState(() {
      markdownData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chanage History'),
      ),
      // bottomNavigationBar: bannerAds != null
      //     ? SizedBox(height: 60, child: StartAppBanner(bannerAds!))
      //     : const SizedBox(),
      bottomNavigationBar: const BookifyAds(
        apiUrl: 'https://gokeihub.github.io/bookify_api/ads/changelog.json',
      ),
      body: Markdown(
        data: markdownData,
      ),
    );
  }
}
