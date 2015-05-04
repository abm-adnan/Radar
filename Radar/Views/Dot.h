
#import <UIKit/UIKit.h>

@interface Dot : UIView {
    
}

@property (nonatomic, strong) UIColor *color;
@property (nonatomic, strong) NSNumber *bearing;
@property (nonatomic, strong) NSNumber *userDistance;
@property (nonatomic, strong) NSNumber *distance;
@property (nonatomic, strong) NSDictionary *userProfile;
@property (nonatomic, readwrite) BOOL zoomEnabled;

@end
