//
//  NVScanView.m
//  QRCode
//
//  Created by 薛佳妮 on 2018/3/6.
//  Copyright © 2018年 jiani. All rights reserved.
//

#import "NVScanView.h"
#define NVWidth self.bounds.size.width
#define NVHeight self.bounds.size.height

static CGFloat scanTime = 3.0; //线扫描时间
static CGFloat borderLineWidth = 0.5; //矩形的宽度
static CGFloat cornerLineWidth = 4.0; //四个角的宽度
static CGFloat scanLineWidth = 3.0; //扫描线的高度（包括阴影）
static NSString *const scanLineAnimationName = @"scanLineAnimation";

typedef void(^lightClickBlock)(UIButton *button);

@interface NVScanView()

/**
 扫描线颜色
 */
@property (nonatomic, strong) UIColor *scanLineColor;

/**
 四角的线的颜色，默认为橙色
 */
@property (nonatomic, strong) UIColor *cornerLineColor;

/**
 扫描边框的颜色，默认为白色
 */
@property (nonatomic, strong) UIColor *borderLineColor;

@property (nonatomic, strong) CAShapeLayer *rectangleLayer; //矩形
@property (nonatomic, strong) CAShapeLayer *loadingLayer;         //四个角

@property (nonatomic, strong) UIView *maskView;
@property (nonatomic, strong) UIView *middleView;
@property (nonatomic, strong) UIView *scanLine;
@property (nonatomic, strong) UIButton *lightBtn;
@property (nonatomic, strong, nullable) UIActivityIndicatorView* activityView;

@property (nonatomic, copy  ) lightClickBlock block;

@end

@implementation NVScanView

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        
        self.backgroundColor = [UIColor clearColor]; // 清空背景色，否则为黑
        [self loadSubViews];
    }
    return self;
}

- (void)loadSubViews {
    //显示背景半透明遮罩
    [self addSubview:self.maskView];
    [self addSubview:self.middleView];
    [self.middleView addSubview:self.scanLine];

    //加载矩形+四个角的layer
    [self loadScanBorderLayer];
    [self loadCornerLinesLayer];
    
    //显示滑动的line
    [self addScanLineAnimation];
}
- (void)loadScanBorderLayer {
    CGRect borderRect = CGRectMake(self.scanRect.origin.x + borderLineWidth,
                                   self.scanRect.origin.y + borderLineWidth,
                                   self.scanRect.size.width - (2 * borderLineWidth),
                                   self.scanRect.size.height - (2 * borderLineWidth));
    
    UIBezierPath *scanBezierPath = [UIBezierPath bezierPathWithRect:borderRect];
    CAShapeLayer *lineLayer = [CAShapeLayer layer];
    lineLayer.path = scanBezierPath.CGPath;
    lineLayer.lineWidth = borderLineWidth;
    lineLayer.strokeColor = self.borderLineColor.CGColor;
    lineLayer.fillColor = [UIColor clearColor].CGColor;
    [self.layer addSublayer:lineLayer];
}

- (void)loadCornerLinesLayer {
    CAShapeLayer *lineLayer = [CAShapeLayer layer];
    lineLayer.lineWidth = cornerLineWidth;
    lineLayer.strokeColor = self.cornerLineColor.CGColor;
    lineLayer.fillColor = [UIColor clearColor].CGColor;
    
    CGFloat halfLineLong = self.scanRect.size.width / 12;
    CGFloat spacing = cornerLineWidth/2;
    UIBezierPath *lineBezierPath = [UIBezierPath bezierPath];

    CGPoint leftUpPoint = (CGPoint){self.scanRect.origin.x + spacing ,
                                    self.scanRect.origin.y + spacing};
    [lineBezierPath moveToPoint:(CGPoint){leftUpPoint.x,
                                          leftUpPoint.y + halfLineLong}];
    [lineBezierPath addLineToPoint:leftUpPoint];
    [lineBezierPath addLineToPoint:(CGPoint){leftUpPoint.x + halfLineLong,
                                             leftUpPoint.y}];
    lineLayer.path = lineBezierPath.CGPath;
    [self.layer addSublayer:lineLayer];
    
    
    CGPoint leftDownPoint = (CGPoint){self.scanRect.origin.x + spacing,
                                      self.scanRect.origin.y + self.scanRect.size.height - spacing};
    [lineBezierPath moveToPoint:(CGPoint){leftDownPoint.x,
                                          leftDownPoint.y - halfLineLong}];
    [lineBezierPath addLineToPoint:leftDownPoint];
    [lineBezierPath addLineToPoint:(CGPoint){leftDownPoint.x + halfLineLong,
                                             leftDownPoint.y}];
    lineLayer.path = lineBezierPath.CGPath;
    [self.layer addSublayer:lineLayer];
    
    CGPoint rightUpPoint = (CGPoint){self.scanRect.origin.x + self.scanRect.size.width - spacing,
                                     self.scanRect.origin.y + spacing};
    [lineBezierPath moveToPoint:(CGPoint){rightUpPoint.x - halfLineLong,
                                          rightUpPoint.y}];
    [lineBezierPath addLineToPoint:rightUpPoint];
    [lineBezierPath addLineToPoint:(CGPoint){rightUpPoint.x,
                                             rightUpPoint.y + halfLineLong}];
    lineLayer.path = lineBezierPath.CGPath;
    [self.layer addSublayer:lineLayer];
    
    CGPoint rightDownPoint = (CGPoint){self.scanRect.origin.x + self.scanRect.size.width - spacing,
                                       self.scanRect.origin.y + self.scanRect.size.height - spacing};
    [lineBezierPath moveToPoint:(CGPoint){rightDownPoint.x - halfLineLong,
                                          rightDownPoint.y}];
    [lineBezierPath addLineToPoint:rightDownPoint];
    [lineBezierPath addLineToPoint:(CGPoint){rightDownPoint.x,rightDownPoint.y - halfLineLong}];
    lineLayer.path = lineBezierPath.CGPath;
    [self.layer addSublayer:lineLayer];
}

- (void)addScanLineAnimation{
    self.scanLine.hidden = NO;
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
    animation.fromValue = @(- scanLineWidth);
    animation.toValue = @(self.scanRect.size.height - scanLineWidth);
    animation.duration = scanTime;
    animation.repeatCount = OPEN_MAX;
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = NO;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.scanLine.layer addAnimation:animation forKey:scanLineAnimationName];
}

- (void)removeScanLineAnimation {
    [self.scanLine.layer removeAnimationForKey:scanLineAnimationName];
    self.scanLine.hidden = YES;
}

- (void)lightClicked:(UIButton *)sender {
    sender.selected = !sender.selected;
    !self.block ? nil : self.block(sender);
}
#pragma mark - GET/SET

- (CGRect)scanRect{
    if (CGRectIsEmpty(_scanRect)) {
        CGSize scanSize = CGSizeMake(self.frame.size.width * (2/3.f),
                                     self.frame.size.width * (2/3.f));
        
        _scanRect = CGRectMake((self.frame.size.width - scanSize.width)/2,
                               (self.frame.size.height - scanSize.height)/2,
                               scanSize.width,
                               scanSize.height);
    }
    return _scanRect;
}

- (UIView *)middleView{
    if (!_middleView) {
        _middleView = [[UIView alloc]initWithFrame:self.scanRect];
        _middleView.clipsToBounds = YES;
    }
    return _middleView;
}

- (UIView *)maskView{
    if (!_maskView) {
        _maskView = [[UIView alloc]initWithFrame:self.bounds];
        _maskView.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5];
        
        UIBezierPath *fullBezierPath = [UIBezierPath bezierPathWithRect:self.bounds];
        UIBezierPath *scanBezierPath = [UIBezierPath bezierPathWithRect:self.scanRect];
        [fullBezierPath appendPath:[scanBezierPath  bezierPathByReversingPath]];
        
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        shapeLayer.path = fullBezierPath.CGPath;
        _maskView.layer.mask = shapeLayer;
    }
    return _maskView;
}

- (UIView *)scanLine{
    if (!_scanLine) {
        _scanLine = [[UIView alloc]initWithFrame:CGRectMake(0,0, self.scanRect.size.width, scanLineWidth)];
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.startPoint = CGPointMake(0, 0.5);
        gradient.endPoint = CGPointMake(1, 0.5);
        gradient.frame = _scanLine.layer.bounds;
        gradient.colors = @[(__bridge id)[[UIColor cyanColor] colorWithAlphaComponent:0].CGColor,
                            (__bridge id)[UIColor cyanColor].CGColor,
                            (__bridge id)[[UIColor cyanColor] colorWithAlphaComponent:0].CGColor];
        gradient.locations = @[@0,@0.5,@1.0];
        [_scanLine.layer addSublayer:gradient];
    }
    return _scanLine;
}

- (UIColor *)cornerLineColor{
    if (!_cornerLineColor) {
        _cornerLineColor = [UIColor cyanColor];
    }
    return _cornerLineColor;
}

- (UIColor *)borderLineColor{
    if (!_borderLineColor) {
        _borderLineColor = [UIColor whiteColor];
    }
    return _borderLineColor;
}

- (UIColor *)scanLineColor{
    if (!_scanLineColor) {
        _scanLineColor = [UIColor cyanColor];
    }
    return _scanLineColor;
}

- (UIActivityIndicatorView *)activityView {
    if (!_activityView) {
        _activityView = [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake((self.scanRect.size.width-30)/2, (self.scanRect.size.height-30)/2, 30, 30)];
        [_activityView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [_middleView addSubview:_activityView];
        _activityView.hidden = YES;
    }
    return _activityView;
}

- (UIButton *)lightBtn {
    if (!_lightBtn) {
        _lightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_lightBtn setTitle:@"亮灯灯💡" forState:UIControlStateNormal];
        [_lightBtn setTitle:@"关灯灯💡" forState:UIControlStateSelected];
        _lightBtn.frame = CGRectMake((self.scanRect.size.width-100)/2, (self.scanRect.size.height-30)/2, 100, 40);
        [_lightBtn addTarget:self action:@selector(lightClicked:) forControlEvents:UIControlEventTouchUpInside];
        [_middleView addSubview:_lightBtn];
    }
    return _lightBtn;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)hiddenActivityIndicator {
    [self.activityView stopAnimating];
    self.activityView.hidden = YES;
}

- (void)hiddenLightBtn {
    if (self.lightBtn.selected != YES) {
        self.lightBtn.hidden = YES;
    }
}

- (void)showActivityIndicator {
    self.activityView.hidden = NO;
    [self.activityView startAnimating];
}

- (void)showLightBtn:(void (^)(UIButton *))block {
    self.lightBtn.hidden = NO;
    self.block = block;
}


@end
