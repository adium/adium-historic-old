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

#import <Adium/Adium.h>
#import "AIMiChatService.h"
#import "AIMiChatAccount.h"

@implementation AIMiChatService

//Init anything global relating to the service
- (void)initService
{

}

//Return a new account with the specified properties
- (id)accountWithProperties:(NSDictionary *)inProperties owner:(id)inOwner
{
    return([[[AIMiChatAccount alloc] initWithProperties:inProperties service:self owner:owner] autorelease]);
}

// Return a Plugin-specific ID, description, and image
- (NSString *)identifier
{
    return(@"AIM (iChat)");
}
- (NSString *)description
{
    return(@"AOL Instant Messenger (iChat)");
}

// Return an ID, description, and image for handles owned by accounts of this type
- (AIServiceType *)handleServiceType
{
    return([AIServiceType serviceTypeWithIdentifier:@"AIM"
                          description:@"AIM, AOL, and .Mac"
                          image:nil
                          caseSensitive:NO
                          allowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyz0123456789@."]]);
}

@end
