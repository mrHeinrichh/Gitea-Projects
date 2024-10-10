//
//  AgoraSampleBufferRender.h
//  APIExample
//
//  Created by 胡润辰 on 2022/4/2.
//  Copyright © 2022 Agora Corp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AgoraRtcKit/AgoraRtcEngineKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AgoraSampleBufferRender : UIView

@property (nonatomic, assign) int videoWidth, videoHeight;
@property (nonatomic, strong) AVSampleBufferDisplayLayer *displayLayer;

- (void)reset;

- (void)renderVideoPixelBuffer:(AgoraOutputVideoFrame *_Nonnull)videoData isMirror: (BOOL)isMirror isDefaultSize:(BOOL)isDefaultSize;

- (void)renderVideoSampleBuffer:(CMSampleBufferRef)sampleBufferRef size:(CGSize)size;

- (CVPixelBufferRef) mirrorPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

NS_ASSUME_NONNULL_END
