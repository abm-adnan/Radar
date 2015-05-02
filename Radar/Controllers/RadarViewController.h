
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface RadarViewController : UIViewController <CLLocationManagerDelegate>

@property (nonatomic, retain) CLLocationManager *locManager;

@end

