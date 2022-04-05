import 'dart:io';

import 'package:media_organizer_flutter/util.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

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
    final dirPath = await FilePicker.platform
        .getDirectoryPath(dialogTitle: 'Select image directory');
    if (dirPath != null) {
      final mediaInfo = await updateMediaInfo(dirPath, onProgress: (entryPath) {
        setState(() {
          _status = 'Processing file $entryPath';
        });
      });
      setState(() {
        _displayImages =
            mediaInfo.map((md) => getThumbPath(dirPath, md.name)).toList();
        _status = 'Processed ${_displayImages.length} images';
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
                GestureDetector(
                  child: SizedBox(
                    child: Image.file(File(imgPath)),
                    width: 128,
                    height: 128,
                  ),
                  onTap: () {
                    debugPrint('Image $imgPath');
                  },
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
