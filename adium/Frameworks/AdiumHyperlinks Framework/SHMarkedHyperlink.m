//
//  SHMarkedHyperlink.m
//  Adium
//
//  Created by Stephen Holt on Tue May 11 2004.


#import "SHMarkedHyperlink.h"


@implementation SHMarkedHyperlink

-(id)initWithString:(NSString *)inString withValidationStatus:(URI_VERIFICATION_STATUS)status parentString:(NSString *)pInString andRange:(NSRange)inRange
{
    linkRange = inRange;
    pString = [pInString retain];
    linkURL = [[NSURL URLWithString:inString] autorelease];
    urlStatus = status;
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

-(URI_VERIFICATION_STATUS)validationStatus
{
    return urlStatus;
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
