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

BOOL AIGetSurrogates(UTF32Char in, UTF16Char *outHigh, UTF16Char *outLow);

void AIWipeMemory(void *buf, size_t len);
/*AIReallocWired is for use with wired memory. it returns a block that is
 *	already wired in memory.
 *before freeing the old block, it wipes (see AIWipeMemory) and unlocks it.
 *if the new block could not be allocated or wired,
 *	the old block is still valid, wired, and unchanged.
 *all other aspects of its behaviour are the same as realloc(3)
 *	(for example, realloc(NULL, x) == malloc(x)).
 */
void *AIReallocWired(void *oldBuf, size_t newLen);

//sets every byte in buf within range to ch.
void AISetRangeInMemory(void *buf, NSRange range, int ch);
