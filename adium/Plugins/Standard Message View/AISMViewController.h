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

@class AIListContact, AIFlexibleTableView, AIChat, AIFlexibleTableCell, AIFlexibleTableFramedTextCell;
@protocol AIFlexibleTableViewDelegate, AIMessageViewController;

@interface AISMViewController : AIObject <AIMessageViewController> {
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

    BOOL			ignoreTextStyles;
    
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
    
	//Threads are a lot like George W. Bush in that they are the devil.
    BOOL                        rebuilding;
    BOOL                        restartRebuilding;
    BOOL                        abandonRebuilding;
	BOOL						lockContentThreadQueue;
    NSMutableArray              *contentThreadQueue;
}

+ (AISMViewController *)messageViewControllerForChat:(AIChat *)inChat;
- (NSView *)messageView;
- (AIChat *)chat;

@end
