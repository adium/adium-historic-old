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

#import <Foundation/Foundation.h>

#define put8(buf, data) ((*(buf) = (char)(data)&0xff),1)
#define put16(buf, data) ( \
                           (*(buf) = (char)((data)>>8)&0xff), \
                           (*((buf)+1) = (char)(data)&0xff),  \
                           2)
#define put32(buf, data) ( \
                           (*((buf)) = (char)((data)>>24)&0xff), \
                           (*((buf)+1) = (char)((data)>>16)&0xff), \
                           (*((buf)+2) = (char)((data)>>8)&0xff), \
                           (*((buf)+3) = (char)(data)&0xff), \
                           4)

#define get8(buf) ((*(buf))&0xff)
#define get16(buf) ((((*(buf))<<8)&0xff00) + \
                    ((*((buf)+1)) & 0x00ff))
#define get32(buf) ((((*(buf))<<24)&0xff000000) + \
                    (((*((buf)+1))<<16)&0x00ff0000) + \
                    (((*((buf)+2))<< 8)&0x0000ff00) + \
                    (((*((buf)+3))&0x000000ff)))

typedef enum{ CHANNEL_SIGNON = 1, CHANNEL_DATA, CHANNEL_ERROR, CHANNEL_SIGNOFF } OSCARCHANNEL;

@class AISocket, AIOscarTLVBlock;

@interface AIOscarPacket : NSObject {
    //Outgoing
    NSData		*headerData;
    NSMutableData	*contentData;

    //Incoming
    char 		*contentBytes;
    int			contentStart;
    int			contentLength;
        
}

//Outgoing
+ (id)packetOnChannel:(OSCARCHANNEL)inChannel withSequence:(unsigned short *)inSequence;
- (id)initOnChannel:(OSCARCHANNEL)inChannel withSequence:(unsigned short *)inSequence;
- (void)addSnacWithFamily:(unsigned short)inFamily type:(unsigned short)inType flags:(unsigned short)inFlags requestID:(unsigned long *)inRequestID;
/*- (void)addType:(unsigned short)inType length:(unsigned)inLength bytes:(const void *)inBytes;
- (void)addType:(unsigned short)inType charValue:(char)inValue;
- (void)addType:(unsigned short)inType shortValue:(unsigned short)inValue;
- (void)addType:(unsigned short)inType longValue:(long)inValue;*/
- (void)addLong:(long)inLong;
- (void)addShort:(unsigned short)inShort;
- (void)sendToSocket:(AISocket *)inSocket;
- (void)addChar:(unsigned char)inChar;
- (void)addString:(NSString *)inString;
- (void)addBytes:(const void *)bytes length:(unsigned)length;
//- (void)addType:(unsigned short)inType string:(NSString *)inString;
- (void)addData:(NSData *)data;
//- (void)addType:(unsigned short)inType data:(NSData *)inData;
- (void)addTLVBlock:(AIOscarTLVBlock *)inBlock;

//Incoming
+ (id)packetFromSocket:(AISocket *)inSocket;
- (id)initFromSocket:(AISocket *)inSocket;
- (BOOL)getSnacFamily:(unsigned short *)family type:(unsigned short *)type flags:(unsigned short *)flags requestID:(long *)requestID;
- (BOOL)getShortValue:(unsigned short *)value;
//- (NSMutableDictionary *)getTLVDictionary;
//- (NSMutableDictionary *)getTLVDictionaryOfLength:(int)scanLength;
- (BOOL)getString:(NSString **)string length:(int)length;
- (BOOL)getLongValue:(unsigned long *)value;
- (BOOL)getCharValue:(unsigned char *)value;
//- (BOOL)getString:(NSString **)string;
- (AIOscarTLVBlock *)getTLVBlock;
- (AIOscarTLVBlock *)getTLVBlockWithLength:(int)scanLength valueCount:(int)count;
- (BOOL)getData:(NSData **)data length:(int)length;

@end
