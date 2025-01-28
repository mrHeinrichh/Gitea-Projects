// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FLTPackageInfoPlusPlugin.h"

@implementation FLTPackageInfoPlusPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel =
      [FlutterMethodChannel methodChannelWithName:@"dev.fluttercommunity.plus/package_info"
                                  binaryMessenger:[registrar messenger]];
  FLTPackageInfoPlusPlugin* instance = [[FLTPackageInfoPlusPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([call.method isEqualToString:@"getAll"]) {
      NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
      [dic setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]
       ?: [NSNull null] forKey:@"appName"];
      [dic setObject:[[NSBundle mainBundle] bundleIdentifier]
       ?: [NSNull null] forKey:@"packageName"];
      [dic setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]
       ?: [NSNull null] forKey:@"version"];
      [dic setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]
       ?: [NSNull null] forKey:@"buildNumber"];
      [dic setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"flutter_son_channel"]
       ?: [NSNull null] forKey:@"flutterSonChannel"];
      
      result(dic);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end
