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

#import "AIFunctions.h"
#include <sys/types.h>
#include <sys/mman.h>
#include <malloc/malloc.h>
#include <stdlib.h>
#include <c.h>

BOOL AIGetSurrogates(UTF32Char in, UTF16Char *outHigh, UTF16Char *outLow)
{
	if(in < 0x10000) {
		if(outHigh) *outHigh = 0;
		if(outLow)  *outLow  = in;
		return NO;
	} else {
		enum {
			UTF32LowShiftToUTF16High = 10,
			UTF32HighShiftToUTF16High,
			UTF16HighMask = 31,  //0b0000 0111 1100 0000
			UTF16LowMask  = 63,  //0b0000 0000 0011 1111
			UTF32LowMask = 1023, //0b0000 0011 1111 1111
			UTF16HighAdditiveMask = 55296, //0b1101 1000 0000 0000
			UTF16LowAdditiveMask  = 56320, //0b1101 1100 0000 0000
		};

		if(outHigh) {
			*outHigh = \
				  ((in >> UTF32HighShiftToUTF16High) & UTF16HighMask) \
				| ((in >> UTF32LowShiftToUTF16High) & UTF16LowMask) \
				| UTF16HighAdditiveMask;
		}

		if(outLow) {
			*outLow = (in & UTF32LowMask) | UTF16LowAdditiveMask;
		}

		return YES;
	}
}

//this uses the algorithm employed by Darwin 7.x's rm(1).
void AIWipeMemory(void *buf, size_t len)
{
	if(buf) {
		char *buf_char = buf;
		for(unsigned long i = 0; i < len; ++i) {
			buf_char[i] = 0xff;
			buf_char[i] = 0x00;
			buf_char[i] = 0xff;
		}
	}
}

void *AIReallocWired(void *oldBuf, size_t newLen)
{
	void *newBuf = malloc(newLen);
	if(!newBuf) {
		NSLog(@"in AIReallocWired: could not allocate %lu bytes", (unsigned long)newLen);
	} else {
		int mlock_retval = mlock(newBuf, newLen);
		if(mlock_retval < 0) {
			NSLog(@"in AIReallocWired: could not wire %lu bytes", (unsigned long)newLen);
			free(newBuf);
			newBuf = NULL;
		} else if(oldBuf) {
			size_t  oldLen = malloc_size(oldBuf);
			size_t copyLen = MIN(newLen, oldLen);

			memcpy(newBuf, oldBuf, copyLen);

			AIWipeMemory(oldBuf, oldLen);
			munlock(oldBuf, oldLen);
			free(oldBuf);
		}
	}
	return newBuf;
}

void AISetRangeInMemory(void *buf, NSRange range, int ch)
{
	unsigned i     = range.location;
	unsigned i_max = range.location + range.length;
	char *buf_ch = buf;
	while(i < i_max) {
		buf_ch[i++] = ch;
	}
}
