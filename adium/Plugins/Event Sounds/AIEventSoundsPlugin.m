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

#import "AIEventSoundsPlugin.h"
#import "AIAdium.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>

@implementation AIEventSoundsPlugin

- (void)installPlugin
{
    [[owner soundController] playSoundNamed:@"(Adium)ReceiveFirst.aif"];

    [[[owner contentController] contentNotificationCenter] addObserver:self selector:@selector(messageIn:) name:Content_DidReceiveContent object:nil];
    [[[owner contentController] contentNotificationCenter] addObserver:self selector:@selector(messageOut:) name:Content_DidSendContent object:nil];
    [[owner contactController] registerHandleObserver:self];

    onlineDict = [[NSMutableDictionary alloc] init];
}

- (void)messageIn:(NSNotification *)notification
{
    [[owner soundController] playSoundNamed:@"(Adium)Receive.aif"];
}

- (void)messageOut:(NSNotification *)notification
{
    [[owner soundController] playSoundNamed:@"(Adium)Send.aif"];
}

- (BOOL)updateHandle:(AIContactHandle *)inHandle keys:(NSArray *)inModifiedKeys
{
    if(![[owner contactController] contactListUpdatesDelayed]){ //Don't play sounds whens signing on
        //Sign on/off
        if([inModifiedKeys containsObject:@"Online"]){
            BOOL	oldOnline = [[onlineDict objectForKey:[inHandle UID]] boolValue]; //! UID is not unique enough !
            BOOL	newOnline = [[inHandle statusArrayForKey:@"Online"] containsAnyIntegerValueOf:1];
    
            if(newOnline != oldOnline){
                if(newOnline){
                    [[owner soundController] playSoundNamed:@"(Adium)Buddy_SignedOn.aif"];
                }else{
                    [[owner soundController] playSoundNamed:@"(Adium)Buddy_SignedOff.aif"];
                }
    
                [onlineDict setObject:[NSNumber numberWithBool:newOnline] forKey:[inHandle UID]];
            }
        }
    }
        
    return(NO);
}

@end
