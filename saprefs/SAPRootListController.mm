#include "SAPRootListController.h"
#include <string>
#include <sstream>

//https://stackoverflow.com/a/26341062/8622854
NSString *hexFromUIColor(UIColor *color) {
    const CGFloat *components = CGColorGetComponents(color.CGColor);

    CGFloat r = components[0];
    CGFloat g = components[1];
    CGFloat b = components[2];

    return [NSString stringWithFormat:@"#%02lX%02lX%02lX",
            lroundf(r * 255),
            lroundf(g * 255),
            lroundf(b * 255)];
}

CGFloat colorComponentFromString(NSString *string, NSUInteger start, NSUInteger length) {
    NSString *substring = [string substringWithRange: NSMakeRange(start, length)];
    NSString *fullHex = length == 2 ? substring : [NSString stringWithFormat: @"%@%@", substring, substring];
    unsigned hexComponent;
    [[NSScanner scannerWithString: fullHex] scanHexInt: &hexComponent];
    return hexComponent / 255.0;
}

UIColor *colorFromHexString(NSString *hexString) {
    NSString *colorString = [[hexString stringByReplacingOccurrencesOfString:@"#" withString:@""] uppercaseString];

    CGFloat alpha, red, blue, green;

    // #RGB
    alpha = 1.0f;
    red   = colorComponentFromString(colorString, 0, 2);
    green = colorComponentFromString(colorString, 2, 2);
    blue  = colorComponentFromString(colorString, 4, 2);

    return [UIColor colorWithRed: red green: green blue: blue alpha: alpha];
}

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

@implementation SQColorPicker

-(void)viewDidLoad {
	[super viewDidLoad];

	_defaultsKey = getDefaultsKeyForSpecifierID([[self performSelector:@selector(specifier)] performSelector:@selector(identifier)]);
	if([[NSUserDefaults standardUserDefaults] objectForKey:_defaultsKey]) {
        if(![[[NSUserDefaults standardUserDefaults] objectForKey:_defaultsKey] isMemberOfClass:[NSString class]]) {
            [[NSUserDefaults standardUserDefaults] setObject:@"#000000" forKey:_defaultsKey];
        }
		UIColor *col = colorFromHexString([[NSUserDefaults standardUserDefaults] objectForKey:_defaultsKey]);
		[self setColor:col];
	} else {
		[self setColor:createColor(255, 255, 255)];
	}

	_rSlider = [[UISlider alloc] initWithFrame:CGRectMake(20, 100, self.view.frame.size.width - 40, 44)];
	_gSlider = [[UISlider alloc] initWithFrame:CGRectMake(20, 200, self.view.frame.size.width - 40, 44)];
	_bSlider = [[UISlider alloc] initWithFrame:CGRectMake(20, 300, self.view.frame.size.width - 40, 44)];

	_rSlider.minimumValue = _gSlider.minimumValue = _bSlider.minimumValue = 0;
	_rSlider.maximumValue = _gSlider.maximumValue = _bSlider.maximumValue = 255;
	_rSlider.value = _gSlider.value = _bSlider.value = 255;

	[_rSlider addTarget:self action:@selector(updateBackgroundColor:) forControlEvents:UIControlEventValueChanged];
	[_gSlider addTarget:self action:@selector(updateBackgroundColor:) forControlEvents:UIControlEventValueChanged];
	[_bSlider addTarget:self action:@selector(updateBackgroundColor:) forControlEvents:UIControlEventValueChanged];

	[[self view] addSubview:_rSlider];
	[[self view] addSubview:_gSlider];
	[[self view] addSubview:_bSlider];
}

-(void)updateBackgroundColor:(UISlider *)sender {
    const float r = _rSlider.value;
    const float g = _gSlider.value;
    const float b = _bSlider.value;

    _color = createColor(r, g, b);
	self.view.backgroundColor = _color;
}

- (void)viewWillDisappear:(BOOL)animated {
	//Save the colour.
	@try {
		[[NSUserDefaults standardUserDefaults] setObject:hexFromUIColor(_color) forKey:_defaultsKey];
	}
	@catch(NSException *e) {
		showAlert(@"err", e.reason, @"fuck");
	}

	[super viewWillDisappear:animated];
}

-(void)setColor:(UIColor *)color {
	CGFloat r = 0, g = 0, b = 0, a = 0;
	[color getRed:&r green:&g blue:&b alpha:&a];

	[_rSlider setValue:int(r * 255)];
	[_gSlider setValue:int(g * 255)];
	[_bSlider setValue:int(b * 255)];

	_color = color;
}

@end

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

@end
