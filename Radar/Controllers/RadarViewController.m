
#import "RadarViewController.h"
#import "Arcs.h"
#import "Radar.h"
#import "Dot.h"

#define degreesToRadians(x) (M_PI * x / 180.0)
#define radiandsToDegrees(x) (x * 180.0 / M_PI)

@interface RadarViewController (){
    __weak IBOutlet UIView *radarViewHolder;
    __weak IBOutlet UIView *radarLine;
    __weak IBOutlet UISlider *distanceSlider;
    Arcs *arcsView;
    Radar *radarView;
    float currentDeviceBearing;
    NSMutableArray *dots;
    NSArray *nearbyUsers;
    NSTimer *detectCollisionTimer;
}

@end

@implementation RadarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    dots = [[NSMutableArray alloc] init];
    nearbyUsers = [[NSArray alloc] init];
    
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
    
    [self loadUsers];
}

#pragma mark - Reload Radar

-(void) removePreviousDots {
    for (Dot *dot in dots) {
        [dot removeFromSuperview];
    }
    dots = [NSMutableArray array];

    // reset slider
    distanceSlider.minimumValue = 0;
    distanceSlider.maximumValue = 0;
    distanceSlider.value = 0;
}

-(void)renderUsersOnRadar:(NSArray*)users{
    
    CLLocationCoordinate2D myLoc = { 48.858370, 2.294481 };
    
    // the last user in the nearbyUsers list is the farthest
    float maxDistance = [[[users lastObject] valueForKey:@"distance"] floatValue];
    float minDistance = [[[users firstObject] valueForKey:@"distance"] floatValue];
    
    distanceSlider.minimumValue = minDistance;
    distanceSlider.maximumValue = maxDistance;
    distanceSlider.value = maxDistance;
    
    // add users dots
    for (NSDictionary *user in users) {
        
        Dot *dot = [[Dot alloc] initWithFrame:CGRectMake(0, 0, 32.0, 32.0)];
        
        // male > blue, female > green
        if ([[user valueForKey:@"gender"] isEqualToString:@"female"]) {
            // pink
            dot.color = [UIColor colorWithRed:234.0/255.0 green:69.0/255.0 blue:130.0/255.0 alpha:1.0];
        } else {
            // cyan
            dot.color = [UIColor colorWithRed:39.0/255.0 green:185.0/255.0 blue:173.0/255.0 alpha:1.0];
        }
        
        CLLocationCoordinate2D userLoc = { [[user valueForKey:@"lat"] floatValue], [[user valueForKey:@"lng"] floatValue] };
        
        float bearing = [self getHeadingForDirectionFromCoordinate:myLoc toCoordinate:userLoc];
        dot.bearing = [NSNumber numberWithFloat:bearing];
        
        float d = [[user valueForKey:@"distance"] floatValue];
        float distance = MAX(35, d * 132.0 / maxDistance); // 140 = radius of the radar circle, so the farthest user will be on the perimiter of radar circle
        
        dot.distance = [NSNumber numberWithFloat:distance]; // relative distance
        
        dot.userDistance = [NSNumber numberWithFloat:d];
        dot.userProfile = user;
        dot.zoomEnabled = NO;
        dot.userInteractionEnabled = NO;
        [self rotateDot:dot fromBearing:0 toBearing:bearing atDistance:distance];
        
        [arcsView addSubview:dot];
        
        [dots addObject:dot];
    }
    
    // start timer to detect collision with radar line and blink
    detectCollisionTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                            target:self
                                                          selector:@selector(detectCollisions:)
                                                          userInfo:nil
                                                           repeats:YES];
}

- (void)loadUsers {
    // empty the existing dots from radar
    [self removePreviousDots]; // this is useful if you want to remove existing dots at runtime
    
    // At this point use your own method to load nearby users from server via network request.
    // I'm using some dummy hardcoded users data.
    // Make sure in your returned data the **sorted** by **nearest to farthest**
    nearbyUsers = @[
                 @{@"gender":@"female", @"lat":@48.859873, @"lng":@2.295083,@"distance":@173.2},    // nearest
                 @{@"gender":@"female", @"lat":@48.856492, @"lng":@2.298515,@"distance":@362.3},    //  THE SORTING is
                 @{@"gender":@"male", @"lat":@48.859718, @"lng":@2.300544,@"distance":@468.6},      //  Very IMPORTANT!
                 @{@"gender":@"female", @"lat":@48.858376, @"lng":@2.287666,@"distance":@499.8},    //
                 @{@"gender":@"male", @"lat":@48.854643, @"lng":@2.289186,@"distance":@567.1}       // farthest
                 ];
    
    // This method should be called after successful return of JSON array from your server-side service
    [self renderUsersOnRadar:nearbyUsers];
}

#pragma mark - Spin the radar view continuously
-(void)spinRadar{
    /**** spin animation object ***/
    CABasicAnimation *spin = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    spin.duration = 1;
    spin.toValue = [NSNumber numberWithFloat:-M_PI];
    spin.cumulative = YES;
    spin.removedOnCompletion = NO; // this is to keep on animating after application pause-resume
    spin.repeatCount = MAXFLOAT;
    radarLine.layer.anchorPoint = CGPointMake(-0.18, 0.5);
    
    [radarLine.layer addAnimation:spin forKey:@"spinRadarLine"];
    [radarView.layer addAnimation:spin forKey:@"spinRadarView"];
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

- (void)rotateArcsToHeading:(CGFloat)angle {
    // rotate the circle to heading degree
    arcsView.transform = CGAffineTransformMakeRotation(angle);
    // rotate all dots to opposite angle to keep the profile image straight up
    /*for (Dot *dot in dots) {
     dot.transform = CGAffineTransformMakeRotation(-angle);
     }*/
}

- (float)getHeadingForDirectionFromCoordinate:(CLLocationCoordinate2D)fromLoc toCoordinate:(CLLocationCoordinate2D)toLoc
{
    float fLat = degreesToRadians(fromLoc.latitude);
    float fLng = degreesToRadians(fromLoc.longitude);
    float tLat = degreesToRadians(toLoc.latitude);
    float tLng = degreesToRadians(toLoc.longitude);
    
    float degree = radiandsToDegrees(atan2(sin(tLng-fLng)*cos(tLat), cos(fLat)*sin(tLat)-sin(fLat)*cos(tLat)*cos(tLng-fLng)));
    
    if (degree >= 0) {
        return -degree;
    } else {
        return -(360+degree);
    }
}

#pragma mark - Rotate/Trsnslate Dot

- (void)rotateDot:(Dot*)dot fromBearing:(CGFloat)fromDegrees toBearing:(CGFloat)degrees atDistance:(CGFloat)distance {
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGPathAddArc(path,nil, 140, 140, distance, degreesToRadians(fromDegrees), degreesToRadians(degrees), YES);
    
    CAKeyframeAnimation *theAnimation;
    
    // animation object for the key path
    theAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    theAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    theAnimation.path=path;
    CGPathRelease(path);
    
    // set the animation properties
    theAnimation.duration=3;
    theAnimation.removedOnCompletion = NO;
    theAnimation.repeatCount = 0;
    theAnimation.autoreverses = NO;
    theAnimation.fillMode = kCAFillModeForwards;
    theAnimation.cumulative = YES;
    
    
    CGPoint newPosition = CGPointMake(distance*cos(degreesToRadians(degrees))+138, distance*sin(degreesToRadians(degrees))+138);
    dot.layer.position = newPosition;
    
    
    [dot.layer addAnimation:theAnimation forKey:@"rotateDot"];
    
}

- (void)translateDot:(Dot*)dot toBearing:(CGFloat)degrees atDistance:(CGFloat)distance {
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
    
    [animation setFromValue:[NSValue valueWithCGPoint:[[dot.layer.presentationLayer valueForKey:@"position"] CGPointValue] ]];
    
    CGPoint newPosition = CGPointMake(distance*cos(degreesToRadians(degrees))+138, distance*sin(degreesToRadians(degrees))+138);
    [animation setToValue:[NSValue valueWithCGPoint: newPosition]];
    
    [animation setDuration:0.3f];
    animation.fillMode = kCAFillModeForwards;
    animation.autoreverses = NO;
    animation.repeatCount = 0;
    animation.removedOnCompletion = NO;
    animation.cumulative = YES;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    
    CABasicAnimation *alphaAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    [alphaAnimation setDuration:0.5f];
    alphaAnimation.fillMode = kCAFillModeForwards;
    alphaAnimation.autoreverses = NO;
    alphaAnimation.repeatCount = 0;
    alphaAnimation.removedOnCompletion = NO;
    alphaAnimation.cumulative = YES;
    alphaAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    if (distance > 132) {
        [alphaAnimation setToValue:[NSNumber numberWithFloat:0.0f]];
        
    }else{
        [alphaAnimation setToValue:[NSNumber numberWithFloat:1.0f]];
        
    }
    
    [dot.layer addAnimation:alphaAnimation forKey:@"alphaDot"];
    
    [dot.layer addAnimation:animation forKey:@"translateDot"];
    
}
#pragma mark - Detect Collisions

- (void)detectCollisions:(NSTimer*)theTimer
{
    float radarLineRotation = radiandsToDegrees( [[radarLine.layer.presentationLayer valueForKeyPath:@"transform.rotation.z"] floatValue] );
    
    if (radarLineRotation >= 0) {
        radarLineRotation -= 360;
    }
    
    
    for (int i = 0; i < [dots count]; i++) {
        Dot *dot = [dots objectAtIndex:i];
        
        float dotBearing = [dot.bearing floatValue] - currentDeviceBearing;
        
        if (dotBearing < -360) {
            dotBearing += 360;
        }
        
        // collision detection
        if( ABS(dotBearing - radarLineRotation) <=  20)
        {
            [self pulse:dot];
            
        }
    }
}
-(void)pulse:(Dot*)dot{
    if([dot.layer.animationKeys containsObject:@"pulse"] || dot.zoomEnabled){ // view is already animating. so return
        return;
    }
    
    CABasicAnimation * pulse = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    pulse.duration = 0.15;
    pulse.toValue = [NSNumber numberWithFloat:1.4];
    pulse.autoreverses = YES;
    [dot.layer addAnimation:pulse forKey:@"pulse"];
}

#pragma mark - Slider
- (IBAction)sliderValueChange:(UISlider *)sender {
    float new_distance = [sender value];
    float distanceFilter = 0;
    for (int i = 0; i < [nearbyUsers count]; i++) {
        NSDictionary *user = nearbyUsers[i];
        
        float distance = [[user valueForKey:@"distance"] floatValue];
        float nextDistance = distance;
        //NSLog(@"distance %f <--->nextDistance %f ===>distanceFilter %f",distance, nextDistance, distanceFilter);
        
        if (i< [nearbyUsers count]-1) {
            NSDictionary *nextUser = nearbyUsers[i+1];
            nextDistance = [[nextUser valueForKey:@"distance"] floatValue];
        }
        
        if (distance <= new_distance && nextDistance >= new_distance) {
            if (nextDistance == new_distance) {
                distanceFilter = nextDistance;
            }else{
                distanceFilter = distance;
            }
            //NSLog(@"%f <---> %f ===> %f",distance, nextDistance, distanceFilter);
            break;
        }
    }
    //NSLog(@"distance filter %f", distanceFilter);
    [self filterNearByUsersByDistance: distanceFilter];
}

// for this function to work, sorting of users data by distance in ASC order (nearest to farthest) is a must
-(void) filterNearByUsersByDistance: (float)maxDistance{
    for (id d in dots) {
        Dot *dot = (Dot *)d;
        float distance = MAX(35,[dot.userDistance floatValue] * 132.0 / maxDistance);
        [self translateDot:dot toBearing:[dot.bearing floatValue] atDistance: distance];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    float heading = newHeading.magneticHeading; //in degrees
    float headingAngle = -(heading*M_PI/180); //assuming needle points to top of iphone. convert to radians
    currentDeviceBearing = heading;
    //    circle.transform = CGAffineTransformMakeRotation(headingAngle);
    [self rotateArcsToHeading:headingAngle];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
