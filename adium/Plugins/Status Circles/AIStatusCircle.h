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

@protocol AIHandleLeftView;

typedef enum {
    AICircleNormal,
    AICircleDot,
    AICirclePreFlash,
    AICircleFlashA,
    AICircleFlashB
} AICircleState;

@interface AIStatusCircle : NSObject <AIListObjectView> {
    NSColor		*color;
    NSColor		*flashColor;
    AICircleState	state;
    NSString		*string;
    NSColor		*stringColor;
    BOOL		bezeled;
    BOOL		flashColorUnique;
    //NSImage 		*statusSquare;
    //Drawing Cache
    NSAttributedString	*_attributedString;
    NSSize		_attributedStringSize;
    float		_maxWidth;
    float		cachedHeight;
}

+ (id)statusCircle;
+ (void)shouldDisplayIdleTime:(BOOL)displayIdleTime;
+ (void)setIsOnLeft:(BOOL)inIsOnLeft;

- (void)setState:(AICircleState)inState;
- (void)setColor:(NSColor *)inColor;
- (void)setFlashColor:(NSColor *)inColor;
- (void)setStringContent:(NSString *)inString;
- (void)setStringColor:(NSColor *)inColor;
- (void)setBezeled:(BOOL)inBezeled;

- (void)drawInRect:(NSRect)inRect;
- (float)widthForHeight:(int)inHeight;

    
@end
