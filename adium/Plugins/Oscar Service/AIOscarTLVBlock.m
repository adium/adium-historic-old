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

#import "AIOscarTLVBlock.h"
#import "AIOscarPacket.h"

void _addTLV(NSMutableData *contentData, unsigned short type, unsigned length, const void *bytes);

@implementation AIOscarTLVBlock

+ (id)TLVBlock
{
    return([[[self alloc] init] autorelease]);
}

//
- (id)init
{
    [super init];

    dataBlock = [[NSMutableData alloc] init];
    tlvCount = 0;

    return(self);
}

//
- (void)dealloc
{
    [dataBlock release];
    
    [super dealloc];
}

//
- (NSData *)data
{
    return(dataBlock);
}


//Incoming ------------------------------------------------------------------------------
//
- (int)processBytes:(const char *)bytes length:(int)totalLength valueCount:(int)count
{
    int	usedLength = 0;

    //Determine the length of this tlv data
    while(usedLength < totalLength && (!count || tlvCount < count)){
        unsigned short 	type;
        unsigned short 	length;

        //Get type and length
        type = get16(bytes + usedLength);
        length = get16(bytes + usedLength + 2);

        //Make sure we aren't about to scan out of the buffer
        if((usedLength + 4 + length) > totalLength) break; //Exit if we prematurely hit the end of our data

        //Scan past the value
        usedLength += (4 + length);
            
        tlvCount++;
    }

    //append the bytes
    [dataBlock appendBytes:bytes length:usedLength];

    return(usedLength);
}

- (BOOL)containsValueForType:(unsigned long)desiredType
{
    const char 	*bytes = [dataBlock bytes];
    int		loop;

    //Scan the bytes for this type
    for(loop = 0; loop < tlvCount; loop++){
        unsigned short 	type;
        unsigned short 	length;

        //Get type and length
        type = get16(bytes);
        length = get16(bytes + 2);

        //Check for a match
        if(type == desiredType){
            return(YES);
        }

        //Move to the next value
        bytes += (4 + length);
    }

    return(NO);
}


- (int)integerForType:(unsigned long)desiredType
{
    const char 	*bytes = [dataBlock bytes];
    int		loop;
    
    //Scan the bytes for this type
    for(loop = 0; loop < tlvCount; loop++){
        unsigned short 	type;
        unsigned short 	length;

        //Get type and length
        type = get16(bytes);
        length = get16(bytes + 2);

        //Check for a match
        if(type == desiredType){
            if(length == 1){
                return(get8(bytes+4)); 
            }else if(length == 2){
                return(get16(bytes+4)); 
            }else if(length == 4){
                return(get32(bytes+4));
            }
        }

        //Move to the next value
        bytes += (4 + length);
    }

    return(0);
}

- (NSString *)stringForType:(unsigned long)desiredType
{
    const char 	*bytes = [dataBlock bytes];
    int		loop;

    //Scan the bytes for this type
    for(loop = 0; loop < tlvCount; loop++){
        unsigned short 	type;
        unsigned short 	length;

        //Get type and length
        type = get16(bytes);
        length = get16(bytes + 2);

        //Check for a match
        if(type == desiredType){
            return([NSString stringWithCString:(bytes + 4) length:length]);
        }

        //Move to the next value
        bytes += (4 + length);
    }

    return(nil);
}




//Outgoing ------------------------------------------------------------------------------
- (void)addType:(unsigned short)inType string:(NSString *)inString
{
    _addTLV(dataBlock, inType, [inString length], [inString cString]);
}
- (void)addType:(unsigned short)inType data:(NSData *)inData
{
    _addTLV(dataBlock, inType, [inData length], [inData bytes]);
}
- (void)addType:(unsigned short)inType bytes:(const void *)inBytes length:(unsigned)inLength
{
    _addTLV(dataBlock, inType, inLength, inBytes);
}
- (void)addType:(unsigned short)inType charValue:(char)inValue
{
    _addTLV(dataBlock, inType, 1, &inValue);
}
- (void)addType:(unsigned short)inType shortValue:(unsigned short)inValue
{
    _addTLV(dataBlock, inType, 2, &inValue);
}
- (void)addType:(unsigned short)inType longValue:(long)inValue
{
    _addTLV(dataBlock, inType, 4, &inValue);
}

//Add TLV bytes
void _addTLV(NSMutableData *contentData, unsigned short type, unsigned length, const void *bytes)
{
    char	header[4];

    //Prepare the TL header
    put16(header, type);
    put16(header+2, length);

    //Add header and value to our data block
    [contentData appendBytes:header length:4];
    [contentData appendBytes:bytes length:length];
}


@end
