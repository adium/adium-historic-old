/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AIDataAdditions.h"

@implementation NSData(AIDataAdditions)

- (NSData *)subdataFromIndex:(unsigned)start {
	return [self subdataWithRange:NSMakeRange(start, [self length] - start)];
}
- (NSData *)subdataToIndex:(unsigned)stop {
	return [self subdataWithRange:NSMakeRange(0, stop)];
}

static char encodingTable[64] = {
	'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
	'Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f',
	'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
'w','x','y','z','0','1','2','3','4','5','6','7','8','9','+','/' };

- (NSString *)base64EncodingWithLineLength:(unsigned int) lineLength {
	const unsigned char	*bytes = [self bytes];
	NSMutableString		*result = [NSMutableString stringWithCapacity:[self length]];
	unsigned long		ixtext = 0;
	unsigned long		lentext = [self length];
	long				ctremaining = 0;
	unsigned char		inbuf[3], outbuf[4];
	unsigned short		i = 0;
	unsigned short		charsonline = 0, ctcopy = 0;
	unsigned long		ix = 0;
	
	while (YES) {
		ctremaining = lentext - ixtext;
		if (ctremaining <= 0) break;
		
		for (i = 0; i < 3; i++) {
			ix = ixtext + i;
			if (ix < lentext)
				inbuf[i] = bytes[ix];
			else
				inbuf [i] = 0;
		}
		
		outbuf [0] = (inbuf [0] & 0xFC) >> 2;
		outbuf [1] = ((inbuf [0] & 0x03) << 4) | ((inbuf [1] & 0xF0) >> 4);
		outbuf [2] = ((inbuf [1] & 0x0F) << 2) | ((inbuf [2] & 0xC0) >> 6);
		outbuf [3] = inbuf [2] & 0x3F;
		ctcopy = 4;
		
		switch (ctremaining) {
			case 1:
				ctcopy = 2;
				break;
			case 2:
				ctcopy = 3;
				break;
		}
		
		for (i = 0; i < ctcopy; i++)
			[result appendFormat:@"%c", encodingTable[outbuf[i]]];
		
		for (i = ctcopy; i < 4; i++)
			[result appendString:@"="];
		
		ixtext += 3;
		charsonline += 4;
		
		if (lineLength > 0) {
			if (charsonline >= lineLength) {
				charsonline = 0;
				[result appendString:@"\n"];
			}
		}
	}
	
	return result;
}

- (NSString *)base64Encoding {
	return [self base64EncodingWithLineLength:0];
}

@end
