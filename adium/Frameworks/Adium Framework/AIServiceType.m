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

#import "AIServiceType.h"
#import "AIContactHandle.h"

// the reason for this class is that there may be multiple instances of AIService that are compatable... so only the service types need to match.  More than one AIService can return the same service type if they are compatable.

@interface AIServiceType (PRIVATE)
- (id)initWithIdentifier:(NSString *)inIdentifier description:(NSString *)inDescription image:(NSImage *)inImage caseSensitive:(BOOL)inCaseSensitive allowedCharacters:(NSCharacterSet *)inAllowedCharacters;
@end

@implementation AIServiceType

//Create a new service type
+ (id)serviceTypeWithIdentifier:(NSString *)inIdentifier description:(NSString *)inDescription image:(NSImage *)inImage caseSensitive:(BOOL)inCaseSensitive allowedCharacters:(NSCharacterSet *)inAllowedCharacters
{
    return([[[self alloc] initWithIdentifier:inIdentifier description:inDescription image:inImage caseSensitive:inCaseSensitive allowedCharacters:inAllowedCharacters] autorelease]);
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

- (BOOL)caseSensitive
{
    return(caseSensitive);
}

//Compare this service type to another
/*- (NSComparisonResult)compare:(AIServiceType *)inService
{
    return([identifier compare:[inService identifier]]);
}*/

//Compare our UID (The passed handle shuold be of this service type!) and service to another handle
- (NSComparisonResult)compareUID:(NSString *)inUID toHandle:(AIContactHandle *)inHandle
{
    NSComparisonResult result;

    if(caseSensitive){
        result = [[inHandle UID] compare:inUID];
    }else{
        result = [[inHandle UID] caseInsensitiveCompare:inUID];
    }

    if(result == 0){ //If they match, double check to ensure the service matches this one
        result = [identifier compare:[inHandle serviceID]];
    }

    return(result);
}


//UID's are ONLY filtered when creating handles, and when renaming handles.
//When changing ownership of a handle, a filter is not necessary, since all the accounts should have the same service types and requirements.
//When account code retrieves handles from the contact list, filtering is NOT done.  It is up to the account to ensure it passes UID's in the proper format for it's service type.


//Filter UID's only when the user has entered or mucked with them in some way... UID's TO and FROM account code SHOULD ALWAYS BE VALID.

//Filters a UID for invalid characters (assuming it belongs to this service type)
- (NSString *)filterUID:(NSString *)inUID
{
    int			nameLength;
    unichar		*source;
    unichar		*dest;
    int			destLength;
    int			loop;
    NSString		*filteredString;

    //Force lowercase
    if(!caseSensitive){
        inUID = [inUID lowercaseString];
    }

    //Get the characters
    nameLength = [inUID length];
    source = malloc( nameLength * sizeof(unichar) );
    dest = malloc( nameLength * sizeof(unichar) );
    [inUID getCharacters:source];

    //Filter them
    destLength = 0;
    for(loop = 0;loop < nameLength;loop++){
        if([allowedCharacters characterIsMember:source[loop]]){
            dest[destLength] = source[loop];
            destLength++;
        }
    }

    //Put them back into a string and return
    filteredString = [NSString stringWithCharacters:dest length:destLength];
    free(source);
    free(dest);
    return(filteredString);
}


//Private ---------------------------------------------------------------------------
- (id)initWithIdentifier:(NSString *)inIdentifier description:(NSString *)inDescription image:(NSImage *)inImage caseSensitive:(BOOL)inCaseSensitive allowedCharacters:(NSCharacterSet *)inAllowedCharacters
{
    [super init];

    identifier = [inIdentifier retain];
    description = [inDescription retain];
    image = [inImage retain];
    caseSensitive = inCaseSensitive;
    allowedCharacters = [inAllowedCharacters retain];

    return(self);
}

- (void)dealloc
{
    [identifier release];
    [description release];
    [image release];
    [allowedCharacters release];

    [super dealloc];
}


@end
