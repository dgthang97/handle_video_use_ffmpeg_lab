import 'dart:io';
import 'dart:math';

import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_ffmpeg/media_information.dart';
import 'package:handle_video_lab/apis/encoding_provider.dart';
import 'package:handle_video_lab/models/video_info.dart';
import 'package:handle_video_lab/widgets/player.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class EncodeView extends StatefulWidget {
  const EncodeView({Key? key}) : super(key: key);

  @override
  _EncodeViewState createState() => _EncodeViewState();
}

class _EncodeViewState extends State<EncodeView> {
  int _videoTime = 0;

  String? _localVideoEndCodedPath;

  File? _sourceFile;
  MediaInformation? _sourceInfo;
  String _sourceFileSize = '';
  String _aspectRatio = '';
  String _sourceDuration = '';

  String _outputType = 'MP4';
  int _outputQuality = 50;
  String _outputFileSize = '';
  String _processingTime = '';

  double _progressEncode = 0;

  bool _inProgressing = false;

  @override
  void initState() {
    super.initState();
    EncodingProvider.enableStatisticsCallback((statistics) {
      setState(() {
        _progressEncode = statistics.time / _videoTime;
        print('object' + _progressEncode.toString());
      });
    });
  }

  List<Widget> _buildDecodeOption() {
    return _sourceFile != null
        ? [
            Divider(height: 2, color: Colors.black),
            Center(
              child: Text('Encode video: ', style: TextStyle(fontSize: 18)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Text('Type:'),
                  const SizedBox(width: 10),
                  DropdownButton(
                    value: _outputType,
                    items: <String>['MP4', 'HLS'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: new Text(value),
                      );
                    }).toList(),
                    onChanged: (v) {
                      setState(() {
                        _outputType = v.toString();
                      });
                    },
                  )
                ],
              ),
            ),
            // _outputType != 'HLS'
            //     ? Padding(
            //         padding: const EdgeInsets.all(8.0),
            //         child: Row(
            //           children: [
            //             Text('Quality:'),
            //             const SizedBox(width: 10),
            //             DropdownButton(
            //               value: _outputQuality,
            //               items: <int>[10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
            //                   .map((int value) {
            //                 return DropdownMenuItem<int>(
            //                   value: value,
            //                   child: new Text(value.toString()),
            //                 );
            //               }).toList(),
            //               onChanged: _outputType == 'HLS'
            //                   ? null
            //                   : (v) {
            //                       setState(() {
            //                         _outputQuality = int.parse(v.toString());
            //                       });
            //                     },
            //             )
            //           ],
            //         ),
            //       )
            //     : const SizedBox(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextButton(
                style: ButtonStyle(
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                          side: BorderSide(color: Colors.red))),
                ),
                onPressed: () {
                  _processVideo(_sourceFile!, decodeType: _outputType);
                  setState(() {
                    _localVideoEndCodedPath = null;
                    _progressEncode = 0;
                  });
                },
                child: Text('Encode video'),
              ),
            ),
            _inProgressing
                ? LinearProgressIndicator(
                    value: _progressEncode > 1 ? 0 : _progressEncode,
                  )
                : const SizedBox(),
            _localVideoEndCodedPath != null
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Time encode: $_processingTime'),
                  )
                : const SizedBox(),
            _localVideoEndCodedPath != null
                ? Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('Video output:\n\n' +
                              'Length: $_outputFileSize\n\nNOTE: If video is HLS type then when play output it\'s only a fragment in video source!'),
                        ),
                      ),
                      TextButton(
                        style: ButtonStyle(
                          shape: MaterialStateProperty.all<
                                  RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                  side: BorderSide(color: Colors.lightGreen))),
                        ),
                        onPressed: () {
                          if (_localVideoEndCodedPath != null) {
                            _showPlayVideoDialog(
                                context, _localVideoEndCodedPath!);
                          }
                        },
                        child: Text('Play video output'),
                      ),
                      const SizedBox(width: 8),
                    ],
                  )
                : const SizedBox(width: 8),
          ]
        : [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Handle video quality')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          GestureDetector(
            onTap: () async {
              _showLoaderDialog(context);
              _sourceInfo = await _takeVideo();
              _videoTime =
                  EncodingProvider.getDuration(_sourceInfo?.getStreams() ?? []);
              _sourceDuration = (_videoTime / 1000).toString() + ' s';

              _aspectRatio = EncodingProvider.getAspectRatio(
                      _sourceInfo?.getStreams() ?? [])
                  .toString();
              _sourceFileSize = filesize(EncodingProvider.getFileSize(
                  _sourceInfo?.getMediaProperties() ?? {}));
              Navigator.pop(context);
              _localVideoEndCodedPath = null;
              _progressEncode = 0;
              setState(() {});
            },
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(8.0),
              padding: const EdgeInsets.all(6.0),
              decoration:
                  BoxDecoration(border: Border.all(color: Colors.blueAccent)),
              child: Text(
                  _sourceInfo == null ? 'Select video' : _sourceFile!.path),
            ),
          ),
          _sourceFile != null
              ? Center(
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('Video source Info:\n\n' +
                              'Duration: $_sourceDuration\nLength: $_sourceFileSize\nAspect Ratio: $_aspectRatio'),
                        ),
                      ),
                      TextButton(
                        style: ButtonStyle(
                            shape: MaterialStateProperty.all<
                                    RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                    side:
                                        BorderSide(color: Colors.lightBlue)))),
                        onPressed: () {
                          _showPlayVideoDialog(context, _sourceFile!.path);
                        },
                        child: Text('Play video source'),
                      ),
                      const SizedBox(width: 8)
                    ],
                  ),
                )
              : const SizedBox(),
          ..._buildDecodeOption(),
        ],
      ),
    );
  }

  String getFileExtension(String fileName) {
    final exploded = fileName.split('.');
    return exploded[exploded.length - 1];
  }

  Future<void> _processVideo(
    File rawVideoFile, {
    String decodeType = 'HLS',
    int quality = 50,
  }) async {
    if (_inProgressing) return;
    Stopwatch stopwatch = new Stopwatch()..start();
    _progressEncode = 0;
    _inProgressing = true;
    final String rand = '${new Random().nextInt(10000)}';
    final videoName = 'video$rand';
    final Directory? extDir = await getApplicationDocumentsDirectory();
    final outDirPath = '${extDir?.path}/$videoName';
    final videosDir = new Directory(outDirPath);
    videosDir.createSync(recursive: true);

    final encodedFilesDir = decodeType == 'HLS'
        ? await EncodingProvider.encodeHLS(
            _sourceFile!.path, outDirPath, quality)
        : await EncodingProvider.encodeMP4(
            _sourceFile!.path, outDirPath, quality);

    _localVideoEndCodedPath = encodedFilesDir;

    if (decodeType == 'HLS') {
      List<FileSystemEntity> files =
          Directory(_localVideoEndCodedPath ?? '').listSync();

      num totalSize = 0;
      for (var f in files) {
        if (f is File) {
          var size = await f.length();
          totalSize += size;
        }
      }
      _outputFileSize = filesize(totalSize);
      var fileFullHD = files
          .firstWhere((element) => element.path.contains('fileSequence_0.ts'));
      _localVideoEndCodedPath = (fileFullHD as File).path;
    } else {
      var f = File(encodedFilesDir);
      _outputFileSize = filesize(await f.length());
    }

    setState(() {
      _processingTime =
          (stopwatch.elapsedMilliseconds / 1000).toString() + ' s';
      _inProgressing = false;
    });
  }

  Future<MediaInformation> _takeVideo() async {
    File videoFile;
    var video = await ImagePicker().pickVideo(source: ImageSource.gallery);
    videoFile = File(video?.path ?? '');
    _sourceFile = videoFile;
    final info = await EncodingProvider.getMediaInformation(videoFile.path);
    return info;
  }

  _showPlayVideoDialog(BuildContext context, String videoPath) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return Player(
          key: Key(videoPath),
          video: VideoInfo(videoUrl: videoPath),
        );
      },
    );
  }

  _showLoaderDialog(BuildContext context) {
    AlertDialog alert = AlertDialog(
      content: new Row(
        children: [
          CircularProgressIndicator(),
          Container(
              margin: EdgeInsets.only(left: 7), child: Text("Loading...")),
        ],
      ),
    );
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
