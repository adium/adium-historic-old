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


@interface AIOscarTLVBlock : NSObject {
    NSMutableData	*dataBlock;
    int			tlvCount;
    
}

+ (id)TLVBlock;
- (id)init;
- (int)processBytes:(const char *)bytes length:(int)totalLength valueCount:(int)count;
- (int)integerForType:(unsigned long)desiredType;
- (NSString *)stringForType:(unsigned long)desiredType;
- (NSData *)data;
- (void)addType:(unsigned short)inType string:(NSString *)inString;
- (void)addType:(unsigned short)inType data:(NSData *)inData;
- (void)addType:(unsigned short)inType bytes:(const void *)inBytes length:(unsigned)inLength;
- (void)addType:(unsigned short)inType charValue:(char)inValue;
- (void)addType:(unsigned short)inType shortValue:(unsigned short)inValue;
- (void)addType:(unsigned short)inType longValue:(long)inValue;
- (BOOL)containsValueForType:(unsigned long)desiredType;

@end
