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

#import "AICompletingTextField.h"
#import "AIAttributedStringAdditions.h"
#import "AITextFieldAdditions.h"

/*
    A text field that auto-completes known strings
 */

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
    stringSet = nil;
	impliedCompletionDictionary = nil;
    minLength = 1;
    oldUserLength = 0;

    return(self);
}

- (void)dealloc
{
    [stringSet release];
	[impliedCompletionDictionary release];
	
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
    [stringSet release];
    stringSet = [[NSMutableSet setWithArray:strings] retain];
	
	[impliedCompletionDictionary release]; impliedCompletionDictionary = nil;
}

//Adds a string to the existing string list
- (void)addCompletionString:(NSString *)string
{
    if(!stringSet) stringSet = [[NSMutableSet alloc] init];

    [stringSet addObject:string];
}

- (void)addCompletionString:(NSString *)string withImpliedCompletion:(NSString *)impliedCompletion
{
	if (![string isEqualToString:impliedCompletion]){
		if (!impliedCompletionDictionary) impliedCompletionDictionary = [[NSMutableDictionary alloc] init];
		
		[impliedCompletionDictionary setObject:impliedCompletion forKey:string];
	}
	
	[self addCompletionString:string];
}


//Private ------------------------------------------------------------------------------------------
- (void)textDidChange:(NSNotification *)notification
{
    NSString		*userValue, *completionValue;
	unsigned int	userValueLength;
	
    //Auto-complete
    userValue = [self stringValue];
	userValueLength = [userValue length];
	
	//We only need to attempt an autocompletion if characters have been added - deleting shouldn't autocomplete
    if(userValueLength > oldUserLength){
        completionValue = [self completionForString:userValue];
    
        if(completionValue != nil && [completionValue length] > userValueLength){
            //Auto-complete the string - note that it retains the text that the user typed, and simply adds
            //the additional characters needed to match the completionValue
            [self setStringValue:[userValue stringByAppendingString:[completionValue substringFromIndex:userValueLength]]];
			
            //Select the auto-completed text
            [self selectRange:NSMakeRange(userValueLength, [completionValue length] - userValueLength)];
        }
    }

    oldUserLength = userValueLength;
}

- (void)textDidEndEditing:(NSNotification *)notification
{
    // This method helps make the text field a little smarter - as the user types, the auto-completions retain
    // the user-entered characters as they were typed (basically, retaining the case as it was entered). If
    // the user presses tab or enter, then this method is triggered and the text field tries to replace the
    // text with a (case-insensitive) matching string (basically, having the effect that the entered string's
    // case is "corrected" to match the auto-completion value). If the user *wants* to enter a string identical
    // to a completion value, but with different case, he or she can avoid this automatic case "correction" by
    // NOT hitting tab or enter, and instead just clicking the appropriate button or control they want to use.
    
    NSEnumerator    *enumerator;
    NSString        *userValue, *currentString;
    
    // If the field matches an entry in stringSet (except maybe case) replace it with the correct-case string
    userValue = [self stringValue];
    
    if([userValue length] >= minLength){
        // Look for matching first matching string (except for case)
        enumerator = [stringSet objectEnumerator];
        while((currentString = [enumerator nextObject])){
            if([currentString compare:userValue options:NSCaseInsensitiveSearch] == 0){
                [self setStringValue:currentString];
                break;
            }
        }
    }
    
    [super textDidEndEditing:notification];
}

//Returns the known completion for a string segment
- (NSString *)completionForString:(NSString *)inString
{
    NSEnumerator	*enumerator;
    NSString		*autoString;
    int				length;
    NSRange			range;

    //Setup
    length = [inString length];
    range = NSMakeRange(0, length);

    if(length >= minLength){
        //Check each auto-complete string for a match
        enumerator = [stringSet objectEnumerator];
        while((autoString = [enumerator nextObject])){
            if(([autoString length] > length) && [autoString compare:inString options:NSCaseInsensitiveSearch range:range] == 0){
                return(autoString);
            }
        }
    }
        
    return(nil);
}

//Return a string which may be the actual stringValue or may be some other string implied by it
- (NSString *)impliedStringValue
{
	NSString		*returnString = [self stringValue];
	if (returnString){
		//Check if the stringValue implies a different completion; ensure that this new completion is not itself
		//a potential completion (if it is, we assume the user's manually entered stringValue to be the intended value)
		NSString	*impliedCompletion = [impliedCompletionDictionary objectForKey:returnString];
				
		NSString	*impliedCompletionOfImpliedCompletion = [impliedCompletionDictionary objectForKey:impliedCompletion];
		//If we got an implied completion, and using that implied completion wouldn't get us into a loop with other
		//completions (leading to unpredicatable behavior as far as the user would be concerned), return the implied
		//completion
		if (impliedCompletion && (!impliedCompletionOfImpliedCompletion || [impliedCompletionOfImpliedCompletion isEqualToString:impliedCompletion])){
			returnString = impliedCompletion;
		}
	}

	return returnString;
}

@end
