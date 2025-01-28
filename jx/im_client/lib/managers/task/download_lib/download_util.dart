library download_util;

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:jxim_client/tasks/data_analytics_task.dart';
import 'package:jxim_client/tasks/schedule_task.dart';
import 'package:jxim_client/transfer/download_mgr.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/dio/dio_util.dart';
import 'package:jxim_client/utils/net/download_mgr.dart';
import 'package:jxim_client/utils/utility.dart';

part 'download_queue.dart';

part 'queue_download_task_mgr.dart';
