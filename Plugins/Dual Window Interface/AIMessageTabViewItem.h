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

@class AIMessageViewController, AIMessageWindowController;
@protocol AIInterfaceContainer, AICustomTabViewItem;

@interface AIMessageTabViewItem : NSTabViewItem <AIInterfaceContainer, AICustomTabViewItem> {
	AIMessageWindowController	*container;
    AIMessageViewController 	*messageViewController;
    AIAdium						*adium;
	NSImage						*tabViewItemImage;
}

+ (AIMessageTabViewItem *)messageTabWithView:(AIMessageViewController *)inMessageView;
- (void)makeActive:(id)sender;
- (void)close:(id)sender;
- (NSString *)label;
- (NSImage *)icon;
- (NSImage *)statusIcon;
- (NSImage *)stateIcon;
- (AIChat *)chat;
- (NSImage *)image;
- (AIMessageViewController *)messageViewController;
- (void)tabViewItemWasSelected;
- (void)setContainer:(AIMessageWindowController *)inContainer;
- (AIMessageWindowController *)container;

@end
