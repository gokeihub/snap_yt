// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'youtube_download.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouTube Downloader',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const YoutubeDownloader(),
    );
  }
}
