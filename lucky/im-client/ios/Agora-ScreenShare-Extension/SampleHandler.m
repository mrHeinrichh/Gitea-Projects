//
//  SampleHandler.m
//  Agora-ScreenShare-Extension
//
//  Created by BM on 12/6/23.
//


#import "SampleHandler.h"

@implementation SampleHandler

- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *,NSObject *> *)setupInfo {
    // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional. 
    NSLog (@"this is a test broadcastStartedWithSetupInfo");
}

- (void)broadcastPaused {
    // User has requested to pause the broadcast. Samples will stop being delivered.
    NSLog (@"this is a test broadcastPaused");
}

- (void)broadcastResumed {
    // User has requested to resume the broadcast. Samples delivery will resume.
    NSLog (@"this is a test broadcastResumed");
}

- (void)broadcastFinished {
    // User has requested to finish the broadcast.
    NSLog (@"this is a test broadcastFinished");
}

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType {
    NSLog (@"this is a test processSampleBuffer");
    switch (sampleBufferType) {
        case RPSampleBufferTypeVideo:
            // Handle video sample buffer
            break;
        case RPSampleBufferTypeAudioApp:
            // Handle audio sample buffer for app audio
            break;
        case RPSampleBufferTypeAudioMic:
            // Handle audio sample buffer for mic audio
            break;
            
        default:
            break;
    }
}

@end
