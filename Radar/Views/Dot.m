
#import "Dot.h"

@implementation Dot

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
    // Drawing code
    [self.color setFill];
    
    UIBezierPath *dotPath = [UIBezierPath bezierPathWithOvalInRect:
                             CGRectMake(rect.size.width / 4, rect.size.height / 4, rect.size.width/2, rect.size.height/2)];
    
    // Fill the path
    [dotPath fill];
}

@end
