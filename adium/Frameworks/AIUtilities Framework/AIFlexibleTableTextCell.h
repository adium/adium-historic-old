/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AIFlexibleTableCell.h"

@class AIFlexibleTableColumn, AIFlexibleLink, AILinkTrackingController;

@interface AIFlexibleTableTextCell : AIFlexibleTableCell {
    NSAttributedString		*string;
    BOOL			containsLinks;
    int				contentHeight;
    
    //Link
    AILinkTrackingController	*linkTrackingController;
    
    //Text rendering cache
    NSTextStorage 		*textStorage;
    NSTextContainer 		*textContainer;
    NSLayoutManager 		*layoutManager;
    NSRange			glyphRange;

    NSRange			selectionRange;

    int				uniqueEmoticonID;

}

+ (AIFlexibleTableTextCell *)cellWithString:(NSString *)inString color:(NSColor *)inTextColor font:(NSFont *)inFont alignment:(NSTextAlignment)inAlignment;
+ (AIFlexibleTableTextCell *)cellWithAttributedString:(NSAttributedString *)inString;
- (AIFlexibleTableTextCell *)initWithAttributedString:(NSAttributedString *)inString;

@end
