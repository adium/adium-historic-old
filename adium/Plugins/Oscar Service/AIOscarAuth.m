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

#import "AIOscarAuth.h"
#import "AIOscarAccount.h"
#import "AIOscarService.h"
#import "AIOscarPacket.h"
#import "AIOscarTLVBlock.h"
#import "AIOscarConnection.h"
#import <AIUtilities/AIUtilities.h>
#import <openssl/md5.h>

//CLIENTINFO_AIM_5_1_3036
#define CLIENT_String	"AOL Instant Messenger, version 5.1.3036/WIN32"
#define CLIENT_ID	0x0109
#define CLIENT_Major	0x0005
#define CLIENT_Minor	0x0001
#define CLIENT_Point	0x0000
#define CLIENT_Build	0x0bdc
#define CLIENT_Distrib	0x000000d2
#define CLIENT_Country	"us"
#define CLIENT_Lang	"en"

//
#define AIM_MD5_STRING "AOL Instant Messenger (SM)"

@interface AIOscarAuth (PRIVATE)
- (void)_handleAuthResponse:(AIOscarPacket *)inPacket;
- (void)_handleLogin:(AIOscarPacket *)inPacket;
- (void)_sendLoginRequestWithKey:(NSString *)md5Key userName:(NSString *)userName password:(NSString *)password;
@end

@implementation AIOscarAuth

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
    return(0x0017);
}
+ (unsigned short)moduleVersion{
    return(0x0000);
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
        case 0x0003: [self _handleAuthResponse:inPacket]; break;
        case 0x0007: [self _handleLogin:inPacket]; break;
        default: NSLog(@"(%@) Unknown type: %i",self,type); break;
    }
}

//
- (void)_handleAuthResponse:(AIOscarPacket *)inPacket
{
    AIOscarTLVBlock	*valueBlock = [inPacket getTLVBlock];
    NSString		*stringValue;
    NSString		*host;
    int			port;
    NSString		*cookie;

    //Check for an error
    if(stringValue = [valueBlock stringForType:0x0004]){
        NSLog(@"AuthResponse Error: %@",stringValue);

    }else{
        AIOscarConnection	*serviceConnection;
        
        //Get the server host & port
        if(stringValue = [valueBlock stringForType:0x0005]){
            [AIOscarService extractHost:&host andPort:&port fromString:stringValue];
        }

        //Get the cookie
        cookie = [valueBlock stringForType:0x0006];

        //Get some other interesting info
        NSLog(@"ScreenName: %@",[valueBlock stringForType:0x0001]);
        NSLog(@"Email: %@",[valueBlock stringForType:0x0011]);
        /*NSLog(@"Status: %@",[valueBlock stringForType:0x0013]);
        NSLog(@"Unknown(0x0040): %@",[valueDict objectForIntegerKey:0x0040]]);
        NSLog(@"Newest Version URL: %@",[valueDict objectForIntegerKey:0x0041]]);
        NSLog(@"BetaURL: %@",[valueDict objectForIntegerKey:0x0042]]);
        NSLog(@"Newest Version: %@",[valueDict objectForIntegerKey:0x0043]]);
        NSLog(@"Unknown(0x0044): %@",[valueDict objectForIntegerKey:0x0044]]);
        NSLog(@"Newest Version URL: %@",[valueDict objectForIntegerKey:0x0045]]);
        NSLog(@"More Info URL: %@",[valueDict objectForIntegerKey:0x0046]]);
        NSLog(@"My Version?: %@",[valueDict objectForIntegerKey:0x0047]]);
        NSLog(@"Capabilities?: %@",[valueDict objectForIntegerKey:0x0048]]);
        NSLog(@"Capabilities?: %@",[valueDict objectForIntegerKey:0x0049]]);
        NSLog(@"Change Password URL: %@",[valueDict objectForIntegerKey:0x0054]]);
        NSLog(@".Mac ScreenName?: %@",[valueDict objectForIntegerKey:0x0055]]);*/

        //Connect
        serviceConnection = [AIOscarConnection connectionForAccount:account withHost:host port:port delegate:account];
        [AIOscarAuth sendCookie:cookie toConnection:serviceConnection];
        [account addConnection:serviceConnection supportingModules:[NSArray arrayWithObject:[[account availableModules] objectForIntegerKey:0x0001]]];
    }

}

//
- (void)_handleLogin:(AIOscarPacket *)inPacket
{
    NSString		*keyString;
    short 		keyLength;

    //Get MD5 key
    [inPacket getShortValue:&keyLength];
    [inPacket getString:&keyString length:keyLength];

    //Send our login request
    [self _sendLoginRequestWithKey:keyString userName:[account userName] password:[account password]];
}

//
- (void)_sendLoginRequestWithKey:(NSString *)md5Key userName:(NSString *)userName password:(NSString *)password
{
    AIOscarPacket	*loginPacket = [connection snacPacketWithFamily:0x0017 type:0x0002 flags:0x000];
    AIOscarTLVBlock	*loginBlock = [AIOscarTLVBlock TLVBlock];
    unsigned char 	*digest;
    NSString		*tempString;

    //Name/pass
    [loginBlock addType:0x0001 string:userName];
    
    tempString = [NSString stringWithFormat:@"%@%@%s", md5Key, password, AIM_MD5_STRING];
    digest = MD5([tempString cString],[tempString length], NULL);
    
    [loginBlock addType:0x0025 bytes:digest length:strlen(digest)];

    //Client Info
    [loginBlock addType:0x0003 bytes:CLIENT_String length:strlen(CLIENT_String)];
    [loginBlock addType:0x0016 shortValue:CLIENT_ID];
    [loginBlock addType:0x0017 shortValue:CLIENT_Major];
    [loginBlock addType:0x0018 shortValue:CLIENT_Minor];
    [loginBlock addType:0x0019 shortValue:CLIENT_Point];
    [loginBlock addType:0x001a shortValue:CLIENT_Build];
    [loginBlock addType:0x0014 longValue:CLIENT_Distrib];
    [loginBlock addType:0x000e bytes:CLIENT_Country length:strlen(CLIENT_Country)];
    [loginBlock addType:0x000f bytes:CLIENT_Lang length:strlen(CLIENT_Lang)];

    //Use server-side buddy lists
    [loginBlock addType:0x004a charValue:0x01];

    //Send packet
    [loginPacket addTLVBlock:loginBlock];
    [connection sendPacket:loginPacket];
}


//Shared ---------------------------------------------------------------------------------
//
+ (void)sendCookie:(NSString *)cookie toConnection:(AIOscarConnection *)inConnection
{
    AIOscarPacket	*cookiePacket = [inConnection emptyPacketOnChannel:CHANNEL_SIGNON];
    AIOscarTLVBlock	*cookieBlock = [AIOscarTLVBlock TLVBlock];

    //Create the packet
    [cookiePacket addLong:0x00000001];

    //Add the cookie
    [cookieBlock addType:0x0006 bytes:[cookie cString] length:[cookie length]];
    [cookiePacket addTLVBlock:cookieBlock];

    //Send
    [inConnection sendPacket:cookiePacket];
}



@end
