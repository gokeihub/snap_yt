// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:klutter_platfrom_verify/klutter_platfrom_verify.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeDownloader extends StatefulWidget {
  const YoutubeDownloader({super.key});

  @override
  YoutubeDownloaderState createState() => YoutubeDownloaderState();
}

class YoutubeDownloaderState extends State<YoutubeDownloader> {
  final TextEditingController _controller = TextEditingController();
  String _downloadType = 'Video';
  bool isLoading = false;
  String statusMessage = '';
  late YoutubeExplode yt;
  List<_DownloadTask> _tasks = [];
  bool _isCanceled = false;
  bool isDownloading = false;

  @override
  void initState() {
    super.initState();
    yt = YoutubeExplode();
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
      _tasks.clear();
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

  Future<void> _downloadAudio1(String videoId, String savePath) async {
    final yt = YoutubeExplode();

    try {
      final manifest = await yt.videos.streamsClient.getManifest(videoId);
      final audioStream = manifest.audioOnly.withHighestBitrate();
      final file = File(savePath);
      final fileStream = file.openWrite();
      final stream = yt.videos.streamsClient.get(audioStream);
      await stream.pipe(fileStream);
      await fileStream.flush();
      await fileStream.close();

      print('Audio downloaded successfully to $savePath');
    } catch (e) {
      print('Error downloading audio: $e');
    } finally {
      yt.close();
    }
  }

  Future<void> _fetchAudioPlaylist(String playlistUrl) async {
    setState(() {
      isLoading = true;
      statusMessage = 'Fetching playlist details...';
      _tasks.clear();
    });

    final yt = YoutubeExplode();

    try {
      final playlist = await yt.playlists.get(playlistUrl);
      final videos = await yt.playlists.getVideos(playlist.id).toList();

      for (final video in videos) {
        final Directory downloadsDir = Directory('/snapYT');
        if (!downloadsDir.existsSync()) {
          downloadsDir.createSync(recursive: true);
        }
        final savePath =
            '${downloadsDir.path}/${_sanitizeFileName(video.title)}.mp3';

        await _downloadAudio1(video.id.value, savePath);

        setState(() {
          _tasks.add(_DownloadTask(
            video.title,
            video.id.toString(),
            100.0,
            'Completed',
            audioOnly: true,
          ));
        });
      }

      setState(() {
        statusMessage = 'Downloaded audio for ${videos.length} videos.';
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
    } finally {
      yt.close();
    }
  }

  Future<void> _downloadAudio(String videoId, _DownloadTask? task) async {
    var downloadsDir = Directory('/storage/emulated/0/Download');
    if (isMobile()) {
      downloadsDir = Directory('/storage/emulated/0/Download');
    } else if (isDesktop()) {
      downloadsDir = Directory('/snapYT');
    }

    try {
      if (!downloadsDir.existsSync()) {
        downloadsDir.createSync(recursive: true);
      }

      final video = await yt.videos.get(videoId);
      final manifest = await yt.videos.streamsClient.getManifest(video.id);

      if (manifest.audioOnly.isEmpty) {
        throw Exception('No audio streams available for download.');
      }

      final streamInfo = manifest.audioOnly.withHighestBitrate();
      final filePath =
          '${downloadsDir.path}/${_sanitizeFileName(video.title)}.mp3';
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
            SnackBar(content: Text('Downloaded audio: ${video.title}')),
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
        SnackBar(content: Text('Error downloading audio: $e')),
      );
    }
  }

  Future<void> _downloadVideo(String videoId, _DownloadTask? task) async {
    var downloadsDir = Directory('/storage/emulated/0/Download');
    if (isMobile()) {
      downloadsDir = Directory('/storage/emulated/0/Download');
    } else if (isDesktop()) {
      downloadsDir = Directory('/snapYT');
    }
    try {
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

  String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  Future<void> _pasteFromClipboard() async {
    ClipboardData? clipboardData =
        await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null) {
      setState(() {
        _controller.text = clipboardData.text!;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Copy Not found'),
        duration: const Duration(seconds: 1),
        action: SnackBarAction(
          label: 'Cancle',
          onPressed: () {},
        ),
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
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  onPressed: () {
                    _controller.clear();
                  },
                  icon: const Icon(Icons.cancel_outlined),
                ),
                labelText: 'Enter YouTube URL',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.topLeft,
              child: ElevatedButton.icon(
                onPressed: _pasteFromClipboard,
                label: Text('Paste'),
                icon: Icon(
                  Icons.paste,
                ),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButton<String>(
              value: _downloadType,
              onChanged: (String? newValue) {
                setState(() {
                  _downloadType = newValue!;
                  if (_downloadType != 'Playlist') {
                    _tasks.clear();
                  } else if (_downloadType != 'Audio Playlist') {
                    _tasks.clear();
                  }
                });
              },
              items: <String>['Video', 'Audio', 'Playlist', 'Audio Playlist']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (!await _requestPermissions()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Storage permission not granted')),
                  );
                  return;
                }

                var url = _controller.text.trim();
                if (url.isNotEmpty) {
                  if (_downloadType == 'Playlist') {
                    _fetchPlaylist(url);
                  } else if (_downloadType == 'Audio Playlist') {
                    _fetchAudioPlaylist(url);
                  } else if (_downloadType == 'Audio') {
                    _downloadAudio(url, null);
                  } else {
                    _downloadVideo(url, null);
                  }
                }
              },
              child: const Text('Download'),
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
                onPressed: () async {
                  if (!await _requestPermissions()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Storage permission not granted')),
                    );
                    return;
                  }
                  setState(() {
                    _isCanceled = false;
                  });
                  for (final task in _tasks) {
                    if (_isCanceled) break;
                    if (_downloadType == 'Audio') {
                      await _downloadAudio(task.id, task);
                    } else {
                      await _downloadVideo(task.id, task);
                    }
                  }
                  if (!_isCanceled) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Playlist download completed!')),
                    );
                  }
                },
                child: const Text('Download All'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isCanceled = true;
                    for (var task in _tasks) {
                      if (task.status == 'Downloading') {
                        task.status = 'Canceled';
                      }
                    }
                  });
                },
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
  final String id;
  double progress;
  String status;
  final bool audioOnly;

  _DownloadTask(
    this.title,
    this.id,
    this.progress,
    this.status, {
    this.audioOnly = false,
  });
}
