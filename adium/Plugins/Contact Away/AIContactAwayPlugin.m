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

#import "AIContactAwayPlugin.h"

#define	AWAY_LABEL			AILocalizedString(@"Away",nil)
#define	AWAY_MESSAGE_LABEL	AILocalizedString(@"Away Message",nil)
#define	STATUS_LABEL		AILocalizedString(@"Status",nil)

#define AWAY_YES			AILocalizedString(@"Yes",nil)

@implementation AIContactAwayPlugin

- (void)installPlugin
{
    //Install our tooltip entry
    [[adium interfaceController] registerContactListTooltipEntry:self secondaryEntry:YES];
}

//Tooltip entry ---------------------------------------------------------------------------------------
- (NSString *)labelForObject:(AIListObject *)inObject
{
    NSString			*entry = nil;
    NSAttributedString 	*statusMessage = nil;
    BOOL				away;
    
    //Get the away state
    away = [inObject integerStatusObjectForKey:@"Away"];
    
    //Get the status message
    statusMessage = [inObject statusObjectForKey:@"StatusMessage"];
    
    //Return the correct string
    if(statusMessage != nil && [statusMessage length] != 0){
		if (away){
			
			//Check to make sure we're not duplicating server display name information
			NSString	*serverDisplayName = [inObject statusObjectForKey:@"Server Display Name"];
			
			//Return the correct string
			if ([serverDisplayName isEqualToString:[statusMessage string]]){
				entry = AWAY_LABEL;
			}else{
				entry = AWAY_MESSAGE_LABEL;
			}
			
		}else{
			entry = STATUS_LABEL;
		}
    }else if(away){
		entry = AWAY_LABEL;
    }
    
    return(entry);
}

- (NSAttributedString *)entryForObject:(AIListObject *)inObject
{
    NSAttributedString	*entry = nil;
    NSAttributedString 	*statusMessage = nil;
	NSString			*serverDisplayName = nil;
	
    BOOL				away;
	
    //Get the away state
    away = [inObject integerStatusObjectForKey:@"Away"];
	
    //Get the status message
    statusMessage = [inObject statusObjectForKey:@"StatusMessage"];

	//Check to make sure we're not duplicating server display name information
	serverDisplayName = [inObject statusObjectForKey:@"Server Display Name"];

    //Return the correct string
	if ([serverDisplayName isEqualToString:[statusMessage string]]){
		//If the status and server display name are the same, just display YES for away since we'll display the
		//server display name itself in the proper place.
		if(away){
			entry = [[[NSAttributedString alloc] initWithString:AWAY_YES] autorelease];
		}
	}else{
		if(statusMessage != nil && [statusMessage length] != 0){
			entry = statusMessage;
		}else if(away){
			entry = [[[NSAttributedString alloc] initWithString:AWAY_YES] autorelease];
		}
	}
	
    return(entry);
}


@end
