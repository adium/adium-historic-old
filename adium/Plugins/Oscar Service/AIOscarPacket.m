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

#import "AIOscarPacket.h"
#import <AIUtilities/AIUtilities.h>
#import "AIOscarTLVBlock.h"

@interface AIOscarPacket (PRIVATE)
void _addTLV(NSMutableData *contentData, unsigned short type, unsigned length, const void *bytes);
@end

@implementation AIOscarPacket

//Outgoing Packets ------------------------------------------------
+ (id)packetOnChannel:(OSCARCHANNEL)inChannel withSequence:(unsigned short *)inSequence
{
    return([[[self alloc] initOnChannel:inChannel withSequence:inSequence] autorelease]);
}

//
- (id)initOnChannel:(OSCARCHANNEL)inChannel withSequence:(unsigned short *)inSequence
{
    char	header[10];

    //Init
    [super init];

    //Create the header
    put8(header, 0x2a);			//0x2a
    put8(header+1, inChannel);		//Channel
    put16(header+2, *inSequence);	//Sequence
    headerData = [[NSData dataWithBytes:header length:4] retain];

    //Create the content data
    contentData = [[NSMutableData alloc] init];

    //Increase the sequence
    (*inSequence)++;
    
    return(self);
}

//Add a Snac
- (void)addSnacWithFamily:(unsigned short)inFamily type:(unsigned short)inType flags:(unsigned short)inFlags requestID:(unsigned long *)inRequestID
{
    char	snac[10];

    //Organize the snac information
    put16(snac, inFamily);	//Family
    put16(snac+2, inType);	//Type
    put16(snac+4, inFlags);	//Flags
    put32(snac+6, *inRequestID);//Request ID
    
    //Append it to our content data
    [contentData appendBytes:snac length:10];

    //Increase the request ID
    (*inRequestID)++;
}

//Add a TLV block
- (void)addTLVBlock:(AIOscarTLVBlock *)inBlock
{
    [contentData appendData:[inBlock data]];
}

//Adding raw data
- (void)addChar:(unsigned char)inChar
{
    [contentData appendBytes:&inChar length:1];
}
- (void)addLong:(long)inLong
{
    [contentData appendBytes:&inLong length:4];
}
- (void)addShort:(unsigned short)inShort
{
    [contentData appendBytes:&inShort length:2];
}
- (void)addString:(NSString *)inString
{
    [contentData appendBytes:[inString cString] length:[inString length]];
}
- (void)addBytes:(const void *)bytes length:(unsigned)length
{
    [contentData appendBytes:bytes length:length];
}
- (void)addData:(NSData *)data
{
    [contentData appendData:data];
}

//Send the packet
- (void)sendToSocket:(AISocket *)inSocket
{
    unsigned short	length = [contentData length];
    NSData		*lengthData = [NSData dataWithBytes:&length length:2];

    //NSLog(@"(%@) %@ | %@ | %@",inSocket,headerData,lengthData,contentData);

    //
    while(![inSocket sendData:headerData]){};
    while(![inSocket sendData:lengthData]){};
    while(![inSocket sendData:contentData]){};
}


//Incoming Packets ------------------------------------------------
+ (id)packetFromSocket:(AISocket *)inSocket
{
    return([[[self alloc] initFromSocket:inSocket] autorelease]);
}

- (id)initFromSocket:(AISocket *)inSocket
{
    NSData		*headData;
    NSData		*packetData;

    [super init];

    //Get the header
    if([inSocket getData:&headData ofLength:6 remove:NO]){
        const char	*header = [headData bytes];
        char		control;
        char		channel;
        unsigned short	sequence;
        unsigned short	length;

        //Get the header data
        control = get8(header);		//0x2a
        channel = get8(header+1);	//Channel
        sequence = get16(header+2);	//Sequence
        length = get16(header+4);	//Length

        if(control != 0x2a) NSLog(@"  Packet didn't start with 0x2a (*)");

        if([inSocket getData:&packetData ofLength:(6 + length) remove:NO]){
            //NSLog(@"%@",packetData);
            
            //Get the packet contents
            contentBytes = malloc(length);
            [packetData getBytes:contentBytes range:NSMakeRange(6, length)];
            contentStart = 0;
            contentLength = length;

            //Remove the data from the socket
            [inSocket removeDataBytes:6 + length];

            return(self);
        }
    }

    [self autorelease];
    return(nil);
}

- (NSString *)description
{
    
    return([NSString stringWithFormat:@"%@%@", [super description], [NSData dataWithBytes:(contentBytes + contentStart) length:contentLength]]);
}

//Get a snac header from the packet
- (BOOL)getSnacFamily:(unsigned short *)family type:(unsigned short *)type flags:(unsigned short *)flags requestID:(long *)requestID
{
    const char *bytes = contentBytes + contentStart;
    
    if(contentLength >= 10){
        //Get the snac
        *family = get16(bytes);
        *type = get16(bytes+2);
        *flags = get16(bytes+4);
        *requestID = get32(bytes+6);

        //Scan past this data
        contentStart += 10;
        contentLength -= 10;

        return(YES);
    }else{
        return(NO);
    }
}

//Get raw data from the packet
- (BOOL)getCharValue:(unsigned char *)value
{
    if(contentLength >= 1){
        *value = get8(contentBytes + contentStart);
        contentStart += 1;
        contentLength -= 1;

        return(YES);
    }

    return(NO);
}
- (BOOL)getShortValue:(unsigned short *)value
{
    if(contentLength >= 2){
        *value = get16(contentBytes + contentStart);
        contentStart += 2;
        contentLength -= 2;

        return(YES);
    }

    return(NO);
}
- (BOOL)getLongValue:(unsigned long *)value
{
    if(contentLength >= 4){
        *value = get32(contentBytes + contentStart);
        contentStart += 4;
        contentLength -= 4;

        return(YES);
    }

    return(NO);
}

//get null terminated string
/*- (BOOL)getString:(NSString **)string
{
    const char *dataStart = contentBytes + contentStart;
    int	stringLength = 0;

    //Find the null terminator
    while(stringLength < contentLength){
        if(*(dataStart + stringLength) == '\0') break;
        stringLength++;
    }

    return([self getString:string length:stringLength]);
}*/

//
- (BOOL)getString:(NSString **)string length:(int)length
{
    if(contentLength >= length){
        *string = [NSString stringWithCString:(contentBytes + contentStart) length:length];
        contentStart += length;
        contentLength -= length;

        return(YES);
    }else{
        NSLog(@"wanted %i, only have %i",length,contentLength);
    }

    return(NO);
}

//
- (BOOL)getData:(NSData **)data length:(int)length
{
    if(contentLength >= length){
        *data = [NSData dataWithBytes:(contentBytes + contentStart) length:length];
        contentStart += length;
        contentLength -= length;

        return(YES);
    }else{
        NSLog(@"wanted %i, only have %i",length,contentLength);
    }

    return(NO);
}


//Get bytes
/*BOOL _getBytes(const char *contentBytes, int *contentStart, int *contentLength, const void *bytes, int length)
{
    if(*contentLength >= length){
        //Return a reference to the bytes
        bytes = *(*contentBytes + *contentStart);

        //Scan past this data
        (*contentStart) += length;
        (*contentLength) -= length;

        return(YES);
    }

    return(NO);
}*/

- (AIOscarTLVBlock *)getTLVBlock
{
    return([self getTLVBlockWithLength:0 valueCount:0]);
}

    //Pass 0 length for any size
//Pass 0 count for any number of pairs
- (AIOscarTLVBlock *)getTLVBlockWithLength:(int)scanLength valueCount:(int)count
{
    AIOscarTLVBlock 	*block = nil;
    int			length;

    if(!scanLength || scanLength <= contentLength){
        //Extract the TLV data
        block = [[AIOscarTLVBlock alloc] init];
        length = [block processBytes:(contentBytes + contentStart)
                              length:(scanLength ? scanLength : contentLength)
                          valueCount:count];
        
        //Scan past this data
        contentStart += (scanLength ? scanLength : length);
        contentLength -= (scanLength ? scanLength : length);
    }

    return(block);
}




//TLV all the remaining bytes in this packet
/*- (NSMutableDictionary *)getTLVDictionary
{
    return([self getTLVDictionaryOfLength:contentLength]);
}

//TLV the specified amount of bytes
- (NSMutableDictionary *)getTLVDictionaryOfLength:(int)scanLength
{
    NSMutableDictionary	*dict = [NSMutableDictionary dictionary];

    if(scanLength <= contentLength){
        while(scanLength){
            NSNumber	*key; 
            const char 	*bytes = contentBytes + contentStart;
            unsigned short 	type;
            unsigned short 	length;
    
            //Get type and length
            type = get16(bytes);
            length = get16(bytes+2);
    
            if(length <= scanLength){
                //Add the value to our dictionary
                key = [NSNumber numberWithUnsignedShort:type];
                if(length == 1){ //Char
                    [dict setObject:[NSNumber numberWithUnsignedChar:get8(bytes+4)] forKey:key];                    
    
                }else if(length == 2){ //Short
                    [dict setObject:[NSNumber numberWithUnsignedShort:get16(bytes+4)] forKey:key];                    
    
                }else if(length == 4){ //Long
                    [dict setObject:[NSNumber numberWithUnsignedLong:get32(bytes+4)] forKey:key];                    
    
                }else{
                    [dict setObject:[NSString stringWithCString:(bytes+4) length:length] forKey:key];
                    
                }
    
                //Scan past this data
                contentBytes += (4 + length);
                contentLength -= (4 + length);
                scanLength -= (4 + length);
                
            }else{
                NSLog(@"Invalid TLVs");
                return(nil);
            }
        }
    }

    return(dict);
}*/

/*
- (BOOL)getType:(unsigned short *)type length:(unsigned short *)length bytes:(const void **)outBytes 
{
    NSData	*oldData;
    const char 	*bytes = [contentData bytes];

    if([contentData length] >= 4){
        //Get type and length
        *type = get16(bytes);
        *length = get16(bytes+2);


        //Get the bytes
        [contentData getBytes:outBytes range:NSMakeRange(4, *length)];

        //Remove it from the content data
        oldData = contentData;
        contentData = [[NSMutableData alloc] initWithBytes:&bytes[((*length) + 4)] length:([contentData length] - ((*length) + 4))];
        [oldData release];
        
        return(YES);
    }else{
        return(NO);
    }
}*/
/*
- (BOOL)getType:(unsigned short)inType charValue:(unsigned char *)value
{
    const char 	*bytes = [contentData bytes];
    int		length;

    if([contentData length] >= 4){
        //Get the type & length
        *type = get16(bytes);
        *length = get16(bytes+2);

        //Get the value
        if(type == inType && length == 1){
            *value = get8(bytes+4);
            return(YES);
        }
    }
    
    return(NO);
}*/


@end






