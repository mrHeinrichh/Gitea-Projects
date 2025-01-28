library image_libs;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jxim_client/managers/object_mgr.dart';
import 'package:jxim_client/managers/task/upload_lib/upload_util.dart';
import 'package:jxim_client/managers/utils.dart';
import 'package:jxim_client/transfer/download_mgr.dart';
import 'package:jxim_client/transfer/download_task.dart';
import 'package:jxim_client/utils/config.dart';
import 'package:jxim_client/utils/photo_view_util.dart';
import 'package:jxim_client/widgets/image/remote_image_base.dart';
import 'package:jxim_client/widgets/image/remote_image_data.dart';
import 'package:photo_view/photo_view.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

part 'extended_photo_view.dart';
part 'gaussian_image.dart';
part 'remote_image.dart';
part 'remote_image_gaussian.dart';
part 'remote_image_v2.dart';
