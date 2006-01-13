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


#pragma mark Rect utilities

typedef enum AIRectEdgeMask {
	AINoEdges = 0,
	AIMaxXEdgeMask = (1 << NSMaxXEdge),
	AIMaxYEdgeMask = (1 << NSMaxYEdge),
	AIMinXEdgeMask = (1 << NSMinXEdge),
	AIMinYEdgeMask = (1 << NSMinYEdge),
} AIRectEdgeMask;

enum {
	AINotARectEdge = -1
};

// e.g., AICoordinateForRect_edge_(rect, NSMaxXEdge) is the same as NSMaxX(rect)
float AICoordinateForRect_edge_(NSRect rect, NSRectEdge edge);

// returns the distance that a point lies outside of a rect on a particular side.  If the point lies 
// on the interior side of that edge, the number returned will be negative
float AISignedExteriorDistanceRect_edge_toPoint_(NSRect rect, NSRectEdge edge, NSPoint point);

// e.g., AIOppositeRectEdge_(NSMaxXEdge) is the same as NSMinXEdge
NSRectEdge AIOppositeRectEdge_(NSRectEdge edge);

// translate mobileRect so that it aligns with stationaryRect
// undefined if aligning left to top or something else that does not make sense
NSRect AIRectByAligningRect_edge_toRect_edge_(NSRect mobileRect, 
											  NSRectEdge mobileRectEdge, 
											  NSRect stationaryRect, 
											  NSRectEdge stationaryRectEdge);


BOOL AIRectIsAligned_edge_toRect_edge_tolerance_(NSRect rect1, 
												 NSRectEdge edge1, 
												 NSRect rect2, 
												 NSRectEdge edge2, 
												 float tolerance);

// minimally translate mobileRect so that it lies within stationaryRect
NSRect AIRectByMovingRect_intoRect_(NSRect mobileRect, NSRect stationaryRect);
