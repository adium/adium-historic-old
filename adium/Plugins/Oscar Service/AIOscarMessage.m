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

#import "AIOscarMessage.h"
#import "AIOscarAccount.h"
#import "AIOscarPacket.h"
#import "AIOscarInfo.h"
#import "AIOscarConnection.h"
#import "AIOscarTLVBlock.h"
#import "AIOscarIcon.h"

#define MAXICONLEN 7168
#define AIM_ICONIDENT "AVT1cow.jpg"

@interface AIOscarMessage (PRIVATE)
- (void)_handleMessageRights:(AIOscarPacket *)inPacket;
- (void)_handleMessageIn:(AIOscarPacket *)inPacket;
- (NSData *)_encodeMessage:(NSString *)message;
- (void)_handleTypingNotification:(AIOscarPacket *)inPacket;
@end

@implementation AIOscarMessage

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
    return(0x0004);
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
- (void)sendMessageRights
{
    AIOscarPacket	*rightsPacket = [connection snacPacketWithFamily:0x0004 type:0x0002 flags:0x000];

    //Add the rights
    [rightsPacket addShort:0x0000]; //Read only
    [rightsPacket addLong:0x0000000b/*flags*/];
    [rightsPacket addShort:0x1f40/*maxMessageLength*/];
    [rightsPacket addShort:0x03e7/*maxSenderWarn*/];
    [rightsPacket addShort:0x03e7/*maxReceiverWarn*/];
    [rightsPacket addLong:0x00000000/*minMessageInterval*/]; //No min!

    //Send
    [connection sendPacket:rightsPacket];
}

//0x0004
- (void)requestMessageRights
{
    [connection sendPacket:[connection snacPacketWithFamily:0x0004 type:0x0004 flags:0x000]];
}

//0x0006
- (void)sendMessage:(NSString *)message toContact:(NSString *)name advertiseIcon:(BOOL)advertiseIcon requestIcon:(BOOL)requestIcon
{
    AIOscarPacket	*messagePacket = [connection snacPacketWithFamily:0x0004 type:0x0006 flags:0x000];
    AIOscarTLVBlock	*mainBlock;
    AIOscarTLVBlock	*messageBlock;
    NSData		*cookie;
    static const char 	defaultFeatures[] = { 0x01, 0x01, 0x01, 0x02 };

    //Random message cookie
    cookie = [AIOscarMessage randomCookie];

    //ICBM header
    [AIOscarMessage addICBMHeaderToPacket:messagePacket
                               withCookie:cookie
                                  channel:0x0001
                                     name:name];

    //Build the message block
    messageBlock = [AIOscarTLVBlock TLVBlock];
    [messageBlock addType:0x0501 bytes:defaultFeatures length:sizeof(defaultFeatures)]; //Features
    [messageBlock addType:0x0101 data:[self _encodeMessage:message]];			//Encoded message

    //Place the message block into another TLV block
    mainBlock = [AIOscarTLVBlock TLVBlock];
    [mainBlock addType:0x0002 data:[messageBlock data]];

    //Place the main block into our packet
    [messagePacket addTLVBlock:mainBlock];

    //Set the Request Acknowledge flag
    [messagePacket addShort:0x0003];
    [messagePacket addShort:0x0000];

    //Request buddy icon
    if(requestIcon){
        NSLog(@"(%@) Requesting Icon via IM",name);
        [messagePacket addShort:0x0009];
        [messagePacket addShort:0x0000];
    }

    //Advertise our icon (sends out on first outgoing message)
    if(advertiseIcon){
        NSData		*imageData = [account userImageData];
        
        [messagePacket addShort:0x0008];
        [messagePacket addShort:0x000c];
        [messagePacket addLong:[imageData length]]; //length
        [messagePacket addShort:0x0001];
        [messagePacket addShort:[AIOscarMessage checksumData:imageData]]; //checksum
        [messagePacket addLong:[[NSDate date] timeIntervalSince1970]]; //date

        NSLog(@"(%@) Advertising our Icon",name);
    }


    //send
    [connection sendPacket:messagePacket];
}

//0x0006
- (void)sendIconToContact:(NSString *)name
{
    NSData		*iconData = [account userImageData];
    AIOscarPacket	*iconPacket = [connection snacPacketWithFamily:0x0004 type:0x0006 flags:0x000];
    NSData		*cookie;
    NSString		*capabilities;

    NSLog(@"(%@) Sending our icon via IM",name);
    
    //ICBM header
    cookie = [AIOscarMessage randomCookie];
    [AIOscarMessage addICBMHeaderToPacket:iconPacket withCookie:cookie channel:0x0002 name:name];

    //TLV 0x0005
    [iconPacket addShort:0x0005];
    [iconPacket addShort:2+8+16+6+4+4+[iconData length]+4+4+4+strlen(AIM_ICONIDENT)];
    
    //Cookie
    [iconPacket addShort:0x0000];
    [iconPacket addData:cookie];

    //Caps
    capabilities = [AIOscarInfo stringOfCaps:[NSArray arrayWithObject:[NSNumber numberWithInt:AIM_CAPS_BUDDYICON]]];
    [iconPacket addString:capabilities];

    //
    [iconPacket addShort:0x000a];
    [iconPacket addShort:0x0002];
    [iconPacket addShort:0x0001];

    //
    [iconPacket addShort:0x000f];
    [iconPacket addShort:0x0000];

    //
    [iconPacket addShort:0x2711];
    [iconPacket addShort:4+4+4+[iconData length]+strlen(AIM_ICONIDENT)];

    //
    [iconPacket addShort:0x0000];
    [iconPacket addShort:[AIOscarMessage checksumData:iconData]];
    [iconPacket addLong:[iconData length]];
    [iconPacket addLong:[[NSDate date] timeIntervalSince1970]];
    [iconPacket addData:iconData];
    [iconPacket addBytes:AIM_ICONIDENT length:strlen(AIM_ICONIDENT)];

    //
    [iconPacket addShort:0x0003];
    [iconPacket addShort:0x0000];

    //Send
    [connection sendPacket:iconPacket];
}

//0x0006
- (void)requestDirectConnectWith:(NSString *)name
{
    NSLog(@"requestDirectConnectWith (Not implemented)"); //Not implemented
/*    AIOscarPacket	*requestPacket;
    NSData		*cookie;
    NSString		*capabilities;

    //Create the packet
    requestPacket = [AIOscarPacket packetOnChannel:CHANNEL_DATA withSequence:[account localSequence]];
    [requestPacket addSnacWithFamily:0x0004 type:0x0006 flags:0x000 requestID:[account localRequest]];

    //Generate a TOC compatable cookie
    cookie = [AIOscarMessage randomAlphanumericCookie];

    //ICBM header
    [AIOscarMessage addICBMHeaderToPacket:requestPacket withCookie:cookie channel:0x0002 name:name];

    //This is all enclosed in an 0x0005 as well... blech
    //
    [requestPacket addType:0x0003 length:0 bytes:nil];

    //Cookie
    [requestPacket addShort:0x0000];
    [requestPacket addData:cookie];

    //Caps
    capabilities = [AIOscarInfo stringOfCaps:[NSArray arrayWithObject:[NSNumber numberWithInt:AIM_CAPS_IMIMAGE]]];
    [requestPacket addString:capabilities];

    //
    [requestPacket addType:0x000a shortValue:0x0001];
    //[requestPacket addType:0x0003 length:4 bytes:IP];
    [requestPacket addType:0x000a shortValue:port];
    [requestPacket addType:0x000f length:0 bytes:nil];*/
}

//0x0006
- (void)requestFileSendWith:(NSString *)name
{
    NSLog(@"requestFileSendWith (Not implemented)"); //Not implemented
}

//0x0006
- (void)acceptFileTransferWith:(NSString *)name
{
    NSLog(@"acceptFileTransferWith (Not implemented)"); //Not implemented
}

//0x0006
- (void)cancelFileTransfer:(NSString *)name
{
    NSLog(@"cancelFileTransfer (Not implemented)"); //Not implemented
}

//0x0006
- (void)requestStatusMessage:(NSString *)name
{
    NSLog(@"requestStatusMessage (Not implemented)"); //Not implemented
}

//Returns the string encoded and tagged
- (NSData *)_encodeMessage:(NSString *)string
{
    NSMutableData	*encodedMessageData;
    unsigned long 	encodingFlag;
    NSStringEncoding	encoding;

    if([string canBeConvertedToEncoding:NSASCIIStringEncoding]){ //ASCII
        encoding = NSASCIIStringEncoding;
        encodingFlag = 0x00000000;

    }else if([string canBeConvertedToEncoding:NSISOLatin1StringEncoding]){ //ISO-Latin
        encoding = NSISOLatin1StringEncoding;
        encodingFlag = 0x00030000;

    }else{ //Unicode
        encoding = NSUnicodeStringEncoding;
        encodingFlag = 0x00020000;

    }

    //Create the data (Identified, encoded message)
    encodedMessageData = [NSMutableData dataWithBytes:&encodingFlag length:4];
    [encodedMessageData appendData:[string dataUsingEncoding:encoding allowLossyConversion:YES]];

    return(encodedMessageData);
}

//0x00014
- (void)sendTyping:(BOOL)typing toContact:(NSString *)name
{
    AIOscarPacket	*typingPacket = [connection snacPacketWithFamily:0x0004 type:0x0014 flags:0x000];

    //8 bytes of 0's (empty cookie?)
    [typingPacket addLong:0x00000000];
    [typingPacket addLong:0x00000000];

    //Type 1 (1 for typing notification)
    [typingPacket addShort:0x0001];

    //Dest name
    [typingPacket addChar:[name length]];
    [typingPacket addString:name];

    //Typing (yes/no 0,1,2)
    [typingPacket addShort:(typing ? 0x0002 : 0x0000)];

    //Send
    [connection sendPacket:typingPacket];
}



//Handlers -------------------------------------------------------------------------------------
//Handle a request
- (void)handleRequest:(long)requestID type:(unsigned short)type flags:(unsigned short)flags packet:(AIOscarPacket *)inPacket
{
     switch(type){
        case 0x0001: NSLog(@"Error: %@",inPacket); break;
        case 0x0005: [self _handleMessageRights:inPacket]; break;
        case 0x0007: [self _handleMessageIn:inPacket]; break;
        case 0x000b: NSLog(@"Autoresp: %@",inPacket); break;
        case 0x000c: NSLog(@"Ack: %@",inPacket); break;
        case 0x0014: [self _handleTypingNotification:inPacket]; break;
        default: NSLog(@"(%@) Unknown type: %i",self,type); break;
    }
}

//0x0005
- (void)_handleMessageRights:(AIOscarPacket *)inPacket
{
    //Get message rights
    [inPacket getShortValue:&maxchan];
    [inPacket getLongValue:&flags];
    [inPacket getShortValue:&maxMessageLength];
    [inPacket getShortValue:&maxSenderWarn];
    [inPacket getShortValue:&maxReceiverWarn];
    [inPacket getLongValue:&minMessageInterval];

    //NSLog(@"           maxchan:%i",maxchan);
    //NSLog(@"             flags:%i",flags);
    //NSLog(@"  maxMessageLength:%i",maxMessageLength);
    //NSLog(@"     maxSenderWarn:%i",maxSenderWarn);
    //NSLog(@"   maxReceiverWarn:%i",maxReceiverWarn);
    //NSLog(@"minMessageInterval:%i",minMessageInterval);

    //Send back our rights (to accept them)
    [self sendMessageRights];
}

//0x0014
- (void)_handleTypingNotification:(AIOscarPacket *)inPacket
{
    NSString	*cookie;
    unsigned short type1, type2;
    unsigned char nameLength;
    NSString	*name;
    
    //Cookie
    [inPacket getString:&cookie length:8];

    //
    [inPacket getShortValue:&type1];
    [inPacket getCharValue:&nameLength];
    [inPacket getString:&name length:nameLength];
    [inPacket getShortValue:&type2];

    //
    [account noteContact:name typing:(type2 == 2)];    
}

//0x0007
- (void)_handleMessageIn:(AIOscarPacket *)inPacket
{
    NSString 		*cookie;
    unsigned short 	channel;
    NSString		*name;
    AIOscarTLVBlock	*infoBlock;

    //Read cookie
    [inPacket getString:&cookie length:8];

    //Get channel
    [inPacket getShortValue:&channel];
    //Get standard info
    infoBlock = [AIOscarInfo extractInfoFromPacket:inPacket name:&name warnLevel:nil];
    //Read the message
    if(channel == 1){ //Messages

        AIOscarTLVBlock		*messageBlock;
        NSString		*data;
        const char		*bytes;
        int			offset = 0;

        //Get the message block
        messageBlock = [inPacket getTLVBlock];

        //Get the message block form inside that
        data = [messageBlock stringForType:0x0002];
        bytes = [data cString];

        //Skip over 0x0501
        offset += 2;

        //Skip over features
        offset += (2 + get16(bytes + offset));

        NSMutableString	*messageString = nil;

        //Message chunks
        while(offset < [data length]){
            unsigned short length;
            unsigned short encodingFlag1, encodingFlag2;

            //Skip over 0x0101
            offset += 2;

            //msg length
            length = get16(bytes + offset);
            offset += 2;

            //encoding flags
            encodingFlag1 = get16(bytes + offset);
            offset += 2;
            encodingFlag2 = get16(bytes + offset);
            offset += 2;

            //Get string
            NSData *messageData = [NSData dataWithBytes:(bytes + offset) length:length-4];
            NSStringEncoding	encoding;

            if(encodingFlag1 == 0x0000){ //ASCII
                encoding = NSASCIIStringEncoding;
            }else if(encodingFlag1 == 0x0003){ //ISO-Latin
                encoding = NSISOLatin1StringEncoding;
            }else if(encodingFlag1 == 0x0002){ //Unicode
                encoding = NSUnicodeStringEncoding;
            }else{
                NSLog(@"Unknown string encoding %i / %i, using ISO-Latin",encodingFlag1,encodingFlag2);
                encoding = NSASCIIStringEncoding;
            }

            if(!messageString){
                messageString = [[[NSMutableString alloc] initWithData:messageData encoding:encoding] autorelease];
            }else{
                [messageString appendString:[[[NSString alloc] initWithData:messageData encoding:encoding] autorelease]];
            }

            offset += length;
        }

        NSLog(@"OscarMessage past while; the message is %@ and the name is %@",messageString,name);
        //
        [account receivedMessage:messageString fromContact:name];
        NSLog(@"this is after receivedMessage");
        //Typing
        if([messageBlock containsValueForType:0x000b]){
            [account noteContact:name typing:NO];
        }

        //Other info in the message
//        NSLog(@"Server Ack:%i",[messageBlock integerForType:0x0003]);
//        NSLog(@"Auto Response:%i",[messageBlock integerForType:0x0004]);
//        NSLog(@"Offline:%i",[messageBlock integerForType:0x0006]);
        if([messageBlock containsValueForType:0x0008]){
            NSLog(@"(%@) Has an icon for us",name);

            //Extract checksum and other info
/*            NSString	*string = [messageBlock stringForType:0x0008];
            unsigned char *bytes = [string cString];

            NSLog(@"Icon Length:%i",get32(bytes));
            NSLog(@"     0x0001:%i",get16(bytes+4));
            NSLog(@"   Icon sum:%i (%@)", get16(bytes+6),[AIOscarIcon convertDataToBase16:[NSData dataWithBytes:(bytes+6) length:2]]);
            NSLog(@" Icon stamp:%i (%@)", get16(bytes+8),[AIOscarIcon convertDataToBase16:[NSData dataWithBytes:(bytes+8) length:2]]);*/
            
            [account requestIconForContact:name];
        }
        if([messageBlock containsValueForType:0x0009]){
            NSLog(@"(%@) Wants our icon",name);
            //Buddy wants our icon
            //Send our icon over channel 2 w/ the next message
            //[account contactWantsOurIcon:name];
            [self sendIconToContact:name];
            //[self 
        }

    }else if(channel == 2){
        
        AIOscarTLVBlock		*messageBlock;
        NSString		*data;
        const char		*bytes;
        int			offset = 0;
        
        //Get the message block
        messageBlock = [inPacket getTLVBlock];

        //Get the message block form inside that
        data = [messageBlock stringForType:0x0005];
        bytes = [data cString];

        NSArray *classArray;
        
        //Connection status
        //NSLog(@"Status:%i",get16(bytes + offset));
        offset += 2;

        //Cookie
        //NSLog(@"Cookie:%@",[NSData dataWithBytes:(bytes + offset) length:8]);
        offset += 8;

        //Class block
        classArray = [AIOscarInfo getCapsFromString:[NSString stringWithCString:(bytes + offset) length:16]];
        //NSLog(@"classes:%@",classArray);
        offset += 16;

        //NSLog(@"--");

        //TLV
        AIOscarTLVBlock *internalBlock = [AIOscarTLVBlock TLVBlock];
        offset += [internalBlock processBytes:(bytes + offset) length:[[messageBlock data] length]-offset valueCount:0];
/*
        NSLog(@"IP:%@",[internalBlock stringForType:0x0002]);
        NSLog(@"IP(client):%@",[internalBlock stringForType:0x0003]);
        NSLog(@"VerifiedIP:%@",[internalBlock stringForType:0x0004]);
        NSLog(@"Port:%@",[internalBlock integerForType:0x0005]);
        NSLog(@"FTFlag:%i",[internalBlock integerForType:0x000a]);
        NSLog(@"Error:%i",[internalBlock integerForType:0x000b]);
        NSLog(@"Message:%@",[internalBlock stringForType:0x000c]);
        NSLog(@"CharSet:%@",[internalBlock stringForType:0x000d]);
        NSLog(@"Lang:%@",[internalBlock stringForType:0x000e]);
        NSLog(@"Direct?:%i",[internalBlock integerForType:0x000f]);
        NSLog(@"Proxy?:%i",[internalBlock integerForType:0x0010]);
*/
        NSString *dataBlock = [internalBlock stringForType:0x2711];
     //   NSLog(@"DataBlock:%@",dataBlock);
        
       // NSLog(@"--");

        if([classArray containsObject:[NSNumber numberWithInt:AIM_CAPS_BUDDYICON]]){
       //     NSLog(@"Buddy Icon!!! %@",dataBlock);
            const unsigned char *bytes = [dataBlock cString];

            unsigned long checksum, length, timestamp;
            NSImage	*image;
            NSData	*imageData;
            
            checksum = get32(bytes);
            length = get32(bytes+4);
            timestamp = get32(bytes+8);
            
        //    NSLog(@"checksum:%i (%@)",checksum,[AIOscarIcon convertDataToBase16:[NSData dataWithBytes:&bytes length:4]]);
       //     NSLog(@"length:%i (%@)",length,[AIOscarIcon convertDataToBase16:[NSData dataWithBytes:&bytes+4 length:4]]);
        //    NSLog(@"timestamp:%i",timestamp);

            imageData = [NSData dataWithBytes:(bytes+12) length:length];
        //    NSLog(@"imageData:%@",imageData);
                
            //Create an image from the icon data, and pass it to our account
            if(image = [[[NSImage alloc] initWithData:imageData] autorelease]){
                [account noteContact:name icon:image checksum:nil];
            }

        }else{
            NSLog(@"Cannot handle class: %i",classArray);
        }

/*
        if (args.reqclass & AIM_CAPS_BUDDYICON)
            incomingim_ch2_buddyicon(sess, mod, rx, snac, userinfo, &args, sdbsptr);
        else if (args.reqclass & AIM_CAPS_SENDBUDDYLIST)
            incomingim_ch2_buddylist(sess, mod, rx, snac, userinfo, &args, sdbsptr);
        else if (args.reqclass & AIM_CAPS_CHAT)
            incomingim_ch2_chat(sess, mod, rx, snac, userinfo, &args, sdbsptr);
        else if (args.reqclass & AIM_CAPS_ICQSERVERRELAY)
            incomingim_ch2_icqserverrelay(sess, mod, rx, snac, userinfo, &args, sdbsptr);
        else if (args.reqclass & AIM_CAPS_SENDFILE)
            incomingim_ch2_sendfile(sess, mod, rx, snac, userinfo, &args, sdbsptr);
        
        if (servdata) {
            args->info.icon.checksum = aimbs_get32(servdata);
            args->info.icon.length = aimbs_get32(servdata);
            args->info.icon.timestamp = aimbs_get32(servdata);
            args->info.icon.icon = aimbs_getraw(servdata, args->info.icon.length);
        }

        args->destructor = (void *)incomingim_ch2_buddyicon_free;
*/

    }else{
        NSLog(@"Not handling channel %i yet",channel);
    }

}






//Shared -------------------------------------------------------------------------------------
//
+ (NSData *)randomCookie
{
    unsigned char ck[8];
    int i;

    //Generate a cookie
    for (i = 0; i < 8; i++)
        ck[i] = (unsigned char)rand();

    return([NSData dataWithBytes:ck length:8]);
}

//
+ (NSData *)randomAlphanumericCookie
{
    unsigned char ck[8];
    int i;

    //Generate a cookie
    for (i = 0; i < 7; i++)
        ck[i] = 0x30 + ((unsigned char) rand() % 10);
    ck[7] = '\0';

    return([NSData dataWithBytes:ck length:8]);
}

//Adds header
+ (void)addICBMHeaderToPacket:(AIOscarPacket *)packet withCookie:(NSData *)cookie channel:(unsigned short)channel name:(NSString *)name
{
    //Add the header
    [packet addData:cookie];
    [packet addShort:channel];
    [packet addChar:[name length]];
    [packet addString:name];
}

//calculate icon checksum
+ (unsigned short)checksumData:(NSData *)data
{
    const unsigned char *bytes = [data bytes];
    int			length = [data length];
    unsigned long 	sum = 0;
    int 		i;

    for (i=0; i+1<length; i+=2)
        sum += (bytes[i+1] << 8) + bytes[i];
    if (i < length)
        sum += bytes[i];
    
    sum = ((sum & 0xffff0000) >> 16) + (sum & 0x0000ffff);

    return sum;
}

@end

