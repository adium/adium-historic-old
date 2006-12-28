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

@class AIWebKitMessageViewPlugin, AIContentObject, ESWebView, DOMDocument;
@class AIChat, AIContentObject;

@protocol AIMessageViewController;

/*!
 *	@class AIWebKitMessageViewController AIWebKitMessageViewController.h
 *	@brief Main class for the webkit message view. Most of the good stuff happens here
 */
@interface AIWebKitMessageViewController : AIObject <AIMessageViewController> {
	id							plugin;
	ESWebView					*webView;
	id							preferencesChangedDelegate;
	AIChat						*chat;
	BOOL						shouldReflectPreferenceChanges;
	NSBundle					*styleBundle;

	//Content processing
	AIContentObject				*previousContent;
	NSMutableArray				*contentQueue;
	NSMutableArray				*storedContentObjects;
	BOOL						webViewIsReady;
	
	//Style & Variant
	NSString					*activeStyle;
	NSString					*activeVariant;

	//User icon masking
	NSImage						*imageMask;
	NSMutableArray				*objectsWithUserIconsArray;
}

/*!
 *	@brief Create a new message view controller
 */
+ (AIWebKitMessageViewController *)messageViewControllerForChat:(AIChat *)inChat withPlugin:(AIWebKitMessageViewPlugin *)inPlugin;

/*!
 *	@brief Print the webview
 *
 *	WebView does not have a print method, and [[webView mainFrame] frameView] is implemented to print only the visible portion of the view. 
 *	We have to get the scrollview and from there the documentView to have access to all of the webView.
 */
- (void)adiumPrint:(id)sender;

//Webview
/*!
 *	@return  the ESWebView which should be inserted into the message window 
 */
- (NSView *)messageView;

/*!
 *	@return our scroll view
 */
- (NSView *)messageScrollView;

/*!
 *	@return our message style controller
 */

/*!
 *	@brief Enable or disable updating to reflect preference changes
 *
 *	When disabled, the view will not update when a preferece changes that would require rebuilding the views content
 */
- (void)setShouldReflectPreferenceChanges:(BOOL)inValue;

- (void)setPreferencesChangedDelegate:(id)inDelegate;
@end
