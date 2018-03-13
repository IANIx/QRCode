//
//  NV_ScannerProtocol.h
//  QRCode
//
//  Created by 薛佳妮 on 2018/3/8.
//  Copyright © 2018年 jiani. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NV_ScannerProtocol <NSObject>
@required

/**
 显示活动指示器
 */
- (void)showActivityIndicator;

/**
 隐藏活动指示器
 */
- (void)hiddenActivityIndicator;

/**
 显示亮灯按钮
 */
- (void)showLightBtn:(void(^)(UIButton *lightBtn))block;

/**
 隐藏亮灯按钮
 */
- (void)hiddenLightBtn;
@end
