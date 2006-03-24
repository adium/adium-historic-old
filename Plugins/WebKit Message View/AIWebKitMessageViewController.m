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

#import "AIContactController.h"
#import "AIContentController.h"
#import "AIMenuController.h"
#import "AIWebKitMessageViewController.h"
#import "AIWebKitMessageViewStyle.h"
#import "AIWebKitMessageViewPlugin.h"
#import "ESFileTransferController.h"
#import "ESWebFrameViewAdditions.h"
#import "ESWebKitMessageViewPreferences.h"
#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIDateFormatterAdditions.h>
#import <AIUtilities/AIMutableStringAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentContext.h>
#import <Adium/AIContentObject.h>
#import <Adium/AIContentStatus.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListObject.h>
#import <Adium/AIService.h>
#import "ESFileTransfer.h"
#import "ESFileTransferRequestPromptController.h"
#import "ESTextAndButtonsWindowController.h"

#import "ESWebView.h"

@class AIContentMessage, AIContentStatus, AIContentObject;

@interface AIWebKitMessageViewController (PRIVATE)
- (id)initForChat:(AIChat *)inChat withPlugin:(AIWebKitMessageViewPlugin *)inPlugin;
- (void)_initWebView;
- (void)_primeWebViewAndReprocessContent:(BOOL)reprocessContent;
- (void)_updateWebViewForCurrentPreferences;
- (void)_updateVariantWithoutPrimingView;
- (void)processQueuedContent;
- (void)_processContentObject:(AIContentObject *)content willAddMoreContentObjects:(BOOL)willAddMoreContentObjects;
- (void)_appendContent:(AIContentObject *)content similar:(BOOL)contentIsSimilar willAddMoreContentObjects:(BOOL)willAddMoreContentObjects;
- (void)_updateUserIconForObject:(AIListObject *)inObject;
- (NSString *)_webKitUserIconPathForObject:(AIListObject *)inObject;
- (void)participatingListObjectsChanged:(NSNotification *)notification;
- (void)sourceOrDestinationChanged:(NSNotification *)notification;
- (BOOL)shouldHandleDragWithPasteboard:(NSPasteboard *)pasteboard;
- (void) enqueueContentObject:(AIContentObject *)contentObject;
- (void) debugLog:(NSString *)message;
@end

static NSArray *draggedTypes = nil;

@implementation AIWebKitMessageViewController

/*!
 * @brief Create a new message view controller
 */
+ (AIWebKitMessageViewController *)messageViewControllerForChat:(AIChat *)inChat withPlugin:(AIWebKitMessageViewPlugin *)inPlugin
{
    return [[[self alloc] initForChat:inChat withPlugin:inPlugin] autorelease];
}

/*!
 * @brief Initialize
 */
- (id)initForChat:(AIChat *)inChat withPlugin:(AIWebKitMessageViewPlugin *)inPlugin
{
    //init
    if ((self = [super init]))
	{		
		[self _initWebView];

		chat = [inChat retain];
		plugin = [inPlugin retain];
		contentQueue = [[NSMutableArray alloc] init];
		shouldReflectPreferenceChanges = NO;
		storedContentObjects = nil;

		//Observe preference changes.
		[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
		[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_WEBKIT_BACKGROUND_IMAGES];
		
		//Observe participants list changes
		[[adium notificationCenter] addObserver:self 
									   selector:@selector(participatingListObjectsChanged:)
										   name:Chat_ParticipatingListObjectsChanged 
										 object:inChat];

		//Observe source/destination changes
		[[adium notificationCenter] addObserver:self 
									   selector:@selector(sourceOrDestinationChanged:)
										   name:Chat_SourceChanged 
										 object:inChat];
		[[adium notificationCenter] addObserver:self 
									   selector:@selector(sourceOrDestinationChanged:)
										   name:Chat_DestinationChanged 
										 object:inChat];
		[self sourceOrDestinationChanged:nil];
		
		//Observe content additons
		[[adium notificationCenter] addObserver:self 
									   selector:@selector(contentObjectAdded:)
										   name:Content_ContentObjectAdded 
										 object:inChat];
		[[adium notificationCenter] addObserver:self 
									   selector:@selector(chatDidFinishAddingUntrackedContent:)
										   name:Content_ChatDidFinishAddingUntrackedContent 
										 object:inChat];
		
		[[adium notificationCenter] addObserver:self
									   selector:@selector(showFileTransferRequest:)
										   name:@"FileTransferRequestReceived"
										 object:nil];
		
		[[adium notificationCenter] addObserver:self
									   selector:@selector(cancelFileTransferRequest:)
										   name:FILE_TRANSFER_CANCELLED
										 object:nil];
	}
	
    return self;
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[plugin release]; plugin = nil;
	[objectsWithUserIconsArray release]; objectsWithUserIconsArray = nil;

	//Stop any delayed requests and remove all observers
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[[adium preferenceController] unregisterPreferenceObserver:self];
	[[adium notificationCenter] removeObserver:self];
	
	//Stop observing the webview, since it may attempt callbacks shortly after we dealloc
	[webView setFrameLoadDelegate:nil];
	[webView setPolicyDelegate:nil];
	[webView setUIDelegate:nil];
	[webView setDraggingDelegate:nil];
	
	//Release the web view
	[webView release];

	//Clean up style/variant info
	[messageStyle release]; messageStyle = nil;
	[activeStyle release]; activeStyle = nil;
	[activeVariant release]; activeVariant = nil;
	
	//Cleanup content processing
	[contentQueue release]; contentQueue = nil;
	[storedContentObjects release]; storedContentObjects = nil;
	[previousContent release]; previousContent = nil;

	//Release the chat
	[chat release]; chat = nil;
		
	[fileTransferRequestControllers release]; fileTransferRequestControllers = nil;

	[super dealloc];
}

/*!
 * @brief Enable or disable updating to reflect preference changes
 *
 * When disabled, the view will not update when a preferece changes that would require rebuilding the views content
 */
- (void)setShouldReflectPreferenceChanges:(BOOL)inValue
{
	shouldReflectPreferenceChanges = inValue;

	//We'll want to start storing content objects if we're needing to reflect preference changes
	if (shouldReflectPreferenceChanges) {
		if (!storedContentObjects) {
			storedContentObjects = [[NSMutableArray alloc] init];
		}
	} else {
		[storedContentObjects release]; storedContentObjects = nil;
	}
}

/*!
 * @brief Print the webview
 */
- (void)adiumPrint:(id)sender
{
	/*
	 Apple, in its infinite wisdom, did not implement a webView print method, and implemented
	 [[webView mainFrame] frameView] to print only the visible portion of the view. We have to get the scrollview
	 and from there the documentView to have access to all of the webView.
	 */
	
	NSPrintOperation	*op;
	NSView				*documentView;
	NSImage				*image;
	NSImageView			*imageView;
	NSSize				imageSize;
	NSRect				originalWebViewFrame, webViewFrame, documentViewFrame, imageViewFrame;
	NSPrintInfo			*sharedPrintInfo = [NSPrintInfo sharedPrintInfo];
	
	//Calculate the page height in points
    NSSize paperSize = [sharedPrintInfo paperSize];
    float pageWidth = paperSize.width - [sharedPrintInfo leftMargin] - [sharedPrintInfo rightMargin];
	
    //Convert height to the scaled view 
	float scale = [[[sharedPrintInfo dictionary] objectForKey:NSPrintScalingFactor] floatValue];
	if (!scale) scale = 1.0;	
    pageWidth = pageWidth / scale;
	
	//Get the HTMLDocumentView which has all the content we want
	documentView = [[[[[webView mainFrame] frameView] frameScrollView] contentView] documentView];
	
	//Get initial frames
	originalWebViewFrame = [webView frame];
	documentViewFrame = [documentView frame];
	
	//Make the webView the same size as we will be printing so any CSS elements resize themselves properly
	webViewFrame = originalWebViewFrame;
	webViewFrame.size.width = pageWidth;
	webViewFrame.size.height = documentViewFrame.size.height;
	[webView setFrame:webViewFrame];

	//Ensure the documentView is constrained to the pageWidth
	documentViewFrame.size.width = pageWidth;
	
	//Set up our image
	image = [[[NSImage alloc] initWithSize:documentViewFrame.size] autorelease];
	[image setFlipped:YES];
	
	//Draw
	[image lockFocus];
	[documentView drawRect:documentViewFrame];
	[image unlockFocus];

	//Restore the webView's frame to its original state
	[webView setFrame:originalWebViewFrame];

	//Create an NSImageView to hold our image
	imageSize = [image size];
	imageViewFrame = NSMakeRect(0,0,imageSize.width,imageSize.height);
	imageView = [[[NSImageView alloc] initWithFrame:imageViewFrame] autorelease];
	[imageView setImageAlignment:NSImageAlignTop];
	[imageView setAnimates:NO];
	[imageView setImageScaling:NSScaleProportionally];
	[imageView setImage:image];

	//Pass it to NSPrintOperation
	op = [NSPrintOperation printOperationWithView:imageView];
	[op setCanSpawnSeparateThread:YES];
	
//XXX - documentView creates a visual glitch which disappears when the scrollbar or window is changed. odd.
	[op runOperationModalForWindow:[webView window]
						  delegate:self
					didRunSelector:@selector(printOperationDidRun:success:contextInfo:)
					   contextInfo:NULL];
	
}

- (void)printOperationDidRun:(NSPrintOperation *)printOperation success:(BOOL)success contextInfo:(void *)info 
{	
	//Empty
}


//WebView --------------------------------------------------------------------------------------------------
#pragma mark WebView
/*!
 * @brief Return the view which should be inserted into the message window 
 */
- (NSView *)messageView
{
	return webView;
}

/*!
 * @brief Return our scroll view
 */
- (NSView *)messageScrollView
{
	return [[webView mainFrame] frameView];
}

/*!
 * @brief Return our message style controller
 */
- (AIWebkitMessageViewStyle *)messageStyle
{
	return messageStyle;
}

/*!
 * @brief Apply preference changes to our webview
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key object:(AIListObject *)object
					preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	NSString		*variantKey = [plugin styleSpecificKey:@"Variant" forStyle:activeStyle];
	
	if ([group isEqualToString:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY]) {
		//Variant changes we can apply immediately.  All other changes require us to reload the view
		if (!firstTime && [key isEqualToString:variantKey]) {
			[activeVariant release]; activeVariant = [[prefDict objectForKey:variantKey] retain];
			[self _updateVariantWithoutPrimingView];
			
		} else if (firstTime || shouldReflectPreferenceChanges) {
			//Ignore changes related to our background image cache.  These keys are used for storage only and aren't
			//something we need to update in response to.  All other display changes we update our view for.
			if (![key isEqualToString:@"BackgroundCacheUniqueID"] &&
			   ![key isEqualToString:[plugin styleSpecificKey:@"BackgroundCachePath" forStyle:activeStyle]]) {
				[self _updateWebViewForCurrentPreferences];
			}
			
		}
	}
	
	if (([group isEqualToString:PREF_GROUP_WEBKIT_BACKGROUND_IMAGES] && shouldReflectPreferenceChanges)) {
		//If the background image changes, wipe the cache and update for the new image
		[[adium preferenceController] setPreference:nil
											 forKey:[plugin styleSpecificKey:@"BackgroundCachePath" forStyle:activeStyle]
											  group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];	
		[self _updateWebViewForCurrentPreferences];
	}
	
}

/*!
 * @brief Initialiaze the web view
 */
- (void)_initWebView
{
	//Create our webview
	webView = [[ESWebView alloc] initWithFrame:NSMakeRect(0,0,100,100) //Arbitrary frame
									 frameName:nil
									 groupName:nil];
	[webView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
	[webView setPolicyDelegate:self];
	[webView setUIDelegate:self];
	[webView setDraggingDelegate:self];
	[webView setMaintainsBackForwardList:NO];

	if (!draggedTypes) {
		draggedTypes = [[NSArray alloc] initWithObjects:
			NSFilenamesPboardType,
			NSTIFFPboardType,
			NSPDFPboardType,
			NSPICTPboardType,
			NSHTMLPboardType,
			NSFileContentsPboardType,
			NSRTFPboardType,
			NSStringPboardType,
			NSPostScriptPboardType,
			nil];
	}
	[webView registerForDraggedTypes:draggedTypes];
		
	[[webView windowScriptObject] setValue:self forKey:@"client"];
}

/*!
 * @brief Updates our webview to the current preferences, priming the view
 */
- (void)_updateWebViewForCurrentPreferences
{
	NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
	NSBundle		*styleBundle;
	
	//Cleanup first
	[messageStyle release];
	[activeStyle release];
	[activeVariant release];
	
	//Load the message style
	activeStyle = [[prefDict objectForKey:KEY_WEBKIT_STYLE] retain];
	styleBundle = [plugin messageStyleBundleWithIdentifier:activeStyle];
	messageStyle = [[AIWebkitMessageViewStyle messageViewStyleFromBundle:styleBundle] retain];
	[webView setPreferencesIdentifier:activeStyle];

	//Get the prefered variant (or the default if a prefered is not available)
	activeVariant = [[prefDict objectForKey:[plugin styleSpecificKey:@"Variant" forStyle:activeStyle]] retain];
	if (!activeVariant) activeVariant = [[messageStyle defaultVariant] retain];
	
	//Update message style behavior
	[messageStyle setShowUserIcons:[[prefDict objectForKey:KEY_WEBKIT_SHOW_USER_ICONS] boolValue]];
	[messageStyle setShowHeader:[[prefDict objectForKey:KEY_WEBKIT_SHOW_HEADER] boolValue]];
	[messageStyle setUseCustomNameFormat:[[prefDict objectForKey:KEY_WEBKIT_USE_NAME_FORMAT] boolValue]];
	[messageStyle setNameFormat:[[prefDict objectForKey:KEY_WEBKIT_NAME_FORMAT] intValue]];
	[messageStyle setDateFormat:[prefDict objectForKey:KEY_WEBKIT_TIME_STAMP_FORMAT]];
	[messageStyle setShowIncomingMessageColors:[[prefDict objectForKey:KEY_WEBKIT_SHOW_MESSAGE_COLORS] boolValue]];
	[messageStyle setShowIncomingMessageFonts:[[prefDict objectForKey:KEY_WEBKIT_SHOW_MESSAGE_FONTS] boolValue]];
	
	//Custom background image
	//Webkit wants to load these from disk, but we have it stuffed in a plist.  So we'll write it out as an image
	//into the cache and have webkit fetch from there.
	NSString	*cachePath = nil;
	if ([[prefDict objectForKey:[plugin styleSpecificKey:@"UseCustomBackground" forStyle:activeStyle]] boolValue]) {
		cachePath = [prefDict objectForKey:[plugin styleSpecificKey:@"BackgroundCachePath" forStyle:activeStyle]];
		if (!cachePath || ![[NSFileManager defaultManager] fileExistsAtPath:cachePath]) {
			NSData	*backgroundImage = [[adium preferenceController] preferenceForKey:[plugin styleSpecificKey:@"Background" forStyle:activeStyle]
																				group:PREF_GROUP_WEBKIT_BACKGROUND_IMAGES];
			
			if (backgroundImage) {
				//Generate a unique cache ID for this image
				int	uniqueID = [[prefDict objectForKey:@"BackgroundCacheUniqueID"] intValue] + 1;
				[[adium preferenceController] setPreference:[NSNumber numberWithInt:uniqueID]
													 forKey:@"BackgroundCacheUniqueID"
													  group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
				
				//Cache the image under that unique ID
				//Since we prefix the filename with TEMP, Adium will automatically clean it up on quit
				cachePath = [[adium cachesPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"TEMP-WebkitBGImage-%i.png",uniqueID]];
				[backgroundImage writeToFile:cachePath atomically:YES];

				//Remember where we cached it
				[[adium preferenceController] setPreference:cachePath
													 forKey:[plugin styleSpecificKey:@"BackgroundCachePath" forStyle:activeStyle]
													  group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
			} else {
				cachePath = @""; //No custom image found
			}
		}
	}
	[messageStyle setCustomBackgroundPath:cachePath];
	[messageStyle setCustomBackgroundType:[[prefDict objectForKey:[plugin styleSpecificKey:@"BackgroundType" forStyle:activeStyle]] intValue]];

	//Custom background color
	if ([[prefDict objectForKey:[plugin styleSpecificKey:@"UseCustomBackground" forStyle:activeStyle]] boolValue]) {
		[messageStyle setCustomBackgroundColor:[[prefDict objectForKey:[plugin styleSpecificKey:@"BackgroundColor" forStyle:activeStyle]] representedColor]];
	} else {
		[messageStyle setCustomBackgroundColor:nil];
	}
	[webView setDrawsBackground:![[self messageStyle] isBackgroundTransparent]];

	//Update webview font settings
	NSString	*fontFamily = [prefDict objectForKey:[plugin styleSpecificKey:@"FontFamily" forStyle:activeStyle]];
	[webView setFontFamily:(fontFamily ? fontFamily : [messageStyle defaultFontFamily])];
	
	NSNumber	*fontSize = [prefDict objectForKey:[plugin styleSpecificKey:@"FontSize" forStyle:activeStyle]];
	[[webView preferences] setDefaultFontSize:[(fontSize ? fontSize : [messageStyle defaultFontSize]) intValue]];
	
	NSNumber	*minSize = [prefDict objectForKey:KEY_WEBKIT_MIN_FONT_SIZE];
	[[webView preferences] setMinimumFontSize:(minSize ? [minSize intValue] : 1)];
	
	//Prime the webview with the new style/variant and settings, and re-insert all our content back into the view
	[self _primeWebViewAndReprocessContent:YES];	
}

/*!
 * @brief Updates our webview to the currently active varient without refreshing the view
 */
- (void)_updateVariantWithoutPrimingView
{
	//We can only change the variant if the web view is ready.  If it's not ready we wait a bit and try again.
	if (webViewIsReady) {
		[webView stringByEvaluatingJavaScriptFromString:[messageStyle scriptForChangingVariant:activeVariant]];			
	} else {
		[self performSelector:@selector(_updateVariantWithoutPrimingView) withObject:nil afterDelay:NEW_CONTENT_RETRY_DELAY];
	}
}

/*!
 * @brief Primes our webview to the currently active style and variant
 *
 * The webview won't be ready right away, so we flag it as not ready and set ourself as the frame load delegate so
 * it will let us know when it's good to go.  If reprocessContent is NO, all content in the view will be lost.
 */
- (void)_primeWebViewAndReprocessContent:(BOOL)reprocessContent
{
	webViewIsReady = NO;
	[webView setFrameLoadDelegate:self];
	[[webView mainFrame] loadHTMLString:[messageStyle baseTemplateWithVariant:activeVariant chat:chat] baseURL:nil];

	if (reprocessContent) {
		NSArray	*currentContentQueue;
		
		//Keep the array of objects waiting to be added, if necessary, to append them after our currently displayed ones
		currentContentQueue = ([contentQueue count] ?
							   [contentQueue copy] :
							   nil);

		//Start from an empty content queue
		[contentQueue removeAllObjects];

		//Add our stored content objects to the content queue
		[contentQueue addObjectsFromArray:storedContentObjects];
		[storedContentObjects removeAllObjects];

		//Add the old content queue back in if necessary
		if (currentContentQueue) {
			[contentQueue addObjectsFromArray:currentContentQueue];
			[currentContentQueue release];
		}

		//We're still holding onto the previousContent from before, which is no longer accurate. Release it.
		[previousContent release]; previousContent = nil;
	}
}


//Content --------------------------------------------------------------------------------------------------------------
#pragma mark Content
/*!
 * @brief Append new content to our processing queue
 */
- (void)contentObjectAdded:(NSNotification *)notification
{
	AIContentObject	*contentObject = [[notification userInfo] objectForKey:@"AIContentObject"];
	[self enqueueContentObject:contentObject];
}

- (void) enqueueContentObject:(AIContentObject *)contentObject
{
	[contentQueue addObject:contentObject];
	
	/* Immediately update our display if the content requires it.
	* This is NO, for example, when we receive an entire block of message history content so that we can avoid scrolling
	* after each one.
	*/
	if ([contentObject displayContentImmediately]) {
		[self processQueuedContent];
	}
}

/*!
 * @brief Our chat finished adding untracked content
 */
- (void)chatDidFinishAddingUntrackedContent:(NSNotification *)notification
{
	[self processQueuedContent];	
}

/*!
 * @brief Append new content to our processing queueProcess any content in the queuee
 */
- (void)processQueuedContent
{
	unsigned	contentQueueCount, objectsAdded = 0;
	BOOL		willAddMoreContentObjects = NO;
	
	if (webViewIsReady) {
		contentQueueCount = [contentQueue count];

		while (contentQueueCount > 0) {
			AIContentObject *content;

			willAddMoreContentObjects = (contentQueueCount > 1);
			
			//Display the content
			content = [contentQueue objectAtIndex:0];
			[self _processContentObject:content willAddMoreContentObjects:willAddMoreContentObjects];

			//If we are going to reflect preference changes, store this content object
			if (shouldReflectPreferenceChanges) {
				[storedContentObjects addObject:content];
			}

			//Remove the content we just displayed from the queue
			[contentQueue removeObjectAtIndex:0];
			objectsAdded++;
			contentQueueCount--;
		}
	} else {
		/* If the webview isn't ready, assume we have at least one piece of content left to display */
		contentQueueCount = 1;
	}
	
	/* If we added multiple objects, we may want to scroll to the bottom now, having not done it as each object
	 * was added.
	 */
	if (objectsAdded > 1) {
		NSString	*scrollToBottomScript;
		
		if ((scrollToBottomScript = [messageStyle scriptForScrollingAfterAddingMultipleContentObjects])) {
			[webView stringByEvaluatingJavaScriptFromString:scrollToBottomScript];
		}
	}
	
	//If there is still content to process (the webview wasn't ready), we'll try again after a brief delay
	if (contentQueueCount) {
		[self performSelector:@selector(processQueuedContent) withObject:nil afterDelay:NEW_CONTENT_RETRY_DELAY];
	}
}

/*!
 * @brief Process and then append a content object
 */
- (void)_processContentObject:(AIContentObject *)content willAddMoreContentObjects:(BOOL)willAddMoreContentObjects
{
	NSString		*dateMessage = nil;
	AIContentStatus *dateSeparator = nil;
	
	/*
	 If the day has changed since our last message (or if there was no previous message and 
	 we are about to display context), insert a date line.
	 */
	if ((!previousContent && [content isKindOfClass:[AIContentContext class]]) ||
	   (![content isFromSameDayAsContent:previousContent])) {
		dateMessage = [[content date] descriptionWithCalendarFormat:[[NSDateFormatter localizedDateFormatter] dateFormat]
														   timeZone:nil
															 locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
		dateSeparator = [AIContentStatus statusInChat:[content chat]
										   withSource:[[content chat] listObject]
										  destination:[[content chat] account]
												 date:[content date]
											  message:[[[NSAttributedString alloc] initWithString:dateMessage
																					   attributes:[[adium contentController] defaultFormattingAttributes]] autorelease]
											 withType:@"date_separator"];
		//Add the date header
		[self _appendContent:dateSeparator 
					 similar:NO
			willAddMoreContentObjects:YES];
		[previousContent release]; previousContent = [dateSeparator retain];
	}
	
	//Add the content object
	[self _appendContent:content 
				 similar:(previousContent && [content isSimilarToContent:previousContent])
	willAddMoreContentObjects:willAddMoreContentObjects];
	
	[previousContent release]; previousContent = [content retain];
}

/*!
 * @brief Append a content object
 */
- (void)_appendContent:(AIContentObject *)content similar:(BOOL)contentIsSimilar willAddMoreContentObjects:(BOOL)willAddMoreContentObjects
{
	[webView stringByEvaluatingJavaScriptFromString:[messageStyle scriptForAppendingContent:content
																					similar:contentIsSimilar
																  willAddMoreContentObjects:willAddMoreContentObjects]];
}


//WebView Delegates ----------------------------------------------------------------------------------------------------
#pragma mark Webview delegates
/*!
 * @brief Invoked once the webview has loaded and is ready to accept content
 */
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	//Flag the view as ready (as soon as the current methods exit) so we know it's now safe to add content
	[self performSelector:@selector(webViewIsReady) withObject:nil afterDelay:0.00001];
	
	//We don't care about any further didFinishLoad notifications
	[webView setFrameLoadDelegate:nil];
}
- (void)webViewIsReady{
	webViewIsReady = YES;
	[self processQueuedContent];
}

/*!
 * @brief Prevent the webview from following external links.  We direct these to the user's web browser.
 */
- (void)webView:(WebView *)sender
    decidePolicyForNavigationAction:(NSDictionary *)actionInformation
		request:(NSURLRequest *)request
		  frame:(WebFrame *)frame
    decisionListener:(id<WebPolicyDecisionListener>)listener
{
    int actionKey = [[actionInformation objectForKey: WebActionNavigationTypeKey] intValue];
    if (actionKey == WebNavigationTypeOther) {
		[listener use];
    } else {
		NSURL *url = [actionInformation objectForKey:WebActionOriginalURLKey];
		
		//Ignore file URLs, but open anything else
		if (![url isFileURL]) {
			[[NSWorkspace sharedWorkspace] openURL:url];
		}
		
		[listener ignore];
    }
}

/*!
 * @brief Append our own menu items to the webview's contextual menus
 */
- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems
{
	NSMutableArray *webViewMenuItems = [[defaultMenuItems mutableCopy] autorelease];
	AIListContact	*chatListObject = [chat listObject];

	//Remove default items we don't want
	if (webViewMenuItems) {
		NSEnumerator	*enumerator;
		NSMenuItem		*menuItem;
		
		enumerator = [defaultMenuItems objectEnumerator];
		while ((menuItem = [enumerator nextObject])) {
			NSString	*menuItemTitle = [menuItem title];

			if (menuItemTitle &&
				(([menuItemTitle localizedCaseInsensitiveCompare:@"Open Image in New Window"] == NSOrderedSame) ||
				 ([menuItemTitle localizedCaseInsensitiveCompare:@"Download Image"] == NSOrderedSame) ||
				 ([menuItemTitle localizedCaseInsensitiveCompare:@"Reload"] == NSOrderedSame) ||
				 ([menuItemTitle localizedCaseInsensitiveCompare:@"Open Link in New Window"] == NSOrderedSame) ||
				 ([menuItemTitle localizedCaseInsensitiveCompare:@"Download Linked File"] == NSOrderedSame))) {
				[webViewMenuItems removeObjectIdenticalTo:menuItem];
			}			
		}
	}
	
	if (chatListObject) {
		NSMenuItem		*menuItem;
		NSEnumerator	*enumerator;
		if (webViewMenuItems) {
			//Add a separator item if items already exist in webViewMenuItems
			if ([webViewMenuItems count]) {
				[webViewMenuItems addObject:[NSMenuItem separatorItem]];
			}
		} else {
			webViewMenuItems = [NSMutableArray array];
		}
		
		NSArray *locations;
		if ([chatListObject isStranger]) {
			locations = [NSArray arrayWithObjects:
				[NSNumber numberWithInt:Context_Contact_Manage],
				[NSNumber numberWithInt:Context_Contact_Action],
				[NSNumber numberWithInt:Context_Contact_NegativeAction],
				[NSNumber numberWithInt:Context_Contact_ChatAction],
				[NSNumber numberWithInt:Context_Contact_Stranger_ChatAction],
				[NSNumber numberWithInt:Context_Contact_Additions], nil];
		} else {
			locations = [NSArray arrayWithObjects:
				[NSNumber numberWithInt:Context_Contact_Manage],
				[NSNumber numberWithInt:Context_Contact_Action],
				[NSNumber numberWithInt:Context_Contact_NegativeAction],
				[NSNumber numberWithInt:Context_Contact_ChatAction],
				[NSNumber numberWithInt:Context_Contact_Additions], nil];
		}
		
		NSMenu  *originalMenu = [[adium menuController] contextualMenuWithLocations:locations
																	  forListObject:chatListObject];
		
		enumerator = [[originalMenu itemArray] objectEnumerator];
		while ((menuItem = [enumerator nextObject])) {
			NSMenuItem	*webViewMenuItem = [menuItem copy];
			[webViewMenuItems addObject:webViewMenuItem];
			[webViewMenuItem release];
		}
	}
	
	return webViewMenuItems;
}


//Dragging delegate ----------------------------------------------------------------------------------------------------
#pragma mark Dragging delegate
/*!
 * @brief If possible, return the first NSTextView in the message view's responder chain
 *
 * This is used for drag and drop behavior.
 */
- (NSTextView *)textView
{
	id	responder = [webView nextResponder];
	
	//Walkin the responder chain looking for an NSTextView
	while (responder &&
		  ![responder isKindOfClass:[NSTextView class]]) {
		responder = [responder nextResponder];
	}
	
	return responder;
}

/*!
 * @brief Dragging entered
 */
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	NSPasteboard	*pasteboard = [sender draggingPasteboard];

	return ([pasteboard availableTypeFromArray:draggedTypes] ?
		   NSDragOperationCopy :
		   NSDragOperationNone);
}

/*!
* @brief Dragging updated
 */
- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
	return [self draggingEntered:sender];
}

/*!
 * @brief Handle a drag onto the webview
 * 
 * If we're getting a non-image file, we can handle it immediately.  Otherwise, the drag is the textView's problem.
 */
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	NSPasteboard	*pasteboard = [sender draggingPasteboard];
	BOOL			success = NO;
	
	if ([self shouldHandleDragWithPasteboard:pasteboard]) {
		
		//Not an image but it is a file - send it immediately as a file transfer
		NSArray			*files = [pasteboard propertyListForType:NSFilenamesPboardType];
		NSEnumerator	*enumerator = [files objectEnumerator];
		NSString		*path;
		while ((path = [enumerator nextObject])) {
			AIListObject *listObject = [chat listObject];
			if (listObject) {
				[[adium fileTransferController] sendFile:path toListContact:(AIListContact *)listObject];
			}
		}
		success = YES;
		
	} else {
		NSTextView *textView = [self textView];
		if (textView) {
			[[webView window] makeFirstResponder:textView]; //Make it first responder
			success = [textView performDragOperation:sender];
		}
	}
	
	return success;
}

/*!
 * @brief Pass on the prepareForDragOperation if it's not one we're handling in this class
 */
- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	NSPasteboard	*pasteboard = [sender draggingPasteboard];
	BOOL	success = YES;
	
	if (![self shouldHandleDragWithPasteboard:pasteboard]) {	
		NSTextView *textView = [self textView];
		if (textView) {
			success = [textView prepareForDragOperation:sender];
		}
	}
	
	return success;
}
	
/*!
 * @brief Pass on the concludeDragOperation if it's not one we're handling in this class
 */
- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
	NSPasteboard	*pasteboard = [sender draggingPasteboard];
	
	if (![self shouldHandleDragWithPasteboard:pasteboard]) {
		NSTextView *textView = [self textView];
		if (textView) {
			[textView concludeDragOperation:sender];
		}
	}
}

/*!
 * @brief Handle drags of content we recognize
 */
- (BOOL)shouldHandleDragWithPasteboard:(NSPasteboard *)pasteboard
{
	/*
	return (![pasteboard availableTypeFromArray:[NSArray arrayWithObjects:NSTIFFPboardType,NSPDFPboardType,NSPICTPboardType,nil]] &&
			[pasteboard availableTypeFromArray:[NSArray arrayWithObject:NSFilenamesPboardType]]);
	 */
	return NO;
}


//User Icon masking --------------------------------------------------------------------------------------------------
//We allow messaage styles to specify masks for user icons.  This could be user to round the corners of user icons 
//or other related effects.
#pragma mark User icon masking
/*!
 * @brief Update icon masks when participating list objects change
 *
 * We want to observe attributesChanged: notifications for all objects which are participating in our chat.
 * When the list changes, remove the observers we had in place before and add observers for each object in the list
 * so we never observe for contacts not in the chat.
 */
- (void)participatingListObjectsChanged:(NSNotification *)notification
{
	NSArray			*participatingListObjects = [chat participatingListObjects];
	NSEnumerator	*enumerator;
	AIListContact	*listContact;
	
	[[adium notificationCenter] removeObserver:self
										  name:ListObject_AttributesChanged
										object:nil];
	
	enumerator = [participatingListObjects objectEnumerator];
	while ((listContact = [enumerator nextObject])) {
		//Update the mask for any user which just entered the chat
		if (![objectsWithUserIconsArray containsObjectIdenticalTo:listContact]) {
			[self _updateUserIconForObject:listContact];
		}
		
		//In the future, watch for changes on the parent object, since that's the icon we display
		[[adium notificationCenter] addObserver:self
									   selector:@selector(listObjectAttributesChanged:) 
										   name:ListObject_AttributesChanged
										 object:[listContact parentContact]];
	}
	
	//Also observe our account
	[[adium notificationCenter] addObserver:self
								   selector:@selector(listObjectAttributesChanged:) 
									   name:ListObject_AttributesChanged
									 object:[chat account]];
	
	//We've now masked every user currently in the participating list objects
	[objectsWithUserIconsArray release]; 
	objectsWithUserIconsArray = [participatingListObjects mutableCopy];	
}

/*!
 * @brief Update icon masks when source or destination changes
 */
- (void)sourceOrDestinationChanged:(NSNotification *)notification
{
	[objectsWithUserIconsArray release]; objectsWithUserIconsArray = nil;
	[self participatingListObjectsChanged:nil];
	
	[self _updateUserIconForObject:[chat account]];
}

/*!
 * @brief Update icon masks when a list object's attributes change
 */
- (void)listObjectAttributesChanged:(NSNotification *)notification
{
    AIListObject	*inObject = [notification object];
    NSSet			*keys = [[notification userInfo] objectForKey:@"Keys"];
	
	if (inObject &&
		([keys containsObject:KEY_USER_ICON])) {
		AIListObject	*actualObject = nil;
		
		if ([chat account] == inObject) {
			//The account is the object actually in the chat
			actualObject = inObject;
		} else {
			/*
			 * We are notified of a change to the metacontact's icon. Find the contact inside the chat which we will
			 * be displaying as changed.
			 */
			NSEnumerator	*enumerator;
			AIListContact	*participatingListObject;
			
			enumerator = [[chat participatingListObjects] objectEnumerator];
			while ((participatingListObject = [enumerator nextObject])) {
				if ([participatingListObject parentContact] == inObject) {
					actualObject = participatingListObject;
					break;
				}
			}
		}
		
		if (actualObject) {
			[self _updateUserIconForObject:actualObject];
		}
	}
}

/*!
 * @brief Generate an updated masked user icon for the passed list object
 */
- (void)_updateUserIconForObject:(AIListObject *)inObject
{
	AIListObject		*iconSourceObject = ([inObject isKindOfClass:[AIListContact class]] ?
											 [(AIListContact *)inObject parentContact] :
											 inObject);
	NSImage				*userIcon;
	NSString			*webKitUserIconPath;
	NSImage				*webKitUserIcon;
	
	/*
	 * We probably already have a userIcon waiting for us, the active display icon; use that
	 * rather than loading one from disk.
	 */
	if (!(userIcon = [iconSourceObject userIcon])) {
		//If that's not the case, try using the UserIconPath
		userIcon = [[[NSImage alloc] initWithContentsOfFile:[iconSourceObject statusObjectForKey:@"UserIconPath"]] autorelease];
	}
	
	if (userIcon) {
		if ([messageStyle userIconMask]) {
			//Apply the mask is the style has one
			webKitUserIcon = [[[messageStyle userIconMask] copy] autorelease];
			[webKitUserIcon lockFocus];
			[userIcon drawInRect:NSMakeRect(0,0,[webKitUserIcon size].width,[webKitUserIcon size].height)
						fromRect:NSMakeRect(0,0,[userIcon size].width,[userIcon size].height)
					   operation:NSCompositeSourceIn
						fraction:1.0];
			[webKitUserIcon unlockFocus];
		} else {
			//Otherwise, just use the icon as-is
			webKitUserIcon = userIcon;
		}
		
		/*
		 * Writing the icon out is necessary for webkit to be able to use it; it also guarantees that there won't be
		 * any animation, which is good since animation in the message view is slow and annoying.
		 */
		webKitUserIconPath = [self _webKitUserIconPathForObject:inObject];
		if ([[webKitUserIcon TIFFRepresentation] writeToFile:webKitUserIconPath
												  atomically:YES]) {
			[inObject setStatusObject:webKitUserIconPath
							   forKey:KEY_WEBKIT_USER_ICON
							   notify:NO];
			
			//Make sure it's known that this user has been handled (this will rarely be a problem, if ever)
			if (![objectsWithUserIconsArray containsObjectIdenticalTo:inObject]) {
				[objectsWithUserIconsArray addObject:inObject];
			}
			
			DOMNodeList  *images = [[[webView mainFrame] DOMDocument] getElementsByTagName:@"img"];
			unsigned int imagesCount;

			if ((imagesCount = [images length])) {
				NSString	*internalObjectID = [inObject internalObjectID];

				for (int i = 0; i < imagesCount; i++) {
					DOMHTMLImageElement *img = (DOMHTMLImageElement *)[images item:i];
					if([[img getAttribute:@"src"] rangeOfString:internalObjectID].location != NSNotFound)
						[img setSrc:webKitUserIconPath];
				}
			}
		}
	}
}

/*!
 * @brief Returns the path to the list object's masked user icon
 */
- (NSString *)_webKitUserIconPathForObject:(AIListObject *)inObject
{
	NSString	*filename = [NSString stringWithFormat:@"TEMP-%@%@.tiff", [inObject internalObjectID], [NSString randomStringOfLength:5]];
	return [[adium cachesPath] stringByAppendingPathComponent:filename];
}

#pragma mark File Transfer

- (void)showFileTransferRequest:(NSNotification *)not
{
	ESFileTransferRequestPromptController *tc = (ESFileTransferRequestPromptController *)[[not userInfo] objectForKey:@"FileTransferRequestController"];
	ESFileTransfer *transfer = [tc fileTransfer];

	if (!fileTransferRequestControllers) fileTransferRequestControllers = [[NSMutableDictionary alloc] init];
	[fileTransferRequestControllers setObject:tc forKey:[transfer remoteFilename]];

	if ([transfer chat] == chat) {
		[self enqueueContentObject:transfer];
	}
}

- (void)cancelFileTransferRequest:(NSNotification *)not
{
	ESFileTransfer *e = (ESFileTransfer *)[not userInfo];
	[fileTransferRequestControllers removeObjectForKey:[e remoteFilename]];
}

- (void)handleAction:(NSString *)action forFileTransfer:(NSString *)fileName
{
	NSLog(@"%@ : %@", action, fileName);
	ESFileTransferRequestPromptController *tc = [fileTransferRequestControllers objectForKey:fileName];

	if (tc) {
		[fileTransferRequestControllers removeObjectForKey:fileName];
		
		AIFileTransferAction a;
		if ([action isEqualToString:@"SaveAs"])
			a = AISaveFileAs;
		else if ([action isEqualToString:@"Cancel"]) 
			a = AICancel;
		else
			a = AISaveFile;
		
		[tc handleFileTransferAction:a];
	}
}

#pragma mark JS Bridging
/*See http://developer.apple.com/documentation/AppleApplications/Conceptual/SafariJSProgTopics/Tasks/ObjCFromJavaScript.html#//apple_ref/doc/uid/30001215 for more information.
*/

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector
{
	if(aSelector == @selector(handleAction:forFileTransfer:)) return NO;
	if(aSelector == @selector(debugLog:)) return NO;
	if(aSelector == @selector(zoomImage:)) return NO;
	return YES;
}

/*
 * This method returns the name to be used in the scripting environment for the selector specified by aSelector.
 * It is your responsibility to ensure that the returned name is unique to the script invoking this method.
 * If this method returns nil or you do not implement it, the default name for the selector will be constructed as follows:
 *
 * Any colon (“:”)in the Objective-C selector is replaced by an underscore (“_”).
 * Any underscore in the Objective-C selector is prefixed with a dollar sign (“$”).
 * Any dollar sign in the Objective-C selector is prefixed with another dollar sign.
 */
+ (NSString *)webScriptNameForSelector:(SEL)aSelector
{
	if(aSelector == @selector(handleAction:forFileTransfer:)) return @"handleFileTransfer";
	if(aSelector == @selector(debugLog:)) return @"debugLog";
	if(aSelector == @selector(zoomImage:)) return @"zoomImage";
	return @"";
}

- (BOOL)zoomImage:(DOMHTMLImageElement *)img
{
	AILog(@"Zooming an image");
	NSMutableString *className = [[img className]mutableCopy];
	AILog(@"Class name is:%@", className);
	if([className rangeOfString:@"fullSizeImage"].location != NSNotFound)
		[className replaceOccurrencesOfString:@"fullSizeImage"
								   withString:@"scaledToFitImage"
									  options:NSLiteralSearch
										range:NSMakeRange(0, [className length])];
	else if([className rangeOfString:@"scaledToFitImage"].location != NSNotFound)
		[className replaceOccurrencesOfString:@"scaledToFitImage"
								   withString:@"fullSizeImage"
									  options:NSLiteralSearch
										range:NSMakeRange(0, [className length])];
	else return NO;
	
	[img setClassName:className];
	[[webView windowScriptObject] callWebScriptMethod:@"alignChat" withArguments:[NSArray arrayWithObject:[NSNumber numberWithBool:YES]]];
	return YES;
}

- (void)debugLog:(NSString *)message { AILog(message); }

@end
