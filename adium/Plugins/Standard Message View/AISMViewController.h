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

@class AIListContact, AIAdium, AIFlexibleTableView, AIChat, AIFlexibleTableCell, AIFlexibleTableFramedTextCell;
@protocol AIFlexibleTableViewDelegate, AIMessageViewController;

@interface AISMViewController : NSObject <AIMessageViewController> {
    AIAdium			*owner;

    AIChat			*chat;
    AIFlexibleTableView		*messageView;
    AIFlexibleTableRow          *previousRow;
    
    NSImage			*iconIncoming;
    NSImage			*iconOutgoing;

    //Preference cache
    NSColor			*outgoingSourceColor;
    NSColor			*outgoingLightSourceColor;
    NSColor			*incomingSourceColor;
    NSColor			*incomingLightSourceColor;

    BOOL			ignoreTextColor;
    BOOL			ignoreBackgroundColor;
    
    NSString			*prefixIncoming;
    NSString			*prefixOutgoing;
    NSFont			*prefixFont;

    NSMutableString             *timeStampFormat;
    NSDateFormatter		*timeStampFormatter;
    
    NSColor			*colorIncoming;
    NSColor			*colorIncomingBorder;
    NSColor			*colorIncomingDivider;
    NSColor			*colorOutgoing;
    NSColor			*colorOutgoingBorder;
    NSColor			*colorOutgoingDivider;
    
    BOOL			combineMessages;
    BOOL			inlinePrefixes;
    BOOL                        showUserIcons;
    float                       headIndent;
    
    BOOL                        rebuilding;
    BOOL                        restartRebuilding;
    NSMutableArray              *contentQueue;
}

+ (AISMViewController *)messageViewControllerForChat:(AIChat *)inChat owner:(id)inOwner;
- (NSView *)messageView;
- (AIChat *)chat;

@end
