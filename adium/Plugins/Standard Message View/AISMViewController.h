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

#import <Cocoa/Cocoa.h>

@class AIListContact, AIAdium, AIFlexibleTableView, AIFlexibleTableColumn;
@protocol AIFlexibleTableViewDelegate;

@interface AISMViewController : NSObject <AIFlexibleTableViewDelegate> {
    AIAdium			*owner;

    AIListContact		*contact;
    AIFlexibleTableView		*messageView;

    AIFlexibleTableColumn	*senderCol;
    AIFlexibleTableColumn	*messageCol;
    AIFlexibleTableColumn	*timeCol;
/*
    NSColor			*backColorIn;
    NSColor			*backColorOut;
    NSColor			*lineColorDivider;
    NSColor			*lineColorDarkDivider;
    NSColor			*outgoingSourceColor;
    NSColor			*outgoingBrightSourceColor;
    NSColor			*incomingSourceColor;
    NSColor			*incomingBrightSourceColor;*/

    NSColor			*outgoingSourceColor;
    NSColor			*outgoingLightSourceColor;
    NSColor			*incomingSourceColor;
    NSColor			*incomingLightSourceColor;

    BOOL			displayPrefix;
    BOOL			displayTimeStamps;
    BOOL			displayGridLines;
    BOOL			displaySenderGradient;
    BOOL			hideDuplicateTimeStamps;
    BOOL			hideDuplicatePrefixes;

    float			gridDarkness;
    float			senderGradientDarkness;
//    float			senderGradientLightness;

    NSFont			*prefixFont;

    NSString			*timeStampFormat;
    NSString			*prefixIncoming;
    NSString			*prefixOutgoing;
}

+ (AISMViewController *)messageViewControllerForContact:(AIListContact *)inContact owner:(id)inOwner;
- (NSView *)messageView;
- (AIListContact *)contact;

@end
