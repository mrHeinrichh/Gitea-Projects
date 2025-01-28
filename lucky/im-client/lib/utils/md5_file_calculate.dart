library file_md5;

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:async/async.dart';
import 'package:jxim_client/utils/debug_info.dart';

class FileMD5 {
  static Future<Digest?> get({
    required Stream<List<int>> stream,
    required int size,
    int chunkSize = 4096 * 64,
    void Function(bool done, double progress)? onProgress,
    ValueNotifier<bool>? canceled,
  }) async {
    final startTime = kDebugMode ? DateTime.now().millisecondsSinceEpoch : 0;

    final reader = ChunkedStreamReader(stream);
    // const chunkSize = 4096 * 64;
    var output = AccumulatorSink<Digest>();
    var input = md5.startChunkedConversion(output);

    var readed = 0;

    try {
      while (!(canceled?.value ?? false)) {
        final chunk = await reader.readChunk(chunkSize);
        if (chunk.isEmpty) {
          break;
        }

        input.add(chunk);

        readed += chunk.length;

        if (null != onProgress) {
          onProgress(false, readed.toDouble() / size);
        }
      }
    } finally {
      reader.cancel();
      input.close();
    }

    if (canceled?.value ?? false) {
      return null;
    }

    if (kDebugMode) {
      final delta = DateTime.now().millisecondsSinceEpoch - startTime;
      pdebug('MD5 time $delta');
    }

    if (null != onProgress) {
      onProgress(true, 1.0);
    }

    return output.events.single;
  }
}
