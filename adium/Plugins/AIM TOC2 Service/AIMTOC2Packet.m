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

//Includes
#import "AIMTOC2Packet.h"
//Framework Includes

//Private methods
@interface AIMTOC2Packet (PRIVATE)
- (id)initFromSocket:(AISocket *)inSocket sequence:(unsigned short *)desiredSequence;
- (id)initWithType:(FRAMETYPE)inFrameType sequence:(unsigned short *)inSequence data:(NSData *)inData;
@end

@implementation AIMTOC2Packet

//-------------------
//  Public Methods
//-----------------------
+ (id)packetFromSocket:(AISocket *)inSocket sequence:(unsigned short *)desiredSequence
{
    return([[[self alloc] initFromSocket:inSocket sequence:desiredSequence] autorelease]);
}

+ (id)signOnPacketForScreenName:(NSString *)inName sequence:(unsigned short *)inSequence
{
    NSData		*nameData;
    unsigned short	nameLength;
    char		signOnBytes[8];
    NSMutableData	*signOnData;

    NSParameterAssert(inName != nil && [inName length] != 0);

    //create the header
    nameData = [inName dataUsingEncoding:NSUTF8StringEncoding];
    nameLength = [nameData length];

    //set up the sign on bytes
    signOnBytes[0] = 0;
    signOnBytes[1] = 0;
    signOnBytes[2] = 0;
    signOnBytes[3] = 1;
    signOnBytes[4] = 0;
    signOnBytes[5] = 1;
    signOnBytes[6] = nameLength/256;
    signOnBytes[7] = nameLength%256;

    //combine them
    signOnData = [NSMutableData dataWithBytes:signOnBytes length:8];
    [signOnData appendData:nameData];

    //create the sign on packet
    return([self packetOfType:FRAMETYPE_SIGNON sequence:inSequence data:signOnData]);
}

+ (id)packetOfType:(FRAMETYPE)inFrameType sequence:(unsigned short *)inSequence data:(NSData *)inData
{
    return([[[AIMTOC2Packet alloc] initWithType:inFrameType sequence:inSequence data:inData] autorelease]);
}

- (char)dataByte:(int)index
{
    const char *bytes = [data bytes];
    
    if(index >= 0 && index < [data length]){
        return(bytes[index]);
    }else{
        return(-1);
    }
}

- (BOOL)sendToSocket:(AISocket *)inSocket
{
    char		headerBytes[HEADER_LENGTH];
    unsigned short	dataLength = [data length];
    NSMutableData	*packetData;

    //Create the header
    headerBytes[0] = '*';
    headerBytes[1] = frameType;
    headerBytes[2] = sequence/256;
    headerBytes[3] = sequence%256;
    headerBytes[4] = dataLength/256;
    headerBytes[5] = dataLength%256;

    packetData = [NSMutableData dataWithBytes:headerBytes length:HEADER_LENGTH];
    [packetData appendData:data];

    return([inSocket sendData:packetData]);
}

- (FRAMETYPE)frameType{
    return(frameType);
}

- (unsigned short)sequence{
    return(sequence);
}

- (unsigned short)length{
    return([data length]);
}

+ (id)dataPacketWithString:(NSString *)inString sequence:(unsigned short *)inSequence
{
    NSMutableData 	*stringData;
    char 		terminator[1] = {'\0'};
    NSParameterAssert(inString != nil && [inString length] != 0);

    stringData = [[inString dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES] mutableCopy];
    [stringData autorelease];
    [stringData appendBytes:terminator length:1];

    return([self packetOfType:FRAMETYPE_DATA sequence:inSequence data:stringData]);
}

- (NSString *)string
{
    return([NSString stringWithCString:[data bytes] length:[data length]]);
}


//-------------------
//  Hidden Methods
//-----------------------

//-------------------
//  Private Methods
//-----------------------
- (id)initFromSocket:(AISocket *)inSocket sequence:(unsigned short *)desiredSequence
{
    NSData		*headerData;
    NSData		*packetData;
    const char  *bytes;
    int			length;

    [super init];

    //Get the header
    if([inSocket getData:&headerData ofLength:HEADER_LENGTH remove:NO]){

        //Increase the sequence
        
        //Get the header data
        bytes = [headerData bytes];
        frameType = bytes[1];
        sequence = ntohs(* ((unsigned short *)(&bytes[2])));
        length = ntohs(* ((unsigned short *)(&bytes[4])));

        if(desiredSequence != nil && sequence != *desiredSequence){
            NSLog(@"packet out of order (Non fatal) (%i != %i), Adjusting",(int)sequence,(int)*desiredSequence);
            *desiredSequence = sequence+1;
        }

        //Get the packet contents
        if([inSocket getData:&packetData ofLength:(HEADER_LENGTH + length) remove:NO]){
            bytes = [packetData bytes];

            //Remove the data from the socket
            [inSocket removeDataBytes:HEADER_LENGTH + length];

            //Only keep the data portion of the packet
            data = [[NSData dataWithBytes:&bytes[HEADER_LENGTH] length:length] retain];         

            if(desiredSequence != nil){
                (*desiredSequence)++;
            }

            return(self);    
        }
    }

    [self autorelease];
    return(nil);    
}

- (id)initWithType:(FRAMETYPE)inFrameType sequence:(unsigned short *)inSequence data:(NSData *)inData
{
    [super init];

    //init the header
    frameType = inFrameType;
    sequence = *inSequence;
    data = [inData retain];

    (*inSequence)++;

    return(self);
}

- (void)dealloc
{
    [data release];

    [super dealloc];
}


@end




