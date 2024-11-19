import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouTube Video Downloader',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  Future<void> _downloadVideo(String url) async {
    setState(() {
      _isLoading = true;
    });

    // Check for storage permission
    if (await Permission.storage.request().isGranted) {
      try {
        var yt = YoutubeExplode();
        // var videoId = YoutubeExplode.parseVideoId(url); // Extract video ID
        var video = await yt.videos.get(url);
        var manifest = await yt.videos.streamsClient.getManifest(video.id);

        // Check if there are any streams available for download
        if (manifest.muxed.isEmpty) {
          throw Exception('No downloadable streams found for this video.');
        }

        var streamInfo = manifest.muxed.withHighestBitrate();
        var dir = Directory('/storage/emulated/0/Download'); // Path to the download folder
        var filePath = '${dir.path}/${video.title}.mp4';
        var file = File(filePath);
        var stream = yt.videos.streamsClient.get(streamInfo);

        // Start downloading the video
        var output = file.openWrite();
        await stream.pipe(output);
        await output.flush();
        await output.close();

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Downloaded: ${video.title}'),
        ));
      } catch (e) {
        String errorMessage;

        // Handle different types of exceptions
        if (e is VideoUnavailableException) {
          errorMessage = 'This video is unavailable.';
        } else if (e is YoutubeExplodeException) {
          errorMessage = 'Failed to extract video data: ${e.message}';
        } else {
          errorMessage = 'Error: $e';
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMessage),
        ));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Storage permission not granted'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('YouTube Video Downloader'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter YouTube Video URL',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      var url = _controller.text.trim();
                      if (url.isNotEmpty) {
                        _downloadVideo(url);
                      }
                    },
              child: _isLoading
                  ? CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : Text('Download'),
            ),
          ],
        ),
      ),
    );
  }
}
