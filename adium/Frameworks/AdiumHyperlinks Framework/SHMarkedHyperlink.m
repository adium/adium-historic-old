//
//  SHMarkedHyperlink.m
//  Adium
//
//  Created by Stephen Holt on Tue May 11 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "SHMarkedHyperlink.h"


@implementation SHMarkedHyperlink

-(id)initWithString:(NSString *)inString parentString:(NSString *)pInString andRange:(NSRange)inRange
{
    linkRange = inRange;
    pString = [pInString retain];
    linkURL = [[NSURL URLWithString:inString] autorelease];
    [super init];
    
    return self;
}

-(NSRange)range
{
    return linkRange;
}

-(NSString *)parentString
{
    return pString;
}
-(NSURL *)URL
{
    return linkURL;
}

-(void)setRange:(NSRange)inRange
{
    linkRange = inRange;
}

-(void)setURL:(NSURL *)inURL
{
    if(linkURL) [linkURL release];
    linkURL = [inURL retain];
}

-(void)setURLFromString:(NSString *)inString
{
    if(linkURL) [linkURL release];
    linkURL = [[NSURL URLWithString:inString] autorelease];
}

-(void)setParentString:(NSString *)pInString
{
    if(pString) [pString release];
    pString = pInString;
}

@end
