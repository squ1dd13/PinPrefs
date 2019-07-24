@class PSSpecifier;
#import <Preferences/PSListController.h>
#import <Preferences/PSTableCell.h>
#include <iostream>
#include <fstream>
#include <sys/stat.h>
#include <sys/types.h>
#include <dlfcn.h>

UIColor *createColor(const float r, const float g, const float b, const float a = 1.0) {
	return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a];
}

/*
Bugs:
	- The Wallet & Apple Pay cell duplicates itself, adding one version in the original group and the other gets pinned.
	- When the Touch ID & Passcode specifier has a different ID, it doesn't ask for a passcode when opened.
	- When the APPLE_ACCOUNT specifier is pinned and the cell is used, the Settings app crashes and will not open again.
	- The Wifi cell's subtitle (the network name) doesn't change when turned off while pinned.
*/

/*
Stuff worth saying:
	- Dunno if iOS 12 is supported. Probably not.
	- Maybe adding a 3D Touch action to clear all pins would be a good idea?
	- A blacklist for cells that can't be pinned should be introduced.
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
-(void)reloadSpecifierID:(id)identifier animated:(BOOL)anim;
-(void)reloadSpecifier:(PSSpecifier *)speccy;
-(void)reloadVisible;
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

bool dylibLoaded(const char *name) {
	return dlopen(name, RTLD_NOLOAD);
}

@interface PSTableCell (Spaghetti)
-(void)reloadWithSpecifier:(id)speccy animated:(BOOL)anime;
@end

%hook PSTableCell

-(void)setValue:(id)val {
	if(![val isEqual:[self performSelector:@selector(value)]]) {
		//The value is going to change, so change it...
		%orig;
		//Now reload the specifier in the PSUIPrefsListController.
		PSUIPrefsListController *controller = (PSUIPrefsListController *)[self performSelector:@selector(_viewControllerForAncestor)];
		//[controller reloadSpecifier:[self specifier]];
		//[self reloadWithSpecifier:[self specifier] animated:YES];
		[controller reloadVisible];
	} else {
		%orig;
	}
}

%end

%hook PSUIPrefsListController
- (void)viewDidAppear:(BOOL)animated {
	%orig;

	//If we have already warned the user about Cask, just return.
	if(std::ifstream("/var/mobile/Library/Application Support/StickAround/warned.lol")) return;

	//Check for Cask (as it animates cells when we reload and that looks bad).
	bool foundCask = dylibLoaded("/Library/MobileSubstrate/DynamicLibraries/Cask.dylib");

	if(foundCask) {
		UINotificationFeedbackGenerator *feedbackGen = [[UINotificationFeedbackGenerator alloc] init];
		[feedbackGen prepare];
		[feedbackGen notificationOccurred:UINotificationFeedbackTypeWarning];

		NSString *message = @"Please note that Cask animates cells when they are refreshed, which causes lots of unnecessary animations to take place when you pin cells in the Settings app. Please consider removing Cask if you wish to have a better experience.";
		showAlert(@"Cask Installed", message, @"Okay");
		mkdir("/var/mobile/Library/Application Support/StickAround", 0755);

		std::ofstream warnedFile("/var/mobile/Library/Application Support/StickAround/warned.lol");
		warnedFile << "go away im sleeping" << std::endl;
		warnedFile.close();
	}
}

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
		savePinned();
	}

	//TODO: Somehow load app cells.
	for(int i = 0, addIndex = 0; i < [pins count]; i++) {
		PSSpecifier *pinnedSpecifier = getSpecifier([specifiers copy], pins[i]);
		//If the specifier doesn't exist, we obviously can't add it.
		//We don't want to add Bluetooth, and the user has to have modified
		//	NSUserDefaults to add it (because we guard against it). If they modified NSUserDefaults to add it, they must have known
		//	that they were trying to cheat the system. Now they will also know that you *can't* cheat the system (easily).
		if(!pinnedSpecifier || [pinnedSpecifier.identifier isEqualToString:@"Bluetooth"]) {
			continue;
		}

		//This changes the identifier for the pinned cell and the original cell, but also seems to get around the 'too many sections' crash.
		//It's also worth noting that changing the identifier doesn't seem to be linked to any issues.
		pinnedSpecifier.identifier = [[pinnedSpecifier identifier] stringByAppendingString:@"_PINNED"];

		[specifiers insertObject:pinnedSpecifier atIndex:addIndex];

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
	static UINotificationFeedbackGenerator *feedbackGen = [[UINotificationFeedbackGenerator alloc] init];

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
			PSSpecifier *specifier = [(PSUIPrefsListController *)tableView.dataSource specifierForIndexPath:indexPath];
			if([[specifier name] isEqualToString:@"Bluetooth"]) {
				//Pinning bluetooth is a really bad idea... It causes an instant crash due to some reloading issue (-[PSUIPrefsListController bluetoothPowerChanged:] causes it).
				//It's at the top anyway... Why tf would you pin it?

				//Give the triple-tick haptic feeling to represent an error. This is designed to represent an error, so ima use it.
				//Anything that makes the tweak feel like part of iOS is a good thing to use.
				[feedbackGen prepare];
				[feedbackGen notificationOccurred:UINotificationFeedbackTypeError];

				showAlert(@"Bluetooth", @"Sorry, pinning the Bluetooth cell is not yet supported and may cause stability issues.", @"Okay");
				return;
			}

			if(specifierIsAppSpecifier(specifier)) {
				//At the moment, due to the loading order of specifiers, app specifiers produce undefined behaviour.
				/*
					The pinned app specifier is a mysterious creature, characterised by extraordinary shyness. They are only
					known to come out when all the specifiers are loaded, but soon hide again when specifiers are reloaded.
				*/
				//As such, we have a moral obligation to warn the user of the possible (and likely) outcomes of their choice.

				[feedbackGen prepare];
				[feedbackGen notificationOccurred:UINotificationFeedbackTypeWarning];

				NSString *message = @"Due to the order that the settings are loaded in, pinning app cells can produce undefined behaviour. Are you sure you want to pin the cell?";
				UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Warning" message:message preferredStyle:UIAlertControllerStyleAlert];

				UIAlertAction *yessir = [UIAlertAction actionWithTitle:@"Pin" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
					//What a fucking great idea. Good choice, user.
					[pins addObject:specifierIdentifier];
					savePinned();
					[self reloadSpecifiers];
				}];

				[alert addAction:yessir];

				UIAlertAction *nosir = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
				[alert addAction:nosir];

				[[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:alert animated:YES completion:nil];
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

%new
-(void)reloadVisible {
	NSArray<PSTableCell *> *visibleCells = [[self table] performSelector:@selector(visibleCells)];
	for(PSTableCell *cell in visibleCells) {
		[cell reloadWithSpecifier:[cell specifier] animated:YES];
	}
}

%end
