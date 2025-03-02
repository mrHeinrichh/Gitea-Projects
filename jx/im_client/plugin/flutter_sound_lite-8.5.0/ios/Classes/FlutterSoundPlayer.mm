/*
 * Copyright 2018, 2019, 2020, 2021 Dooboolab.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the Mozilla Public License version 2 (MPL2.0),
 * as published by the Mozilla organization.
 *
 * Flutter-Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * MPL General Public License for more details.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */





#import "FlutterSoundPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import <flutter_sound_core/FlautoPlayer.h>
#import <flutter_sound_core/FlautoTrackPlayer.h>
#import <flutter_sound_core/FlautoTrack.h>
#import "FlutterSoundPlayerManager.h"
         
 
//-------------------------------------------------------------------------------------------------------------------------------

@implementation FlutterSoundPlayer
{
}

// ----------------------------------------------  callback ---------------------------------------------------------------------------

- (void)openPlayerCompleted: (bool)success
{
       [self invokeMethod: @"openPlayerCompleted" boolArg: success success: success];
}


- (void)closePlayerCompleted: (bool)success
{
       [self invokeMethod: @"closePlayerCompleted" boolArg: success success: success];
}


- (void)startPlayerCompleted: (bool)success duration: (long)duration
{
     
        int d = (int)duration;
        NSNumber* nd = [NSNumber numberWithInt: d];
        NSDictionary* dico = @{ @"slotNo": [NSNumber numberWithInt: slotNo], @"state":  [self getPlayerStatus], @"duration": nd, @"success": @YES };
        [self invokeMethod:@"startPlayerCompleted" dico: dico ];
}

- (void)pausePlayerCompleted: (bool)success
{
       [self invokeMethod: @"pausePlayerCompleted" boolArg: success success: success];
}

- (void)resumePlayerCompleted: (bool)success
{
       [self invokeMethod: @"resumePlayerCompleted" boolArg: success success: success];
}


- (void)stopPlayerCompleted: (bool)success
{
       [self invokeMethod: @"stopPlayerCompleted" boolArg: success success: success];
}



- (void)needSomeFood: (int) ln
{
        [self invokeMethod:@"needSomeFood" numberArg: [NSNumber numberWithInt: ln]  success: @YES ];
}

- (void)updateProgressPosition: (long)position duration: (long)duration
{
                NSNumber* p = [NSNumber numberWithLong: position];
                NSNumber* d = [NSNumber numberWithLong: duration];
                NSDictionary* dico = @{ @"slotNo": [NSNumber numberWithInt: self ->slotNo], @"state": [self getPlayerStatus], @"position": p, @"duration": d, @"playerStatus": [self getPlayerStatus] };
                [self invokeMethod:@"updateProgress" dico: dico  ];
}

- (void)audioPlayerDidFinishPlaying: (BOOL)flag
{
        [self log: DBG msg: @"IOS:--> @audioPlayerDidFinishPlaying"];
        [self invokeMethod:@"audioPlayerFinishedPlaying" numberArg: [self getPlayerStatus] success: YES];
        [self log: DBG msg: @"IOS:<-- @audioPlayerDidFinishPlaying"];
}

- (void)pause
{
        [self invokeMethod:@"pause" numberArg: [self getPlayerStatus] success: @YES ];
}

- (void)resume
{
        [self invokeMethod:@"resume" numberArg: [self getPlayerStatus]  success: @YES ];
}

- (void)skipForward
{
        [self invokeMethod:@"skipForward" numberArg: [self getPlayerStatus]  success: @YES ];

}

- (void)skipBackward
{
        [self invokeMethod:@"skipBackward" numberArg: [self getPlayerStatus]  success: @YES ];

}


// --------------------------------------------------------------------------------------------------------------------------

// BE CAREFUL : TrackPlayer must instance FlautoTrackPlayer !!!!!
- (FlutterSoundPlayer*)init: (FlutterMethodCall*)call
{
        NSNumber* withUI = call.arguments[@"withUI"];
        if (withUI.intValue == 0)
                flautoPlayer = [ [FlautoPlayer alloc] init: self];
       else
                flautoPlayer = [ [FlautoTrackPlayer alloc] init: self];
        return [super init: call]; // Init Session
}

- (FlutterSoundPlayer*) init
{
        return [super init];
}

- (void)isDecoderSupported:(t_CODEC)codec result: (FlutterResult)result
{
        [self log: DBG msg: @"IOS:--> isDecoderSupported"];

        NSNumber*  b = [NSNumber numberWithBool:[ flautoPlayer isDecoderSupported: codec] ];
        result(b);
        [self log: DBG msg: @"IOS:<-- isDecoderSupported"];
}



-(FlutterSoundPlayerManager*) getPlugin
{
        return flutterSoundPlayerManager;
}


- (void)openPlayer: (FlutterMethodCall*)call result: (FlutterResult)result
{
        [self log: DBG msg: @"IOS:--> initializeFlautoPlayer"];
        t_AUDIO_FOCUS focus = (t_AUDIO_FOCUS)( [(NSNumber*)call.arguments[@"focus"] intValue]);
        t_SESSION_CATEGORY category = (t_SESSION_CATEGORY)( [(NSNumber*)call.arguments[@"category"] intValue]);
        t_SESSION_MODE mode = (t_SESSION_MODE)( [(NSNumber*)call.arguments[@"mode"] intValue]);
        int flags =  [(NSNumber*)call.arguments[@"audioFlags"] intValue];
        t_AUDIO_DEVICE device = (t_AUDIO_DEVICE)( [(NSNumber*)call.arguments[@"device"] intValue]);
        BOOL r = [flautoPlayer initializeFlautoPlayerFocus: focus category: category mode: mode audioFlags: flags audioDevice:device];
        if (r)
                result( [self getPlayerStatus]);
        else
                result([FlutterError
                                errorWithCode:@"Audio Player"
                                message:@"Open session failure"
                                details:nil]);
        [self log: DBG msg: @"IOS:<-- initializeFlautoPlayer"];
}


- (void)setAudioFocus: (FlutterMethodCall*)call result: (FlutterResult)result
{
        [self log: DBG msg: @"IOS:--> setAudioFocus"];
        t_AUDIO_FOCUS focus = (t_AUDIO_FOCUS)( [(NSNumber*)call.arguments[@"focus"] intValue]);
        t_SESSION_CATEGORY category = (t_SESSION_CATEGORY)( [(NSNumber*)call.arguments[@"category"] intValue]);
        t_SESSION_MODE mode = (t_SESSION_MODE)( [(NSNumber*)call.arguments[@"mode"] intValue]);
        int flags =  [(NSNumber*)call.arguments[@"audioFlags"] intValue];
        t_AUDIO_DEVICE device = (t_AUDIO_DEVICE)( [(NSNumber*)call.arguments[@"device"] intValue]);
        BOOL r = [flautoPlayer setAudioFocus: focus category: category mode: mode audioFlags: flags audioDevice:device];
        if (r)
                result( [self getPlayerStatus]);
        else
                result([FlutterError
                                errorWithCode:@"Audio Player"
                                message:@"Open session failure"
                                details:nil]);
        [self log: DBG msg: @"IOS:<-- setAudioFocus"];

}


- (void)reset: (FlutterMethodCall*)call result: (FlutterResult)result
{
        [self log: DBG msg: @"IOS:--> reset (Player)"];
        [self closePlayer: call result: result];
        result([NSNumber numberWithInt: 0]);
        [self log: DBG msg: @"IOS:<-- reset (Player)"];
}

- (void)closePlayer: (FlutterMethodCall*)call result: (FlutterResult)result
{
        [self log: DBG msg: @"IOS:--> releaseFlautoPlayer"];
        [flautoPlayer releaseFlautoPlayer];
        [super releaseSession];
        result([self getPlayerStatus]);
        [self log: DBG msg: @"IOS:<-- releaseFlautoPlayer"];

}

- (void)setCategory: (FlutterMethodCall*)call result:(FlutterResult)result
{
        NSString* categ = (NSString*)call.arguments[@"category"];
        NSString* mode = (NSString*)call.arguments[@"mode"];
        int options = [(NSNumber*)call.arguments[@"options"] intValue];
        bool r = [flautoPlayer setCategory: categ mode: mode options:options ];
        if (r)
                result( [self getPlayerStatus]);
        else
                result([FlutterError
                                errorWithCode:@"Audio Player"
                                message:@"Open session failure"
                                details:nil]);
}

- (void)setActive: (FlutterMethodCall*)call result:(FlutterResult)result
{
        [self log: DBG msg: @"IOS:--> setActive"];
        BOOL enabled = [call.arguments[@"enabled"] boolValue];
        bool r = [flautoPlayer setActive: enabled];
        hasFocus = enabled;

        if (r)
                result([self getPlayerStatus]);
        else
                result([FlutterError
                                errorWithCode:@"Audio Player"
                                message:@"setActive failure"
                                details:nil]);
        [self log: DBG msg: @"IOS:<-- setActive"];
}



- (void)stopPlayer:(FlutterMethodCall*)call  result:(FlutterResult)result
{
        [self log: DBG msg: @"IOS:--> stopPlayer"];
        [flautoPlayer stopPlayer];
        NSNumber* status = [self getPlayerStatus];
        result(status);
        [self log: DBG msg: @"IOS:<-- stopPlayer"];
}



- (void)getPlayerState:(FlutterMethodCall*)call result: (FlutterResult)result
{
                result([self getPlayerStatus]);
}




- (void)startPlayer:(FlutterMethodCall*)call result: (FlutterResult)result
{
        [self log: DBG msg: @"IOS:--> startPlayer"];
        NSString* path = (NSString*)call.arguments[@"fromURI"];
        NSNumber* numChannels = (NSNumber*)call.arguments[@"numChannels"];
        NSNumber* sampleRate = (NSNumber*)call.arguments[@"sampleRate"];
        t_CODEC codec = (t_CODEC)([(NSNumber*)call.arguments[@"codec"] intValue]);
        FlutterStandardTypedData* dataBuffer = (FlutterStandardTypedData*)call.arguments[@"fromDataBuffer"];
        NSData* data = nil;
        if ([dataBuffer class] != [NSNull class])
                data = [dataBuffer data];
        int channels = ([numChannels class] != [NSNull class]) ? [numChannels intValue] : 1;
        long samplerateLong = ([sampleRate class] != [NSNull class]) ? [sampleRate longValue] : 44000;
  
        bool b =
        [
                flautoPlayer startPlayerCodec: codec
                fromURI: path
                fromDataBuffer: data
                channels: channels
                sampleRate: samplerateLong
        ];
        if (b)
        {
                        NSNumber* status = [self getPlayerStatus];
                        result(status);
        } else
        {
                        result(
                        [FlutterError
                        errorWithCode:@"Audio Player"
                        message:@"startPlayer failure"
                        details:nil]);
        }
        [self log: DBG msg: @"IOS:<-- startPlayer"];
}


- (void)startPlayerFromMic:(FlutterMethodCall*)call result: (FlutterResult)result
{
        [self log: DBG msg: @"IOS:--> startPlayerFromMic"];
        NSNumber* numChannels = (NSNumber*)call.arguments[@"numChannels"];
        NSNumber* sampleRate = (NSNumber*)call.arguments[@"sampleRate"];
        long samplerateLong = ([sampleRate class] != [NSNull class]) ? [sampleRate longValue] : 44000;
        int channels = ([numChannels class] != [NSNull class]) ? [numChannels intValue] : 1;
        bool b =
        [
                flautoPlayer startPlayerFromMicSampleRate: samplerateLong
                nbChannels: channels
        ];
        if (b)
        {
                result([self getPlayerStatus]);
        } else
        {
                        result([FlutterError
                        errorWithCode:@"Audio Player"
                        message:@"startPlayerFromMic failure"
                        details:nil]);
        }
        [self log: DBG msg: @"IOS:<-- startPlayer"];
}


- (void)startPlayerFromTrack:(FlutterMethodCall*)call result: (FlutterResult)result
{
         [self log: DBG msg: @"IOS:--> startPlayerFromTrack"];
         NSMutableDictionary* trackDict = (NSMutableDictionary*) call.arguments[@"track"];
         
         if ([trackDict[@"dataBuffer"] class] != [NSNull class])
         {
                trackDict[@"dataBuffer"] = [(FlutterStandardTypedData*)trackDict[@"dataBuffer"] data];
         }
         
         FlautoTrack* track = [[FlautoTrack alloc] initFromDictionary: trackDict];
         //FlutterStandardTypedData* data = (FlutterStandardTypedData*)trackDict[@"dataBuffer"];
         //track[@"dataBuffer"] = [data data];
         //AVAudioPlayer* toto = [[AVAudioPlayer alloc] initWithData: [zozo data] error: nil];

         
         BOOL canPause  = [call.arguments[@"canPause"] boolValue];
         BOOL canSkipForward = [call.arguments[@"canSkipForward"] boolValue];
         BOOL canSkipBackward = [call.arguments[@"canSkipBackward"] boolValue];
         NSNumber* progress = (NSNumber*)call.arguments[@"progress"];
         NSNumber* duration = (NSNumber*)call.arguments[@"duration"];
         bool removeUIWhenStopped  = [call.arguments[@"removeUIWhenStopped"] boolValue];
         bool defaultPauseResume  = [call.arguments[@"defaultPauseResume"] boolValue];
         bool b = [flautoPlayer startPlayerFromTrack: track canPause: canPause canSkipForward: canSkipForward
                       canSkipBackward: canSkipBackward progress: progress duration: duration removeUIWhenStopped: removeUIWhenStopped defaultPauseResume: defaultPauseResume];

        if (b)
        {
   
                        result([self getPlayerStatus]);
        } else
        {
                        result([FlutterError
                        errorWithCode:@"Audio Player"
                        message:@"startPlayer failure"
                        details:nil]);
        }
        [self log: DBG msg: @"IOS:<-- startPlayerFromTrack"];
}

- (void)nowPlaying:(FlutterMethodCall*)call result: (FlutterResult)result
{
                       result([FlutterError
                                errorWithCode:@"Audio Player"
                                message:@"Now Playing failure"
                                details:nil]);
                                
                               // - (void)nowPlaying: (FlautoTrack*)track canPause: (bool)canPause canSkipForward: (bool)canSkipForward canSkipBackward: (bool)canSkipBackward
               // defaultPauseResume: (bool)defaultPauseResume progress: (NSNumber*)progress duration: (NSNumber*)duration
}


- (void)setUIProgressBar:(FlutterMethodCall*)call result: (FlutterResult)result;
{
         NSNumber* progress = (NSNumber*)call.arguments[@"progress"];
         NSNumber* duration = (NSNumber*)call.arguments[@"duration"];
         double x = [ progress doubleValue];
         progress = [NSNumber numberWithFloat: x/1000.0];
         double y = [ duration doubleValue];
         duration = [NSNumber numberWithFloat: y/1000.0];


         [flautoPlayer setUIProgressBar: progress duration:duration];
         result([self getPlayerStatus]);
}


     

- (void)pausePlayer:(FlutterResult)result
{
        [self log: DBG msg: @"IOS:--> pausePlayer"];

        if ([flautoPlayer pausePlayer])
        {
                result([self getPlayerStatus]);
        } else
        {
                       result([FlutterError
                                  errorWithCode:@"Audio Player"
                                  message:@"audioPlayer pause failure"
                                  details:nil]);

        }
        [self log: DBG msg: @"IOS:<-- pausePlayer"];

}

- (void)resumePlayer:(FlutterResult)result
{
        [self log: DBG msg: @"IOS:--> resumePlayer"];

        if ([flautoPlayer resumePlayer])
        {
                result([self getPlayerStatus]);
        } else
        {
                       result([FlutterError
                                  errorWithCode:@"Audio Player"
                                  message:@"audioPlayer resumePlayer failure"
                                  details:nil]);

        }
        [self log: DBG msg: @"IOS:<-- resumePlayer"];
}



- (void)feed:(FlutterMethodCall*)call result: (FlutterResult)result
{
                int r = -1;
                FlutterStandardTypedData* x = call.arguments[ @"data" ] ;
                assert ([x elementSize] == 1);
                NSData* data = [x data];
                assert ([data length] == [x elementCount]);
                r = [flautoPlayer feed: data];
                if (r >= 0)
                {
			result([NSNumber numberWithInt: r]);
                } else
                {
                        result([FlutterError
                                errorWithCode:@"feed"
                                message:@"error"
                                details:nil]);
                
                }

}

- (void)seekToPlayer:(FlutterMethodCall*)call result: (FlutterResult)result
{
                [self log: DBG msg: @"IOS:--> seekToPlayer"];

                NSNumber* milli = (NSNumber*)(call.arguments[@"duration"]);
                long t = [milli longValue];
                [flautoPlayer seekToPlayer: t];
                result([self getPlayerStatus]);
                [self log: DBG msg: @"IOS:<-- seekToPlayer"];

}

- (void)setVolume:(double) volume  fadeDuration: (double)fadeDuration result: (FlutterResult)result // Volume is between 0.0 and 1.0
{
                [self log: DBG msg: @"IOS:--> setVolume"];

                [flautoPlayer setVolume: volume fadeDuration: fadeDuration];
                result([self getPlayerStatus]);
                [self log: DBG msg: @"IOS:<-- setVolume"];
}

- (void)setSpeed:(double) speed  result: (FlutterResult)result // speed is 0.0 to 1.0 to slow and 1.0 to n to speed
{
        [self log: DBG msg: @"IOS:--> setSpeed"];

        [flautoPlayer setSpeed: speed];
        result([self getPlayerStatus]);
        [self log: DBG msg: @"IOS:<-- setSpeed"];

}


- (void)getProgress:(FlutterMethodCall*)call result: (FlutterResult)result
{
        [self log: DBG msg: @"IOS:--> getProgress"];
        NSDictionary* dico = [flautoPlayer getProgress];
        result(dico);
        [self log: DBG msg: @"IOS:--> getProgress"];

}


- (void)setSubscriptionDuration:(FlutterMethodCall*)call  result: (FlutterResult)result
{
        [self log: DBG msg: @"IOS:--> setSubscriptionDuration"];
        NSNumber* milliSec = (NSNumber*)call.arguments[@"duration"];
        [flautoPlayer setSubscriptionDuration: [milliSec longValue]];
        result([self getPlayerStatus]);
        [self log: DBG msg: @"IOS:<-- setSubscriptionDuration"];
}


// post fix with _FlutterSound to avoid conflicts with common libs including path_provider
- (NSString*) GetDirectoryOfType_FlutterSound: (NSSearchPathDirectory) dir
{
        NSArray* paths = NSSearchPathForDirectoriesInDomains(dir, NSUserDomainMask, YES);
        return [paths.firstObject stringByAppendingString:@"/"];
}



- (int)getStatus
{
         return [flautoPlayer getStatus];
}

- (NSNumber*)getPlayerStatus
{
        return [NSNumber numberWithInt: [self getStatus]];
}


- (void)setLogLevel: (FlutterMethodCall*)call result: (FlutterResult)result
{
    
}

@end
//---------------------------------------------------------------------------------------------

