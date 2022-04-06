import 'dart:io';

import 'package:media_organizer_flutter/util.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MediaOrganizer());
}

class MediaOrganizer extends StatelessWidget {
  const MediaOrganizer({Key? key}) : super(key: key);

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
  String _status = '';
  String _viewImage = '';
  MediaCollectionInfo _mediaCollectionInfo =
      MediaCollectionInfo(dirPath: '', images: [], subdirectories: []);

  void _selectDirectory() async {
    final dirPath = await FilePicker.platform
        .getDirectoryPath(dialogTitle: 'Select image directory');
    if (dirPath != null) {
      await openImageDirectory(dirPath);
    } else {
      // User canceled
    }
  }

  // Future<void> openImageDirectory(String dirPath) async {
  //   var mediaInfo = await getMediaInfo(dirPath);
  //   if (mediaInfo == null) {
  //     debugPrint('No media info found, updating..');
  //     mediaInfo = await updateMediaInfo(dirPath, onProgress: (entryPath) {
  //       setState(() {
  //         _status = 'Processing file $entryPath';
  //       });
  //     });
  //   }
  //   for (var md in mediaInfo.images) {
  //     debugPrint(md.toString());
  //   }
  //   setState(() {
  //     if (mediaInfo != null) {
  //       _mediaCollectionInfo = mediaInfo;
  //     }
  //     _status = 'Processed ${_mediaCollectionInfo.images.length} images';
  //     mediaInfo?.dirPath = dirPath;
  //   });
  // }

  Future<void> openImageDirectory(String dirPath) async {
    final mci =
        MediaCollectionInfo(dirPath: dirPath, images: [], subdirectories: []);
    await getMediaInfo2(mci);
    final numUpdates = await updateMediaInfoFiles(mci);
    if (numUpdates > 0) {
      writeMediaInfo(mci);
    }
    setState(() {
      _mediaCollectionInfo = mci;
      _status = 'Processed ${_mediaCollectionInfo.images.length} images';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title + ': ' + _mediaCollectionInfo.dirPath),
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
                    GestureDetector(
                      child: const SizedBox(
                        child: Text('UP'),
                        width: 128,
                        height: 128,
                      ),
                      onTap: () {
                        setState(() {
                          openImageDirectory(
                              parentPath(_mediaCollectionInfo.dirPath));
                        });
                      },
                    ),
                    for (var sdName in _mediaCollectionInfo.subdirectories)
                      GestureDetector(
                        child: SizedBox(
                          child: Text(sdName),
                          width: 128,
                          height: 128,
                        ),
                        onTap: () {
                          setState(() {
                            openImageDirectory(
                                joinPath(_mediaCollectionInfo.dirPath, sdName));
                          });
                        },
                      ),
                    for (var md in _mediaCollectionInfo.images)
                      GestureDetector(
                        child: SizedBox(
                          child: Image.file(File(getThumbPath(
                              _mediaCollectionInfo.dirPath, md.name))),
                          width: 128,
                          height: 128,
                        ),
                        onTap: () {
                          setState(() {
                            _viewImage = getImagePath(
                                _mediaCollectionInfo.dirPath, md.name);
                          });
                        },
                      ),
                  ]),
                ],
              ),
            ),
            if (_viewImage.isNotEmpty)
              Expanded(
                  child: Image.file(File(
                      getImagePath(_mediaCollectionInfo.dirPath, _viewImage)))),
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
