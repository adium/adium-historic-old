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

#import "AIOscarInfo.h"
#import "AIOscarAccount.h"
#import "AIOscarPacket.h"
#import "AIOscarTLVBlock.h"
#import "AIOscarConnection.h"

@interface AIOscarInfo (PRIVATE)
- (NSData *)_encoding:(NSString **)encoding forString:(NSString *)string;
- (void)_handleLocatorRights:(AIOscarPacket *)inPacket;
- (void)_handleUserInfo:(AIOscarPacket *)inPacket;
@end

@implementation AIOscarInfo

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
    return(0x0002);
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
- (void)requestLocatorRights
{
    [connection sendPacket:[connection snacPacketWithFamily:0x0002 type:0x0002 flags:0x000]];
}

//0x0004
- (void)setProfile:(NSString *)profile awayMessage:(NSString *)awayMessage capabilities:(NSArray *)capabilities
{
    AIOscarPacket	*profilePacket = [connection snacPacketWithFamily:0x0002 type:0x0004 flags:0x000];
    AIOscarTLVBlock	*profileBlock = [AIOscarTLVBlock TLVBlock];

    //Add profile
    if(profile){
        NSData		*encodedProfile;
        NSString	*encoding;

        //Determine the profile encoding
        encodedProfile = [self _encoding:&encoding forString:profile];

        //Add profile data to the packet
        [profileBlock addType:0x0001 bytes:[encoding cString] length:[encoding length]];
        [profileBlock addType:0x0002 bytes:[encodedProfile bytes] length:[encodedProfile length]];
    }
    
    //Add away message
    if(awayMessage){
        if([awayMessage length]){
            NSData	*encodedAwayMessage;
            NSString	*encoding;
            
            //Determine the away message encoding
            encodedAwayMessage = [self _encoding:&encoding forString:awayMessage];

            //Add away data to the packet
            [profileBlock addType:0x0003 bytes:[encoding cString] length:[encoding length]];
            [profileBlock addType:0x0004 bytes:[encodedAwayMessage bytes] length:[encodedAwayMessage length]];

        }else{
            //Add the type so we are flagged as not away
            [profileBlock addType:0x0004 bytes:nil length:0];

        }
    }

    //Add our capabilities (Hard coded for now)
    if(capabilities){
        NSString	*capsString = [AIOscarInfo stringOfCaps:capabilities];
        [profileBlock addType:0x0005 bytes:[capsString cString] length:[capsString length]];
    }

    //Send packet
    [profilePacket addTLVBlock:profileBlock];
    [connection sendPacket:profilePacket];
}

//Returns the string encoded, passing back the encoding type used
- (NSData *)_encoding:(NSString **)encoding forString:(NSString *)string
{
    NSData	*encodedString;
    
    //Check ASCII first
    if([string canBeConvertedToEncoding:NSASCIIStringEncoding]){
        *encoding = @"text/aolrtf; charset=\"us-ascii\"";
        encodedString = [string dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];

    }else{ //If ASCII won't work, use unicode
        *encoding = @"text/aolrtf; charset=\"unicode-2-0\"";
        encodedString = [string dataUsingEncoding:NSUnicodeStringEncoding allowLossyConversion:YES];

    }

    return(encodedString);
}

//0x0005
- (void)getInfo:(OscarInfoType)infoType forUser:(NSString *)name
{
    AIOscarPacket	*requestPacket = [connection snacPacketWithFamily:0x0002 type:0x0005 flags:0x000];

    //Add info type and name
    [requestPacket addShort:infoType];
    [requestPacket addString:name];

    //Send
    [connection sendPacket:requestPacket];
}

//0x0009
- (void)setDirectoryInfoPrivacy:(unsigned short)privacy first:(NSString *)first last:(NSString *)last middle:(NSString *)middle maiden:(NSString *)maiden state:(NSString *)state city:(NSString *)city nickname:(NSString *)nickname zip:(NSString *)zip street:(NSString *)street
{
    AIOscarPacket	*infoPacket = [connection snacPacketWithFamily:0x0002 type:0x0009 flags:0x000];
    AIOscarTLVBlock	*infoBlock = [AIOscarTLVBlock TLVBlock];

    //Add the info
    [infoBlock addType:0x000a shortValue:privacy];
    if(first) [infoBlock addType:0x0001 string:first];
    if(last) [infoBlock addType:0x0002 string:last];
    if(middle) [infoBlock addType:0x0003 string:middle];
    if(maiden) [infoBlock addType:0x0004 string:maiden];
    if(state) [infoBlock addType:0x0007 string:state];
    if(city) [infoBlock addType:0x0008 string:city];
    if(nickname) [infoBlock addType:0x000c string:nickname];
    if(zip) [infoBlock addType:0x000d string:zip];
    if(street) [infoBlock addType:0x0021 string:street];
    
    //Send
    [infoPacket addTLVBlock:infoBlock];
    [connection sendPacket:infoPacket];
}

//0x000f
- (void)setDirectoryInfoPrivacy:(unsigned short)privacy interests:(NSArray *)interests
{
    //Interests
    if([interests count] <= 5){
        AIOscarPacket	*infoPacket = [connection snacPacketWithFamily:0x0002 type:0x000f flags:0x000];
        AIOscarTLVBlock	*infoBlock = [AIOscarTLVBlock TLVBlock];
        NSEnumerator	*enumerator;
        NSString	*interest;

        //Add privacy
        [infoBlock addType:0x000a shortValue:privacy];

        //Add interests
        enumerator = [interests objectEnumerator];
        while(interest = [enumerator nextObject]){
            [infoBlock addType:0x0000b string:interest];
        }

        //Send
        [infoPacket addTLVBlock:infoBlock];
        [connection sendPacket:infoPacket];
        
    }else{
        NSLog(@"Cannot set more than 5 interests");
    }
}

//0x0015
- (void)getAwayMessageForUser:(NSString *)name
{
    AIOscarPacket	*requestPacket = [connection snacPacketWithFamily:0x0002 type:0x0015 flags:0x000];

    //Add info type and username
    [requestPacket addLong:0x00000002];
    [requestPacket addChar:[name length]];
    [requestPacket addString:name];

    //Send
    [connection sendPacket:requestPacket];
}



//Handlers -------------------------------------------------------------------------------------
//Handle a request
- (void)handleRequest:(long)requestID type:(unsigned short)type flags:(unsigned short)flags packet:(AIOscarPacket *)inPacket
{
    switch(type){
        case 0x0003: [self _handleLocatorRights:inPacket]; break;
        case 0x0006: [self _handleUserInfo:inPacket]; break;
        default: NSLog(@"(%@) Unknown type: %i",self,type); break;
    }
}

//0x0003
- (void)_handleLocatorRights:(AIOscarPacket *)inPacket
{
    NSLog(@"_handleLocatorRights (Not implemented)"); //Not implemented
    //AIOscarTLVBlock	*valueBlock = [inPacket getTLVBlock];

    //Max sig length (and away?)
    //NSLog(@"Max profile length: %i",[valueBlock integerForType:0x0001]);
    //NSLog(@"?: %i",[valueBlock integerForType:0x0002]);
    //NSLog(@"?: %i",[valueBlock integerForType:0x0003]);
    //NSLog(@"?: %i",[valueBlock integerForType:0x0004]);
}

//0x0006
- (void)_handleUserInfo:(AIOscarPacket *)inPacket
{
    NSString		*name;
    NSString		*encoding, *info, *capabilities;
    AIOscarTLVBlock	*standardValueBlock;
    AIOscarTLVBlock	*valueBlock;

    //Get the standard user info
    standardValueBlock = [AIOscarInfo extractInfoFromPacket:inPacket name:&name warnLevel:nil];
        
    //Get the requested info
    valueBlock = [inPacket getTLVBlock];
    
    //General info
    if((encoding = [valueBlock stringForType:0x0001]) && (info = [valueBlock stringForType:0x0002])){

        //NSLog(@"Encoding: %@",encoding);
        //NSLog(@"Info: %@",info);
        
    //Away message
    }else if((encoding = [valueBlock stringForType:0x0003]) && (info = [valueBlock stringForType:0x0004])){

        //NSLog(@"Encoding: %@",encoding);
        //NSLog(@"Info: %@",info);        

        //Convert to unicode
        if([encoding rangeOfString:@"unicode-2-0"].location != NSNotFound){
            info = [[[NSString alloc] initWithData:[NSData dataWithBytes:[info cString] length:[info length]]
                                          encoding:NSUnicodeStringEncoding] autorelease];
        }
        
        //Update away
        [account updateContact:name awayMessage:info];

        
    //Capabilities
    }else if(capabilities = [valueBlock stringForType:0x0005]){
        //NSLog(@"Caps: %@",[AIOscarInfo getCapsFromString:capabilities]);
        
    }
}



//Shared -------------------------------------------------------------------------------------
//Capabilities
static const struct {
    unsigned long flag;
    unsigned char data[16];
} aim_caps[] = {

    /*
     * These are in ascending numerical order.
     */
    {AIM_CAPS_ICHAT,
    {0x09, 0x46, 0x00, 0x00, 0x4c, 0x7f, 0x11, 0xd1, 0x82, 0x22, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00}},

    {AIM_CAPS_HIPTOP,
    {0x09, 0x46, 0x13, 0x23, 0x4c, 0x7f, 0x11, 0xd1,
        0x82, 0x22, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00}},

    {AIM_CAPS_VOICE,
    {0x09, 0x46, 0x13, 0x41, 0x4c, 0x7f, 0x11, 0xd1,
        0x82, 0x22, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00}},

    {AIM_CAPS_SENDFILE,
    {0x09, 0x46, 0x13, 0x43, 0x4c, 0x7f, 0x11, 0xd1,
        0x82, 0x22, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00}},

    /*
     * Advertised by the EveryBuddy client.
     */
    {AIM_CAPS_ICQ,
    {0x09, 0x46, 0x13, 0x44, 0x4c, 0x7f, 0x11, 0xd1,
        0x82, 0x22, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00}},

    {AIM_CAPS_IMIMAGE,
    {0x09, 0x46, 0x13, 0x45, 0x4c, 0x7f, 0x11, 0xd1,
        0x82, 0x22, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00}},

    {AIM_CAPS_BUDDYICON,
    {0x09, 0x46, 0x13, 0x46, 0x4c, 0x7f, 0x11, 0xd1,
        0x82, 0x22, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00}},

    /*
     * Windows AIM calls this "Add-ins," which is probably more accurate
     */
    {AIM_CAPS_SAVESTOCKS,
    {0x09, 0x46, 0x13, 0x47, 0x4c, 0x7f, 0x11, 0xd1,
        0x82, 0x22, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00}},

    {AIM_CAPS_GETFILE,
    {0x09, 0x46, 0x13, 0x48, 0x4c, 0x7f, 0x11, 0xd1,
        0x82, 0x22, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00}},

    {AIM_CAPS_ICQSERVERRELAY,
    {0x09, 0x46, 0x13, 0x49, 0x4c, 0x7f, 0x11, 0xd1,
        0x82, 0x22, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00}},

    /*
     * Indeed, there are two of these.  The former appears to be correct,
     * but in some versions of winaim, the second one is set.  Either they
     * forgot to fix endianness, or they made a typo. It really doesn't
     * matter which.
     */
    {AIM_CAPS_GAMES,
    {0x09, 0x46, 0x13, 0x4a, 0x4c, 0x7f, 0x11, 0xd1,
        0x82, 0x22, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00}},
    {AIM_CAPS_GAMES2,
    {0x09, 0x46, 0x13, 0x4a, 0x4c, 0x7f, 0x11, 0xd1,
        0x22, 0x82, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00}},

    {AIM_CAPS_SENDBUDDYLIST,
    {0x09, 0x46, 0x13, 0x4b, 0x4c, 0x7f, 0x11, 0xd1,
        0x82, 0x22, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00}},

    /*
     * Setting this lets AIM users receive messages from ICQ users, and ICQ
     * users receive messages from AIM users.  It also lets ICQ users show
     * up in buddy lists for AIM users, and AIM users show up in buddy lists
     * for ICQ users.  And ICQ privacy/invisibility acts like AIM privacy,
     * in that if you add a user to your deny list, you will not be able to
     * see them as online (previous you could still see them, but they
                           * couldn't see you.
                           */
    {AIM_CAPS_INTEROPERATE,
    {0x09, 0x46, 0x13, 0x4d, 0x4c, 0x7f, 0x11, 0xd1,
        0x82, 0x22, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00}},

    {AIM_CAPS_ICQUTF8,
    {0x09, 0x46, 0x13, 0x4e, 0x4c, 0x7f, 0x11, 0xd1,
        0x82, 0x22, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00}},

    {AIM_CAPS_ICQUNKNOWN,
    {0x2e, 0x7a, 0x64, 0x75, 0xfa, 0xdf, 0x4d, 0xc8,
        0x88, 0x6f, 0xea, 0x35, 0x95, 0xfd, 0xb6, 0xdf}},

    /*
     * Chat is oddball.
     */
    {AIM_CAPS_CHAT,
    {0x74, 0x8f, 0x24, 0x20, 0x62, 0x87, 0x11, 0xd1,
        0x82, 0x22, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00}},

    /*
     {AIM_CAPS_ICQ2GO,
     {0x56, 0x3f, 0xc8, 0x09, 0x0b, 0x6f, 0x41, 0xbd,
         0x9f, 0x79, 0x42, 0x26, 0x09, 0xdf, 0xa2, 0xf3}},
     */

    {AIM_CAPS_ICQRTF,
    {0x97, 0xb1, 0x27, 0x51, 0x24, 0x3c, 0x43, 0x34,
        0xad, 0x22, 0xd6, 0xab, 0xf7, 0x3f, 0x14, 0x92}},

    /* supposed to be ICQRTF?
    {AIM_CAPS_TRILLUNKNOWN,
    {0x97, 0xb1, 0x27, 0x51, 0x24, 0x3c, 0x43, 0x34,
        0xad, 0x22, 0xd6, 0xab, 0xf7, 0x3f, 0x14, 0x09}}, */

    {AIM_CAPS_APINFO,
    {0xaa, 0x4a, 0x32, 0xb5, 0xf8, 0x84, 0x48, 0xc6,
        0xa3, 0xd7, 0x8c, 0x50, 0x97, 0x19, 0xfd, 0x5b}},

    {AIM_CAPS_TRILLIANCRYPT,
    {0xf2, 0xe7, 0xc7, 0xf4, 0xfe, 0xad, 0x4d, 0xfb,
        0xb2, 0x35, 0x36, 0x79, 0x8b, 0xdf, 0x00, 0x00}},

    {AIM_CAPS_EMPTY,
    {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}},

    {AIM_CAPS_LAST}
};

//
+ (NSString *)stringOfCaps:(NSArray *)capArray
{
    NSMutableString	*capString = [NSMutableString string];
    NSEnumerator	*enumerator;
    NSNumber		*capNumber;
    
    //Get each capability in the array
    enumerator = [capArray objectEnumerator];
    while(capNumber = [enumerator nextObject]){
        int	capIndex;
        int	capFlag = [capNumber intValue];

        //Search for this cap in our list
        for(capIndex = 0; !(aim_caps[capIndex].flag == AIM_CAPS_LAST); capIndex++) {

            //Add the cap
            if(aim_caps[capIndex].flag == capFlag){
                [capString appendString:[NSString stringWithCString:aim_caps[capIndex].data length:16]];
                break;
            }

        }
    }

    return(capString);
}

//
+ (NSArray *)getCapsFromString:(NSString *)capString
{
    NSMutableArray	*capArray = [NSMutableArray array];
    int			length = [capString length];
    const char 		*cString = [capString cString];
    int			offset;

    //Scan each cap in this string
    for(offset = 0; offset < length; offset += 16){
        int	capIndex;

        //Compare the bytes to all known caps
        for(capIndex = 0; !(aim_caps[capIndex].flag == AIM_CAPS_LAST); capIndex++) {
            if(memcmp(&aim_caps[capIndex].data, (cString + offset), 16) == 0){
                [capArray addObject:[NSNumber numberWithInt:aim_caps[capIndex].flag]];
                break;
            }
        }
    }

    return(capArray);
}

//
+ (AIOscarTLVBlock *)extractInfoFromPacket:(AIOscarPacket *)inPacket name:(NSString **)outName warnLevel:(unsigned short *)outWarnLevel
{
    AIOscarTLVBlock	*valueBlock;
    NSString		*name;
    unsigned short	warningLevel;
    unsigned char	nameLength;
    unsigned short	tlvCount;
    
    //Get username and warning level
    [inPacket getCharValue:&nameLength];
    [inPacket getString:&name length:nameLength];
    [inPacket getShortValue:&warningLevel];

    //TLV data
    [inPacket getShortValue:&tlvCount];
    valueBlock = [inPacket getTLVBlockWithLength:0 valueCount:tlvCount];

    //Return
    if(outName) *outName = name;
    if(outWarnLevel) *outWarnLevel = warningLevel;    
    return(valueBlock);
}

@end
