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

#import "AIOscarICQ.h"
#import "AIOscarAccount.h"
#import "AIOscarPacket.h"
#import "AIOscarConnection.h"

@interface AIOscarICQ (PRIVATE)
@end

@implementation AIOscarICQ

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
    return(0x0015);
}
+ (unsigned short)moduleVersion{
    return(0x0001);
}
+ (unsigned short)toolID{
    return(0x0110);
}
+ (unsigned short)toolVersion{
    return(0x047c);
}

//
- (void)setICQStatus
{
    //Set our ICQ status
    AIOscarPacket	*requestPacket = [connection snacPacketWithFamily:0x0001 type:0x001e flags:0x000];

    [requestPacket addShort:0x001d];
    [requestPacket addShort:0x0008];
    [requestPacket addShort:0x0002];
    [requestPacket addShort:0x0404];
    [requestPacket addShort:0x0000];
    [requestPacket addShort:0x0000];

    [connection sendPacket:requestPacket];
}

//Handle a request
- (void)handleRequest:(long)requestID type:(unsigned short)type flags:(unsigned short)flags packet:(AIOscarPacket *)inPacket
{
    switch(type){
        default: NSLog(@"(%@) Unknown type: %i",self,type); break;
    }
}

@end
