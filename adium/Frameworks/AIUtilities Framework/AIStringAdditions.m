//
//  AIStringAdditions.m
//  Adium
//
//  Created by Adam Iser on Sat Dec 28 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "AIStringAdditions.h"


@implementation NSString (AIStringAdditions)

/* compactedString
*   returns the string in all lowercase without spaces
*/
- (NSString *)compactedString
{
    NSMutableString 	*outName;
    short		pos;

    outName = [[NSMutableString alloc] initWithString:[self lowercaseString]];
    for(pos = 0;pos < [outName length];pos++){
        if([outName characterAtIndex:pos] == ' '){
            [outName deleteCharactersInRange:NSMakeRange(pos,1)];
            pos--;
        }
    }

    return([outName autorelease]);
}

@end
