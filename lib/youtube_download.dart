import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeVideoDownloader extends StatefulWidget {
  const YoutubeVideoDownloader({super.key});

  @override
  YoutubeVideoDownloaderState createState() => YoutubeVideoDownloaderState();
}

class YoutubeVideoDownloaderState extends State<YoutubeVideoDownloader> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String _downloadType = 'Video';
  double _downloadProgress = 0.0;
  String _downloadStatus = '';
  late YoutubeExplode yt;
  late Video video;
  late StreamInfo streamInfo;
  late File file;
  late IOSink output;
  late Stream<List<int>> stream;
  bool _isDownloading = false;

  bool _isCanceled = false;

  Future<bool> _requestPermissions() async {
    if (await Permission.storage.request().isGranted) return true;
    if (await Permission.manageExternalStorage.isGranted) return true;

    final status = await Permission.storage.request();
    return status.isGranted ||
        await Permission.manageExternalStorage.request().isGranted;
  }

  Future<void> _downloadContent(String url) async {
    setState(() {
      _isLoading = true;
      _downloadProgress = 0.0;
      _downloadStatus = 'Preparing download...';
    });

    if (!await _requestPermissions()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission not granted')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      yt = YoutubeExplode();
      video = await yt.videos.get(url);
      var manifest = await yt.videos.streamsClient.getManifest(video.id);

      final Directory downloadsDir = Directory('/storage/emulated/0/Download');
      if (!downloadsDir.existsSync()) {
        downloadsDir.createSync(recursive: true);
      }

      if (_downloadType == 'Video') {
        if (manifest.muxed.isEmpty) {
          throw Exception('No video streams available for download.');
        }

        streamInfo = manifest.muxed.withHighestBitrate();
        var filePath =
            '${downloadsDir.path}/${_sanitizeFileName(video.title)}.mp4';
        file = File(filePath);
        stream = yt.videos.streamsClient.get(streamInfo);

        final totalBytes = streamInfo.size.totalBytes;
        var downloadedBytes = 0;

        output = file.openWrite();

        _isDownloading = true;

        _isCanceled = false;

        await for (final chunk in stream) {
          if (_isCanceled) {
            break;
          }

          downloadedBytes += chunk.length;
          output.add(chunk);

          final progress = downloadedBytes / totalBytes;
          final downloadedMB =
              (downloadedBytes / (1024 * 1024)).toStringAsFixed(1);
          final totalMB = (totalBytes / (1024 * 1024)).toStringAsFixed(1);

          setState(() {
            _downloadProgress = progress;
            _downloadStatus = 'Downloaded $downloadedMB MB / $totalMB MB';
          });
        }

        await output.flush();
        await output.close();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloaded video: ${video.title}')),
        );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _downloadProgress = 0.0;
        _downloadStatus = '';
      });
    }
  }

  String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  void _cancelDownload() {
    setState(() {
      _isCanceled = true;
      _isDownloading = false;
      _downloadStatus = 'Download canceled';
    });
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
            if (_isLoading) ...[
              LinearProgressIndicator(value: _downloadProgress),
              const SizedBox(height: 10),
              Text(_downloadStatus),
              const SizedBox(height: 10),
            ],
            ElevatedButton(
              onPressed: _isDownloading
                  ? null
                  : () {
                      var url = _controller.text.trim();
                      if (url.isNotEmpty) {
                        _downloadContent(url);
                      }
                    },
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Download'),
            ),
            if (_isDownloading) ...[
              ElevatedButton(
                onPressed: _cancelDownload,
                child: const Text('Cancel'),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
