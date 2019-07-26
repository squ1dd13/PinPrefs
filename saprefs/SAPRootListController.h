#import <Preferences/PSListController.h>
#import <Preferences/PSViewController.h>
@interface SAPHeaderView : UITableViewCell
@property (nonatomic, strong, readwrite) UILabel *label;
@end

@interface SAPRootListController : PSListController

@end

@interface SQColorPicker : PSViewController
@property (nonatomic, assign, readwrite) UIColor *color;
@property (nonatomic, strong, readwrite) UISlider *rSlider;
@property (nonatomic, strong, readwrite) UISlider *gSlider;
@property (nonatomic, strong, readwrite) UISlider *bSlider;
@property (nonatomic, assign, readwrite) NSString *defaultsKey;
-(void)setColor:(UIColor *)color;
@end
