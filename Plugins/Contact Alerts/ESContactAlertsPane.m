//
//  ESContactAlertsWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Jul 14 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#import "ESContactAlertsPane.h"
#import <Adium/ESContactAlertsViewController.h>

@implementation ESContactAlertsPane

//Preference pane properties
- (CONTACT_INFO_CATEGORY)contactInfoCategory{
    return(AIInfo_Alerts);
}
- (NSString *)label{
    return(@"Contact Alerts");
}
- (NSString *)nibName{
    return(@"ContactAlerts");
}

- (void)configureForListObject:(AIListObject *)inObject{
	[contactAlertsViewController configureForListObject:inObject];
}

- (void)viewWillClose
{
	[contactAlertsViewController viewWillClose];
	
	[super viewWillClose];
}
@end