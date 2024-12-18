// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:klutter_platfrom_verify/klutter_platfrom_verify.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeSearch extends StatefulWidget {
  const YoutubeSearch({super.key});

  @override
  YoutubeSearchState createState() => YoutubeSearchState();
}

class YoutubeSearchState extends State<YoutubeSearch> {
  final TextEditingController _searchController = TextEditingController();
  // final String _downloadType = 'Video';
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

  Future<void> _searchYouTube(String query) async {
    setState(() {
      isLoading = true;
      statusMessage = 'Searching for "$query"...';
    });

    try {
      final searchResults = await yt.search.getVideos(query);

      if (searchResults.isEmpty) {
        setState(() {
          statusMessage = 'No results found for "$query".';
          isLoading = false;
        });
        return;
      }

      setState(() {
        _tasks = searchResults
            .map((video) => _DownloadTask(
                  video.title,
                  video.id.value,
                  video.author,
                  'https://yt3.ggpht.com/ytc/default',
                  video.duration?.toString() ?? 'Unknown duration',
                  0.0,
                  'Pending',
                  audioOnly: false,
                ))
            .toList();
        statusMessage = 'Found ${searchResults.length} videos.';
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching YouTube: $e')),
      );
      setState(() {
        isLoading = false;
        statusMessage = '';
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    ClipboardData? clipboardData =
        await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null) {
      setState(() {
        _searchController.text = clipboardData.text!;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Copy Not found'),
        duration: const Duration(seconds: 1),
        action: SnackBarAction(
          label: 'Cancel',
          onPressed: () {},
        ),
      ));
    }
  }

  Future<void> _downloadVideo(String videoId, _DownloadTask? task) async {
    var downloadsDir =
        Directory('/storage/emulated/0/Download/SnapYT/SearchYoutubeVideo');
    if (isMobile()) {
      downloadsDir =
          Directory('/storage/emulated/0/Download/SnapYT/SearchYoutubeVideo');
    } else if (isDesktop()) {
      downloadsDir = Directory('/snapYT/SearchYoutubeVideo');
    }
    try {
      if (!downloadsDir.existsSync()) {
        downloadsDir.createSync(recursive: true);
      }

      final video = await yt.videos.get(videoId);

      // Use `ytClients` to fetch the manifest
      final manifest = await yt.videos.streams.getManifest(
        video.id.value,
        ytClients: [
          YoutubeApiClient.safari,
          YoutubeApiClient.androidVr,
        ],
      );

      if (manifest.muxed.isEmpty) {
        throw Exception('No video streams available for download.');
      }

      final streamInfo = manifest.muxed.withHighestBitrate();
      final filePath =
          '${downloadsDir.path}/${_sanitizeFileName(video.title)}.mp4';
      final file = File(filePath);
      final stream = yt.videos.streams.get(streamInfo);

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

  Future<void> _downloadAudio(String videoId, _DownloadTask? task) async {
    var downloadsDir =
        Directory('/storage/emulated/0/Download/SnapYT/SearchYoutubeAudio');
    if (isMobile()) {
      downloadsDir =
          Directory('/storage/emulated/0/Download/SnapYT/SearchYoutubeAudio');
    } else if (isDesktop()) {
      downloadsDir = Directory('/snapYT/SearchYoutubeAudio');
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

  String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  Future<void> _showDownloadOptionsDialog(
      String videoId, _DownloadTask? task) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Download Options'),
          content: const Text('Choose download type:'),
          actions: <Widget>[
            TextButton(
              child: const Text('Video'),
              onPressed: () {
                Navigator.of(context).pop();
                _downloadVideo(videoId, task);
              },
            ),
            TextButton(
              child: const Text('Audio'),
              onPressed: () {
                Navigator.of(context).pop();
                _downloadAudio(videoId, task);
              },
            ),
          ],
        );
      },
    );
  }

  downloadAll() async {
    if (!await _requestPermissions()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission not granted')),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Download Options'),
          content: const Text('Choose download type for all videos:'),
          actions: <Widget>[
            TextButton(
              child: const Text('Video'),
              onPressed: () async {
                Navigator.of(context).pop();
                setState(() {
                  _isCanceled = false;
                });
                for (final task in _tasks) {
                  if (_isCanceled) break;
                  await _downloadVideo(task.id, task);
                }
                if (!_isCanceled) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All videos downloaded!')),
                  );
                }
              },
            ),
            TextButton(
              child: const Text('Audio'),
              onPressed: () async {
                Navigator.of(context).pop();
                setState(() {
                  _isCanceled = false;
                });
                for (final task in _tasks) {
                  if (_isCanceled) break;
                  await _downloadAudio(task.id, task);
                }
                if (!_isCanceled) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('All audio files downloaded!')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.enter): SearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyX): CutIntent(),
      },
      child: Actions(
        actions: {
          SearchIntent: CallbackAction<SearchIntent>(
            onInvoke: (intent) {
              _searchYouTube(_searchController.text);
              return null;
            },
          ),
          CutIntent: CallbackAction<CutIntent>(
            onInvoke: (intent) {
              final text = _searchController.text;
              _searchController.clear();
              Clipboard.setData(ClipboardData(text: text));
              return null;
            },
          ),
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('YouTube Downloader'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      onPressed: () => _searchYouTube(_searchController.text),
                      icon: const Icon(Icons.search),
                    ),
                    labelText: 'Search YouTube',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.topLeft,
                  child: ElevatedButton.icon(
                    onPressed: _pasteFromClipboard,
                    label: const Text('Paste'),
                    icon: const Icon(Icons.paste),
                  ),
                ),
                const SizedBox(height: 10),
                const SizedBox(height: 20),
                if (_tasks.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        final task = _tasks[index];
                        final videoThumbnailUrl =
                            'https://img.youtube.com/vi/${task.id}/mqdefault.jpg';

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          child: ListTile(
                            leading: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Image.network(
                                  videoThumbnailUrl,
                                  width: 120,
                                  height: 68,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.broken_image);
                                  },
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  color: Colors.black.withOpacity(0.7),
                                  child: Text(
                                    task.duration,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            title: Text(
                              task.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.grey[300],
                                  child: ClipOval(
                                    child: Image.network(
                                      task.channelThumbnail,
                                      width: 24,
                                      height: 24,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.person,
                                          size: 16,
                                          color: Colors.grey,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        task.channelName,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      Text(
                                        task.status,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              onPressed: () async {
                                if (!await _requestPermissions()) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Storage permission not granted')),
                                  );
                                  return;
                                }
                                await _showDownloadOptionsDialog(task.id, task);
                              },
                              icon: const Icon(Icons.download),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                if (_tasks.isNotEmpty) ...[
                 Row(
                  children: [
                     Padding(
                    padding: const EdgeInsets.all(4),
                    child: ElevatedButton(
                      onPressed: () {
                        downloadAll();
                      },
                      child: const Text('Download All'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: ElevatedButton(
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
                  ),
                  ],
                 ),
                ],
                if (isDownloading) ...[
                  const CircularProgressIndicator(),
                  Text(statusMessage),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DownloadTask {
  final String title;
  final String id;
  final String channelName;
  final String channelThumbnail;
  final String duration;
  double progress;
  String status;
  final bool audioOnly;

  _DownloadTask(
    this.title,
    this.id,
    this.channelName,
    this.channelThumbnail,
    this.duration,
    this.progress,
    this.status, {
    this.audioOnly = false,
  });
}

class CutIntent extends Intent {}

class SearchIntent extends Intent {}
