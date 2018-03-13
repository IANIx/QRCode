//
//  NVScanView.h
//  QRCode
//
//  Created by 薛佳妮 on 2018/3/6.
//  Copyright © 2018年 jiani. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NV_ScannerProtocol.h"

@interface NVScanView : UIView<NV_ScannerProtocol>

@property (nonatomic, assign) CGRect scanRect;


- (void)addScanLineAnimation;
- (void)removeScanLineAnimation;

@end
