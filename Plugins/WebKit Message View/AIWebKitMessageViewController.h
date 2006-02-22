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

#import <Adium/AIObject.h>

@class AIWebKitMessageViewPlugin, AIWebkitMessageViewStyle, AIContentObject, ESWebView;

@protocol AIMessageViewController;

@interface AIWebKitMessageViewController : AIObject <AIMessageViewController> {
	id							plugin;
	ESWebView					*webView;
	AIChat						*chat;
	BOOL						shouldReflectPreferenceChanges;

	//Content processing
	AIContentObject				*previousContent;
	NSMutableArray				*contentQueue;
	NSMutableArray				*storedContentObjects;
	BOOL						webViewIsReady;
	
	//Style & Variant
	AIWebkitMessageViewStyle	*messageStyle;
	NSString					*activeStyle;
	NSString					*activeVariant;

	//User icon masking
	NSImage						*imageMask;
	NSMutableArray				*objectsWithUserIconsArray;
	
	//for inline file transfer requests
	NSMutableDictionary			*fileTransferRequestControllers;
}

+ (AIWebKitMessageViewController *)messageViewControllerForChat:(AIChat *)inChat withPlugin:(AIWebKitMessageViewPlugin *)inPlugin;
- (void)adiumPrint:(id)sender;

//Webview
- (NSView *)messageView;
- (NSView *)messageScrollView;
- (AIWebkitMessageViewStyle *)messageStyle;

//Content
- (void)processQueuedContent;

//Other
- (void)setShouldReflectPreferenceChanges:(BOOL)inValue;

@end
