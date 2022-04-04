import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as imglib;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media Organizer',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const MyHomePage(title: 'Browsing'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _imageDir = '';
  String _status = '';
  List<String> _displayImages = [];

  void _selectDirectory() async {
    final extensions = Set<String>.from({'.png', '.jpg', '.jpeg', '.webp'});
    final dirPath = await FilePicker.platform
        .getDirectoryPath(dialogTitle: 'Select image directory');
    if (dirPath != null) {
      // Scan all files in the directory
      final dir = Directory(dirPath);

      final thumbsDirPath = path.join(dirPath, '.thumbs');
      final thumbsDir = Directory(thumbsDirPath);
      // Create thumbs dir if it doesn't exist yet
      if (!(await thumbsDir.exists())) {
        await (thumbsDir.create());
      }

      // Process file entries
      List<String> thumbPaths = [];
      await for (var entry in dir.list()) {
        // final stat = await entry.stat();
        // final fileSize = stat.size;
        final entryPath = entry.path;
        if (extensions.contains(path.extension(entryPath).toLowerCase())) {
          setState(() {
            _status = 'Processing file $entryPath';
          });
          final imageFile = File(entryPath);
          final image = imglib.decodeImage(imageFile.readAsBytesSync())!;

          int? w;
          int? h;
          if (image.width >= image.height) {
            w = 128;
          } else {
            h = 128;
          }

          // Resize the image to a max 128x128 thumbnail (maintaining the aspect ratio).
          final thumbImage = imglib.copyResize(image, width: w, height: h);

          // Save thumbnail
          final thumbImagePath = path.join(thumbsDirPath,
              '_' + path.basenameWithoutExtension(entryPath) + '.png');
          await File(thumbImagePath).writeAsBytes(imglib.encodePng(thumbImage));
          thumbPaths.add(thumbImagePath);
        }
      }

      setState(() {
        _status = 'Processed ${_displayImages.length} images';
        _imageDir = dirPath;
        _displayImages = thumbPaths;
      });
    } else {
      // User canceled
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title + ': ' + _imageDir),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_status.isNotEmpty) Text(_status),
            Wrap(spacing: 20, runSpacing: 20, children: [
              for (var imgPath in _displayImages)
                SizedBox(
                  child: Image.file(File(imgPath)),
                  width: 128,
                  height: 128,
                ),
            ]),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _selectDirectory,
        tooltip: 'Load dir',
        child: const Icon(Icons.add),
      ),
    );
  }
}
