/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import <Cocoa/Cocoa.h>

#define HEADER_LENGTH 6

@class AISocket;

typedef enum{ FRAMETYPE_SIGNON = 1, FRAMETYPE_DATA, FRAMETYPE_ERROR, FRAMETYPE_SIGNOFF, FRAMETYPE_KEEPALIVE } FRAMETYPE;

@interface AIMTOC2Packet : NSObject {
    int 		frameType;
    int 		sequence;
    NSData		*data;
}

+ (id)packetFromSocket:(AISocket *)inSocket sequence:(unsigned short *)desiredSequence;
+ (id)signOnPacketForScreenName:(NSString *)inName sequence:(unsigned short *)inSequence;
+ (id)packetOfType:(FRAMETYPE)inFrameType sequence:(unsigned short *)inSequence data:(NSData *)inData;
- (char)dataByte:(int)index;
- (void)sendToSocket:(AISocket *)inSocket;
- (unsigned char)frameType;
- (unsigned short)sequence;
- (unsigned short)length;
+ (id)dataPacketWithString:(NSString *)inString sequence:(unsigned short *)inSequence;
- (NSString *)string;
           
@end
