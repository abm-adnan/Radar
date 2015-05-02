
#import "AngleGradientLayer.h"
#import "Radar.h"

@implementation Radar

+ (Class)layerClass
{
	return [AngleGradientLayer class];
}

- (id)initWithFrame:(CGRect)frame
{
	if (!(self = [super initWithFrame:frame]))
		return nil;
	
	self.backgroundColor = [UIColor clearColor];
    [self setOpaque:NO];

    NSArray *colors = @[
                    (id)[UIColor colorWithRed:1 green:1 blue:1 alpha:0].CGColor,
                    (id)[UIColor colorWithRed:1 green:1 blue:1 alpha:0].CGColor,
                    (id)[UIColor colorWithRed:1 green:1 blue:1 alpha:0].CGColor,
                    (id)[UIColor colorWithRed:1 green:1 blue:1 alpha:0].CGColor,
                    (id)[UIColor colorWithRed:1 green:1 blue:1 alpha:0].CGColor,
                    (id)[UIColor colorWithRed:232.0/255.0 green:240.0/255.0 blue:44.0/255.0 alpha:1.0].CGColor
                    ];
    
	AngleGradientLayer *l = (AngleGradientLayer *)self.layer;
	l.colors = colors;
    
    l.cornerRadius = CGRectGetWidth(self.bounds) / 2;
    
    
    // Create a mask layer and the frame to determine what will be visible in the view.
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    
    // Create a path with the rectangle in it.
    int radius = 21;
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, frame.size.width, frame.size.height) cornerRadius:0];
    UIBezierPath *circlePath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(frame.size.width/2 - radius, frame.size.height/2 - radius, 2.0 * radius, 2.0 * radius) cornerRadius:radius];
    [path appendPath:circlePath];
    [path setUsesEvenOddFillRule:YES];
    
    // Set the path to the mask layer.
    maskLayer.path = path.CGPath;
    maskLayer.fillRule = kCAFillRuleEvenOdd;
    
    // Release the path since it's not covered by ARC.
    //CGPathRelease(path);
    
    l.mask = maskLayer;
    
	self.clipsToBounds = YES;
    self.userInteractionEnabled = NO;
    
    
	return self;
}

@end
