import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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

  void _selectDirectory() async {
    final extensions = Set<String>.from({'.png', '.jpg', '.jpeg', '.webp'});
    final dirPath = await FilePicker.platform
        .getDirectoryPath(dialogTitle: 'Select image directory');
    if (dirPath != null) {
      // Scan all files in the directory
      final dir = Directory(dirPath);

      // Create thumbs dir
      final thumbsDirPath = path.join(dirPath, '.thumbs');
      final thumbsDir = Directory(thumbsDirPath);
      if (!(await thumbsDir.exists())) {
        await (thumbsDir.create());
      }
      await for (var entry in dir.list()) {
        final entryPath = entry.path;
        if (extensions.contains(path.extension(entryPath))) {
          final imageFile = File(entryPath);
          final image = decodeImage(imageFile.readAsBytesSync())!;

          // Resize the image to a 120x? thumbnail (maintaining the aspect ratio).
          final thumbImage = copyResize(image, width: 120);

          // Save thumbnail
          final thumbImagePath =
              path.join(thumbsDirPath, '_' + path.basename(entryPath));
          File(thumbImagePath).writeAsBytesSync(encodePng(thumbImage));
        }
      }

      setState(() {
        _imageDir = dirPath;
      });
    } else {
      // User canceled
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Image dir:',
            ),
            Text(
              _imageDir,
              style: Theme.of(context).textTheme.headline4,
            ),
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
