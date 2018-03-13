//
//  NVScanner.m
//  QRCode
//
//  Created by 薛佳妮 on 2018/3/6.
//  Copyright © 2018年 jiani. All rights reserved.
//

#import "NVScanner.h"
#import <AVFoundation/AVFoundation.h>

@interface NVScanner () <AVCaptureMetadataOutputObjectsDelegate,AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, weak  ) UIView<NV_ScannerProtocol> *targetView;
@property (nonatomic, assign) CGRect scanRect;
@property (nonatomic, strong) AVCaptureSession *session;

@property (nonatomic, strong, nullable) UIActivityIndicatorView *activityView;

@property (copy,nonatomic) ResultBlock block;

@end

@implementation NVScanner
#pragma mark - LifeCycle

/**
 *  @brief 初始化NVScanner
 *
 *  @param targetView 摄像头渲染视图
 *  @param delegate   委托
 *
 *  @return NVScanner
 */
- (instancetype)initWithTargetView:(UIView<NV_ScannerProtocol> *)targetView
                          withRect:(CGRect)rect
                      withDelegate:(id)delegate {
    
    self = [super init];
    if (self) {
        
        _targetView = targetView;
        _delegate = delegate;
        _scanRect = rect;
        
        
    }
    return self;
}


/**
 *  @brief 初始化AVCapture
 */
-(void)setupAVCapture {
    
    NSError *captureError = nil;
    
    //获取摄像设备
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //创建输入流
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&captureError];
    //创建输出流
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc]init];
    
    CGRect viewRect = self.targetView.frame;
    CGRect containerRect = self.scanRect;
    
    CGFloat x = containerRect.origin.y / viewRect.size.height;
    CGFloat y = containerRect.origin.x / viewRect.size.width;
    CGFloat width = containerRect.size.height / viewRect.size.height;
    CGFloat height = containerRect.size.width / viewRect.size.width;
    //rectOfInterest属性设置设备的扫描范围
    output.rectOfInterest = CGRectMake(x, y, width, height);
    [self.targetView showActivityIndicator];

    //打开摄像头失败
    if(captureError) {
        
        if([_delegate respondsToSelector:@selector(scanner:didOpenCaptureFaild:)]) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [_delegate scanner:self didOpenCaptureFaild:captureError];
                
            });
            
        }
        
        return;
        
    }
    
    
    //设置代理，后台线程刷新
    [output setMetadataObjectsDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    
    AVCaptureVideoDataOutput *lightOutput = [[AVCaptureVideoDataOutput alloc] init];
    [lightOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
    //初始化Session
    self.session = [[AVCaptureSession alloc]init];
    [self.session addInput:input];
    [self.session addOutput:output];
    [self.session addOutput:lightOutput];
    
    //设置支持的编码格式（条形码和二维码）
    output.metadataObjectTypes=@[AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code, AVMetadataObjectTypeUPCECode, AVMetadataObjectTypeCode93Code, AVMetadataObjectTypeQRCode];
    
    AVCaptureVideoPreviewLayer *layer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    layer.frame = _targetView.layer.bounds;
    
    [_targetView.layer insertSublayer:layer atIndex:0];
    
}

#pragma mark - Public

/**
 *  @brief 开始扫描
 *
 *  @discuz 扫描结果可通过block返回，也可通过delegate返回
 *
 *  @param block 扫描结果
 */
-(void)startScan:(ResultBlock)block {
    
    self.block = block;
    
    self.isStop = NO;
    
    if(self.session && ![self.session isRunning]) {
        
        [self.session startRunning];
        [self.targetView hiddenActivityIndicator];
        
    }else {
        
        NSLog(@"[NVScanner]: startScan Failed!");
        [self.targetView hiddenActivityIndicator];
        
    }
    
}

/**
 *  @brief 继续扫描
 *
 *  @discuz 当获取到扫描结果以后，程序会自动停止扫描，需要继续扫描请调用continueScan
 */
-(void)continueScan {
    
    
    if(self.session && [self.session isRunning]){
        
        
        self.isStop = NO;
        
    }else {
        
        NSLog(@"[NVScanner]: continueScan Failed!");
        
    }
    
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

-(void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputMetadataObjects:(NSArray *)metadataObjects
      fromConnection:(AVCaptureConnection *)connection {
    
    if(metadataObjects.count > 0) {
        
        //获取解析字符
        AVMetadataMachineReadableCodeObject *metadataObject = [metadataObjects firstObject];
        NSString *encodeStr = metadataObject.stringValue;
        
        //获取条码类型
        NSString *metaDesc = metadataObject.description;
        NSRange range = [metaDesc rangeOfString:@"(?<=type=\").*(?=\",)" options:NSRegularExpressionSearch];
        NSString *codeType = [metaDesc substringWithRange:range];
        
        
        if(!_isStop) {
            
            
            self.isStop = YES;
            
            [self.session stopRunning];
            
            //播放音效
            NSURL *url=[[NSBundle mainBundle]URLForResource:@"scanSuccess.wav" withExtension:nil];
            SystemSoundID soundID=8787;
            AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &soundID);
            AudioServicesPlayAlertSound(soundID);
            
            //Block使用后台线程
            self.block?self.block(encodeStr,codeType):nil;
            
            if([_delegate respondsToSelector:@selector(scanner:didEncodeQRCode:codeType:)]) {
                
                //使用主线程回调
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [_delegate scanner:self
                       didEncodeQRCode:encodeStr
                              codeType:codeType];
                    
                });
                
                
            }
            
        }
        
    }
    
}
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    
    if (captureDeviceClass != nil) {
        
        
        
        CFDictionaryRef metadataDict = CMCopyDictionaryOfAttachments(NULL,sampleBuffer, kCMAttachmentMode_ShouldPropagate);
        
        NSDictionary *metadata = [[NSMutableDictionary alloc] initWithDictionary:(__bridge NSDictionary*)metadataDict];
        
        CFRelease(metadataDict);
        
        NSDictionary *exifMetadata = [[metadata objectForKey:(NSString *)kCGImagePropertyExifDictionary] mutableCopy];
        
        float brightnessValue = [[exifMetadata objectForKey:(NSString *)kCGImagePropertyExifBrightnessValue] floatValue];
        
        
        // 根据brightnessValue的值来打开和关闭闪光灯
        
        AVCaptureDevice * myLightDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        BOOL result = [myLightDevice hasTorch];// 判断设备是否有闪光灯
        
        if ((brightnessValue < 0) && result) {
            
            [self.targetView showLightBtn:^(UIButton *lightBtn) {
                
                if (lightBtn.selected == YES) {
                    //打开闪光灯
                    [myLightDevice lockForConfiguration:nil];
                    [myLightDevice setTorchMode: AVCaptureTorchModeOn];
                    [myLightDevice unlockForConfiguration];
                } else {
                    //关闭闪光灯
                    [myLightDevice lockForConfiguration:nil];
                    [myLightDevice setTorchMode: AVCaptureTorchModeOff];
                    [myLightDevice unlockForConfiguration];
                }
                
            }];
           
            
            
            
        }else if((brightnessValue > 0) && result) {
            
            //隐藏亮灯按钮
            [self.targetView hiddenLightBtn];

            
        }
        
    }
}
@end
