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

#import "AIMiChatServicePlugin.h"
#import "AIMiChatAccount.h"

@implementation AIMiChatServicePlugin

//init
- (void)installPlugin
{
    handleServiceType = [[AIServiceType serviceTypeWithIdentifier:@"AIM"
                                                      description:@"AIM, AOL, and .Mac"
                                                            image:[AIImageUtilities imageNamed:@"LilYellowDuck" forClass:[self class]]
                                                    caseSensitive:NO
                                                allowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyz0123456789@.+"]] retain]; //added + for phone numbers - still need to enable the send button though.

    //Launch the agent
    [[NSTask launchedTaskWithLaunchPath:@"/System/Library/PrivateFrameworks/InstantMessage.framework/iChatAgent.app/Contents/MacOS/iChatAgent" arguments:[NSArray array]] retain];
    
    //Register this service
    //[[owner accountController] registerService:self];
}

- (void)uninstallPlugin
{
    //[[owner accountController] unregisterService:self];
    //unregister, remove, ...
}


//Return a new account with the specified properties
- (id)accountWithProperties:(NSDictionary *)inProperties
{
    return([[[AIMiChatAccount alloc] initWithProperties:inProperties service:self] autorelease]);
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
    return(handleServiceType);
}

@end
