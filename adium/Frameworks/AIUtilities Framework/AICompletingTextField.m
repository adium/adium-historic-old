/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AICompletingTextField.h"
#import "AIAttributedStringAdditions.h"
#import "AITextFieldAdditions.h"

@interface AICompletingTextField (PRIVATE)
- (id)_init;
- (void)insertText:(id)insertString;
- (NSString *)completionForString:(NSString *)inString;
@end

@implementation AICompletingTextField

//Init the field
- (id)initWithCoder:(NSCoder *)aDecoder
{
    [super initWithCoder:aDecoder];
    [self _init];
    return(self);
}

- (id)initWithFrame:(NSRect)frameRect
{
    [super initWithFrame:frameRect];
    [self _init];
    return(self);
}

- (id)_init
{
    stringArray = nil;
    minLength = 3;
    oldUserLength = 0;

    return(self);
}

- (void)dealloc
{
    [stringArray release];

    [super dealloc];
}

//Sets the minimum string length required before completion kicks in
- (void)setMinStringLength:(int)length
{
    minLength = length;
}

//Set the strings that this field will use to auto-complete
- (void)setCompletingStrings:(NSArray *)strings
{
    [stringArray release];
    stringArray = [strings mutableCopy];
}

//Adds a string to the existing string list
- (void)addCompletionString:(NSString *)string
{
    if(!stringArray) stringArray = [[NSMutableArray alloc] init];

    [stringArray addObject:string];
}




//Private ------------------------------------------------------------------------------------------
//- (void)insertText:(id)insertString
- (void)textDidChange:(NSNotification *)notification
//- (void)insertText:(id)insertString
{
    NSString	*userValue, *completionValue;

    //Auto-complete
    userValue = [self stringValue];

    if([userValue length] > oldUserLength){
        completionValue = [self completionForString:userValue];
    
        if(completionValue != nil && [completionValue length] != 0){
            //Auto-complete the string
            [self setStringValue:completionValue];
    
            //Select the auto-completed text
            [self selectRange:NSMakeRange([userValue length], [completionValue length] - [userValue length])];
        }
    }

    oldUserLength = [userValue length];
}

- (NSString *)completionForString:(NSString *)inString
{
    NSEnumerator	*enumerator;
    NSString		*autoString;
    int			length;
    NSRange		range;

    //Setup
    length = [inString length];
    range = NSMakeRange(0, length);

    if(length >= 3){
        //Check each auto-complete string for a match
        enumerator = [stringArray objectEnumerator];
        while((autoString = [enumerator nextObject])){
            if(([autoString length] > length) && [autoString compare:inString options:NSCaseInsensitiveSearch range:range] == 0){
                return(autoString);
            }
        }
    }
        
    return(nil);
}



@end
