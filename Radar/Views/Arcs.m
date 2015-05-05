/*
 
 The MIT License (MIT)
 
 Copyright (c) 2015 ABM Adnan
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 */

#import "Arcs.h"

#define DEGREES_TO_RADIANS(degrees) (M_PI*degrees/180)

@implementation Arcs

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setOpaque:NO];
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect{
    // Set the render colors.
    // the colors of the arcs
    NSArray *colors = @[
                        [UIColor colorWithRed:176.0/255.0 green:228.0/255.0 blue:37.0/255.0 alpha:1.0],
                        [UIColor colorWithRed:51.0/255.0 green:181.0/255.0 blue:187.0/255.0 alpha:1.0],
                        [UIColor colorWithRed:236.0/255.0 green:68.0/255.0 blue:151.0/255.0 alpha:1.0],
                        [UIColor colorWithRed:196.0/255.0 green:217.0/255.0 blue:56.0/255.0 alpha:1.0],
                        [UIColor colorWithRed:51.0/255.0 green:181.0/255.0 blue:187.0/255.0 alpha:1.0],
                        [UIColor colorWithRed:137.0/255.0 green:182.0/255.0 blue:51.0/255.0 alpha:1.0]
                        ];
    
    // initial radius & increment in radius
    NSInteger radius = 38, increment = 20;
    
    // angles - some random start & end angles
    NSArray *angles = @[
                        @{@"start":@291, @"end":@248},
                        @{@"start":@88, @"end":@17},
                        @{@"start":@225, @"end":@150},
                        @{@"start":@278, @"end":@230},
                        @{@"start":@27, @"end":@296},
                        @{@"start":@135, @"end":@45},
                        ];
    for (int i = 0; i < colors.count; i++) {
        // set stroke color
        [colors[i] setStroke];
        // create a bezier path arc
        UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(140, 140)
                                                         radius:radius
                                                     startAngle:DEGREES_TO_RADIANS([[angles[i] valueForKey:@"start"] integerValue])
                                                       endAngle:DEGREES_TO_RADIANS([[angles[i] valueForKey:@"end"] integerValue])
                                                      clockwise:YES];
        // Adjust the drawing options as needed
        // The line width of the path
        path.lineWidth = 2;
        // draw the arc
        [path stroke];
        
        // increase the radius for next arc
        radius += increment;
    }
        
    // create the center circle (to hold profile photo of the logged in user)
    [[UIColor whiteColor] setStroke];
    [[UIColor colorWithRed:130.0/255.0 green:130.0/255.0 blue:131.0/255.0 alpha:0.44] setFill];
    UIBezierPath *circlePath = [UIBezierPath bezierPathWithOvalInRect:
                           CGRectMake(120, 120, 40, 40)];
    circlePath.lineWidth = 2;
    [circlePath fill];
    [circlePath stroke];
}



@end
