//
//  BDImporter.m
//  Adium
//
//  Created by Brandon on 2/3/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BDImporter.h"

@interface BDImporter(PRIVATE)


@end

@implementation BDImporter

#pragma mark Initialization & Deallocation
#pragma mark -

- (id)initWithIdentifier:(NSString *)clientName
{
	clientIcon = [[NSWorkspace sharedWorkspace]iconForFile:[[NSWorkspace sharedWorkspace] fullPathForApplication:clientName]];
	
	return self;
}

- (void)dealloc
{
}

#pragma mark Simple accessors
#pragma mark -

- (NSImage *)iconAtSize:(int)iconSize
{
	return [clientIcon setSize:NSMakeSize(iconSize,iconSize)];
}
@end
