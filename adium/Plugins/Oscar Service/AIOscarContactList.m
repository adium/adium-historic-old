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

/* PLEASE NOTE -------------------------------------------------------------------------------------------
    The contents of this file, and the majority of this plugin, are an obj-c rewrite of Gaim's libfaim/oscar
    library.  In fact, portions of the original Gaim code may still remain intact, and other portions may
    have simply been re-arranged, removed, or rewritten.

    More information on Gaim is available at http://gaim.sourceforge.net
 -------------------------------------------------------------------------------------------------------*/

#import "AIOscarContactList.h"
#import "AIOscarAccount.h"
#import "AIOscarPacket.h"
#import "AIOscarInfo.h"
#import "AIOscarConnection.h"
#import "AIOscarTLVBlock.h"
#import "AIOscarIcon.h"

@interface AIOscarContactList (PRIVATE)
- (void)_handleContactRights:(AIOscarPacket *)inPacket;
- (void)_handleContactOnline:(AIOscarPacket *)inPacket;
- (void)_handleContactOffline:(AIOscarPacket *)inPacket;
@end

@implementation AIOscarContactList

//Init
- (id)initWithAccount:(AIOscarAccount *)inAccount forConnection:(AIOscarConnection *)inConnection
{
    [super init];

    account = [inAccount retain];
    connection = [inConnection retain];

    return(self);
}

//Return our module information
+ (unsigned short)moduleFamily{
    return(0x0003);
}
+ (unsigned short)moduleVersion{
    return(0x0001);
}
+ (unsigned short)toolID{
    return(0x0110);
}
+ (unsigned short)toolVersion{
    return(0x0629);
}


//Commands -------------------------------------------------------------------------------------
//0x0002
- (void)requestContactRights
{
    [connection sendPacket:[connection snacPacketWithFamily:0x0003 type:0x0002 flags:0x000]];
}

//0x0004
- (void)addBuddy:(NSString *)name
{
    AIOscarPacket	*packet = [connection snacPacketWithFamily:0x0003 type:0x0004 flags:0x000];

    //Add buddy name
    [packet addString:name];
    
    //Send
    [connection sendPacket:packet];
}

//0x0005
- (void)removeBuddy:(NSString *)name
{
    AIOscarPacket	*packet = [connection snacPacketWithFamily:0x0003 type:0x0005 flags:0x000];

    //Add buddy name
    [packet addString:name];

    //Send
    [connection sendPacket:packet];
}


//Handlers -------------------------------------------------------------------------------------
//Handle a request
- (void)handleRequest:(long)requestID type:(unsigned short)type flags:(unsigned short)flags packet:(AIOscarPacket *)inPacket
{
    switch(type){
        case 0x0003: [self _handleContactRights:inPacket]; break;
        case 0x000b: [self _handleContactOnline:inPacket]; break;
        case 0x000c: [self _handleContactOffline:inPacket]; break;
        default: NSLog(@"(%@) Unknown type: %i",self,type); break;
    }
}

//0x0003
- (void)_handleContactRights:(AIOscarPacket *)inPacket
{
    AIOscarTLVBlock	*valueBlock = [inPacket getTLVBlock];
    int			maxBuddies;
    int			maxWatchers;

    maxBuddies = [valueBlock integerForType:0x0001];
    maxWatchers = [valueBlock integerForType:0x0002];

    //NSLog(@"Max buddies: %i",maxBuddies);
    //NSLog(@"Max watchers: %i",maxWatchers);
}

//0x000b
- (void)_handleContactOnline:(AIOscarPacket *)inPacket
{
    NSString		*name;
    AIOscarTLVBlock	*valueBlock = [AIOscarInfo extractInfoFromPacket:inPacket name:&name warnLevel:nil];
    NSString		*iChatBlock;
    
    //Buddy icon / status message
    if(iChatBlock = [valueBlock stringForType:0x001d]){
        const char 	*bytes = [iChatBlock cString];
        unsigned short	type;
        unsigned char	number, length;
        int		offset = 0;

        while(offset < [iChatBlock length]){
            type = get16(bytes+offset);
            number = get8(bytes+offset+2);
            length = get8(bytes+offset+3);
            offset += 4;

            switch(type){
                case 0x0001:
                    if((length > 0) && (number == 0x01)){
                        [account requestIconForContact:name checksum:[NSData dataWithBytes:(bytes + offset) length:length]];
                    }
                break;
                case 0x0002:
                    //NSLog(@"Status Message: %@",[NSString stringWithCString:(bytes+offset) length:length]);
                break;
            }

            offset += length;
        }        
    }

    //Pass the updated status to our account
    [account updateContact:name
                    online:YES
               onlineSince:[NSDate dateWithTimeIntervalSince1970:[valueBlock integerForType:0x0003]]
                      away:(([valueBlock integerForType:0x0001] & 0x0020) != 0)
                      idle:[valueBlock integerForType:0x0004]];
}

//0x000c
- (void)_handleContactOffline:(AIOscarPacket *)inPacket
{
    NSString		*name;

    //Get the info
    [AIOscarInfo extractInfoFromPacket:inPacket name:&name warnLevel:nil];

    //Pass the updated status to our account
    [account updateContact:name
                    online:NO
               onlineSince:nil
                      away:NO
                      idle:0];
}


@end


/*
 int class = [[valueDict objectForIntegerKey:0x0001] intValue];
 if(class & 0x0001) NSLog(@"Trial (user less than 60days)");
 if(class & 0x0002) NSLog(@"Unknown bit 2");
 if(class & 0x0004) NSLog(@"AOL Main Service user");
 if(class & 0x0008) NSLog(@"Unknown bit 4");
 if(class & 0x0010) NSLog(@"Free (AIM) user");
 if(class & 0x0020) NSLog(@"Away");
 if(class & 0x0400) NSLog(@"ActiveBuddy");

 NSLog(@"Account Created: %@", [[NSDate dateWithTimeIntervalSince1970:[[valueDict objectForIntegerKey:0x0002] intValue]] description]);
 NSLog(@"Online Since: %@", [[NSDate dateWithTimeIntervalSince1970:[[valueDict objectForIntegerKey:0x0003] intValue]] description]);

 NSLog(@"Idle Time: %i", [[valueDict objectForIntegerKey:0x0004]] intValue]);
 NSLog(@"Member Since: %@", [[NSDate dateWithTimeIntervalSince1970:[[valueDict objectForIntegerKey:0x0005] intValue]] description]);

 NSLog(@"ICQ Status: %i", [[valueDict objectForIntegerKey:0x0006] intValue]);
 NSLog(@"ICQ IP: %i", [[valueDict objectForIntegerKey:0x000a] intValue]);
 NSLog(@"ICQ IP??: %i", [[valueDict objectForIntegerKey:0x000c] intValue]);

 NSLog(@"Caps: %@",[valueDict objectForIntegerKey:0x000d]);
 NSLog(@"%@",[self _getCapsFromString:[valueDict objectForIntegerKey:0x000d]]);

 NSLog(@"Session Length (AIM): %i", [[valueDict objectForIntegerKey:0x000f] intValue]);
 NSLog(@"Session Length (AOL): %i", [[valueDict objectForIntegerKey:0x0010] intValue]);

 NSLog(@"iChat type: %@", [valueDict objectForIntegerKey:0x001d]);
 */
