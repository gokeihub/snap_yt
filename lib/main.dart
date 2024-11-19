import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

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
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String _downloadType = 'Video'; // Default download type

  Future<void> _downloadContent(String url) async {
    setState(() {
      _isLoading = true;
    });

    // Check for storage permission
    if (await Permission.storage.request().isGranted) {
      try {
        var yt = YoutubeExplode();
        var video = await yt.videos.get(url);
        var manifest = await yt.videos.streamsClient.getManifest(video.id);

        var dir = Directory('/storage/emulated/0/Download'); // Download path
        dir.createSync(recursive: true); // Ensure the directory exists

        if (_downloadType == 'Video') {
          // Video download
          if (manifest.muxed.isEmpty) {
            throw Exception('No video streams available for download.');
          }
          var streamInfo = manifest.muxed.withHighestBitrate();
          var filePath = '${dir.path}/${video.title}.mp4';
          var file = File(filePath);
          var stream = yt.videos.streamsClient.get(streamInfo);
          var output = file.openWrite();
          await stream.pipe(output);
          await output.flush();
          await output.close();

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Downloaded video: ${video.title}'),
          ));
        } else {
          // Audio download
          if (manifest.audioOnly.isEmpty) {
            throw Exception('No audio streams available for download.');
          }
          var streamInfo = manifest.audioOnly.withHighestBitrate();
          var filePath = '${dir.path}/${video.title}.mp3';
          var file = File(filePath);
          var stream = yt.videos.streamsClient.get(streamInfo);
          var output = file.openWrite();
          await stream.pipe(output);
          await output.flush();
          await output.close();

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Downloaded audio: ${video.title}'),
          ));
        }
      } catch (e) {
        String errorMessage;

        if (e is VideoUnavailableException) {
          errorMessage = 'This video is unavailable.';
        } else if (e is YoutubeExplodeException) {
          errorMessage = 'Failed to extract data: ${e.message}';
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Storage permission not granted'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube Downloader'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Enter YouTube Video URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButton<String>(
              value: _downloadType,
              onChanged: (String? newValue) {
                setState(() {
                  _downloadType = newValue!;
                });
              },
              items: <String>['Video', 'Audio']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      var url = _controller.text.trim();
                      if (url.isNotEmpty) {
                        _downloadContent(url);
                      }
                    },
              child: _isLoading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : const Text('Download'),
            ),
          ],
        ),
      ),
    );
  }
}
