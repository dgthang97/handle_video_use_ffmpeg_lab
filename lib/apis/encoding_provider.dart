import 'dart:io';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:flutter_ffmpeg/media_information.dart';
import 'package:flutter_ffmpeg/stream_information.dart';

removeExtension(String path) {
  final str = path.substring(0, path.length - 4);
  return str;
}

class EncodingProvider {
  static final FlutterFFmpeg _encoder = FlutterFFmpeg();
  static final FlutterFFprobe _probe = FlutterFFprobe();
  static final FlutterFFmpegConfig _config = FlutterFFmpegConfig();

  static Future<String> encodeHLS(videoPath, outDirPath, quality) async {
    assert(File(videoPath).existsSync());

    // Source https://hlsbook.net/creating-a-master-playlist-with-ffmpeg/
    final arguments = '-y -i $videoPath ' +
        '-preset ultrafast -g 48 -sc_threshold 0 ' +
        '-map 0:0 -map 0:1 ' +
        '-c:v 1280x720 -c:v libx264 -b:v 3200k ' +
        '-c:a copy ' +
        '-var_stream_map "v:0,a:0 " ' +
        '-master_pl_name master.m3u8 ' +
        '-f hls -hls_time 6 -hls_list_size 0 ' +
        '-hls_segment_filename "$outDirPath/fileSequence_%d.ts" ' +
        '$outDirPath/playlistVariant.m3u8';

    final int rc = await _encoder.execute(arguments);
    assert(rc == 0);

    return outDirPath;
  }

  static Future<String> encodeMP4(videoPath, outDirPath, quality) async {
    assert(File(videoPath).existsSync());

    final arguments = '-y -i $videoPath ' +
        '-vf scale=1280:720 ' +
        '-preset ultrafast -crf 28 ' +
        '-c:a copy ' +
        '$outDirPath.mp4';

    final int rc = await _encoder.execute(arguments);
    assert(rc == 0);

    return outDirPath + '.mp4';
  }

  static double getAspectRatio(List<StreamInformation> infos) {
    int width = 0;
    int height = 0;
    for (var info in infos) {
      var properties = info.getAllProperties();
      if (properties.containsKey('display_aspect_ratio')) {
        var ratios = properties['display_aspect_ratio'].toString().split(':');
        return int.parse(ratios[1]) / int.parse(ratios[0]);
      }
    }

    for (var info in infos) {
      var properties = info.getAllProperties();
      if (properties.containsKey('width') || properties.containsKey('height')) {
        width = properties['width'];
        height = properties['height'];
        return height / width;
      }
    }

    return 0;
  }

  static Future<String> getThumb(videoPath, width, height) async {
    assert(File(videoPath).existsSync());

    final String outPath = '$videoPath.jpg';
    final arguments =
        '-y -i $videoPath -vframes 1 -an -s ${width}x$height -ss 1 $outPath';

    final int rc = await _encoder.execute(arguments);
    assert(rc == 0);
    assert(File(outPath).existsSync());

    return outPath;
  }

  static void enableStatisticsCallback(StatisticsCallback cb) {
    return _config.enableStatisticsCallback(cb);
  }

  static Future<void> cancel() async {
    await _encoder.cancel();
  }

  static Future<MediaInformation> getMediaInformation(String path) async {
    assert(File(path).existsSync());

    return await _probe.getMediaInformation(path);
  }

  static int getDuration(List<StreamInformation> infos) {
    for (var info in infos) {
      var properties = info.getAllProperties();
      if (properties['codec_type'] == 'video' && properties.containsKey('duration')) {
        return (double.parse(
            info.getAllProperties()['duration'].toString()) * 1000).round();
      }
    }
    return 0;
  }

  static int getFileSize(Map infos) {
    if (infos.containsKey('size')) {
      return int.parse(infos['size']);
    }
    return 0;
  }

  static void enableLogCallback(LogCallback logCallback) {
    _config.enableLogCallback(logCallback);
  }
}
