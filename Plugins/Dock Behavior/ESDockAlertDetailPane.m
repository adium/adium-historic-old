//
//  ESDockBehaviorContactAlert.m
//  Adium
//
//  Created by Evan Schoenberg on Thu Nov 27 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "ESDockAlertDetailPane.h"

@interface ESDockAlertDetailPane (PRIVATE)
- (NSMenuItem *)menuItemForBehavior:(DOCK_BEHAVIOR)behavior withName:(NSString *)name;
- (NSMenu *)behaviorListMenu;
@end

@implementation ESDockAlertDetailPane

//Pane Details
- (NSString *)label{
	return(@"");
}
- (NSString *)nibName{
    return(@"DockBehaviorContactAlert");    
}

//Configure the detail view
- (void)viewDidLoad
{
    [popUp_actionDetails setMenu:[self behaviorListMenu]];
}

//Configure for the action
- (void)configureForActionDetails:(NSDictionary *)inDetails listObject:(AIListObject *)inObject
{
	int behaviorIndex = [popUp_actionDetails indexOfItemWithRepresentedObject:[inDetails objectForKey:KEY_DOCK_BEHAVIOR_TYPE]];
	if(behaviorIndex >= 0 && behaviorIndex < [popUp_actionDetails numberOfItems]){
		[popUp_actionDetails selectItemAtIndex:behaviorIndex];        
	}
}

//Return our current configuration
- (NSDictionary *)actionDetails
{
	NSString	*behavior = [[popUp_actionDetails selectedItem] representedObject];
	
	if(behavior){
		return([NSDictionary dictionaryWithObject:behavior forKey:KEY_DOCK_BEHAVIOR_TYPE]);
	}else{
		return(nil);
	}	
}

//The user selected a behavior
- (IBAction)selectBehavior:(id)sender
{
	[self detailsForHeaderChanged];
}

//Builds and returns a dock behavior list menu
- (NSMenu *)behaviorListMenu
{
    NSMenu			*behaviorMenu = [[[NSMenu allocWithZone:[NSMenu menuZone]] init] autorelease];
    DOCK_BEHAVIOR	behavior;

	for(behavior = BOUNCE_ONCE; behavior < BOUNCE_DELAY60; behavior++){
		NSString *name = [[adium dockController] descriptionForBehavior:behavior];
		[behaviorMenu addItem:[self menuItemForBehavior:behavior withName:name]];
	}
    
    [behaviorMenu setAutoenablesItems:NO];
    
    return(behaviorMenu);
}

//
- (NSMenuItem *)menuItemForBehavior:(DOCK_BEHAVIOR)behavior withName:(NSString *)name
{
    NSMenuItem		*menuItem;
    menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:name
																	 target:self
																	 action:@selector(selectBehavior:)
															  keyEquivalent:@""] autorelease];
    [menuItem setRepresentedObject:[NSNumber numberWithInt:behavior]];
    
    return(menuItem);
}


@end

