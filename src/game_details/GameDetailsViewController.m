//
//  GameDetailsViewController.m
//  ARIS
//
//  Created by David J Gagnon on 4/18/10.
//  Copyright 2010 University of Wisconsin - Madison. All rights reserved.
//

#import <MapKit/MKReverseGeocoder.h>
#import "GameDetailsViewController.h"
#import "AppServices.h"
#import "AppModel.h"
#import "commentsViewController.h"
#import "RatingCell.h"
#import "Game.h"
#import "ARISMediaView.h"
#import "Media.h"

#import "ARISAlertHandler.h"
#import "UIColor+ARISColors.h"

#import <QuartzCore/QuartzCore.h>

@interface GameDetailsViewController() <ARISMediaViewDelegate, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate,  UIWebViewDelegate>
{
	Game *game; 
    
    UITableView *tableView;
    ARISMediaView *mediaImageView;
    UIWebView *descriptionWebView;
    
    NSIndexPath *descriptionIndexPath;
    CGFloat newHeight;
    
    id<GameDetailsViewControllerDelegate> __unsafe_unretained delegate;
}

@property (nonatomic, strong) Game *game;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) ARISMediaView *mediaImageView;
@property (nonatomic, strong) UIWebView *descriptionWebView;
@property (nonatomic, assign) CGFloat newHeight;
@property (nonatomic, strong) NSIndexPath *descriptionIndexPath;

@end

@implementation GameDetailsViewController

@synthesize game;
@synthesize tableView;
@synthesize mediaImageView;
@synthesize descriptionWebView;
@synthesize newHeight;
@synthesize descriptionIndexPath;

- (id) initWithGame:(Game *)g delegate:(id<GameDetailsViewControllerDelegate>)d
{
    if(self = [super init])
    {
        delegate = d;
        self.game = g;
        
        //THIS NEXT LINE IS AWFUL. NEEDS REFACTOR.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewDidIntentionallyAppear) name:@"PlayerSettingsDidDismiss" object:nil];
    }
    return self;
}

- (void) loadView
{
    [super loadView];
}

- (void) viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
    [self.view addSubview:self.tableView];
    [self setLayoutFrames];
}

- (void) viewDidAppear:(BOOL)animated 
{
    //for some reason, frames get messed up when you get to this screen from leaving a game. This corrects it.
    [super viewDidAppear:animated];
    [self setLayoutFrames];
}

- (void) setLayoutFrames
{
    self.tableView.frame = self.view.bounds;
    self.tableView.contentInset = UIEdgeInsetsMake(64,0,0,0);
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backButton.frame = CGRectMake(0,0,19,19);
    [backButton setImage:[UIImage imageNamed:@"arrowBack"] forState:UIControlStateNormal];
    backButton.accessibilityLabel = @"Back Button";
    [backButton addTarget:self action:@selector(backButtonTouched) forControlEvents:UIControlEventTouchUpInside];
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];

    if(self.game.splashMedia)
        self.mediaImageView = [[ARISMediaView alloc] initWithFrame:CGRectMake(0,0,self.view.bounds.size.width,200) media:self.game.splashMedia mode:ARISMediaDisplayModeAspectFit delegate:self];
    else
        self.mediaImageView = [[ARISMediaView alloc] initWithFrame:CGRectMake(0,0,self.view.bounds.size.width,200) image:[UIImage imageNamed:@"DefaultGameSplash"] mode:ARISMediaDisplayModeAspectFit delegate:self];
    
    self.descriptionWebView = [[UIWebView alloc] initWithFrame:CGRectMake(15, 15, self.view.bounds.size.width-30, 10)];
    [descriptionWebView setBackgroundColor:[UIColor clearColor]];
    self.descriptionWebView.delegate = self;
    if(![self.game.gdescription isEqualToString:@""])
        [self.descriptionWebView loadHTMLString:[NSString stringWithFormat:[UIColor ARISHtmlTemplate], self.game.gdescription] baseURL:nil];
    
    self.title = self.game.name;
}

- (void) viewDidIntentionallyAppear
{
    if([AppModel sharedAppModel].skipGameDetails)
    {
        [AppModel sharedAppModel].skipGameDetails = 0;
        [self playGame];
    }
}

- (void) webViewDidFinishLoad:(UIWebView *)descriptionView
{
	self.newHeight = [[descriptionView stringByEvaluatingJavaScriptFromString:@"document.body.offsetHeight;"] floatValue] + 3;
	
	CGRect descriptionFrame = [descriptionView frame];	
	descriptionFrame.size = CGSizeMake(descriptionFrame.size.width,newHeight);
	[descriptionView setFrame:descriptionFrame];
    [tableView reloadRowsAtIndexPaths:[[NSArray alloc] initWithObjects:self.descriptionIndexPath, nil] withRowAnimation:UITableViewRowAnimationFade];
}

- (BOOL) webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL *requestURL = [request URL];  

    if(([[requestURL scheme] isEqualToString:@"http"] ||
        [[requestURL scheme] isEqualToString:@"https"]) &&
       (navigationType == UIWebViewNavigationTypeLinkClicked))
        return ![[UIApplication sharedApplication] openURL:requestURL];

    return YES;  
} 

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch(section)
    {
        case 0:
            return 1;
            break;
        case 1:
            if(self.game.hasBeenPlayed) return 3;
            else return 2;
            break;
        case 2:
            return 1;
            break;
        case 3:
            return 1;
            break;
    }
    return 0; //Should never get here
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @""; 
}

- (UITableViewCell *) tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
	NSString *CellIdentifier = [NSString stringWithFormat: @"Cell%d%d",indexPath.section,indexPath.row];
    UITableViewCell *cell = (UITableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(cell == nil) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];;
	
    if(indexPath.section == 0 && indexPath.row == 0)
    {
        cell.backgroundView = self.mediaImageView;
        cell.userInteractionEnabled = NO;
    }
    else if(indexPath.section == 1)
    {
        if (indexPath.row == 0)
        {
            if(self.game.hasBeenPlayed) cell.textLabel.text = NSLocalizedString(@"GameDetailsResumeKey", @"");
            else                        cell.textLabel.text = NSLocalizedString(@"GameDetailsNewGameKey", @""); 
            cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
        }
        else if (indexPath.row ==1)
        {
            if(self.game.hasBeenPlayed)
            {
                cell.textLabel.text = NSLocalizedString(@"GameDetailsResetKey", @"");
                cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
                cell.textLabel.textAlignment = NSTextAlignmentCenter;
            } 
            else
                cell = [self constructReviewCell];
        }
        else if (indexPath.row ==2)
            cell = [self constructReviewCell];
    }
    else if(indexPath.section == 2)
    {
        descriptionIndexPath = [indexPath copy];
        cell.userInteractionEnabled = NO;
        descriptionWebView.opaque = NO;
        descriptionWebView.backgroundColor = [UIColor clearColor];
        [cell.contentView addSubview:descriptionWebView];
    }
    else if (indexPath.section == 3)
    {
        // MG:
        cell.textLabel.text = NSLocalizedString(@"Download Game", @"");
    }
    
    return cell;
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1)
    {
        if(indexPath.row == 0)//Start/Resume
        {
            cell.backgroundColor = [UIColor ARISColorLightBlue];
            cell.textLabel.textColor = [UIColor whiteColor];
        }
        else if(indexPath.row == 1 && self.game.hasBeenPlayed)//Reset
        {
            cell.backgroundColor = [UIColor ARISColorRed];
            cell.textLabel.textColor = [UIColor whiteColor];
        }
        else if((indexPath.row == 1 && !game.hasBeenPlayed) || indexPath.row == 2)//Ratings
        {
            cell.backgroundColor = [UIColor ARISColorOffWhite];
        }
    }
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section //hides empty cells at bottom
{
    return 0.01f;
}

- (void) playGame
{
    self.game.hasBeenPlayed = YES;
    [delegate gameDetailsWereConfirmed:self.game];
}

- (void) backButtonTouched
{
    [delegate gameDetailsWereCanceled:self.game];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 1)
    {
        if(indexPath.row == 0)
        {
            [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
            [self playGame];
            [self.tableView reloadData];
        }
        else if(indexPath.row ==1)
        {
            if(self.game.hasBeenPlayed)
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"GameDetailsResetTitleKey", nil) message:NSLocalizedString(@"GameDetailsResetMessageKey", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"CancelKey", @"") otherButtonTitles:NSLocalizedString(@"GameDetailsResetKey", @""), nil];
                [alert show];	
                [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
            }
            else
            {
                commentsViewController *commentsVC = [[commentsViewController alloc] initWithNibName:@"commentsView" bundle:nil];
                commentsVC.game = self.game;
                [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
                [self.navigationController pushViewController:commentsVC animated:YES];
            }
        }
        else if(indexPath.row == 2)
        {
            commentsViewController *commentsVC = [[commentsViewController alloc] initWithNibName:@"commentsView" bundle:nil];
            commentsVC.game = self.game;
            [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
            [self.navigationController pushViewController:commentsVC animated:YES];     
        }
    }
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSString *title = [alertView title];
    
    if([title isEqualToString:NSLocalizedString(@"GameDetailsResetTitleKey", nil)])
    {
        if (buttonIndex == 1)
        {
            [[AppServices sharedAppServices] startOverGame:self.game.gameId];
            self.game.hasBeenPlayed = NO;
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
}

- (CGFloat) tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if     (indexPath.section == 0 && indexPath.row == 0)                   return 220;
    else if(indexPath.section == 2 && indexPath.row == 0 && self.newHeight) return self.newHeight+30;
    
    return 40;
}

- (UITableViewCell *) constructReviewCell
{
    UITableViewCell *cell = (RatingCell *)[[ARISViewController alloc] initWithNibName:@"RatingCell" bundle:nil].view;
    
    RatingCell *ratingCell = (RatingCell *)cell;

    ratingCell.ratingView.rating = self.game.rating;
    ratingCell.ratingView.userInteractionEnabled = NO;
    ratingCell.reviewsLabel.text = [NSString stringWithFormat:@"%d %@",self.game.numReviews, NSLocalizedString(@"ReviewsKey", @"")];
    [ratingCell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    
    [ratingCell.ratingView setStarImage:[UIImage imageNamed:@"small-star-highlighted.png"] forState:kSCRatingViewHighlighted];
    [ratingCell.ratingView setStarImage:[UIImage imageNamed:@"small-star-selected.png"]    forState:kSCRatingViewHot];
    [ratingCell.ratingView setStarImage:[UIImage imageNamed:@"small-star-highlighted.png"] forState:kSCRatingViewNonSelected];
    [ratingCell.ratingView setStarImage:[UIImage imageNamed:@"small-star-selected.png"]    forState:kSCRatingViewSelected];
    [ratingCell.ratingView setStarImage:[UIImage imageNamed:@"small-star-selected.png"]    forState:kSCRatingViewUserSelected];
    
    return cell;
}

- (void) ARISMediaViewUpdated:(ARISMediaView *)amv
{
    
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
