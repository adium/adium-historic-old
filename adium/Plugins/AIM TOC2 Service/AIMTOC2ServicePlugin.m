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

#import "AIMTOC2ServicePlugin.h"
#import "AIMTOC2Account.h"

@interface AIMTOC2ServicePlugin (PRIVATE)
- (void)configureView;
@end

@implementation AIMTOC2ServicePlugin

- (void)installPlugin
{
    //Create our handle service type
    handleServiceType = [[AIServiceType serviceTypeWithIdentifier:@"AIM"
													  description:@"AIM, AOL, and .Mac"
															image:[AIImageUtilities imageNamed:@"LilYellowDuck"
																					  forClass:[self class]]
													caseSensitive:NO
												allowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyz0123456789@. "]
													allowedLength:24] retain];
    
    //Register this service
    [[adium accountController] registerService:self];
}

//Return a new account with the specified properties
- (id)accountWithUID:(NSString *)inUID
{
    return([[[AIMTOC2Account alloc] initWithUID:inUID service:self] autorelease]);
}

//Returns a unique identifier for this plugin (Used by this plugin only)
- (NSString *)identifier
{
    return(@"AIM (TOC2)");
}
//Returns a description for this service (User readable)
- (NSString *)description
{
    return(@"AIM / ICQ (TOC2)");
}

// Return an ID, description, and image for handles owned by accounts of this type
- (AIServiceType *)handleServiceType
{
    return(handleServiceType);
}

@end
