//
//  ViewController.m
//  VideoReader
//
//  Created by Benson on 2017/6/28.
//  Copyright © 2017年 NetEease. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "APLEAGLView.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet APLEAGLView *playView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.playView.lumaThreshold = 1.0;
    self.playView.chromaThreshold = 1.0;
    [self.playView setupGL];
    [NSThread detachNewThreadSelector:@selector(readVideoFile) toTarget:self withObject:nil];
//    [self readVideoFile];
    
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)readVideoFile {
    NSTimeInterval sampleInternal = 1.0/60.0;
    AVAsset *asset = [AVAsset assetWithURL:[[NSBundle mainBundle] URLForResource:@"SampleVideo" withExtension:@"mp4"]];
    NSError *error = nil;
    AVAssetReader* reader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
    
    //读取视频
    NSArray* videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    AVAssetTrack* videoTrack = [videoTracks objectAtIndex:0];
    CGAffineTransform preferredTransform = [videoTrack preferredTransform];
    self.playView.preferredRotation = -1 * atan2(preferredTransform.b, preferredTransform.a);
    // 视频播放时，m_pixelFormatType=kCVPixelFormatType_32BGRA
    // 其他用途，如视频压缩，m_pixelFormatType=kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
    //    NSDictionary* options = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:
    //                                                                (int)m_pixelFormatType] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
//    NSDictionary *pixBuffAttributes = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)};
    NSDictionary *pixBuffAttributes = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)};
//    CMSampleBufferGetImageBuffer
    AVAssetReaderTrackOutput* videoReaderOutput = [[AVAssetReaderTrackOutput alloc]
                                                   initWithTrack:videoTrack outputSettings:pixBuffAttributes];
    [reader addOutput:videoReaderOutput];
    
    //读取音频
//    NSDictionary * outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
//                                     [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
//                                     [NSNumber numberWithFloat:44100.0], AVSampleRateKey,
//                                     [NSNumber numberWithInt:2], AVNumberOfChannelsKey,
//                                     [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
//                                     [NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
//                                     [NSNumber numberWithBool:NO], AVLinearPCMIsFloatKey,
//                                     [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
//                                     
//                                     nil];
//    
//    AVAssetReaderAudioMixOutput *audioReaderOutput = [[AVAssetReaderAudioMixOutput alloc] initWithAudioTracks:asset.tracks audioSettings:outputSettings];
//    [reader addOutput:audioReaderOutput];
//    AVAssetTrack *assetTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
//    AVAssetReaderTrackOutput *audioReaderOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:assetTrack outputSettings:NULL];
//    [reader addOutput:audioReaderOutput];
    
    
    [reader startReading];
    // 要确保nominalFrameRate>0，之前出现过android拍的0帧视频
    while ([reader status] == AVAssetReaderStatusReading && videoTrack.nominalFrameRate > 0) {
        // 读取video sample
        CMSampleBufferRef videoBuffer = [videoReaderOutput copyNextSampleBuffer];
        //        [m_delegate mMovieDecoder:self onNewVideoFrameReady:videoBuffer);
//        dispatch_semaphore_t semaphore = dispatch_semaphore_create(10);
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self showVideoFrameReady:videoBuffer];
//            dispatch_semaphore_signal(semaphore);
        });
//        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        if (videoBuffer) {
            CFRelease(videoBuffer);
        }
        
        // 根据需要休眠一段时间；比如上层播放视频时每帧之间是有间隔的
        [NSThread sleepForTimeInterval:sampleInternal];
    }
    
    // 告诉上层视频解码结束
    //         [m_delegate mMovieDecoderOnDecodeFinished:self];
    
}

- (void)showVideoFrameReady:(CMSampleBufferRef)videoBuffer {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(videoBuffer);
    [self.playView displayPixelBuffer:imageBuffer];
    
    
//    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(videoBuffer);
//    // Lock the base address of the pixel buffer.
//    CVPixelBufferLockBaseAddress(imageBuffer,0);
//    
//    // Get the number of bytes per row for the pixel buffer.
//    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
//    // Get the pixel buffer width and height.
//    size_t pixelsWide = CVPixelBufferGetWidth(imageBuffer);
//    size_t pixelsHigh = CVPixelBufferGetHeight(imageBuffer);
//    //    size_t dataSize = CVPixelBufferGetDataSize(imageBuffer);
//    //    OSType type = CVPixelBufferGetPixelFormatType(imageBuffer);
//    
//    // Get the base address of the pixel buffer.
//    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer,0);
//    
//    // Get the data size for contiguous planes of the pixel buffer.
//    //size_t bufferSize = CVPixelBufferGetDataSize(imageBuffer);
//    
//    //    if (!baseAddress) {
//    //        NSLog(@"baseAddress 为空");
//    //    }
//    //    NSLog(@"%ld - %ld - %ld - %ld - %ld",pixelsWide,pixelsHigh,bytesPerRow,dataSize,type);
//    
//    CGContextRef    context = NULL;
//    CGColorSpaceRef colorSpace;
//    
//    
//    colorSpace = CGColorSpaceCreateDeviceRGB();//CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);// 2
//    
//    context = CGBitmapContextCreate(baseAddress,
//                                    pixelsWide,
//                                    pixelsHigh,
//                                    8,
//                                    bytesPerRow,
//                                    colorSpace,
//                                    kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
//    if (context== NULL)
//    {
//        //        //free (bitmapData);// 5
//        //        NSLog(@"context == NULL") ;
//        //        fprintf (stderr, "Context not created!");
//        return ;
//    }
//    CGColorSpaceRelease( colorSpace );// 6
//    
//    CGImageRef imageRef = CGBitmapContextCreateImage(context);
//    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:1.0f orientation:UIImageOrientationRight];
////    if (!self.imageView.image) {
//    self.imageView.image = [image copy];
////    }
//    
//    CGContextRelease(context);
//#if 0
//    NSData *data = UIImagePNGRepresentation(image);
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *docDir = [paths objectAtIndex:0];
//    if (!docDir) {
//        NSLog(@"Documents directory not found!");
//        return;
//    }
//    NSString *filePath = [docDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%.4f.png",[[NSDate date] timeIntervalSince1970]]];
//    NSLog(@"输出%@",filePath);
//    NSLog(@"bool = %d",[data writeToFile:filePath atomically:YES]);
//#endif
//    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
////    NSData *data = UIImageJPEGRepresentation(image, 0.5f);
////    [image release];
//    CGImageRelease(imageRef);
}

@end
