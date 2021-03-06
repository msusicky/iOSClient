//
//  ARISCollapseView.h
//  ARIS
//
//  Created by Phil Dougherty on 8/12/13.
//
//

#import <UIKit/UIKit.h>

@class ARISCollapseView;

@protocol ARISCollapseViewDelegate
@optional 
- (void) collapseView:(ARISCollapseView *)cv didStartOpen:(BOOL)o;
- (void) collapseView:(ARISCollapseView *)cv didFinishOpen:(BOOL)o;
- (void) collapseView:(ARISCollapseView *)cv wasDragged:(UIPanGestureRecognizer *)r;
@end

@interface ARISCollapseView : UIView
- (id) initWithContentView:(UIView *)v frame:(CGRect)f open:(BOOL)o showHandle:(BOOL)h draggable:(BOOL)d tappable:(BOOL)t delegate:(id<ARISCollapseViewDelegate>)del;
- (void) setFrame:(CGRect)f;
- (void) setFrameHeight:(CGFloat)h; //sets open frame while keeping bottom in same spot
- (void) setContentFrame:(CGRect)f;
- (void) setContentFrameHeight:(CGFloat)h;
- (void) open;
- (void) close;

//use to add drag/tap areas outside of the collapse view
- (void) handleTapped:(UITapGestureRecognizer *)g;
- (void) handlePanned:(UIPanGestureRecognizer *)g;

@end
