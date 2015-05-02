
#import "RadarViewController.h"
#import "Arcs.h"
#import "Radar.h"

@interface RadarViewController (){
    __weak IBOutlet UIView *radarViewHolder;
    __weak IBOutlet UIView *radarLine;
    Arcs *arcsView;
    Radar *radarView;
    float currentDeviceBearing;
}

@end

@implementation RadarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    arcsView = [[Arcs alloc] initWithFrame:CGRectMake(0, 0, 280, 280)];
    [radarViewHolder addSubview:arcsView];
    
    radarView = [[Radar alloc] initWithFrame:CGRectMake(3, 3, radarViewHolder.frame.size.width-6, radarViewHolder.frame.size.height-6)];
    radarView.alpha = 0.68;
    
    [radarViewHolder addSubview:radarView];
    // start spinning the radar forever
    [self spinRadar];
    // start heading event to rotate the arcs along with device rotation
    currentDeviceBearing = 0;
    [self startHeadingEvent];
}

// spin the radar view continuously
-(void)spinRadar{
    CABasicAnimation * spin = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    spin.duration = 1;
    spin.toValue = [NSNumber numberWithFloat:-M_PI];
    spin.cumulative = YES;
    spin.repeatCount = MAXFLOAT;
    
    radarLine.layer.anchorPoint = CGPointMake(-0.18, 0.5);
    [radarLine.layer addAnimation:spin forKey:@"spin"];
    
    [radarView.layer addAnimation:spin forKey:@"spin"];
}

- (void)startHeadingEvent {
    if (nil == _locManager) {
        // Retain the object in a property.
        _locManager = [[CLLocationManager alloc] init];
        _locManager.delegate = self;
        _locManager.desiredAccuracy = kCLLocationAccuracyBest;
        _locManager.distanceFilter = kCLDistanceFilterNone;
        _locManager.headingFilter = kCLHeadingFilterNone;
    }
    
    // Check for iOS 8. Without this guard the code will crash with "unknown selector" on iOS 7.
    if ([_locManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [_locManager requestWhenInUseAuthorization];
    }
    
    // Start heading updates.
    if ([CLLocationManager headingAvailable]) {
        [_locManager startUpdatingHeading];
    }
}

- (void) rotateCircleToHeading:(CGFloat)angle {
    // rotate the circle to heading degree
    arcsView.transform = CGAffineTransformMakeRotation(angle);
    // rotate all dots to opposite angle to keep the profile image straight up
    /*for (Dot *dot in dots) {
        dot.transform = CGAffineTransformMakeRotation(-angle);
    }*/
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    float heading = newHeading.magneticHeading; //in degrees
    float headingAngle = -(heading*M_PI/180); //assuming needle points to top of iphone. convert to radians
    currentDeviceBearing = heading;
    //    circle.transform = CGAffineTransformMakeRotation(headingAngle);
    [self rotateCircleToHeading:headingAngle];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
