import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';



class VideoDownloaderApp extends StatelessWidget {
  const VideoDownloaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Video Downloader',
      home: VideoDownloaderScreen(),
    );
  }
}

class VideoDownloaderScreen extends StatefulWidget {
  const VideoDownloaderScreen({super.key});

  @override
  VideoDownloaderScreenState createState() => VideoDownloaderScreenState();
}

class VideoDownloaderScreenState extends State<VideoDownloaderScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isDownloading = false;
  String _statusMessage = "";

  /// Requests necessary permissions.
  Future<bool> _requestPermissions() async {
    if (await Permission.storage.isGranted) return true;

    // For Android 11+, request manage external storage permission
    if (await Permission.manageExternalStorage.isGranted) return true;

    final status = await Permission.storage.request();
    return status.isGranted || await Permission.manageExternalStorage.request().isGranted;
  }

  /// Downloads a video and saves it in the public Downloads folder.
  Future<void> _downloadVideo(String url) async {
    if (url.isEmpty) {
      setState(() {
        _statusMessage = "Please enter a valid URL.";
      });
      return;
    }

    // Request permissions
    if (!await _requestPermissions()) {
      setState(() {
        _statusMessage = "Storage permission is required.";
      });
      return;
    }

    setState(() {
      _isDownloading = true;
      _statusMessage = "Downloading...";
    });

    try {
      final Dio dio = Dio();

      // Download the file as bytes
      final Response<List<int>> response = await dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final Uint8List fileBytes = Uint8List.fromList(response.data!);

      // Save to the public Downloads folder
      final String fileName = "video_${DateTime.now().millisecondsSinceEpoch}.mp4";
      final Directory downloadsDir = Directory('/storage/emulated/0/Download');
      final File file = File('${downloadsDir.path}/$fileName');

      // Write the file
      await file.writeAsBytes(fileBytes);

      setState(() {
        _statusMessage = "Download complete! Video saved at: ${file.path}";
      });
    } catch (e) {
      setState(() {
        _statusMessage = "Error: $e";
      });
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Video Downloader"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: "Enter Video URL",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isDownloading
                  ? null
                  : () => _downloadVideo(_urlController.text),
              child: Text(_isDownloading ? "Downloading..." : "Download"),
            ),
            const SizedBox(height: 16),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
