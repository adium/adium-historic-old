//
//  AIContactInfoContentController.m
//  Adium
//
//  Created by Elliott Harris on 1/13/08.
//  Copyright 2008 Adium. All rights reserved.
//

#import "AIContactInfoContentController.h"

@interface AIContactInfoContentController (PRIVATE)
//Methods for animation and managing inspector views.
-(void)addInspectorView:(NSView *)aView animate:(BOOL)doAnimate;
-(void)animateRemovingRect:(NSRect)aRect inView:(NSView *)aView;
-(void)animateViewIn:(NSView *)aView;
-(void)animateViewOut:(NSView *)aView;
-(void)_setLoadedPanes:(NSArray *)anArray;
@end

@implementation AIContactInfoContentController

- (id) init
{
	return [self initWithContentPanes:[AIContactInfoContentController defaultPanes]];
}

- (id)initWithContentPanes:(NSArray *)panes
{
	self = [super init];
	if (self != nil) {
		[self loadContentPanes:panes];
	}
	return self;
}

+(NSArray *)defaultPanes
{
	return [NSArray arrayWithObjects:@"AIInfoInspectorPane", @"AIAddressBookInspectorPane", @"AIEventsInspectorPane",
			@"AIAdvancedInspectorPane", nil];
}

-(NSArray *)loadedPanes
{
	return loadedPanes;
}

-(void)_setLoadedPanes:(NSArray *)newPanes
{
	if(loadedPanes == newPanes)
		return;
	[loadedPanes release];
	loadedPanes = [newPanes retain];
}

-(void)loadContentPanes:(NSArray *)contentPanes
{
	NSMutableArray *contentArray = [[NSMutableArray alloc] init];
	//Allocate and initalize each class, then stick it in the array.
	id currentPane = nil;
	NSEnumerator *paneEnumerator = [contentPanes objectEnumerator];
	
	while((currentPane = [paneEnumerator nextObject])) {
		Class planeClass = nil;
		if(!(planeClass = NSClassFromString(currentPane))) {
			return nil;
		}
		
		[contentArray addObject:[[planeClass alloc] init]];
	}
	
	//FIXME: Remove NSLog.
	NSLog(@"Created content array: %@", contentArray);
	
	[self _setLoadedPanes:contentArray];
}


@end
