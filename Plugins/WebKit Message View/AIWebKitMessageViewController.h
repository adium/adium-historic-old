/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIWebKitMessageViewPlugin.h"
#import "ESWebView.h"
#import <WebKit/WebKit.h>

@interface AIWebKitMessageViewController : AIObject <AIMessageViewController> {
	ESWebView					*webView;
	NSString					*stylePath;
	NSString					*loadedStyleID;
	NSString					*loadedVariantID;
	AIChat						*chat;
	
	BOOL						webViewIsReady;
	BOOL						shouldRefreshContent;
	
	AIContentObject				*previousContent;
	NSMutableArray				*newContent;
	NSTimer						*newContentTimer;
	NSTimer						*setStylesheetTimer;
	
	id							plugin;
	
	NSString					*contentInHTML;
	NSString					*nextContentInHTML;
	NSString					*contextInHTML;
	NSString					*nextContextInHTML;
	NSString					*contentOutHTML;
	NSString					*nextContentOutHTML;
	NSString					*contextOutHTML;
	NSString					*nextContextOutHTML;
	NSString					*statusHTML;
	
	NSString					*background;
	NSString					*backgroundOriginalPath;
	NSColor						*backgroundColor;
	
	NSDateFormatter				*timeStampFormatter;
	NameFormat					nameFormat;
	BOOL						allowColors;
	BOOL						showUserIcons;
	BOOL						allowBackgrounds;
	BOOL						useCustomNameFormat;
	BOOL						combineConsecutive;
	BOOL						allowTextBackgrounds;
	int							styleVersion;	
	NSImage						*imageMask;
	NSMutableArray				*objectsWithUserIconsArray;
	AIImageBackgroundStyle		imageBackgroundStyle;
}

+ (AIWebKitMessageViewController *)messageViewControllerForChat:(AIChat *)inChat withPlugin:(AIWebKitMessageViewPlugin *)inPlugin;
- (void)forceReload;

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender;
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender;
- (void)concludeDragOperation:(id <NSDraggingInfo>)sender;
@end
