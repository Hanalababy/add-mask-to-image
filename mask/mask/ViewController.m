//
//  ViewController.m
//  mask
//
//  Created by Tang Hana on 2017/1/20.
//  Copyright © 2017年 Tang Hana. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController


- (void)drawRadialGradient:(CGContextRef)context
                      path:(CGPathRef)path
                    center:(CGPoint) center;
{
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat locations[] = { 0.0,0.25,0.45 };
    
    NSArray *colors = @[(id)[[UIColor colorWithWhite:0 alpha:1] CGColor],
                        (id)[[UIColor colorWithWhite:0 alpha:0.75] CGColor],
                        (id)[[UIColor colorWithWhite:0 alpha:0] CGColor],];
    
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef) colors, locations);
    
    
    CGRect pathRect = CGPathGetBoundingBox(path);
    CGFloat radius = MAX(pathRect.size.width / 2.0, pathRect.size.height / 2.0) * sqrt(2);
    
    CGContextSaveGState(context);
    CGContextAddPath(context, path);
    CGContextEOClip(context);
    CGContextDrawRadialGradient(context, gradient, center, 0, center, radius, 0);
    
    CGContextRestoreGState(context);
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //创建CGContextRef
    UIGraphicsBeginImageContext(CGSizeMake(300,200));
    CGContextRef gc = UIGraphicsGetCurrentContext();
    
    UIImage*image=[UIImage imageNamed:@"1.jpg"];
    
    //创建CGMutablePathRef
    CGMutablePathRef path = CGPathCreateMutable();
    
    //绘制Path
    CGRect rect = CGRectMake(0,0, 300, 200);
    CGPathMoveToPoint(path, NULL, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGPathAddLineToPoint(path, NULL, CGRectGetWidth(rect), CGRectGetMinY(rect));
    CGPathAddLineToPoint(path, NULL, CGRectGetWidth(rect), CGRectGetMaxY(rect));
    CGPathAddLineToPoint(path, NULL, CGRectGetMinX(rect), CGRectGetMaxY(rect));
    CGPathMoveToPoint(path, NULL, CGRectGetMinX(rect), CGRectGetMaxY(rect));
    CGPathCloseSubpath(path);
    
    //绘制渐变
    [self drawRadialGradient:gc path:path center:CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect))];
    
    //注意释放CGMutablePathRef
    CGPathRelease(path);
    
    //从Context中获取图像 创建mask
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CALayer *maskLayer = [CALayer layer];
    maskLayer.contents = (id)[img CGImage];
    maskLayer.frame =CGRectMake(0,0,300,200);
    /*mark it oval*/
    //maskLayer.transform = CATransform3DMakeScale(0.8,1.0,0);
    view=[[UIImageView alloc] initWithFrame:CGRectMake(0,100,300,200)];
    view.image=image;
    
    view.layer.mask=maskLayer;
    view.layer.masksToBounds = YES;
    [self.view addSubview:view];
    
    
    /********PART II镂空********/
    //create path
    UIBezierPath *path2 = [UIBezierPath bezierPathWithArcCenter:CGPointMake(300 / 2, 200/2) radius:100 startAngle:0 endAngle:2*M_PI clockwise:NO];
    
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.backgroundColor=[[UIColor yellowColor] CGColor];
    
    shapeLayer.path = path2.CGPath;
    
    UIImageView* view2=[[UIImageView alloc] initWithFrame:CGRectMake(0,350,300,200)];
    view2.image=image;
    [view2.layer setMask:shapeLayer];
    [self.view addSubview:view2];
    
    /***************渐变文字********************/
    // 创建UILabel
    UILabel *label = [[UILabel alloc] init];
    label.text = @"Hello, Princess Shit!";
    label.font = [UIFont boldSystemFontOfSize:30.0];
    [label sizeToFit];
    label.center = CGPointMake(200, 50);
    
    // 疑问：label只是用来做文字裁剪，能否不添加到view上。
    // 必须要把Label添加到view上，如果不添加到view上，label的图层就不会调用drawRect方法绘制文字，也就没有文字裁剪了。
    // 如何验证，自定义Label,重写drawRect方法，看是否调用,发现不添加上去，就不会调用
    [self.view addSubview:label];
    
    // 创建渐变层
    gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = label.frame;
    // 设置渐变层的颜色，随机颜色渐变
    gradientLayer.colors = @[(id)[self randomColor].CGColor,
                             (id)[self randomColor].CGColor,
                             (id)[self randomColor].CGColor,
                             (id)[self randomColor].CGColor,
                             (id)[self randomColor].CGColor,
                             (id)[self randomColor].CGColor,];
    
    
    // 疑问:渐变层能不能加在label上
    // 不能，mask原理：默认会显示mask层底部的内容，如果渐变层放在mask层上，就不会显示了
    
    // 添加渐变层到控制器的view图层上
    [self.view.layer addSublayer:gradientLayer];
    
    // mask层工作原理:按照透明度裁剪，只保留非透明部分，文字就是非透明的，因此除了文字，其他都被裁剪掉，这样就只会显示文字下面渐变层的内容，相当于留了文字的区域，让渐变层去填充文字的颜色。
    // 设置渐变层的裁剪层
    gradientLayer.mask = label.layer;
    
    // 注意:一旦把label层设置为mask层，label层就不能显示了,会直接从父层中移除，然后作为渐变层的mask层，且label层的父层会指向渐变层，这样做的目的：以渐变层为坐标系，方便计算裁剪区域，如果以其他层为坐标系，还需要做点的转换，需要把别的坐标系上的点，转换成自己坐标系上点，判断当前点在不在裁剪范围内，比较麻烦。
    
    
    // 父层改了，坐标系也就改了，需要重新设置label的位置，才能正确的设置裁剪区域。
    label.frame = gradientLayer.bounds;
    
    // 利用定时器，快速的切换渐变颜色，就有文字颜色变化效果
    CADisplayLink *link = [CADisplayLink displayLinkWithTarget:self selector:@selector(textColorChange)];
    [link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
}



- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [touches anyObject];
    
    //当前的point
    CGPoint tapPoint = [touch locationInView:self.view];
    //判断落点是否在view内
    if(tapPoint.x>300||tapPoint.y<100||tapPoint.y>300) return;
    //创建CGContextRef
    UIGraphicsBeginImageContext(CGSizeMake(300,200));
    CGContextRef gc = UIGraphicsGetCurrentContext();
    
    //创建CGMutablePathRef
    CGMutablePathRef path = CGPathCreateMutable();
    
    //绘制Path
    CGRect rect = CGRectMake(0,0,300,200);
    CGPathMoveToPoint(path, NULL, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGPathAddLineToPoint(path, NULL, CGRectGetWidth(rect), CGRectGetMinY(rect));
    CGPathAddLineToPoint(path, NULL, CGRectGetWidth(rect), CGRectGetMaxY(rect));
    CGPathAddLineToPoint(path, NULL, CGRectGetMinX(rect), CGRectGetMaxY(rect));
    CGPathMoveToPoint(path, NULL, CGRectGetMinX(rect), CGRectGetMaxY(rect));
    CGPathCloseSubpath(path);
    
    //绘制渐变
    [self drawRadialGradient:gc path:path center:CGPointMake(tapPoint.x,tapPoint.y-100)];
    
    //注意释放CGMutablePathRef
    CGPathRelease(path);
    
    //从Context中获取图像 创建mask
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CALayer *maskLayer = [CALayer layer];
    maskLayer.contents = (id)[img CGImage];
    maskLayer.frame =CGRectMake(0,0,300,200);
    /*mark it oval*/
    //maskLayer.transform = CATransform3DMakeScale(0.8,1.0,0);
    view.layer.mask=maskLayer;
    view.layer.masksToBounds = YES;
}


// 随机颜色方法
-(UIColor *)randomColor{
    CGFloat r = arc4random_uniform(256) / 255.0;
    CGFloat g = arc4random_uniform(256) / 255.0;
    CGFloat b = arc4random_uniform(256) / 255.0;
    return [UIColor colorWithRed:r green:g blue:b alpha:1];
}

// 定时器触发方法
-(void)textColorChange {
    gradientLayer.colors = @[(id)[self randomColor].CGColor,
                             (id)[self randomColor].CGColor,
                             (id)[self randomColor].CGColor,
                             (id)[self randomColor].CGColor,
                             (id)[self randomColor].CGColor,
                             (id)[self randomColor].CGColor,];
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
