//! The user interface of this page is similar to that of LocalSend

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../widgets/text_button_widget.dart';

class SnapYTAbout extends StatelessWidget {
  const SnapYTAbout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About SnapYT"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: SizedBox(
                    height: 200,
                    width: 200,
                    child: CachedNetworkImage(
                      imageUrl: "https://i.postimg.cc/pXbs1jD8/applogo.webp",
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  "SnapYT",
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text("© 2024 Gokeihub"),
                const SizedBox(height: 15),
                const TextButtonWidget(
                    text: "Gokei Hub", url: 'https://gokeihub.com/'),
                const SizedBox(height: 15),
                const Text(
                  "SnapYT is an open-source YouTube video downloader application built using the Flutter framework. Designed for simplicity and performance, SnapYT allows users to save YouTube videos and access them offline anytime. It is open-source and freely available, encouraging developers to contribute and improve the project.",
                ),
                const SizedBox(height: 15),
                const Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    "Auther",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Row(
                  children: [
                    Text("Gokeihub"),
                    TextButtonWidget(
                      text: "gokeihub",
                      url: 'https://github.com/gokeihub',
                    ),
                  ],
                ),
                const Align(
                  alignment: Alignment.topLeft,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextButtonWidget(
                        text: "HomePage",
                        url: 'https://gokeihub.com/',
                      ),
                      TextButtonWidget(
                        text: "Source Code (Github)",
                        url: 'https://github.com/gokeihub/snap_yt',
                      ),
                     
                      TextButtonWidget(
                        text: "License",
                        url:
                            'https://github.com/gokeihub/snap_yt/blob/main/LICENSE',
                      ),
                      TextButtonWidget(
                        text: "CHANGELOG",
                        url:
                            'https://github.com/gokeihub/snap_yt/blob/main/CHANGELOG.md',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
