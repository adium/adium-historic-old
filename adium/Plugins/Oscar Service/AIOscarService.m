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

#import "AIOscarService.h"
#import "AIOscarAccount.h"
#import "AIOscarPacket.h"
#import "AIOscarConnection.h"
#import "AIOscarAuth.h"
#import "AIOscarTLVBlock.h"
#import <AIUtilities/AIUtilities.h>

@interface AIOscarService (PRIVATE)
- (void)handleRequest:(long)requestID type:(unsigned short)type flags:(unsigned short)flags packet:(AIOscarPacket *)inPacket;
- (void)_handleServerReady:(AIOscarPacket *)inPacket;
- (void)_handleRedirect:(AIOscarPacket *)inPacket;
- (void)_handleRateResponse:(AIOscarPacket *)inPacket;
- (void)_handleRateChange:(AIOscarPacket *)inPacket;
- (void)_handleServicePause:(AIOscarPacket *)inPacket;
- (void)_handleServiceResume:(AIOscarPacket *)inPacket;
- (void)_handleSelfInfo:(AIOscarPacket *)inPacket;
- (void)_handleEviled:(AIOscarPacket *)inPacket;
- (void)_handleMigrate:(AIOscarPacket *)inPacket;
- (void)_handleMessageOfTheDay:(AIOscarPacket *)inPacket;
- (void)_handleHostVersions:(AIOscarPacket *)inPacket;
- (void)_handleClientVerification:(AIOscarPacket *)inPacket;
- (void)_handleExtendedStatusRequest:(AIOscarPacket *)inPacket;
@end

@implementation AIOscarService

//Init
- (id)initWithAccount:(AIOscarAccount *)inAccount forConnection:(AIOscarConnection *)inConnection
{
    [super init];

    account = [inAccount retain];
    connection = [inConnection retain];

    return(self);
}

- (void)dealloc
{
    [account release];
    [connection release];
}

//Return our module information
+ (unsigned short)moduleFamily{
    return(0x0001);
}
+ (unsigned short)moduleVersion{
    return(0x0003);
}
+ (unsigned short)toolID{
    return(0x0110);
}
+ (unsigned short)toolVersion{
    return(0x0629);
}

//Commands -------------------------------------------------------------------------------------
//0x0002
- (void)sendClientReady
{
    AIOscarPacket	*readyPacket = [connection snacPacketWithFamily:0x0001 type:0x0002 flags:0x000];
    NSEnumerator	*enumerator;
    id <AIOscarModule>	module;

    //Add the values and ids of all our modules
    enumerator = [[[connection supportedModules] allValues] objectEnumerator];
    while(module = [enumerator nextObject]){
        [readyPacket addShort:[[module class] moduleFamily]];
        [readyPacket addShort:[[module class] moduleVersion]];
        [readyPacket addShort:[[module class] toolID]];
        [readyPacket addShort:[[module class] toolVersion]];
    }

    //Send
    [connection sendPacket:readyPacket];
}

//0x0004
- (void)requestServiceForFamily:(unsigned short)inFamily
{
    AIOscarPacket	*requestPacket = [connection snacPacketWithFamily:0x0001 type:0x0004 flags:0x000];

    //Icon Server
    [requestPacket addShort:inFamily];

    //Send
    [connection sendPacket:requestPacket];
}

//0x0006
- (void)requestRates
{
    [connection sendPacket:[connection snacPacketWithFamily:0x0001 type:0x0006 flags:0x000]];
}

//0x0008
- (void)addRateParameter
{
    NSLog(@"addRateParameter (Not implemented)"); //Not implemented
}

//0x0009
- (void)deleteRateParameter
{
    NSLog(@"deleteRateParameter (Not implemented)"); //Not implemented
}

//0x000c
- (void)acknowledgeServicePause
{
    NSLog(@"acknowledgeServicePause (Not implemented)"); //Not implemented
}

//0x000e
- (void)requestPersonalInformation
{
    [connection sendPacket:[connection snacPacketWithFamily:0x0001 type:0x000e flags:0x000]];
}

//0x0011
- (void)setIdleTime:(unsigned long)idleTime
{
    AIOscarPacket	*idlePacket = [connection snacPacketWithFamily:0x0001 type:0x0011 flags:0x0000];

    //Idle time
    [idlePacket addLong:idleTime];

    //Send
    [connection sendPacket:idlePacket];
}

//0x0014
- (void)setPrivacyFlagsAllowIdle:(BOOL)allowIdle allowMemberSince:(BOOL)allowMemberSince
{
    AIOscarPacket	*idlePacket = [connection snacPacketWithFamily:0x0001 type:0x0014 flags:0x0000];

    //Idle time
    [idlePacket addLong:( (allowIdle ? 0x01 : 0x00) & (allowMemberSince ? 0x02 : 0x00) )];

    //Send
    [connection sendPacket:idlePacket];
}

//0x0016
- (void)sendNoOp
{
    [connection sendPacket:[connection snacPacketWithFamily:0x0001 type:0x0016 flags:0x000]];
}

//0x0017
- (void)sendClientModuleVersions
{
    AIOscarPacket	*versionPacket = [connection snacPacketWithFamily:0x0001 type:0x0017 flags:0x000];
    NSEnumerator	*enumerator;
    id <AIOscarModule>	module;

    //Add the family and version of all our modules
    enumerator = [[[connection supportedModules] allValues] reverseObjectEnumerator];
    while(module = [enumerator nextObject]){
        [versionPacket addShort:[[module class] moduleFamily]];
        [versionPacket addShort:[[module class] moduleVersion]];
    }

    //Send
    [connection sendPacket:versionPacket];
}

//0x001e
- (void)setExtendedStatus // ( / available message)
{
    NSLog(@"setExtendedStatus (Not implemented)"); //Not implemented
}

//0x0020
- (void)sendClientVerification
{
    NSLog(@"sendClientVerification (Not implemented)"); //Not implemented
}


//Handlers -------------------------------------------------------------------------------------
//Handle a request
- (void)handleRequest:(long)requestID type:(unsigned short)type flags:(unsigned short)flags packet:(AIOscarPacket *)inPacket
{
    switch(type){
        case 0x0001: NSLog(@"Error: %@",inPacket); break;
        case 0x0003: [self _handleServerReady:inPacket]; break;
        case 0x0005: [self _handleRedirect:inPacket]; break;
        case 0x0007: [self _handleRateResponse:inPacket]; break;
        case 0x000a: [self _handleRateChange:inPacket]; break;
        case 0x000b: [self _handleServicePause:inPacket]; break;
        case 0x000d: [self _handleServiceResume:inPacket]; break;
        case 0x000F: [self _handleSelfInfo:inPacket]; break;
        case 0x0010: [self _handleEviled:inPacket]; break;
        case 0x0012: [self _handleMigrate:inPacket]; break;
        case 0x0013: [self _handleMessageOfTheDay:inPacket]; break;
        case 0x0018: [self _handleHostVersions:inPacket]; break;
        case 0x001f: [self _handleClientVerification:inPacket]; break;
        case 0x0021: [self _handleExtendedStatusRequest:inPacket]; break;
        default: NSLog(@"(%@) Unknown type: %i",self,type); break;
    }
}

//0x0003
- (void)_handleServerReady:(AIOscarPacket *)inPacket
{
    NSDictionary	*availableModules = [account availableModules];
    NSMutableArray	*supportedModules = [NSMutableArray array];
    unsigned short	moduleFamily;

    //Get supported modules
    while([inPacket getShortValue:&moduleFamily]){
        id <AIOscarModule>	module = [availableModules objectForIntegerKey:moduleFamily];

        if(module){
            [supportedModules addObject:module];
        }else{
            NSLog(@"Unsupported module family %i", moduleFamily);
        }
    }
    [connection addSupportedModules:supportedModules];

    //Send module/version packet
    [self sendClientModuleVersions];
}

//0x0005
- (void)_handleRedirect:(AIOscarPacket *)inPacket
{
    AIOscarTLVBlock	*valueBlock;
    NSString		*hostPortString;
    NSString		*host = nil;
    NSString		*cookie;
    int			port = 0;
    int			family;
    unsigned short	valueCount;
    AIOscarConnection	*newConnection;

    //Get the family
    [inPacket getShortValue:&valueCount];
    valueBlock = [inPacket getTLVBlock];
    family = [valueBlock integerForType:0x000d];

    //Get the server host & port
    if(hostPortString = [valueBlock stringForType:0x0005]){
        [AIOscarService extractHost:&host andPort:&port fromString:hostPortString];
    }

    //Get the cookie
    cookie = [valueBlock stringForType:0x0006];

    //Handle the redirect
    switch(family){
        case 0x0010:            
            newConnection = [AIOscarConnection connectionForAccount:account withHost:host port:port delegate:account];
            [AIOscarAuth sendCookie:cookie toConnection:newConnection];
            [account addConnection:newConnection supportingModules:[NSArray arrayWithObject:[[account availableModules] objectForIntegerKey:0x0001]]];
        break;
        default:
            NSLog(@"Unknown redirect (%i, %@:%i)", family, host, port);
        break;
    }
}

//0x0007
- (void)_handleRateResponse:(AIOscarPacket *)inPacket
{
    AIOscarPacket	*ackPacket = [connection snacPacketWithFamily:0x0001 type:0x0008 flags:0x000];
    NSString		*extraBytesString;
    unsigned short 	numberOfClasses;
    int			loop;

    //All we need to send back are the rate class ID values, we can just ignore everything else
    //Parameters
    [inPacket getShortValue:&numberOfClasses];
    for(loop = 0;loop < numberOfClasses;loop++){
        unsigned long 	windowSize, clear, alert, limit, disconnect, current, max;
        unsigned short 	classID;

        //Get values
        [inPacket getShortValue:&classID];
        [inPacket getLongValue:&windowSize];
        [inPacket getLongValue:&clear];
        [inPacket getLongValue:&alert];
        [inPacket getLongValue:&limit];
        [inPacket getLongValue:&disconnect];
        [inPacket getLongValue:&current];
        [inPacket getLongValue:&max];
        [inPacket getString:&extraBytesString length:5]; //5 extra bytes

        //Add the class ID to our array
        [ackPacket addShort:classID];
    }

    //Send our ack packet
    [connection sendPacket:ackPacket];

    //Finish the sign on process by invoking the rest of our modules
    [account sendSignonRequestsForConnection:connection];
}

//0x000a
- (void)_handleRateChange:(AIOscarPacket *)inPacket
{
    unsigned short code, rateClass;
    unsigned long currentAvg, maxAvg, windowSize, clear, alert, limit, disconnect;

    //Get code & class
    [inPacket getShortValue:&code];
    [inPacket getShortValue:&rateClass];

    //Get rate info
    [inPacket getLongValue:&windowSize];
    [inPacket getLongValue:&clear];
    [inPacket getLongValue:&alert];
    [inPacket getLongValue:&limit];
    [inPacket getLongValue:&disconnect];
    [inPacket getLongValue:&currentAvg];
    [inPacket getLongValue:&maxAvg];

    //Log
    NSLog(@"Rate Change: (%i, %i) (%i, %i, %i, %i, %i, %i, %i)", code, rateClass, windowSize, clear, alert, limit, disconnect, currentAvg, maxAvg);
}

//0x000b
- (void)_handleServicePause:(AIOscarPacket *)inPacket
{
    NSLog(@"_handleServicePause (Not implemented)"); //Not implemented
}

//0x000d
- (void)_handleServiceResume:(AIOscarPacket *)inPacket
{
    NSLog(@"_handleServiceResume (Not implemented)"); //Not implemented
}

//0x000f
- (void)_handleSelfInfo:(AIOscarPacket *)inPacket
{
    NSLog(@"_handleSelfInfo (Not implemented)"); //Not implemented
}

//0x0010
- (void)_handleEviled:(AIOscarPacket *)inPacket
{
    NSLog(@"_handleEviled (Not implemented)"); //Not implemented
}

//0x0012
- (void)_handleMigrate:(AIOscarPacket *)inPacket
{
    NSLog(@"_handleMigrate (Not implemented)"); //Not implemented
}

//0x0013
- (void)_handleMessageOfTheDay:(AIOscarPacket *)inPacket
{
    NSLog(@"_handleMessageOfTheDay (Not implemented)"); //Not implemented
}

//0x0018
- (void)_handleHostVersions:(AIOscarPacket *)inPacket
{
    NSLog(@"_handleHostVersions (Not implemented)"); //Not implemented
    
    //Request rates
    [self requestRates];    
}

//0x001f
- (void)_handleClientVerification:(AIOscarPacket *)inPacket
{
    NSLog(@"_handleClientVerification (Not implemented)"); //Not implemented
}

//0x0021
- (void)_handleExtendedStatusRequest:(AIOscarPacket *)inPacket
{
    unsigned short	type;

    NSLog(@"_handleExtendedStatusRequest (Not implemented)"); //Not implemented

    //Get type
    [inPacket getShortValue:&type];

    switch(type){
        case 0x0000:
        case 0x0001:{ //
        }break;

        case 0x0002:{ //
        }break;

        case 0x0006:{ //        
        }break;
    }
}


//Shared ------------------------------------------------------------------------------------
//
+ (void)extractHost:(NSString **)outHost andPort:(int *)outPort fromString:(NSString *)stringValue
{
    NSRange	colonRange;
    NSString	*host;
    int		port;

    //Break the string at the colon
    colonRange = [stringValue rangeOfString:@":"];
    if(colonRange.location != NSNotFound){
        host = [stringValue substringToIndex:colonRange.location];
        port = [[stringValue substringFromIndex:(colonRange.location + 1)] intValue];

    }else{
        host = stringValue;
        port = 5190; //No port is provided
    }

    //
    if(outHost) *outHost = host;
    if(outPort) *outPort = port;
}

@end
