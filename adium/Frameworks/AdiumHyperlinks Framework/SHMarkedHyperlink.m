//
//  SHMarkedHyperlink.m
//  Adium
//
//  Created by Stephen Holt on Tue May 11 2004.
//
// This is just an ADT... hardly even that.
// the method names are description enough, aren't they?
// I shouldn't need to comment everything here...


#import "SHMarkedHyperlink.h"


@implementation SHMarkedHyperlink

#pragma mark init
// one really big init method that does it all...
-(id)initWithString:(NSString *)inString withValidationStatus:(URI_VERIFICATION_STATUS)status parentString:(NSString *)pInString andRange:(NSRange)inRange
{
    linkRange = inRange;
    pString = [pInString retain];
    linkURL = [[NSURL URLWithString:inString] retain];
    urlStatus = status;
    
    [super init];
    
    return self;
}

#pragma mark accessors
-(void)dealloc
{
    [linkURL release];
    [pString release];
    [super dealloc];
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

-(URI_VERIFICATION_STATUS)validationStatus
{
    return urlStatus;
}

-(BOOL)parentStringMatchesString:(NSString *)inString
{
    return [pString isEqualToString:inString];
}

#pragma mark transformers
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

-(void)setValidationStatus:(URI_VERIFICATION_STATUS)status;
{
    urlStatus = status;
}

-(void)setParentString:(NSString *)pInString
{
    if(pString) [pString release];
    pString = pInString;
}

@end
