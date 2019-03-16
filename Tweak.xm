@class PSSpecifier;
#import <Preferences/PSListController.h>

@interface PSUIPrefsListController : PSListController
-(void)_moveSpecifierAtIndex:(NSUInteger)index toIndex:(NSUInteger)toIndex animated:(BOOL)anim;
-(NSUInteger)indexForIndexPath:(NSIndexPath *)indexPath;
-(void)performSpecifierUpdates:(id)arg1;
-(NSMutableArray *)specifiers;
-(void)setSpecifiers:(NSArray *)spec;
-(void)removeSpecifierAtIndex:(NSUInteger)index animated:(BOOL)animated;
-(void)insertSpecifier:(id)spec atIndex:(NSUInteger)index animated:(BOOL)a;
-(void)reloadSpecifiers;
-(NSInteger)indexOfSpecifier:(PSSpecifier *)specifier;
-(void)removeSpecifier:(PSSpecifier *)specifier animated:(BOOL)a;
-(void)createPinGroup;
-(void)recreatePinnedCells;
-(PSSpecifier *)specifierForID:(NSString *)identifier;
-(void)cleanOutPinGroups;
@end

//static BOOL hasInsertedSection = NO;
static NSMutableArray *pinnedSpecifiers;

@interface PSSpecifier : NSObject
@property (nonatomic, assign) BOOL pinned;
@property (nonatomic, assign) BOOL isPinGroup;
@property (nonatomic, assign) BOOL isTwinGroup;
@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) NSString *identifier;
-(void)setProperties:(id)properties;
@end

%hook PSSpecifier
%property (nonatomic, assign) BOOL pinned;
%property (nonatomic, assign) BOOL isPinGroup;
%property (nonatomic, assign) BOOL isTwinGroup;
%end

%ctor {
	NSLog(@"Getting ready to load");
	//TODO: remove this, it is unnecessary
	pinnedSpecifiers = [NSMutableArray array];
}

//static NSUInteger lastIndex = 0;

static BOOL hasAddedGroup = NO;
static BOOL recovering = NO;
static BOOL hasSwitched = NO;
static PSSpecifier *currentPinGroup;
static PSSpecifier *currentTwinGroup;

BOOL hasAnyGroup(NSArray *specifiers) {
	for(PSSpecifier *specifier in specifiers) {
		if([[specifier identifier] containsString:@"PINNED_CELLS_GROUP"]) return YES;
	}
	return NO;
}

NSArray *groupsInArray(NSArray *array) {
	NSMutableArray *matches = [NSMutableArray array];
	for(PSSpecifier *specifier in array) {
		if([[specifier identifier] containsString:@"PINNED_CELLS_GROUP"]) {
			[matches addObject:specifier];
		}
	}
	return [matches copy];
}
/*
#import <objc/runtime.h>

@implementation PSListController (Specifiers)

+ (void)load {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		Class cls = [self class];
		if(![self isKindOfClass:NSClassFromString(@"PSUIPrefsListController")]) return;

		SEL originalSelector = @selector(specifiers);
		SEL swizzledSelector = @selector(pinp_specifiers);

		Method originalMethod = class_getInstanceMethod(cls, originalSelector);
		Method swizzledMethod = class_getInstanceMethod(cls, swizzledSelector);

		BOOL didAddMethod =
		class_addMethod(cls, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));

		if (didAddMethod) {
			class_replaceMethod(cls, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
		} else {
			method_exchangeImplementations(originalMethod, swizzledMethod);
		}
	});
}

- (NSMutableArray *)pinp_specifiers {
	NSMutableArray *specifiers = [self pinp_specifiers];
	PSSpecifier *pinGroupSpecifier = [[%c(PSSpecifier) alloc] init];

	[pinGroupSpecifier setProperties:@{
		@"id" : @"PINNED_CELLS_GROUPPdsds",
		@"cell" : @"PSGroupCell",
		@"isTopLevel" : @YES
	}];
	[specifiers addObject:pinGroupSpecifier];
	return specifiers;
}

@end
*/
%hook PSUIPrefsListController
/*
+ (void)load {
	NSLog(@"Load");
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		Class cls = [self class];

		SEL originalSelector = @selector(specifiers);
		SEL swizzledSelector = @selector(pinp_specifiers);

		Method originalMethod = class_getInstanceMethod(cls, originalSelector);
		Method swizzledMethod = class_getInstanceMethod(cls, swizzledSelector);

		BOOL didAddMethod =
		class_addMethod(cls, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));

		if (didAddMethod) {
			class_replaceMethod(cls, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
		} else {
			method_exchangeImplementations(originalMethod, swizzledMethod);
		}
	});
}

%new
- (NSMutableArray *)pinp_specifiers {
	NSMutableArray *specifiers = [self pinp_specifiers];
	PSSpecifier *pinGroupSpecifier = [[%c(PSSpecifier) alloc] init];

	[pinGroupSpecifier setProperties:@{
		@"id" : @"PINNED_CELLS_GROUPPdsds",
		@"cell" : @"PSGroupCell",
		@"isTopLevel" : @YES
	}];
	[specifiers addObject:pinGroupSpecifier];
	return specifiers;
}
*/
-(void)loadView {
	%orig;
	//if(!recovering) {
	NSLog(@"Specifiers class: %@", NSStringFromClass([[self specifiers] class]));
	[self recreatePinnedCells];
	//} else {
	//	NSLog(@"Recovering from error.");
//	}
}

-(void)reloadSpecifiers {
	%orig;
	if(!recovering) {
		hasAddedGroup = NO;
		[self recreatePinnedCells];
	} else {
		NSLog(@"Recovering from error.");
	}
}
/*
-(NSMutableArray *)specifiers {
	NSMutableArray *specifiers = %orig;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		PSSpecifier *pinGroupSpecifier = [[%c(PSSpecifier) alloc] init];

		[pinGroupSpecifier setProperties:@{
			@"id" : @"PINNED_CELLS_GROUPssP",
			@"cell" : @"PSGroupCell",
			@"isTopLevel" : @YES
		}];
		[specifiers insertObject:pinGroupSpecifier atIndex:0];
	});
	return specifiers;
}
*/
%new
-(void)recreatePinnedCells {
	NSLog(@"Loading saved specifiers");
	@try {

		//load the specifiers
		pinnedSpecifiers = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"pinnedSpecifiers"] mutableCopy];

		//if there are none saved, pinnedSpecifiers will be nil. Create it.
		if(!pinnedSpecifiers) {
			pinnedSpecifiers = [NSMutableArray array];
			[[NSUserDefaults standardUserDefaults] setObject:pinnedSpecifiers forKey:@"pinnedSpecifiers"];
		}

		NSLog(@"%@", pinnedSpecifiers);

		//temp storage for matches
		NSMutableArray *found = [NSMutableArray array];

		//go through the specifier names, and look at the loaded specifiers to find which one it is
		for(NSString *specifierName in pinnedSpecifiers) {
			for(PSSpecifier *specifier in [self specifiers]) {
				if([specifier.name isEqualToString:specifierName]) {
					[found addObject:specifier];
				}
			}
		}

		NSLog(@"Found: %@", found);


		BOOL first = YES;
		//pin all the matches
		for(PSSpecifier *specifier in found) {
			specifier.pinned = YES;
			/*

			PSSpecifier *pinGroupSpecifier = [[%c(PSSpecifier) alloc] init];
			[pinGroupSpecifier setProperties:@{
				@"id" : @"PINNED_CELLS_GROUP",
				@"cell" : @"PSGroupCell",
				@"isTopLevel" : @YES
			}];
			NSLog(@"Group: %@", pinGroupSpecifier);
			[self insertSpecifier:pinGroupSpecifier atIndex:[self indexForIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] animated:YES];
			hasAddedGroup = YES;
			*/
			//static dispatch_once_t onceToken;
			//dispatch_once(&onceToken, ^{
				//[self createPinGroup];
			//});

			if(first) {
				first = NO;
				if(!hasAddedGroup) [self createPinGroup];

				//if the group cannot be added, then hasAddedGroup will return false
				if(!hasAddedGroup) {
					NSLog(@"Could not create a group cell, stopping here.");
					return;
				}
			}

			NSLog(@"Done group, pinning specifiers now.");
			NSUInteger newIndex = [self indexForIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
			[self insertSpecifier:specifier atIndex:newIndex animated:YES];
			NSLog(@"Pinned one.");
		}
	}
	@catch(NSException *e) {
		NSLog(@"ERR: %@", e.reason);
	}
}

-(void)dataSource:(id)dtas performUpdates:(id)upds {
	NSLog(@"%@ %@", dtas, upds);
	%orig;
}

%new
-(void)cleanOutPinGroups {
	//if(hasAnyGroup([self specifiers])) {
		//NSLog(@"Cleaning out groups...");
		//for(PSSpecifier *brokenGroup in groupsInArray([self specifiers])) {
			//if(brokenGroup.isPinGroup) {
				//[self removeSpecifier:brokenGroup animated:YES];
			//}
		//}
	//}
}

/*
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section==[self numberOfSectionsInTableView:tableView]-1) {
        return sectionFooterHeight;
    }
    return 0;
}
*/
%new
-(void)createPinGroup {
	//if(!hasAddedGroup) {
	NSMutableArray *oldSpecs = [self specifiers];
	@try {
		NSLog(@"Creating pin group.");
		PSSpecifier *pinGroupSpecifier = [[%c(PSSpecifier) alloc] init];

		//if we will need to swap, then put in the misspelled name
		//NSString *ID = ([self specifierForID:@"PRIMARY_APPLE_ACCOUNT_GROUP"]) ? @"PINNED_CELLS_GROUPP" : @"PINNED_CELLS_GROUP";
		[pinGroupSpecifier setProperties:@{
			@"id" : @"PINNED_CELLS_GROUPP",
			@"cell" : @"PSGroupCell",
			@"isTopLevel" : @YES
		}];

		[self cleanOutPinGroups];

		@try {
			[self insertSpecifier:pinGroupSpecifier atIndex:[self indexForIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] animated:YES];
			hasAddedGroup = YES;
		}
		@catch(NSException *e) {
			//failed
			[self insertSpecifier:pinGroupSpecifier atIndex:[self indexForIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]] animated:YES];
			hasAddedGroup = YES;
		}



		//on devices that don't display the account cells, we need to swap with the wireless group
		NSString *indentifierToSwitchWith = ([self specifierForID:@"PRIMARY_APPLE_ACCOUNT_GROUP"]) ? @"PRIMARY_APPLE_ACCOUNT_GROUP" : @"WIRELESS_GROUP";


		//the account group is section 0, so we actually inserted our group into that. Swapping the specifier IDs around puts the pin group in the perfect place.
		NSLog(@"Switching specifier IDs");

/*
		//ORDER IS VITAL
		//changing the stock group ID to the pin group ID
		for(PSSpecifier *spec in [self specifiers]) {
			if([spec.identifier isEqualToString:indentifierToSwitchWith] || [spec isEqualToSpecifier:currentTwinGroup]) {
				[spec setIdentifier:@"PINNED_CELLS_GROUP"];
				spec.isPinGroup = YES;
				spec.isTwinGroup = NO;
				NSLog(@"Switched stock --> pin");
				hasSwitched = YES;
				currentPinGroup = spec;
				break;
			}
		}

		//changing the new group ID to the stock group ID
		for(PSSpecifier *spec in [self specifiers]) {
			if ([spec.identifier isEqualToString:@"PINNED_CELLS_GROUPP"] || [spec isEqualToSpecifier:currentPinGroup]) {
				[spec setIdentifier:indentifierToSwitchWith];
				spec.isTwinGroup = YES;
				spec.isPinGroup = NO;
				currentTwinGroup = spec;
				NSLog(@"Switched new --> stock");
				break;
			}
		}
*/

		//FIXME: only works a few times and then breaks due to a mixup of IDs
		for(PSSpecifier *spec in [self specifiers]) {
			BOOL hasDoneFirst = NO;
			if([spec.identifier isEqualToString:indentifierToSwitchWith]) {
				[spec setIdentifier:@"PINNED_CELLS_GROUP"];
				spec.isPinGroup = YES;
				NSLog(@"Changed first group.");
				hasDoneFirst = YES;
			} else if ([spec.identifier isEqualToString:@"PINNED_CELLS_GROUPP"]) {
				//if the original ID were spelled correctly, we would get a crash, because you can't have two IDs the same.
				[spec setIdentifier:indentifierToSwitchWith];
				NSLog(@"Changed second group.");
				if(hasDoneFirst) {
					//if we have finished both bits of the swap, we can stop enumerating
					break;
				}
			}
		}
		hasSwitched = YES;

	}
	@catch(NSException *e) {
		NSLog(@"Groups: %lu", (unsigned long)[self numberOfGroups]);
		NSLog(@"Diff: %@", [self specifiers]);
		NSMutableArray *groups = [NSMutableArray array];
		for(PSSpecifier *spec in [self specifiers]) {
			if([[[spec properties] objectForKey:@"cell"] isEqualToString:@"PSGroupCell"]) {
				[groups addObject:spec];
			}
		}
		NSLog(@"%@", groups);
		NSLog(@"EXC: %@", e.reason);
	}
}

%new
- (BOOL)tableView: (UITableView *)tableView canEditRowAtIndexPath: (NSIndexPath *)indexPath {
	return YES;
}

%new
- (NSArray *)tableView: (UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath_ {
	//TODO: remove try and catch
	UITableViewRowAction *pin = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Pin" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
		NSLog(@"Pin");
		@try {
			NSUInteger newIndex = [(PSUIPrefsListController *)tableView.dataSource indexForIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];

			PSSpecifier *specifier = [[tableView cellForRowAtIndexPath:indexPath] valueForKey:@"specifier"];
			specifier.pinned = YES;
			NSLog(@"Specifier is: %@, found in cell: %@, index %lu", specifier, [tableView cellForRowAtIndexPath:indexPath], (unsigned long)[self indexForIndexPath:indexPath]);

			if(!specifier) {
				NSLog(@"Unable to find specifier.");
				//failed to get specifier
				UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
				specifier = [cell valueForKey:@"specifier"];
				specifier.pinned = YES;
			}

			if(!hasAddedGroup) [self createPinGroup];

			[self insertSpecifier:specifier atIndex:newIndex animated:YES];

			//we have to store the name, because PSSpecifiers cannot be saved in NSUserDefaults
			[pinnedSpecifiers addObject:specifier.name];
			NSLog(@"Pinned: %@, now %@", specifier.name, pinnedSpecifiers);

			[[NSUserDefaults standardUserDefaults] setObject:pinnedSpecifiers forKey:@"pinnedSpecifiers"];

			//instantly write our changes
			[[NSUserDefaults standardUserDefaults] synchronize];

			NSLog(@"Currently loaded: %@", [[NSUserDefaults standardUserDefaults] objectForKey:@"pinnedSpecifiers"]);
		}
		@catch(NSException *e) {
			NSLog(@"ERR: %@", e.reason);
		}
	}];

	//we don't want to let the user pin the same cell multiple times, so if the cell is pinned, we change it to an unpin button
	PSSpecifier *specifier = [[tableView cellForRowAtIndexPath:indexPath_] valueForKey:@"specifier"];
	if(specifier.pinned) {
		//we cannot change the handler block once created, so we need to reassign pin
		pin = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Unpin" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
			@try {
			NSLog(@"Unpin");
			specifier.pinned = NO;

			[pinnedSpecifiers removeObject:specifier.name];
			[[NSUserDefaults standardUserDefaults] setObject:pinnedSpecifiers forKey:@"pinnedSpecifiers"];
			[[NSUserDefaults standardUserDefaults] synchronize];

			[self removeSpecifierAtIndex:[self indexForIndexPath:indexPath] animated:YES];

			//make sure there are no nonexistent specifiers
			for(NSString *name in pinnedSpecifiers) {
				BOOL hasFoundName = NO;
				for(PSSpecifier *spec in [self specifiers]) {
					if([spec.name isEqualToString:name]) {
						hasFoundName = YES;
					}
				}
				if(!hasFoundName) {
					[pinnedSpecifiers removeObject:name];
				}
			}

			//if there are no more pinned cells, we need to remove the group
			if([pinnedSpecifiers count] == 0) {
				NSLog(@"No more pins");
				for(PSSpecifier *spec in [self specifiers]) {
					if([spec.identifier isEqualToString:@"PINNED_CELLS_GROUP"] || spec.isPinGroup) {
						NSLog(@"Found group cell.");
						[self removeSpecifier:spec animated:YES];
						hasAddedGroup = NO;
						currentPinGroup = nil;
						break;
					}
				}
				[self cleanOutPinGroups];
			} else {
				NSLog(@"Pinned now: %@", pinnedSpecifiers);
			}
			}
			@catch(NSException *e) {
				NSLog(@"ERR: %@, pncur: %@", e.reason, pinnedSpecifiers);
			}
		}];
	}

	//purple colour
	pin.backgroundColor = [UIColor colorWithRed:106/255.0 green:60/255.0 blue:188/255.0 alpha:1.0];
	return @[pin];
}

%new
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	//after the user has interacted with the action button, hide it again
	[tableView setEditing:NO animated:YES];
}

//-(NSInteger)numberOfGroups {
	//return %orig + 1;
//}

//-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	//return %orig + 1;
//}

%end

%hook UITableView

-(void)insertSections:(id)sects withRowAnimation:(NSInteger)a {
	NSLog(@"Inserting: %@", sects);
	%orig;
}
%end
