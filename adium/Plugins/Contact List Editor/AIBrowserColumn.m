//
//  AIBrowserColumn.m
//  Adium XCode
//
//  Created by Adam Iser on Sun Jan 11 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIBrowserColumn.h"


@implementation AIBrowserColumn

- (id)initWithScrollView:(id)inScroll tableView:(id)inTable representedObject:(id)inObject
{
	[super init];
	
	scrollView = [inScroll retain];
	tableView = [inTable retain];
	representedObject = [inObject retain];
	
	return(self);
}

- (void)dealloc
{
	[scrollView release];
	[tableView release];
	[representedObject release];
	
	
	[super dealloc];
}

- (NSScrollView *)scrollView
{
	return(scrollView);
}

- (NSTableView *)tableView
{
	return(tableView);
}

- (id)representedObject
{
	return(representedObject);
}


@end
