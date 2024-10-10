library log_libs;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:get/get_utils/src/platform/platform.dart';
import 'package:jxim_client/managers/call_mgr.dart';
import 'package:jxim_client/managers/interface.dart';
import 'package:jxim_client/managers/network_mgr.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/object/chat/chat.dart';
import 'package:jxim_client/utils/app_version_utils.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/debug_info.dart';
import 'package:jxim_client/utils/net/custom_request.dart';
import 'package:jxim_client/utils/net/response_data.dart';
import 'package:jxim_client/utils/platform_utils.dart';
import 'package:logger/logger.dart';
import 'package:synchronized/synchronized.dart';
part 'log_base.dart';
part 'log_mgr.dart';
part 'metrics_mgr.dart';