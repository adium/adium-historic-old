/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

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



