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

#import "AIMTOC2StringAdditions.h"


@implementation NSString (AIMTOC2Additions)

/* TOCStringArgumentAtIndex
*   returns the TOC string argument (arguments are seperated by :'s) at the specified index
*/
- (NSString *)TOCStringArgumentAtIndex:(int)index
{
    int 	loop;
    NSString	*argument;
    NSScanner	*scanner = [NSScanner scannerWithString:self];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];

    for(loop = 0;loop < index;loop++){
        [scanner scanUpToString:@":" intoString:nil];
        if(![scanner scanString:@":" intoString:nil]){
            return(nil);
        }
    }

    if([scanner scanUpToString:@":" intoString:&argument]){
        return(argument);
    }else{
        return(nil);
    }
}
/* nonBreakingTOCStringArgumentAtIndex
*   returns the TOC string argument (arguments are seperated by :'s) at the specified index, ignoring
*   any additional :'s
*/
- (NSString *)nonBreakingTOCStringArgumentAtIndex:(int)index
{
    int 	loop;
    NSScanner	*scanner = [NSScanner scannerWithString:self];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];

    for(loop = 0;loop < index;loop++){
        [scanner scanUpToString:@":" intoString:nil];
        if(![scanner scanString:@":" intoString:nil]){
            return(nil);
        }
    }

    return([self substringFromIndex:[scanner scanLocation]]);
}


- (NSMutableString *)validAIMStringCopy
{
    NSMutableString		*message;
    short			loop = 0;

    message = [[self mutableCopy] autorelease];

    //---backslash certain characters---
    while(loop < [message length]){
        char currentChar = [message characterAtIndex:loop];

        if( currentChar == '$' ||
            currentChar == '{' || currentChar == '}' ||
            currentChar == '[' || currentChar == ']' ||
            currentChar == '(' || currentChar == ')' ||
            currentChar == '\"' || currentChar == '\'' || currentChar == '`' ||
            currentChar == '\\'){
            
            [message insertString:@"\\" atIndex:loop];
            loop += 2;
        }else{
            loop += 1;
        }
    }

    return(message);
}

@end
