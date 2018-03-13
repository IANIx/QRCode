//
//  ViewController.m
//  QRCode
//
//  Created by 薛佳妮 on 2018/3/6.
//  Copyright © 2018年 jiani. All rights reserved.
//

#import "ViewController.h"
#import "NVScanView.h"
#import "NVScanner.h"

@interface ViewController ()

@property (nonatomic, strong) NVScanView *scanView;
@property (nonatomic, strong) NVScanner *scanner;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    self.scanner = [[NVScanner alloc]initWithTargetView:self.scanView
                                               withRect:self.scanView.scanRect
                                           withDelegate:self];
    [self.scanner setupAVCapture];
    [self.scanner startScan:^(NSString *encodeStr, NSString *codeType) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.scanView removeScanLineAnimation];
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                                message:encodeStr
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil, nil];
            [alertView show];
        });
        NSLog(@"%@ -- %@",encodeStr,codeType);
        
    }];
    
    // Do any additional setup after loading the view, typically from a nib.
}


- (NVScanView *)scanView {
    if (!_scanView) {
        _scanView = [[NVScanView alloc]initWithFrame:[[UIScreen mainScreen] bounds]];
        [self.view addSubview:_scanView];
    }
    return _scanView;
}
@end
