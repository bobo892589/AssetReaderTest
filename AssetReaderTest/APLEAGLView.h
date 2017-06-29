//
//  APLEAGLView.h
//  VideoReader
//
//  Created by Benson on 2017/6/28.
//  Copyright © 2017年 NetEease. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface APLEAGLView : UIView

@property GLfloat preferredRotation;
@property CGSize presentationRect;
@property GLfloat chromaThreshold;
@property GLfloat lumaThreshold;

- (void)setupGL;
- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end
