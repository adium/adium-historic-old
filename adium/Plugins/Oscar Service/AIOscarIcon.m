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

#import "AIOscarIcon.h"
#import "AIOscarAccount.h"
#import "AIOscarConnection.h"
#import "AIOscarPacket.h"
#import "AIOscarMessage.h"

@interface AIOscarIcon (PRIVATE)
- (void)_sendCookie:(NSString *)cookie;
- (void)_handleIconAcknowledge:(AIOscarPacket *)inPacket;
- (void)_handleContactIcon:(AIOscarPacket *)inPacket;
@end

@implementation AIOscarIcon

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
    return(0x0010);
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
//
- (void)requestIconForContact:(NSString *)name checksum:(NSData *)checksum
{
    AIOscarPacket	*requestPacket = [connection snacPacketWithFamily:0x0010 type:0x0004 flags:0x000];

    //name
    [requestPacket addChar:[name length]];
    [requestPacket addString:name];

    //numbers
    [requestPacket addChar:0x01];
    [requestPacket addShort:0x0001];
    [requestPacket addChar:0x01];

    //Icon checksum
    [requestPacket addChar:[checksum length]];
    [requestPacket addData:checksum];

    //Send
    [connection sendPacket:requestPacket];
}

//
- (void)uploadIcon
{
    AIOscarPacket	*iconPacket = [connection snacPacketWithFamily:0x0010 type:0x0002 flags:0x000];

    //The reference number for the icon
    [iconPacket addShort:0x0001];

    //The icon
    NSData	*imageData = [account userImageData];
    [iconPacket addShort:[imageData length]];
    [iconPacket addData:imageData];

    //Send
    [connection sendPacket:iconPacket];
}


//Handlers -------------------------------------------------------------------------------------
//Handle a request
- (void)handleRequest:(long)requestID type:(unsigned short)type flags:(unsigned short)flags packet:(AIOscarPacket *)inPacket
{
    switch(type){
        case 0x0001: NSLog(@"Error: %@",inPacket); break;
        case 0x0003: [self _handleIconAcknowledge:inPacket]; break;
        case 0x0005: [self _handleContactIcon:inPacket]; break;
        default: NSLog(@"(%@) Unknown type: %i",self,type); break;
    }
}

//0x0003
- (void)_handleIconAcknowledge:(AIOscarPacket *)inPacket
{
    NSLog(@"_handleIconAcknowledge (Not implemented)"); //Not implemented
}

//0x0005
- (void)_handleContactIcon:(AIOscarPacket *)inPacket
{
    NSString		*name;
    NSData		*checksum;
    NSData		*icon;
    NSImage		*image;
    unsigned char	nameLength;
    unsigned char	checksumLength;
    unsigned short	iconLength;
    unsigned char	number;
    unsigned short	flags;

    //Get the contact name
    [inPacket getCharValue:&nameLength];
    [inPacket getString:&name length:nameLength];

    //Flags
    [inPacket getShortValue:&flags];
    [inPacket getCharValue:&number];

    //Icon checksum
    [inPacket getCharValue:&checksumLength];
    [inPacket getData:&checksum length:checksumLength];

    //Icon data
    [inPacket getShortValue:&iconLength];
    [inPacket getData:&icon length:iconLength];

    //Create an image from the icon data, and pass it to our account
    if(image = [[[NSImage alloc] initWithData:icon] autorelease]){
        [account noteContact:name icon:image checksum:checksum];
    }
}


//Shared --------------------------------------------------------------------------------------------
//
+ (NSString *)convertDataToBase16:(NSData *)data
{
    NSString		*base16String;
    const unsigned char	*bytes;
    int			index;
    int			length;
    unsigned char 	*cString;

    //
    bytes = [data bytes];
    length = [data length];

    //Convert (NSMutableString's appendFormat: doesn't appear to work right with @"%02hhx");
    cString = malloc((length * 2) + 1);
    for(index = 0; index < length; index++){
        snprintf(&cString[index * 2], 3, "%02hhx", bytes[index]);
    }
    base16String = [NSString stringWithCString:cString length:length];
    free(cString);

    //
    return(base16String);
}

@end

