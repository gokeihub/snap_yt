// // ignore_for_file: use_build_context_synchronously

//! this code not use

// import 'package:flutter/material.dart';
// import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
// import 'package:ffmpeg_kit_flutter/return_code.dart';


// class ConverterScreen extends StatefulWidget {
//   const ConverterScreen({super.key});

//   @override
//   ConverterScreenState createState() => ConverterScreenState();
// }

// class ConverterScreenState extends State<ConverterScreen> {
//   final TextEditingController _urlController = TextEditingController();
//   bool _isConverting = false;
//   String? _outputFilePath;

//   Future<void> convertM3U8ToMP4(String m3u8Url) async {
//     setState(() {
//       _isConverting = true;
//       _outputFilePath = null;
//     });

//     try {
//       final outputPath = '/storage/emulated/0/Download/SnapYT/output_video.mp4';

//       final command = '-i "$m3u8Url" -c copy "$outputPath"';

//       await FFmpegKit.execute(command).then((session) async {
//         final returnCode = await session.getReturnCode();

//         if (ReturnCode.isSuccess(returnCode)) {
//           setState(() {
//             _outputFilePath = outputPath;
//             _isConverting = false;
//           });
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Conversion successful!')),
//           );
//         } else {
//           final failStackTrace = await session.getFailStackTrace();
//           setState(() {
//             _isConverting = false;
//           });
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Conversion failed: $failStackTrace')),
//           );
//         }
//       });
//     } catch (e) {
//       setState(() {
//         _isConverting = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: ${e.toString()}')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('M3U8 to MP4 Converter')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextField(
//               controller: _urlController,
//               decoration: InputDecoration(
//                 labelText: 'Enter or Paste .m3u8 URL',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: _isConverting
//                   ? null
//                   : () => convertM3U8ToMP4(_urlController.text.trim()),
//               child: Text(_isConverting ? 'Converting...' : 'Convert to MP4'),
//             ),
//             if (_outputFilePath != null) ...[
//               SizedBox(height: 16),
//               Text('Output File: $_outputFilePath'),
//             ]
//           ],
//         ),
//       ),
//     );
//   }
// }
