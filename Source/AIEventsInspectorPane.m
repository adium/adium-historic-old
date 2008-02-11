//
//  AIEventsInspectorPane.m
//  Adium
//
//  Created by Elliott Harris on 1/17/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "AIEventsInspectorPane.h"

#define EVENTS_NIB_NAME (@"AIEventsInspectorPane")

@implementation AIEventsInspectorPane

- (id) init
{
	self = [super init];
	if (self != nil) {
		[NSBundle loadNibNamed:[self nibName] owner:self];
		//Other init goes here.
	}
	return self;
}

-(NSString *)nibName
{
	return EVENTS_NIB_NAME;
}

-(NSView *)inspectorContentView
{
	return inspectorContentView;
}

-(void)updateForListObject:(AIListObject *)inObject
{
	//Events update goes here.
}

@end
