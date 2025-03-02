library upload_util;

import 'dart:async';
import 'dart:convert' as convert;
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:blurhash_ffi/blurhash_ffi.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/media_information.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/media_information_session.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/stream_information.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:im_video_compressor/im_video_compressor.dart';
import 'package:image/image.dart' as img;
import 'package:image_compression_flutter/flutter_image_compress.dart';
import 'package:jxim_client/logs/log_libs.dart';
import 'package:jxim_client/managers/cache_media_mgr.dart';
import 'package:jxim_client/managers/interface.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/network/servers_uri_mgr.dart';
import 'package:jxim_client/object/upload_ext.dart';
import 'package:jxim_client/object/video.dart';
import 'package:jxim_client/tasks/data_analytics_task.dart';
import 'package:jxim_client/tasks/schedule_task.dart';
import 'package:jxim_client/transfer/download_mgr.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/file_type_util.dart';
import 'package:jxim_client/utils/io.dart';
import 'package:jxim_client/utils/net/app_exception.dart';
import 'package:jxim_client/utils/net/custom_request.dart';
import 'package:jxim_client/utils/net/dio/dio_util.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:jxim_client/utils/utility.dart';
import 'package:path/path.dart' as path;
import 'package:pdf_render/pdf_render.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

part 'document/document_mgr.dart';
part 'document/document_upload_request.dart';
part 'handle_base.dart';
part 'image/image_mgr.dart';
part 'image/image_upload_request.dart';
part 'queue_upload_task_mgr.dart';
part 'upload_queue.dart';
part 'video/video_mgr.dart';
part 'video/video_upload_request.dart';
