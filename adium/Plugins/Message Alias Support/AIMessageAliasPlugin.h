//
//  AIMessageAliasPlugin.h
//  Adium
//
//  Created by Benjamin Grabkowitz on Fri Sep 19 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Adium/Adium.h>
#import <Cocoa/Cocoa.h>

@protocol AIContentFilter;

@interface AIMessageAliasPlugin  : AIPlugin <AIContentFilter>
{
    NSDictionary *hash;
}

- (NSString *) hashLookup:(NSString *)pattern  contentMessage:(AIContentMessage *)content;

@end
