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

#import "AIOscarConnection.h"
#import <AIUtilities/AIUtilities.h>
#import "AIOscarAccount.h"

@interface AIOscarConnection (PRIVATE)
- (id)initForAccount:(AIOscarAccount *)inAccount withHost:(NSString *)inHost port:(int)inPort delegate:(id)inDelegate;
- (void)update:(NSTimer *)timer;
@end

@implementation AIOscarConnection

//
+ (id)connectionForAccount:(AIOscarAccount *)inAccount withHost:(NSString *)inHost port:(int)inPort delegate:(id)inDelegate
{
    return([[[self alloc] initForAccount:inAccount withHost:inHost port:inPort delegate:inDelegate] autorelease]);
}

//
- (id)initForAccount:(AIOscarAccount *)inAccount withHost:(NSString *)inHost port:(int)inPort delegate:(id)inDelegate
{
    [super init];

    //
    account = [inAccount retain];
    host = [inHost retain];
    port = inPort;
    delegate = inDelegate;
    supportedModules = [[NSMutableDictionary alloc] init];

    //Connect
    socket = [[AISocket socketWithHost:inHost port:inPort] retain];
    localSequence = (short)(65536.0*rand()/(RAND_MAX+1.0));
    localRequest = 1;

    //Install our update timer
    updateTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0 / 10.0) target:self selector:@selector(update:) userInfo:nil repeats:YES];
    
    return(self);
}

//
- (void)dealloc
{
    [account release];
    [socket release];
    [host release];
    [supportedModules release];
    [updateTimer invalidate]; [updateTimer release];
}

//Pass an array of modules supported by the server
- (void)addSupportedModules:(NSArray *)inArray
{
    NSEnumerator	*enumerator;
    Class		moduleClass;

    //Activate and add the modules
    enumerator = [inArray objectEnumerator];
    while(moduleClass = [enumerator nextObject]){
        id <AIOscarModule>	module;

        if([supportedModules objectForKey:[NSNumber numberWithInt:[moduleClass moduleFamily]]] == nil){
            //Create/active module
            module = [[[moduleClass alloc] initWithAccount:account forConnection:self] autorelease];
            NSLog(@"Creating %@ for %@", module, self);

            //Add
            [supportedModules setObject:module forKey:[NSNumber numberWithInt:[moduleClass moduleFamily]]];
        }
    }
}
- (NSDictionary *)supportedModules
{
    return(supportedModules);
}

- (id <AIOscarModule>)moduleForFamily:(int)inFamily
{
    return([supportedModules objectForKey:[NSNumber numberWithInt:inFamily]]);
}

//Delegate
- (void)setDelegate:(id)inDelegate
{
    delegate = inDelegate;
}

//Receive packets
- (void)update:(NSTimer *)timer
{
    AIOscarPacket	*packet;
    //Process a packet
    while(packet = [AIOscarPacket packetFromSocket:socket]){
        unsigned short	family, type, flags;
        long		requestID;
        //Get the family and type
        if([packet getSnacFamily:&family type:&type flags:&flags requestID:&requestID]){
            id <AIOscarModule>	module;
            //Pass the request to the correct module
            if(module = [supportedModules objectForIntegerKey:family]){
             //   NSLog(@"->0x%04x, 0x%04x",family,type);
                [module handleRequest:requestID type:type flags:flags packet:packet];

            }else{
                NSLog(@"No module loaded for %i",family);

            }

        }else{
            NSLog(@"No Snac found in packet");
        }
    }
}

//Send the packet
- (void)sendPacket:(AIOscarPacket *)inPacket
{
    if([socket isValid]){
        [inPacket sendToSocket:socket];
    }else{
        NSLog(@"Socket invalid for connection %@",self);
    }
}

//
/*- (unsigned short *)localSequence
{
    return(&localSequence);
}

//
- (unsigned long *)localRequest
{
    return(&localRequest);
}*/





- (AIOscarPacket *)emptyPacketOnChannel:(OSCARCHANNEL)inChannel
{
    AIOscarPacket	*packet;

    packet = [AIOscarPacket packetOnChannel:inChannel withSequence:&localSequence];

    return(packet);
}

- (AIOscarPacket *)snacPacketWithFamily:(unsigned short)inFamily type:(unsigned short)inType flags:(unsigned short)inFlags
{
    AIOscarPacket	*packet;

    packet = [AIOscarPacket packetOnChannel:CHANNEL_DATA withSequence:&localSequence];
    [packet addSnacWithFamily:inFamily type:inType flags:inFlags requestID:&localRequest];

    return(packet);
}












@end
