//
//  BDProteusImporter.m
//  Adium
//
//  Created by Brandon on 2/2/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "BDProteusImporter.h"


@implementation BDProteusImporter

- (id)init
{
	[self setProteusVersion];
	return self;
}

- (void)setProteusVersion
{
	NSBundle *pr0t3us = [NSBundle bundleWithPath:PATH_TO_PROTEUS];
	NSDictionary *proteusInfo = [NSDictionary dictionaryWithContentsOfFile:[pr0t3us pathForResource:@"Info" ofType:@".plist"]];
	NSLog(@"%@",[proteusInfo objectForKey:@"CFBundleShortVersionString"]);
	
}




@end
