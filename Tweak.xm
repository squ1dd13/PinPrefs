@class PSSpecifier;
#import <Preferences/PSListController.h>

UIColor *createColor(const float r, const float g, const float b, const float a = 1.0) {
	return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a];
}

/*
Bugs:
	- Changing one cell's value (say, a switch) doesn't update the other cell.
*/

/*
Stuff worth saying:
	- Dunno if iOS 12 is supported. Probably not.
	- NEEDS MORE C++
*/

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
-(PSSpecifier *)specifierForIndexPath:(NSIndexPath *)indexPath;
-(UITableView *)table;
@end

static NSMutableArray *pins;
bool didAddPinGroup = false;
void savePinned() {
	[[NSUserDefaults standardUserDefaults] setObject:pins forKey:@"pins"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

void showAlert(NSString *title, NSString *content, NSString *dismissButtonStr) {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:content preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *dismiss = [UIAlertAction actionWithTitle:dismissButtonStr style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:dismiss];
    [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:alert animated:YES completion:nil];
}

@interface PSSpecifier : NSObject
@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) NSString *identifier;
-(void)setProperties:(id)properties;
@end

bool specifierIsAppSpecifier(PSSpecifier *specifier) {
	//TODO: Make this more efficient (string comparison? really?).
	//Not to be used in a loop or anything, because that would be slow.
	Class dcc;
	return (dcc = [specifier valueForKey:@"detailControllerClass"]) && [NSStringFromClass(dcc) isEqualToString:@"PSAppListController"];
}

bool specifierIsTweakSpecifier(PSSpecifier *specifier) {
	return [specifier respondsToSelector:@selector(preferenceLoaderBundle)] && [specifier valueForKey:@"preferenceLoaderBundle"];
}

PSSpecifier *getSpecifier(NSArray *specifiers, NSString *identifier) {
	for(PSSpecifier *spec in specifiers) {
		if([[spec identifier] isEqualToString:identifier]) return spec;
	}

	return nil;
}

%hook PSUIPrefsListController
%new
-(PSSpecifier *)specifierForIndexPath:(NSIndexPath *)indexPath {
	return [[[self table] cellForRowAtIndexPath:indexPath] valueForKey:@"specifier"];
}

-(NSMutableArray *)specifiers {
	NSMutableArray *specifiers = %orig;

	//Get the pin identifiers.
	pins = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"pins"] mutableCopy];

	if(!pins) {
		pins = [NSMutableArray array];
		//Just set this in NSUserDefaults now.
		[[NSUserDefaults standardUserDefaults] setObject:pins forKey:@"pins"];
	}

	for(int i = 0, addIndex = 0; i < [pins count]; i++) {
		PSSpecifier *pinnedSpecifier = getSpecifier([specifiers copy], pins[i]);
		//If the specifier doesn't exist, we obviously can't add it.
		//We don't want to add Bluetooth, and the user has to have modified
		//	NSUserDefaults to add it (because we guard against it). If they modified NSUserDefaults to add it, they must have known
		//	that they were trying to cheat the system. Now they will also know that you *can't* cheat the system (easily).
		if(!pinnedSpecifier || [pinnedSpecifier.identifier isEqualToString:@"Bluetooth"]) {
			showAlert(pinnedSpecifier.identifier, [NSString stringWithFormat:@"skipping %@", pinnedSpecifier.identifier], @"cool");
			continue;
		}

		//This changes the identifier for the pinned cell and the original cell, but also seems to get around the 'too many sections' crash.
		//It's also worth noting that changing the identifier doesn't seem to be linked to any issues.
		pinnedSpecifier.identifier = [[pinnedSpecifier identifier] stringByAppendingString:@"_PINNED"];

		[specifiers insertObject:pinnedSpecifier atIndex:addIndex];
		showAlert(pinnedSpecifier.identifier, [NSString stringWithFormat:@"%@ pinned at specifiers index %d", pinnedSpecifier.identifier, addIndex], @"cool");

		//We added something, so increase addIndex. We can't just use i for adding as well as getting objects from the pins array,
		//	because then when we use 'continue' to skip, the next specifier gets added at 'i + 1' even though nothing was added at 'i' this time.
		addIndex++;
	}

	/*
		We don't need to add a group; by adding cells that already exist to the front of the specifiers array (so before the first group specifier),
		we force the creation of a new group. If we added new cells (not pointers to the original cells), we would need to create our own group.
	*/

	return specifiers;
}

%new
- (BOOL)tableView:(UITableView *)tv canEditRowAtIndexPath:(NSIndexPath *)ip {
	return YES;
}

%new
- (NSArray *)tableView: (UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath_ {
	//Get the specifier ID from the indexPath.
	NSString *specifierIdentifier = [[(PSUIPrefsListController *)tableView.dataSource specifierForIndexPath:indexPath_] identifier];

	//Work out if the action should be 'Pin' or 'Unpin'.
	bool isPinned = [pins containsObject:specifierIdentifier] || [specifierIdentifier containsString:@"_PINNED"];

	UITableViewRowAction *action = nil;
	if(isPinned) {
		//Create an unpin button.
		action = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Unpin" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
			//Remove from the pinned cells and reload.
			[pins removeObject:[specifierIdentifier stringByReplacingOccurrencesOfString:@"_PINNED.0" withString:@""]];
			savePinned();
			//By using reloadSpecifiers, we eliminate the issue of the swipe action closing animation being on the wrong cell.
			//If we added the specifier normally, all the visible cells would move down 1. reloadSpecifiers does not animate anything.
			//Using -[self setSpecifiers:] here is a really bad idea. While it does not cause crashes, it messes with the cells, and
			//	some pinned cells somehow turn into group cells, huge gaps get created, cells disappear, and a crash would probably follow
			//	any sort of attempt to use the cells.
			[self reloadSpecifiers];
		}];

		//Unpin button, so use orange.
		action.backgroundColor = createColor(255.0, 149.0, 0.0);
	} else {
		//Create a pin button.
		action = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Pin" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
			if([[[(PSUIPrefsListController *)tableView.dataSource specifierForIndexPath:indexPath] name] isEqualToString:@"Bluetooth"]) {
				//Pinning bluetooth is a really bad idea... It causes an instant crash due to some reloading issue (-[PSUIPrefsListController bluetoothPowerChanged:] causes it).
				//It's at the top anyway... Why tf would you pin it?

				//Give the triple-tick haptic feeling to represent an error. This is designed to represent an error, so ima use it.
				//Anything that makes the tweak feel like part of iOS is a good thing to use.
				if(NSClassFromString(@"UIFeedbackGenerator")) {
					UINotificationFeedbackGenerator *feedbackGen = [[UINotificationFeedbackGenerator alloc] init];
					[feedbackGen notificationOccurred:UINotificationFeedbackTypeError];
				}

				showAlert(@"Bluetooth", @"Sorry, pinning the Bluetooth cell is not yet supported and may cause stability issues.", @"Okay");
				return;
			}

			//Add to the pinned cells and reload.
			[pins addObject:specifierIdentifier];
			savePinned();
			[self reloadSpecifiers];
		}];

		//Pin button, so use green.
		action.backgroundColor = createColor(52.0, 199.0, 89.0);
	}

	return @[action];
}

%new
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView setEditing:NO animated:YES];
}

%end
