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

#import "AIOscarSSI.h"
#import "AIOscarAccount.h"
#import "AIOscarPacket.h"
#import "AIOscarConnection.h"

@interface AIOscarSSI (PRIVATE)
- (void)_handleSSIRights:(AIOscarPacket *)inPacket;
- (void)_handleSSIData:(AIOscarPacket *)inPacket;
- (void)_sendActivateList;
@end

@implementation AIOscarSSI

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
    return(0x0013);
}
+ (unsigned short)moduleVersion{
    return(0x0004);
}
+ (unsigned short)toolID{
    return(0x0110);
}
+ (unsigned short)toolVersion{
    return(0x0629);
}


//Handle a request
- (void)handleRequest:(long)requestID type:(unsigned short)type flags:(unsigned short)flags packet:(AIOscarPacket *)inPacket
{
    switch(type){
        case 0x0001: NSLog(@"Error: %@",inPacket); break;
        case 0x0003: [self _handleSSIRights:inPacket]; break;
        case 0x0006: [self _handleSSIData:inPacket]; break;
        default: NSLog(@"(%@) Unknown type: %i",self,type); break;
    }
}

//
- (void)_handleSSIRights:(AIOscarPacket *)inPacket
{
    NSLog(@"_handleSSIRights (Not implemented)"); //Not implemented
}

//
- (void)requestSSIRights
{
    [connection sendPacket:[connection snacPacketWithFamily:0x0013 type:0x0002 flags:0x000]];
}

//
- (void)requestSSIData
{
    AIOscarPacket	*requestPacket = [connection snacPacketWithFamily:0x0013 type:0x0005 flags:0x000];

    //The time of our last SSI data request
    [requestPacket addLong:0]; //timestamp
    [requestPacket addShort:0]; //number of items

    //Send
    [connection sendPacket:requestPacket];
}

//
- (void)_handleSSIData:(AIOscarPacket *)inPacket
{
    static NSMutableArray	*groupArray = nil;
    static NSString		*groupName = nil;
    NSMutableArray		*contactList = [NSMutableArray array];
    unsigned char		dataVersion;
    unsigned short		numberOfItems;
    int				loop;

    NSString *crap;
    [inPacket getString:&crap length:8];
        
    //Get version of the SSI data 
    [inPacket getCharValue:&dataVersion];

    //Get all the buddies / groups / prefs
    [inPacket getShortValue:&numberOfItems];
    for(loop = 0; loop < numberOfItems; loop++){
        NSString	*nameString = nil;
        unsigned short 	nameLength;
        unsigned short 	gid, bid, type, dataLength;
        AIOscarTLVBlock	*valueBlock;
        
        //Get name and properties of this object
        if([inPacket getShortValue:&nameLength] && nameLength != 0){
            [inPacket getString:&nameString length:nameLength];
        }
        [inPacket getShortValue:&gid]; //Group ID
        [inPacket getShortValue:&bid]; //Buddy ID
        [inPacket getShortValue:&type]; //Type
        [inPacket getShortValue:&dataLength]; //Auxilary data
        if(dataLength){
            valueBlock = [inPacket getTLVBlockWithLength:dataLength valueCount:0];
        }

        //Add it to our contact list
        if(nameString){
            if(type == 0){ //Buddy
                //Add the buddy
                [groupArray addObject:nameString];

            }else if(type = 1){ //Group
                //Close and add the existing group
                if(groupArray && groupName){
                    [contactList addObject:[NSDictionary dictionaryWithObjectsAndKeys:groupName, @"Name", groupArray, @"Contents", nil]];
                    [groupName release]; groupName = nil;
                    [groupArray release]; groupArray = nil;
                }

                //Create a new group
                groupArray = [[NSMutableArray alloc] init];
                groupName = [nameString retain];
            }
        }
    }

    //Add the group
    [contactList addObject:[NSDictionary dictionaryWithObjectsAndKeys:groupName, @"Name", groupArray, @"Contents", nil]];

    //Get the time stamp
    //

    //Send contact list to account
    [account noteContactList:contactList];

    //Activate this contact list
    [self _sendActivateList];
}

//
- (void)_sendActivateList
{
    [connection sendPacket:[connection snacPacketWithFamily:0x0013 type:0x0007 flags:0x000]];
}

@end

