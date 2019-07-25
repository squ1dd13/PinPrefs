#import <Preferences/PSListController.h>

@interface SAPHeaderView : UITableViewCell
@property (nonatomic, strong, readwrite) UIView *fakeCellView;
@property (nonatomic, strong, readwrite) UIView *fakeSwipeView;
-(void)simulateSwipe;
-(void)simulateReset;
@end

@interface SAPRootListController : PSListController

@end
