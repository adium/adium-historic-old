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
    [super init];
    
    [self setURLFromString:inString];
    linkRange = inRange;
    [self setParentString:pInString];
    urlStatus = status;
    
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
    return [[pString copy] autorelease];
}

-(NSURL *)URL
{
    return [[linkURL copy] autorelease];
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
    if(linkURL != inURL){
        [linkURL autorelease];
        linkURL = [inURL retain];
    }
}

-(void)setURLFromString:(NSString *)inString
{
    [linkURL autorelease];
    linkURL = [[[NSURL alloc] initWithString:inString] retain];
}

-(void)setValidationStatus:(URI_VERIFICATION_STATUS)status;
{
    urlStatus = status;
}

-(void)setParentString:(NSString *)pInString
{
    if(pString != pInString){
        [pString autorelease];
        pString = [pInString retain];
    }
}

#pragma mark copying
- (id)copyWithZone:(NSZone *)zone
{
    SHMarkedHyperlink   *newLink = [[[self class] allocWithZone:zone] initWithString:[[self URL] absoluteString]
                                                                withValidationStatus:[self validationStatus]
                                                                        parentString:[self parentString]
                                                                            andRange:[self range]];
    return newLink;
}

@end
