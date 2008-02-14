//
//  AIEventsInspectorPane.h
//  Adium
//
//  Created by Elliott Harris on 1/17/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/AIListObject.h>
#import <Adium/AIListContact.h>
#import <AIContactInfoContentController.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/ESContactAlertsViewController.h>

@interface AIEventsInspectorPane : AIObject <AIContentInspectorPane> {
			 AIListObject						*displayedObject;
	
	IBOutlet NSView								*inspectorContentView;
	IBOutlet ESContactAlertsViewController		*alertsController;
	//Other IBOutlets here
}

-(NSString *)nibName;
-(NSView *)inspectorContentView;
-(void)updateForListObject:(AIListObject *)inObject;

@end
