//
//  ESDockBehaviorContactAlert.m
//  Adium
//
//  Created by Evan Schoenberg on Thu Nov 27 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "ESDockAlertDetailPane.h"

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
    [popUp_actionDetails setMenu:[AIDockBehaviorPlugin behaviorListMenuForTarget:self]];
}

//Configure for the action
- (void)configureForActionDetails:(NSDictionary *)inDetails listObject:(AIListObject *)listObject
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
	//Empty
}

@end

