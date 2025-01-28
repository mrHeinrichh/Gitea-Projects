//
//  AgoraPictureInPictureController.m
//  APIExample
//
//  Created by 胡润辰 on 2022/4/1.
//  Copyright © 2022 Agora Corp. All rights reserved.
//

#import "AgoraPictureInPictureController.h"

@implementation AgoraPictureInPictureController

- (instancetype)initWithDisplayView:(AgoraSampleBufferRender *)displayView {
    self.isStopping = NO;
    if (@available(iOS 15.0, *)) {
        if ([AVPictureInPictureController isPictureInPictureSupported]) {
            self = [super init];
            if (self) {
                _displayView = displayView;
                AVPictureInPictureControllerContentSource *pipControllerContentSource = [[AVPictureInPictureControllerContentSource alloc] initWithSampleBufferDisplayLayer:_displayView.displayLayer playbackDelegate:self];
                
                _pipController = [[AVPictureInPictureController alloc] initWithContentSource:pipControllerContentSource];
                [_pipController setDelegate: self];
            }
            return self;
        }
    }
    return nil;
}

- (void)updateDisplayView:(AgoraSampleBufferRender *)displayView {
    if (@available(iOS 15.0, *)) {
        _displayView = displayView;
        AVPictureInPictureControllerContentSource *pipControllerContentSource = [[AVPictureInPictureControllerContentSource alloc] initWithSampleBufferDisplayLayer: displayView.displayLayer playbackDelegate:self];
        [_pipController setContentSource: pipControllerContentSource];
    }
}

- (void)releasePIP {
    if(_pipController.isPictureInPictureActive){
        [_pipController stopPictureInPicture];
    }
    
    self.isStopping = NO;
    _pipController.delegate = nil;
    _pipController = nil;
    [_displayView reset];
    _displayView = nil;
}

#pragma mark - <AVPictureInPictureSampleBufferPlaybackDelegate>

- (void)pictureInPictureController:(nonnull AVPictureInPictureController *)pictureInPictureController didTransitionToRenderSize:(CMVideoDimensions)newRenderSize {
    NSLog(@"pictureInPictureController==========> didTransitionToRenderSize, %i, %i", newRenderSize.width, newRenderSize.height);
}

- (void)pictureInPictureController:(nonnull AVPictureInPictureController *)pictureInPictureController setPlaying:(BOOL)playing {
    NSLog(@"pictureInPictureController==========> setPlaying, %lu", (unsigned long)_displayView.hash);
}

- (void)pictureInPictureController:(nonnull AVPictureInPictureController *)pictureInPictureController skipByInterval:(CMTime)skipInterval completionHandler:(nonnull void (^)(void))completionHandler {
    NSLog(@"pictureInPictureController==========> skipByInterval, %lu", (unsigned long)_displayView.hash);
}

- (BOOL)pictureInPictureControllerIsPlaybackPaused:(nonnull AVPictureInPictureController *)pictureInPictureController {
    return NO;
}

- (CMTimeRange)pictureInPictureControllerTimeRangeForPlayback:(nonnull AVPictureInPictureController *)pictureInPictureController {
    return CMTimeRangeMake(kCMTimeZero, CMTimeMake(INT64_MAX, 1000));
}

-(void) pictureInPictureControllerWillStartPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
    NSLog(@"pictureInPictureControllerWillStartPictureInPicture");
}

-(void) pictureInPictureControllerWillStopPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
    NSLog(@"pictureInPictureControllerWillStopPictureInPicture");
    [self.displayView.displayLayer setHidden:YES];
    self.isStopping = YES;
}

-(void) pictureInPictureControllerDidStopPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
    NSLog(@"pictureInPictureControllerDidStopPictureInPicture");
    [self.displayView.displayLayer setHidden:NO];
    self.isStopping = NO;
}

-(void) pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:(void (^)(BOOL))completionHandler{
    NSLog(@"restoreUserInterfaceForPictureInPictureStopWithCompletionHandler");
}

@end
