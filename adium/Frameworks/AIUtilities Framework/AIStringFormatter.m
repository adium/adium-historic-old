//
//  AIStringFormatter.m
//  Adium
//
//  Created by Adam Iser on Sun Feb 09 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIStringFormatter.h"

#define ERRORS_BEFORE_DIALOG	3	//Number of mistakes that can be made before an error dialog will appear

@interface AIStringFormatter (PRIVATE)
- (id)initAllowingCharacters:(NSCharacterSet *)inCharacters length:(int)inLength caseSensitive:(BOOL)inCaseSensitive errorMessage:(NSString *)inErrorMessage;
@end

@implementation AIStringFormatter

+ (id)stringFormatterAllowingCharacters:(NSCharacterSet *)inCharacters length:(int)inLength caseSensitive:(BOOL)inCaseSensitive errorMessage:(NSString *)inErrorMessage
{
    return([[[self alloc] initAllowingCharacters:inCharacters length:inLength caseSensitive:inCaseSensitive errorMessage:inErrorMessage] autorelease]);
}

- (id)initAllowingCharacters:(NSCharacterSet *)inCharacters length:(int)inLength caseSensitive:(BOOL)inCaseSensitive errorMessage:(NSString *)inErrorMessage
{
    [super init];

    errorMessage = [inErrorMessage retain];
    characters = [inCharacters retain];
    length = inLength;
    caseSensitive = inCaseSensitive;
    errorCount = 0;

    return(self);
}

- (NSString *)stringForObjectValue:(id)obj
{
    if(![obj isKindOfClass:[NSString class]]){
        return(nil);
    }

    return(obj);
}

- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error
{
    if(![*obj isKindOfClass:[NSString class]]){
        return(NO);
    }

    *obj = string;
    return(YES);
}

- (BOOL)isPartialStringValid:(NSString **)partialStringPtr proposedSelectedRange:(NSRangePointer)proposedSelRangePtr originalString:(NSString *)origString originalSelectedRange:(NSRange)origSelRange errorDescription:(NSString **)error
{
    BOOL	valid = YES;

    //Check length
    if(length > 0 && [*partialStringPtr length] > length){
        valid = NO;
    }

    //Check for invalid characters
    if(characters != nil && [*partialStringPtr length] > 0){
        NSScanner	*scanner = [NSScanner scannerWithString:(caseSensitive ? *partialStringPtr : [*partialStringPtr lowercaseString])];
        NSString	*validSegment;

        if(![scanner scanCharactersFromSet:characters intoString:&validSegment] || [validSegment length] != [*partialStringPtr length]){
            valid = NO;
        }
    }

    if(!valid){
        errorCount++;

        if(errorMessage != nil && errorCount > ERRORS_BEFORE_DIALOG){
            NSRunAlertPanel(@"Invalid Input", errorMessage, @"OK", nil, nil);
        }else{
            NSBeep();
        }
    }
    
    return(valid);
}

- (void)dealloc
{
    [errorMessage release];
    [characters release];

    [super dealloc];
}

@end












