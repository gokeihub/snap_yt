// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeDownloader extends StatefulWidget {
  const YoutubeDownloader({super.key});

  @override
  YoutubeDownloaderState createState() => YoutubeDownloaderState();
}

class YoutubeDownloaderState extends State<YoutubeDownloader> {
  final TextEditingController _controller = TextEditingController();
  String _downloadType = 'Video'; // Default: Video
  bool isLoading = false;
  String statusMessage = '';
  late YoutubeExplode yt;
  List<_DownloadTask> _tasks = [];
  bool _isCanceled = false;
  bool isDownloading = false;

  @override
  void initState() {
    super.initState();
    yt = YoutubeExplode(); // Initialize yt when the state is created
  }

  Future<bool> _requestPermissions() async {
    if (await Permission.storage.request().isGranted) return true;
    if (await Permission.manageExternalStorage.isGranted) return true;

    final status = await Permission.storage.request();
    return status.isGranted ||
        await Permission.manageExternalStorage.request().isGranted;
  }

  Future<void> _fetchPlaylist(String playlistUrl) async {
    setState(() {
      isLoading = true;
      statusMessage = 'Fetching playlist details...';
      _tasks
          .clear(); // Clear previous task list when switching to playlist mode
    });

    try {
      final playlist = await yt.playlists.get(playlistUrl);
      final videos = await yt.playlists.getVideos(playlist.id).toList();

      setState(() {
        _tasks = videos
            .map((video) =>
                _DownloadTask(video.title, video.id.toString(), 0.0, 'Pending'))
            .toList();
        statusMessage = 'Found ${videos.length} videos in the playlist.';
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching playlist: $e')),
      );
      setState(() {
        isLoading = false;
        statusMessage = '';
      });
    }
  }

  Future<void> _downloadVideo(String videoId, _DownloadTask? task) async {
    try {
      final Directory downloadsDir = Directory('/storage/emulated/0/Download');
      if (!downloadsDir.existsSync()) {
        downloadsDir.createSync(recursive: true);
      }

      final video = await yt.videos.get(videoId);
      final manifest = await yt.videos.streamsClient.getManifest(video.id);

      if (manifest.muxed.isEmpty) {
        throw Exception('No video streams available for download.');
      }

      final streamInfo = manifest.muxed.withHighestBitrate();
      final filePath =
          '${downloadsDir.path}/${_sanitizeFileName(video.title)}.mp4';
      final file = File(filePath);
      final stream = yt.videos.streamsClient.get(streamInfo);

      final totalBytes = streamInfo.size.totalBytes;
      var downloadedBytes = 0;
      final output = file.openWrite();

      if (task != null) {
        task.status = 'Downloading';
      }

      setState(() {
        isDownloading = true;
      });

      await for (final chunk in stream) {
        if (_isCanceled) break;

        downloadedBytes += chunk.length;
        output.add(chunk);

        final progress = downloadedBytes / totalBytes;

        if (task != null) {
          setState(() {
            task.progress = progress;
            task.status = 'Downloading ${(progress * 100).toStringAsFixed(1)}%';
          });
        } else {
          setState(() {
            statusMessage =
                'Downloading ${(progress * 100).toStringAsFixed(1)}%';
          });
        }
      }

      await output.flush();
      await output.close();

      if (!_isCanceled) {
        if (task != null) {
          task.status = 'Completed';
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Downloaded video: ${video.title}')),
          );
        }
      }
      setState(() {
        isDownloading = false;
      });
    } catch (e) {
      if (task != null) {
        task.status = 'Error';
      }
      setState(() {
        isDownloading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading video: $e')),
      );
    }
  }

  Future<void> _downloadPlaylist() async {
    if (!await _requestPermissions()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission not granted')),
      );
      return;
    }

    setState(() {
      _isCanceled = false;
    });

    for (final task in _tasks) {
      if (_isCanceled) break;
      await _downloadVideo(task.videoId, task);
    }

    if (!_isCanceled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Playlist download completed!')),
      );
    }
  }

  void _cancelDownloads() {
    setState(() {
      _isCanceled = true;
      for (var task in _tasks) {
        if (task.status == 'Downloading') {
          task.status = 'Canceled';
        }
      }
    });
  }

  String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
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
              decoration:  InputDecoration(
                suffixIcon: IconButton(onPressed: (){
                  _controller.clear();
                }, icon: const Icon(Icons.cancel_outlined) ),
                labelText: 'Enter YouTube URL',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButton<String>(
              value: _downloadType,
              onChanged: (String? newValue) {
                setState(() {
                  _downloadType = newValue!;
                  if (_downloadType != 'Playlist') {
                    _tasks.clear(); // Clear tasks when switching to video/audio
                  }
                });
              },
              items: <String>['Video', 'Audio', 'Playlist']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                var url = _controller.text.trim();
                if (url.isNotEmpty) {
                  if (_downloadType == 'Playlist') {
                    _fetchPlaylist(url);
                  } else {
                    _downloadVideo(url, null);
                  }
                }
              },
              child: const Text('Start'),
            ),
            const SizedBox(height: 20),
            if (_tasks.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    return ListTile(
                      title: Text(task.title),
                      subtitle: Text(task.status),
                      trailing: task.status.contains('Downloading')
                          ? CircularProgressIndicator(value: task.progress)
                          : null,
                    );
                  },
                ),
              ),
            if (_tasks.isNotEmpty) ...[
              ElevatedButton(
                onPressed: _downloadPlaylist,
                child: const Text('Download All'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _cancelDownloads,
                child: const Text('Cancel All'),
              ),
            ],
            if (isDownloading) ...[
              const CircularProgressIndicator(),
              Text(statusMessage),
            ]
          ],
        ),
      ),
    );
  }
}

class _DownloadTask {
  final String title;
  final String videoId;
  double progress;
  String status;

  _DownloadTask(this.title, this.videoId, this.progress, this.status);
}
