import 'package:flutter/material.dart';
import 'package:quick_actions/quick_actions.dart';
import '../page/setting/screen/setting.dart';
import '../page/video_download/video_download.dart';
import '../page/youtube_download/youtube_download.dart';

const QuickActions quickActions = QuickActions();

initializeAction(BuildContext context) {
  quickActions.initialize((String shortvutType) {
    switch (shortvutType) {
      case 'Youtube Download':
        Navigator.of(context).push(
            MaterialPageRoute(builder: (builder) => const YoutubeDownloader()));
        return;
      case 'Video Download':
        Navigator.of(context).push(MaterialPageRoute(
            builder: (builder) => const VideoDownloaderScreen(),),);
        return;
      default:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (builder) => const SettingPage(),
          ),
        );
        return;
    }
  });
  quickActions.setShortcutItems(
    [
      const ShortcutItem(
          type: 'Youtube Download', localizedTitle: 'Youtube Download'),
      const ShortcutItem(
          type: 'Video Download',
          localizedTitle: 'Video Download',
          icon: 'video'),
      const ShortcutItem(
          type: 'Setting', localizedTitle: 'Setting', icon: 'settings'),
    ],
  );
}
