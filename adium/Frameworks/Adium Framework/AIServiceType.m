/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AIServiceType.h"

// the reason for this class is that there may be multiple instances of AIService that are compatable... so only the service types need to match.  More than one AIService can return the same service type if they are compatable.

@interface AIServiceType (PRIVATE)
- (id)initWithIdentifier:(NSString *)inIdentifier description:(NSString *)inDescription image:(NSImage *)inImage
		   caseSensitive:(BOOL)inCaseSensitive allowedCharacters:(NSCharacterSet *)inAllowedCharacters
	   ignoredCharacters:(NSCharacterSet *)inIgnoredCharacters allowedLength:(int)inAllowedLength;
@end

@implementation AIServiceType

//Create a new service type
+ (id)serviceTypeWithIdentifier:(NSString *)inIdentifier description:(NSString *)inDescription image:(NSImage *)inImage
				  caseSensitive:(BOOL)inCaseSensitive allowedCharacters:(NSCharacterSet *)inAllowedCharacters
			  ignoredCharacters:(NSCharacterSet *)inIgnoredCharacters allowedLength:(int)inAllowedLength
{
    return([[[self alloc] initWithIdentifier:inIdentifier
								 description:inDescription
									   image:inImage
							   caseSensitive:inCaseSensitive
						   allowedCharacters:inAllowedCharacters
						   ignoredCharacters:inIgnoredCharacters
							   allowedLength:inAllowedLength] autorelease]);
}

- (NSString *)identifier{
    return(identifier);
}

- (NSString *)description{
    return(description);
}

- (NSImage *)image{
    return(image);
}

- (NSCharacterSet *)allowedCharacters
{
    return(allowedCharacters);
}

- (NSCharacterSet *)ignoredCharacters
{
    return(ignoredCharacters);
}

- (int)allowedLength
{
    return(allowedLength);
}

- (BOOL)caseSensitive
{
    return(caseSensitive);
}


//UID's are ONLY filtered when creating handles, and when renaming handles.
//When changing ownership of a handle, a filter is not necessary, since all the accounts should have the same service types and requirements.
//When account code retrieves handles from the contact list, filtering is NOT done.  It is up to the account to ensure it passes UID's in the proper format for it's service type.
//Filter UID's only when the user has entered or mucked with them in some way... UID's TO and FROM account code SHOULD ALWAYS BE VALID.
//Filters a UID.  All invalid characters and ignored characters are removed.
- (NSString *)filterUID:(NSString *)inUID removeIgnoredCharacters:(BOOL)removeIgnored
{
	NSString	*workingString = (caseSensitive ? inUID : [inUID lowercaseString]);
	
	//Prepare a little buffer for our filtered UID
	int		destLength = 0;
	unichar *dest = malloc([workingString length] * sizeof(unichar));
	
	//Filter the UID
	int pos;
	for(pos = 0; pos < [workingString length]; pos++){
		unichar c = [workingString characterAtIndex:pos];
		
        if([allowedCharacters characterIsMember:c] && (!removeIgnored || ![ignoredCharacters characterIsMember:c])){
            dest[destLength] = (removeIgnored ? [workingString characterAtIndex:pos] : [inUID characterAtIndex:pos]);
			destLength++;
		}
	}

	//Turn it back into a string and return
    NSString *filteredString = [NSString stringWithCharacters:dest length:destLength];
	free(dest);
	return(filteredString);
}


//Private ---------------------------------------------------------------------------
- (id)initWithIdentifier:(NSString *)inIdentifier description:(NSString *)inDescription image:(NSImage *)inImage
		   caseSensitive:(BOOL)inCaseSensitive allowedCharacters:(NSCharacterSet *)inAllowedCharacters
		   ignoredCharacters:(NSCharacterSet *)inIgnoredCharacters allowedLength:(int)inAllowedLength
{
    [super init];

    identifier = [inIdentifier retain];
    description = [inDescription retain];
    image = [inImage retain];
    caseSensitive = inCaseSensitive;
    allowedCharacters = [inAllowedCharacters retain];
    ignoredCharacters = [inIgnoredCharacters retain];
	allowedLength = inAllowedLength;

    return(self);
}

- (void)dealloc
{
    [identifier release];
    [description release];
    [image release];
    [allowedCharacters release];
    [ignoredCharacters release];

    [super dealloc];
}


@end
