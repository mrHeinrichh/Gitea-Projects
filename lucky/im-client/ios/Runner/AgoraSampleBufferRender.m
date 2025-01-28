//
//  AgoraSampleBufferRender.m
//  APIExample
//
//  Created by 胡润辰 on 2022/4/2.
//  Copyright © 2022 Agora Corp. All rights reserved.
//

#import "AgoraSampleBufferRender.h"


@implementation AgoraSampleBufferRender

- (AVSampleBufferDisplayLayer *)displayLayer {
    if (!_displayLayer) {
        _displayLayer = [AVSampleBufferDisplayLayer new];
    }
    
    return _displayLayer;
}

- (instancetype)init {
    if (self = [super init]) {
        [self.layer addSublayer:self.displayLayer];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self.layer addSublayer:self.displayLayer];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.layer addSublayer:self.displayLayer];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.clipsToBounds = YES;
    [self layoutDisplayLayer];
}

- (void)layoutDisplayLayer {
    if (_videoWidth == 0 || _videoHeight == 0 || CGSizeEqualToSize(self.frame.size, CGSizeZero)) {
        return;
    }
    
    CGFloat viewWidth = UIScreen.mainScreen.bounds.size.width;
    CGFloat viewHeight =  UIScreen.mainScreen.bounds.size.height;
    CGFloat videoRatio = (CGFloat)_videoWidth/(CGFloat)_videoHeight;
    CGFloat viewRatio = viewWidth/viewHeight;
    
    CGSize videoSize;
    if (videoRatio >= viewRatio) {
        videoSize.height = viewHeight;
        videoSize.width = videoSize.height * videoRatio;
    }else {
        videoSize.width = viewWidth;
        videoSize.height = videoSize.width / videoRatio;
    }
    
    CGRect renderRect = CGRectMake(0.5 * (viewWidth - videoSize.width), 0.5 * (viewHeight - videoSize.height), videoSize.width, videoSize.height);
    
    if (!CGRectEqualToRect(renderRect, self.displayLayer.frame)) {
        self.displayLayer.frame = renderRect;
    }
}

- (void)reset {
    [self.displayLayer flushAndRemoveImage];
}

- (OSType)getFormatType: (NSInteger)type {
    switch (type) {
        case 1:
            return kCVPixelFormatType_420YpCbCr8Planar;
            
        case 2:
            return kCVPixelFormatType_32BGRA;
            
        default:
            return kCVPixelFormatType_32BGRA;
    }
}

- (void)renderVideoSampleBuffer:(CMSampleBufferRef)sampleBufferRef size:(CGSize)size {
    if (!sampleBufferRef) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_videoWidth = size.width;
        self->_videoHeight = size.height;
        
        [self layoutDisplayLayer];
    });
    @autoreleasepool {
        CMSampleTimingInfo timingInfo;
        timingInfo.duration = kCMTimeZero;
        timingInfo.decodeTimeStamp = kCMTimeInvalid;
        timingInfo.presentationTimeStamp = CMTimeMake(CACurrentMediaTime()*1000, 1000);
        
        if (sampleBufferRef) {
            [self.displayLayer enqueueSampleBuffer:sampleBufferRef];
            [self.displayLayer setNeedsDisplay];
            [_displayLayer display];
            [self.layer display];
        }
    }
}

- (void)renderVideoPixelBuffer:(AgoraOutputVideoFrame *_Nonnull)videoData isMirror:(BOOL)isMirror isDefaultSize:(BOOL)isDefaultSize{
    if (!videoData) {
        return;
    }
    
    if(isDefaultSize) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self layoutDisplayLayer];
        });
    }

    CVPixelBufferRef pixelBuffer = videoData.pixelBuffer;
    
    if(isMirror){
        pixelBuffer = [self mirrorPixelBuffer:videoData.pixelBuffer];
    }
    
    CMVideoFormatDescriptionRef videoInfo;
    CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault,
                                                 pixelBuffer,
                                                 &videoInfo);
    
    CMSampleTimingInfo timingInfo;
    timingInfo.duration = kCMTimeZero;
    timingInfo.decodeTimeStamp = kCMTimeInvalid;
    timingInfo.presentationTimeStamp = CMTimeMake(CACurrentMediaTime()*20, 20);
    
    CMSampleBufferRef sampleBuffer;
    CMSampleBufferCreateReadyWithImageBuffer(kCFAllocatorDefault,
                                             pixelBuffer,
                                             videoInfo,
                                             &timingInfo,
                                             &sampleBuffer);
    
    [self.displayLayer enqueueSampleBuffer:sampleBuffer];
    if (self.displayLayer.status == AVQueuedSampleBufferRenderingStatusFailed) {
        [self.displayLayer flush];
    }
    CMSampleBufferInvalidate(sampleBuffer);
    CFRelease(sampleBuffer);
    
    if (pixelBuffer && isMirror) {
        CVPixelBufferRelease(pixelBuffer);
        pixelBuffer = NULL;
    }
}

-(CVPixelBufferRef)mirrorPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    CIImage *mirroredImage = [ciImage imageByApplyingOrientation:kCGImagePropertyOrientationUpMirrored];
    
    CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    OSType pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);

    NSDictionary *pixelBufferAttributes = @{
        (NSString *)kCVPixelBufferIOSurfacePropertiesKey: @{}
    };

    CVPixelBufferRef mirroredPixelBuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          width,
                                          height,
                                          pixelFormat,
                                          (__bridge CFDictionaryRef)pixelBufferAttributes,
                                          &mirroredPixelBuffer);

    if (status != kCVReturnSuccess) {
        NSLog(@"Error: Could not create pixel buffer (%d)", status);
        return NULL;
    }

    CIContext *context = [CIContext context];
    [context render:mirroredImage toCVPixelBuffer:mirroredPixelBuffer];

    return mirroredPixelBuffer;
}

@end
