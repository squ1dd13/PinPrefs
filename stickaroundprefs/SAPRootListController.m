#include "SAPRootListController.h"

UIColor *createColor(const float r, const float g, const float b) {
	return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0f];
}

@implementation SAPHeaderView
#define fakeCellView _fakeCellView
#define fakeSwipeView _fakeSwipeView

- (id)initWithSpecifier:(PSSpecifier *)specifier {
	self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
	if (self) {
		CGRect frame = [self frame];
		frame.size.height *= 2;
		[self setFrame:frame];

		fakeCellView = [[UIView alloc] initWithFrame:[self frame]];
		fakeCellView.backgroundColor = createColor(21, 21, 21);

		UILabel *fakeCellLabel = [[UILabel alloc] initWithFrame:[self frame]];
		fakeCellLabel.textAlignment = NSTextAlignmentLeft;
		fakeCellLabel.textColor = createColor(157, 157, 157);
		fakeCellLabel.text = @" StickAround";
		fakeCellLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:30];
		fakeCellLabel.adjustsFontSizeToFitWidth = YES;

		[fakeCellView addSubview:fakeCellLabel];

		fakeSwipeView = [[UIView alloc] initWithFrame:CGRectMake(self.frame.origin.x + self.frame.size.width, self.frame.origin.y, self.frame.size.width / 4, self.frame.size.height)];
		fakeSwipeView.backgroundColor = createColor(242, 28, 84);

		UILabel *fakeSwipeLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.origin.x + self.frame.size.width, self.frame.origin.y, self.frame.size.width / 4.5, self.frame.size.height)];
		fakeSwipeLabel.textAlignment = NSTextAlignmentCenter;
		fakeSwipeLabel.textColor = createColor(21, 21, 21);
		fakeSwipeLabel.text = @"By Squ1dd13";
		fakeSwipeLabel.adjustsFontSizeToFitWidth = YES;

		[fakeSwipeView addSubview:fakeSwipeLabel];

		[self addSubview:fakeCellView];
		[self addSubview:fakeSwipeView];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loopAnimations:) name:@"oi move" object:nil];
	}
	return self;
}

-(void)simulateSwipe {
	[UIView animateWithDuration:0.5 animations:^{
			CGRect newCellFrame = [fakeCellView frame];
			newCellFrame.origin.x -= fakeSwipeView.frame.size.width;
			fakeCellView.frame = newCellFrame;

			CGRect newSwipeFrame = [fakeSwipeView frame];
			newSwipeFrame.origin.x -= fakeSwipeView.frame.size.width;
			fakeSwipeView.frame = newSwipeFrame;
	    } completion:^(BOOL finished) {}
	];
}

-(void)simulateReset {
	[UIView animateWithDuration:0.5 animations:^{
			CGRect newCellFrame = [fakeCellView frame];
			newCellFrame.origin.x += fakeSwipeView.frame.size.width;
			fakeCellView.frame = newCellFrame;

			CGRect newSwipeFrame = [fakeSwipeView frame];
			newSwipeFrame.origin.x += fakeSwipeView.frame.size.width;
			fakeSwipeView.frame = newSwipeFrame;
	    } completion:^(BOOL finished) {}
	];
}

-(void)loopAnimations:(NSNotification *)n {
	while(true) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			[self simulateSwipe];
		});

		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			[self simulateReset];
		});
	}
}

- (CGFloat)preferredHeightForWidth:(CGFloat)arg1 {
    return 140.0f;
}
@end

@implementation SAPRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}

	return _specifiers;
}

-(void)viewDidAppear:(BOOL)animated {
	//[[NSNotificationCenter defaultCenter] postNotificationName:@"oi move" object:self];
}

@end
