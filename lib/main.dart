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
  String _viewImage = '';
  List<MediaDescriptor> _mediaDescriptors = [];

  void _selectDirectory() async {
    final dirPath = await FilePicker.platform
        .getDirectoryPath(dialogTitle: 'Select image directory');
    if (dirPath != null) {
      var mediaInfo = await getMediaInfo(dirPath);
      if (mediaInfo == null) {
        debugPrint('No media info found, updating..');
        mediaInfo = await updateMediaInfo(dirPath, onProgress: (entryPath) {
          setState(() {
            _status = 'Processing file $entryPath';
          });
        });
      }
      for (var md in mediaInfo) {
        debugPrint(md.toString());
      }
      setState(() {
        if (mediaInfo != null) {
          _mediaDescriptors = mediaInfo;
        }
        _status = 'Processed ${_mediaDescriptors.length} images';
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
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  if (_status.isNotEmpty) Text(_status),
                  Wrap(spacing: 20, runSpacing: 20, children: [
                    for (var md in _mediaDescriptors)
                      GestureDetector(
                        child: SizedBox(
                          child: Image.file(
                              File(getThumbPath(_imageDir, md.name))),
                          width: 128,
                          height: 128,
                        ),
                        onTap: () {
                          setState(() {
                            _viewImage = getImagePath(_imageDir, md.name);
                          });
                        },
                      ),
                  ]),
                ],
              ),
            ),
            if (_viewImage.isNotEmpty)
              Expanded(
                  child: Image.file(File(getImagePath(_imageDir, _viewImage)))),
            if (_viewImage.isEmpty) const Text("No image selected"),
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
