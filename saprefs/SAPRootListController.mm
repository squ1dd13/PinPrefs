#include "SAPRootListController.h"
#include <string>
#include <sstream>

UIColor *createColor(const float r, const float g, const float b) {
	return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0f];
}

void showAlert(NSString *title, NSString *content, NSString *dismissButtonStr) {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:content preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *dismiss = [UIAlertAction actionWithTitle:dismissButtonStr style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:dismiss];
	//If I don't use dot notation here, it fucks up my syntax highlighting, so I apologise, but ¯\_(ツ)_/¯.
    [UIApplication.sharedApplication.keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
}

@implementation SAPHeaderView
//My response to @synthesize not working:
#define label _label

- (id)initWithSpecifier:(PSSpecifier *)specifier {
	self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
	if (self) {
		CGRect labelFrame = CGRectMake(0, -15, [[UIApplication sharedApplication] keyWindow].frame.size.width, 70);

		label = [[UILabel alloc] initWithFrame:labelFrame];

		[label.layer setMasksToBounds:YES];
		[label setNumberOfLines:1];
		label.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:40];

		label.textColor = [UIColor blackColor];
		label.textAlignment = NSTextAlignmentCenter;
		label.text = @"StickAround";

		[self addSubview:label];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doScramble:) name:@"CookEggs" object:nil];
	}

	return self;
}

- (CGFloat)preferredHeightForWidth:(CGFloat)arg1 {
    return 70.0f;
}

@end

NSString *getDefaultsKeyForSpecifierID(NSString *identifier) {
	if([identifier isEqualToString:@"Select 'Pin' Colour"]) {
		return @"saPinColor";
	}

	return @"saUnpinColor";
}

#import "ViewController.h"

@implementation SAPRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}

	return _specifiers;
}

- (BOOL)tableView:(UITableView *)tv canEditRowAtIndexPath:(NSIndexPath *)ip {
	return YES;
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath_ {
	static UINotificationFeedbackGenerator *feedbackGen = [[UINotificationFeedbackGenerator alloc] init];

	UITableViewRowAction *action = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Hi" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
		[feedbackGen prepare];
		[feedbackGen notificationOccurred:UINotificationFeedbackTypeError];

		showAlert(@"Nice Try", @"You can only do it on the main Settings page. 🙄", @"Okay");
	}];

	action.backgroundColor = createColor(255.0, 149.0, 0.0);

	return @[action];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView setEditing:NO animated:YES];
}

-(void)openColorPicker {
    ViewController *colorPickerController = [[ViewController alloc] initWithDefaultsKey:@"chosenColor" domain:@"com.apple.preferences" defaultColor:createColor(255.0, 149.0, 0.0)];
    [self presentViewController:colorPickerController animated:YES completion:nil];
}

@end
