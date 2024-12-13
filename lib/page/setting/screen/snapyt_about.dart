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
        title: const Text("About Bookify"),
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
                      imageUrl: "https://i.postimg.cc/KYHd794P/app-icon.jpg",
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  "Bookify Audio",
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text("© 2024 Md Apon Ahmed"),
                const SizedBox(height: 15),
                const TextButtonWidget(
                    text: "Gokei Hub", url: 'https://gokeihub.com/'),
                const SizedBox(height: 15),
                const Text(
                  "Bookify Audio is free, open-source app where you Play Audio Book you need. Which you can use very easily",
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
                    Text("Md Apon Ahmed"),
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
                        url: 'https://github.com/gokeihub/bookify_audio',
                      ),
                       TextButtonWidget(
                        text: "Bookify Audio Api",
                        url: 'https://github.com/gokeihub/bookify_api',
                      ),
                      TextButtonWidget(
                        text: "License",
                        url:
                            'https://github.com/gokeihub/bookify_audio/blob/main/LICENSE',
                      ),
                      TextButtonWidget(
                        text: "CHANGELOG",
                        url:
                            'https://github.com/gokeihub/bookify_audio/blob/main/CHANGELOG.md',
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
