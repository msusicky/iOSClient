//
//  ARViewViewControler.m
//  ARIS
//
//  Created by David J Gagnon on 12/4/09.
//  Copyright 2009 University of Wisconsin - Madison. All rights reserved.
//

#import "ARViewViewControler.h"
#import "ARISMediaView.h"
#import "NearbyObjectARCoordinate.h"
#import "Location.h"

@implementation ARViewViewControler

@synthesize locations;

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle
{
    if(self = [super initWithNibName:nibName bundle:nibBundle])
    {
        self.tabID = @"AR";
        self.tabIconName = @"cameraTabBarSelected";
        self.title = NSLocalizedString(@"ARViewTitleKey",@"");
    }
    return self;
}

- (void)viewDidLoad
{	
	ARviewController = [[ARGeoViewController alloc] init];
	ARviewController.debugMode = NO;
	ARviewController.delegate = self;
	ARviewController.scaleViewsBasedOnDistance = NO;
	ARviewController.minimumScaleFactor = .5;
	ARviewController.rotateViewsBasedOnPerspective = NO;

	NSMutableArray *tempLocationArray = [[NSMutableArray alloc] initWithCapacity:10];
	
	NearbyObjectARCoordinate *tempCoordinate;
	for ( Location *nearbyLocation in [AppModel sharedAppModel].nearbyLocationsList ) {		
		tempCoordinate = [NearbyObjectARCoordinate coordinateWithNearbyLocation: nearbyLocation];
		[tempLocationArray addObject:tempCoordinate];
		NSLog(@"ARViewViewController: Added %@", tempCoordinate.title);
	}
	
	
	/* Example point being added
	CLLocation *tempLocation;
	ARGeoCoordinate *tempCoordinate;
	tempLocation = [[CLLocation alloc] initWithCoordinate:location altitude:1609.0 horizontalAccuracy:1.0 verticalAccuracy:1.0 timestamp:[NSDate date]];
	tempCoordinate = [ARGeoCoordinate coordinateWithLocation:tempLocation];
	tempCoordinate.title = @"Denver";
	[tempLocationArray addObject:tempCoordinate];
	*/
	
	
	[ARviewController addCoordinates:tempLocationArray];
	
	ARviewController.centerLocation = [AppModel sharedAppModel].player.location;
	[ARviewController startListening];
	
	//[[[RootViewController sharedRootViewController] window] addSubview:ARviewController.view];
	
	//Add a close button
	UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[closeButton setTitle:@"Close" forState:UIControlStateNormal];	
	[closeButton addTarget:self action:@selector(closeButtonTouched) forControlEvents:UIControlEventTouchUpInside];
	closeButton.frame = CGRectMake(50, 50, 50, 50);
	[ARviewController.view addSubview:closeButton];
	
	
    // Override point for customization after application launch
    //[[[RootViewController sharedRootViewController] window] makeKeyAndVisible];
	
	[super viewDidLoad];
}

- (void)closeButtonTouched
{
	NSLog(@"ARViewViewController: close button pressed");
	//[self dismissModalViewControllerAnimated:NO];
	//[self.view removeFromSuperview];
	//[self.cameraController dismissModalViewControllerAnimated:NO];
	//[self release];
	[ARviewController dismissViewControllerAnimated:NO completion:nil]; //bad code
}

#define BOX_WIDTH 300
#define BOX_HEIGHT 320

- (UIView *)viewForCoordinate:(NearbyObjectARCoordinate *)coordinate
{
	CGRect theFrame = CGRectMake(0, 0, BOX_WIDTH, BOX_HEIGHT);
	UIView *tempView = [[UIView alloc] initWithFrame:theFrame];
		
	UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, BOX_WIDTH, 20.0)];
	titleLabel.backgroundColor = [UIColor colorWithWhite:.3 alpha:.8];
	titleLabel.textColor = [UIColor whiteColor];
	titleLabel.textAlignment = NSTextAlignmentCenter;
	titleLabel.text = coordinate.title;
	[titleLabel sizeToFit];
	titleLabel.frame = CGRectMake(BOX_WIDTH / 2.0 - titleLabel.frame.size.width / 2.0 - 4.0, 0, titleLabel.frame.size.width + 8.0, titleLabel.frame.size.height + 8.0);
	
	ARISMediaView *imageView = [[ARISMediaView alloc] initWithFrame:CGRectZero];
	imageView.frame = CGRectMake((int)(BOX_WIDTH / 2.0 - 300 / 2.0), 20, 300, 300);
	//if(coordinate.mediaId != 0)
		//[imageView refreshWithFrame:CGRectZero media:[[AppModel sharedAppModel] mediaForMediaId:coordinate.mediaId ofType:@"PHOTO"] mode:ARISMediaDisplayModeAspectFit delegate:self];
	//else
        //[imageView refreshWithFrame:CGRectZero image:[UIImage imageNamed:@"location.png"] mode:ARISMediaDisplayModeAspectFit delegate:self];
    
	//[imageView addTarget:self action:@selector(closeButtonTouched) forControlEvents:UIControlEventTouchUpInside];
	
	[tempView addSubview:titleLabel];
	[tempView addSubview:imageView];
	
	return tempView;
}

- (void)refresh
{
	
}

@end
