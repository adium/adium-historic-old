//
//  ESWebKitMessageViewPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Apr 18 2004.
//

#import "ESWebKitMessageViewPreferences.h"
#import "AIWebKitMessageViewPlugin.h"

#define PREVIEW_FILE	@"Preview"

@interface ESWebKitMessageViewPreferences (PRIVATE)
- (void)updatePreview;
- (void) _loadPreviewFromStylePath:(NSString *)inStylePath;
- (void)_createListObjectsFromDict:(NSDictionary *)previewDict withLoadedPreviewDirectory:(NSString *)loadedPreviewDirectory;
- (void)processNewContent;

- (NSMenu *)_stylesMenu;
- (void)_buildFontMenus;
- (NSMenu *)_fontMenu;
- (NSMenu *)_fontSizeMenu;
- (void)_buildTimeStampMenu;
- (void)_buildTimeStampMenu_AddFormat:(NSString *)format;
- (void)_updatePopupMenuSelectionsForStyle:(NSString *)styleName;

- (void)_createPreviewConversationFromChatDict:(NSDictionary *)chatDict;
@end

@implementation ESWebKitMessageViewPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Messages_Display);
}
- (NSString *)label{
    return(@"Message Display");
}
- (NSString *)nibName{
    return(@"WebKitPreferencesView");
}

//Configure the preference view
- (void)viewDidLoad
{	
	stylePath = nil;
	previewListObjectsDict = nil;
	newContent = [[NSMutableArray alloc] init];
	
	[preview setFrameLoadDelegate:self];
	[preview setPolicyDelegate:self];
	[preview setUIDelegate:self];
	[preview setMaintainsBackForwardList:NO];
	
	[self _buildTimeStampMenu];
	[self _buildFontMenus];
	[popUp_styles setMenu:[self _stylesMenu]];
	
	{
		NSDictionary *prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
		
		[checkBox_showUserIcons setState:[[prefDict objectForKey:KEY_WEBKIT_SHOW_USER_ICONS] boolValue]];
		
		[popUp_timeStamps selectItemWithRepresentedObject:[prefDict objectForKey:KEY_WEBKIT_TIME_STAMP_FORMAT]];
		if (![popUp_timeStamps selectedItem]){
			[popUp_timeStamps selectItem:[popUp_timeStamps lastItem]];
		}
		
		[popUp_styles selectItemWithTitle:[prefDict objectForKey:KEY_WEBKIT_STYLE]];
	}

	[self updatePreview];
}

//Close the preference view
- (void)viewWillClose
{
    [[adium notificationCenter] removeObserver:self];
	[previewListObjectsDict release]; previewListObjectsDict = nil;
}


#pragma mark Changing preferences
//Save changed preference
- (IBAction)changePreference:(id)sender
{
    if(sender == checkBox_showUserIcons){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_WEBKIT_SHOW_USER_ICONS
                                              group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
		
    }else if(sender == popUp_timeStamps){
        [[adium preferenceController] setPreference:[[popUp_timeStamps selectedItem] representedObject]
                                             forKey:KEY_WEBKIT_TIME_STAMP_FORMAT
                                              group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
	}else if (sender == popUp_font){
		[preview setFontFamily:[[popUp_font selectedItem] representedObject]];
		
	}else if (sender == popUp_fontSize){
		[[preview preferences] setDefaultFontSize:[[popUp_fontSize selectedItem] tag]];
		
	}else if (sender == popUp_minimumFontSize){
		[[preview preferences] setMinimumFontSize:[[popUp_minimumFontSize selectedItem] tag]];
		
	}
	
	[self updatePreview];
}

- (IBAction)changeStyle:(id)sender
{
	[[adium preferenceController] delayPreferenceChangedNotifications:YES];
	
	NSDictionary *newStyleDict = [sender representedObject];
	
	NSString	*newStyleName = [newStyleDict objectForKey:@"styleName"];
	[[adium preferenceController] setPreference:newStyleName
										 forKey:KEY_WEBKIT_STYLE
										  group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
	
	//If we were passed a variant as well, we want to change the variant preference for this style.
	//A variant of @"" indicates the user selected the normal view.
	//A variant of nil means that the user selected the menu item (rather than a submenu item); we should therefore
	//leave the variant preference alone - this will let the previously selected variant be selected automatically
	NSString	*variant = [newStyleDict objectForKey:@"variant"];
	if (variant){
		NSString	*variantKey = [plugin keyForDesiredVariantOfStyle:newStyleName];
		[[adium preferenceController] setPreference:([variant length] ? variant : nil)
											 forKey:variantKey
											  group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
		
		//Clicking a variant won't automatically change the popup's selected item, so change it manually.
		[popUp_styles selectItemWithTitle:newStyleName];
	}

	[self updatePreview];

	[[adium preferenceController] delayPreferenceChangedNotifications:NO];
}

#pragma mark Menus
- (void)_buildFontMenus
{
	[popUp_font setMenu:[self _fontMenu]];	
	[popUp_fontSize setMenu:[self _fontSizeMenu]];
	[popUp_minimumFontSize setMenu:[self _fontSizeMenu]];
}

-(NSMenu *)_fontMenu
{
	NSMenu			*menu = [[[NSMenu alloc] init] autorelease];
	NSMenuItem		*menuItem;
	
	NSArray			*availableFamilies = [[[NSFontManager sharedFontManager] availableFontFamilies] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	NSEnumerator	*enumerator = [availableFamilies objectEnumerator];
	NSString		*fontFamilyName;
	
	while (fontFamilyName = [enumerator nextObject]){
		menuItem = [[[NSMenuItem alloc] initWithTitle:fontFamilyName 
											   target:nil
											   action:nil
										keyEquivalent:@""] autorelease];
		[menuItem setRepresentedObject:fontFamilyName];
		[menu addItem:menuItem];
	}
	
	return menu;
}

-(NSMenu *)_fontSizeMenu
{
	NSMenu			*menu = [[[NSMenu alloc] init] autorelease];
	NSMenuItem		*menuItem;
	
	int sizes[] = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,18,20,22,24,36,48,64,72,96};
	int loopCounter;
	
	for (loopCounter = 0; loopCounter < 23; loopCounter++){
		menuItem = [[[NSMenuItem alloc] initWithTitle:[[NSNumber numberWithInt:sizes[loopCounter]] stringValue]
											   target:nil
											   action:nil
										keyEquivalent:@""] autorelease];
		[menuItem setTag:sizes[loopCounter]];
		[menu addItem:menuItem];
	}
	
	return menu;
}

//Build the time stamp selection menu
- (void)_buildTimeStampMenu
{
    //Empty the menu
    [popUp_timeStamps removeAllItems];
    
    //Add the available time stamp formats
    NSString    *noSecondsNoAMPM = [NSDateFormatter localizedDateFormatStringShowingSeconds:NO showingAMorPM:NO];
    NSString    *noSecondsAMPM = [NSDateFormatter localizedDateFormatStringShowingSeconds:NO showingAMorPM:YES];
    BOOL        twentyFourHourTimeIsOff = ([noSecondsNoAMPM compare:noSecondsAMPM] != 0);
	
    [self _buildTimeStampMenu_AddFormat:noSecondsNoAMPM];
    if (twentyFourHourTimeIsOff)
        [self _buildTimeStampMenu_AddFormat:noSecondsAMPM];
    [self _buildTimeStampMenu_AddFormat:[NSDateFormatter localizedDateFormatStringShowingSeconds:YES showingAMorPM:NO]];
    if (twentyFourHourTimeIsOff)
        [self _buildTimeStampMenu_AddFormat:[NSDateFormatter localizedDateFormatStringShowingSeconds:YES showingAMorPM:YES]];
}

//Add time stamp format to the menu
- (void)_buildTimeStampMenu_AddFormat:(NSString *)format
{
    //Create the menu item
    NSDateFormatter *stampFormatter = [[[NSDateFormatter alloc] initWithDateFormat:format allowNaturalLanguage:NO] autorelease];
    NSString        *dateString = [stampFormatter stringForObjectValue:[NSDate date]];
    NSMenuItem      *menuItem = [[[NSMenuItem alloc] initWithTitle:dateString target:nil action:nil keyEquivalent:@""] autorelease];
    
    [menuItem setRepresentedObject:format];
    [[popUp_timeStamps menu] addItem:menuItem];
}

- (NSMenu *)_stylesMenu
{
	NSEnumerator	*enumerator = [[[[plugin availableStyleDictionary] allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] objectEnumerator];
	NSString		*styleName;

	NSMenu			*menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
	
	while (styleName = [enumerator nextObject]){
		//Create and add the menu item for this style
		NSMenuItem		*menuItem;
				
		menuItem = [[[NSMenuItem alloc] initWithTitle:styleName target:self action:@selector(changeStyle:) keyEquivalent:@""] autorelease];
		[menuItem setRepresentedObject:[NSDictionary dictionaryWithObjectsAndKeys:styleName, @"styleName", nil]];
		[menu addItem:menuItem];
		
		//If variants exist, we need to create and set a submenu
		NSBundle		*style = [plugin messageStyleBundleWithName:styleName];			
		NSArray			*variantsArray = [style pathsForResourcesOfType:@"css" inDirectory:@"Variants"];
		
		if([variantsArray count]) {
			NSEnumerator	*variantsEnumerator;
			NSString		*variant;
			NSMenu			*subMenu = nil;
			NSMenuItem		*subMenuItem;
						
			variantsEnumerator = [variantsArray objectEnumerator];
			while (variant = [variantsEnumerator nextObject]){
				
				//Generate the subMenu if it does not yet exist
				if (!subMenu){
					subMenu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
					
					//Add the No Variant menu item
					NSString		*noVariantName = [style objectForInfoDictionaryKey:@"DisplayNameForNoVariant"];
					if (!noVariantName){
						noVariantName = AILocalizedString(@"Normal","Normal style variant menu item");
					}
					subMenuItem = [[[NSMenuItem alloc] initWithTitle:noVariantName 
															  target:self
															  action:@selector(changeStyle:)
													   keyEquivalent:@""] autorelease];
					[subMenuItem setRepresentedObject:[NSDictionary dictionaryWithObjectsAndKeys:styleName, @"styleName", @"", @"variant",nil]];
					[subMenu addItem:subMenuItem];
				}
				
				variant = [[variant lastPathComponent] stringByDeletingPathExtension];
				subMenuItem = [[[NSMenuItem alloc] initWithTitle:variant
														  target:self
														  action:@selector(changeStyle:) 
												   keyEquivalent:@""] autorelease];
				[subMenuItem setRepresentedObject:[NSDictionary dictionaryWithObjectsAndKeys:styleName, @"styleName", variant, @"variant", nil]];
				[subMenu addItem:subMenuItem];
			}
			
			//If we generated a subMenu, set it and then clear the variable for the next pass through the loop
			if (subMenu){
				[menuItem setSubmenu:subMenu];
				subMenu = nil;
			}
		}
	}
	
	return menu;
}

- (void)_updatePopupMenuSelectionsForStyle:(NSString *)styleName
{
	NSMenu		*submenu;
	
	[popUp_font selectItemWithTitle:[preview fontFamily]];
	[popUp_fontSize selectItemAtIndex:[[popUp_fontSize menu] indexOfItemWithTag:[[preview preferences] defaultFontSize]]];
	[popUp_minimumFontSize selectItemAtIndex:[[popUp_minimumFontSize menu] indexOfItemWithTag:[[preview preferences] minimumFontSize]]];
	
	NSEnumerator	*enumerator = [[[popUp_styles menu] itemArray] objectEnumerator];
	NSMenuItem		*item;
	while(item = [enumerator nextObject]){
		if (submenu = [item submenu]){
			[submenu setAllMenuItemsToState:NSOffState];
		}
	}
	
	submenu = [[popUp_styles selectedItem] submenu];
	if (submenu){
		NSString	*variant = [[adium preferenceController] preferenceForKey:[plugin keyForDesiredVariantOfStyle:styleName]
																   group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
		if ([variant length]){
			[[submenu itemWithTitle:variant] setState:NSOnState];
		}else{
			[[submenu itemAtIndex:0] setState:NSOnState];
		}
	}
}

#pragma mark Preview WebView
- (void)updatePreview
{
	NSString		*basePath, *headerHTML, *footerHTML, *templateHTML;
	NSString		*styleName, *CSS;
	NSBundle		*style;
	NSString		*loadedPreviewDirectory = nil;
	NSDictionary	*previewDict;
	AIChat			*chat;
	
	//We aren't ready for that kind of commitment yet...
	webViewIsReady = NO;
	
	//Load the style as per preferences
	{
		styleName = [[adium preferenceController] preferenceForKey:KEY_WEBKIT_STYLE
															 group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
		[stylePath release];
		style = [plugin messageStyleBundleWithName:styleName];

		//If the preferred style is unavailable, load Smooth Operator
		if (!style){
			styleName = AILocalizedString(@"Smooth Operator","Smooth Operator message style name. Make sure this matches the localized Smooth Operator style bundle's name!");
			style = [plugin messageStyleBundleWithName:styleName];
		}
		
		//Load preferences for the style and update the popup menus
		[plugin loadPreferencesForWebView:preview withStyleNamed:styleName];
		[self _updatePopupMenuSelectionsForStyle:styleName];

		//Retain the stylePath
		stylePath = [[style resourcePath] retain];
	}
	
	//Load the preview from the style if possible; otherwise use the bundle's own preview.plist
	{
		NSString		*previewFilePath;
		
		previewFilePath = [[stylePath stringByAppendingPathComponent:PREVIEW_FILE] stringByAppendingPathExtension:@"plist"];
		
		if([[NSFileManager defaultManager] fileExistsAtPath:previewFilePath]){
			previewDict = [NSDictionary dictionaryWithContentsOfFile:previewFilePath];
			loadedPreviewDirectory = stylePath;
		}else{
			previewDict = [NSDictionary dictionaryNamed:PREVIEW_FILE forClass:[self class]];
			loadedPreviewDirectory = [[[NSBundle bundleForClass:[self class]] pathForResource:PREVIEW_FILE 
																					   ofType:@"plist"] stringByDeletingLastPathComponent];
		}
		//Create the AIListObjects we will need, putting them into previewListObjectsDict 
		[self _createListObjectsFromDict:previewDict withLoadedPreviewDirectory:loadedPreviewDirectory];
	}
	
	//Load the variant
	{
		NSString *desiredVariant;
		
		desiredVariant = [[adium preferenceController] preferenceForKey:[plugin keyForDesiredVariantOfStyle:styleName]
																  group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
		CSS = (desiredVariant ? [NSString stringWithFormat:@"Variants/%@.css",desiredVariant] : @"main.css");
	}
	

	//Create and set up our temporary chat for filling keywords in headerHTML and footerHTML
	{
		NSDictionary	*chatDict = [previewDict objectForKey:@"Chat"];
		NSString		*type = [chatDict objectForKey:@"Type"];

		chat = [AIChat chatForAccount:nil initialStatusDictionary:nil];
		
		if ([type isEqualToString:@"IM"]){
			NSString *UID;
			if (UID = [chatDict objectForKey:@"Destination UID"]){
				[chat addParticipatingListObject:[previewListObjectsDict objectForKey:UID]];
			}
			if (UID = [chatDict objectForKey:@"Source UID"]){
				[chat setAccount:(AIAccount *)[previewListObjectsDict objectForKey:UID]];
			}
		}else{
			NSString *name;
			if (name = [chatDict objectForKey:@"Name"]){
				[chat setName:name];
			}
		}

		NSString	*dateOpened;
		if (dateOpened = [chatDict objectForKey:@"Date Opened"]){
			[chat setDateOpened:[NSDate dateWithNaturalLanguageString:dateOpened]];
		}
	}

	//Load the template, and fill it up
	{
		basePath = [[NSURL fileURLWithPath:stylePath] absoluteString];	
		headerHTML = [NSString stringWithContentsOfFile:[stylePath stringByAppendingPathComponent:@"Header.html"]];
		headerHTML = [plugin fillKeywords:[[headerHTML mutableCopy] autorelease] forChat:chat];
						
		footerHTML = [NSString stringWithContentsOfFile:[stylePath stringByAppendingPathComponent:@"Footer.html"]];
		footerHTML = [plugin fillKeywords:[[footerHTML mutableCopy] autorelease] forChat:chat];
						
		templateHTML = [NSString stringWithContentsOfFile:[stylePath stringByAppendingPathComponent:@"Template.html"]];
		templateHTML = [NSString stringWithFormat:templateHTML, basePath, CSS, headerHTML, footerHTML];
	}
	
	//Feed it to the webview
	[[preview mainFrame] loadHTMLString:templateHTML baseURL:nil];
	
	//Load and display the desired content objects
	[self _createPreviewConversationFromChatDict:[previewDict objectForKey:@"Preview Messages"]];
}

//Take the fake conversation contained in chatDict and send it to our webView
- (void)_createPreviewConversationFromChatDict:(NSDictionary *)chatDict
{
	NSDictionary		*messageDict;
	int					cnt;
	NSString			*type;
	AIContentContext	*responseContent;
	AIListObject		*source, *dest;
	
	cnt = [chatDict count];
	//Add messages until: we add our max (linesToDisplay) OR we run out of saved messages
	while( (messageDict = [chatDict objectForKey:[[NSNumber numberWithInt:cnt] stringValue]]) && cnt > 0 ) {
		cnt--;
		type = [messageDict objectForKey:@"Type"];		
		responseContent = nil;
		
		if([type isEqualToString:CONTENT_MESSAGE_TYPE]) {
			//Create message content object
			NSAttributedString  *message =[NSAttributedString stringWithData:[messageDict objectForKey:@"Message"]];
			BOOL				outgoing = [[messageDict objectForKey:@"Outgoing"] boolValue];
			NSString			*from = [messageDict objectForKey:@"From"];
			NSString			*to = [messageDict objectForKey:@"To"];
			
			// The other person is always the one we're chatting with right now
			dest = [previewListObjectsDict objectForKey:to];
			source =  [previewListObjectsDict objectForKey:from];
			
			responseContent = [AIContentMessage messageInChat:nil
												   withSource:source
												  destination:dest
														 date:[NSDate dateWithNaturalLanguageString:[messageDict objectForKey:@"Date"]]
													  message:message
													autoreply:[[messageDict objectForKey:@"Autoreply"] boolValue]];
			//AIContentMessage won't know whether the message is outgoing unless we tell it since neither our source
			//nor our destination are AIAccount objects.
			[responseContent _setIsOutgoing:outgoing];
			
		}else if ([type isEqualToString:CONTENT_STATUS_TYPE]){
			//Create status content object
			NSString	*message = [messageDict objectForKey:@"Message"];
			NSString	*statusMessageType = [messageDict objectForKey:@"Status Message Type"];
			
			NSString	*from = [messageDict objectForKey:@"From"];
			source = (from ? [previewListObjectsDict objectForKey:from] : nil);
			
			//Create our content object
			responseContent = [AIContentStatus statusInChat:nil
												 withSource:source
												destination:nil
													   date:[NSDate dateWithNaturalLanguageString:[messageDict objectForKey:@"Date"]]
													message:message
												   withType:statusMessageType];
		}
		
		if (responseContent){
			[newContent addObject:responseContent];
		}
	}
	
	[self processNewContent];
}

- (void)processNewContent
{
	while(webViewIsReady && [newContent count]){
		AIContentObject *content = [newContent objectAtIndex:0];
		
		[plugin processContent:content withPreviousContent:previousContent forWebView:preview fromStylePath:stylePath];
		
		//
		[previousContent release];
		previousContent = [content retain];
		
		//de-queue
		[newContent removeObjectAtIndex:0];
	}
	
	//cleanup previous 
	if(newContentTimer){
		[newContentTimer invalidate]; [newContentTimer release];
		newContentTimer = nil;
	}
	
	//if not added, Try to add this content again in a little bit
	if([newContent count]){
		newContentTimer = [[NSTimer scheduledTimerWithTimeInterval:NEW_CONTENT_RETRY_DELAY
															target:self
														  selector:@selector(processNewContent)
														  userInfo:nil
														   repeats:NO] retain]; 
	}
}

- (void)_createListObjectsFromDict:(NSDictionary *)previewDict withLoadedPreviewDirectory:(NSString *)loadedPreviewDirectory
{
	//Create AIListObjects 
	NSEnumerator	*enumerator = [[previewDict objectForKey:@"Participants"] objectEnumerator];
	NSDictionary	*participant;
	
	[previewListObjectsDict release]; previewListObjectsDict = [[NSMutableDictionary alloc] init];
	while (participant = [enumerator nextObject]){
		AIListObject	*listObject;
		NSString		*UID =[participant objectForKey:@"UID"];
		
		listObject = [[[AIListObject alloc] initWithUID:UID
											  serviceID:@"AIM"] autorelease];
		
		//Display name
		[[listObject displayArrayForKey:@"Display Name"] setObject:[participant objectForKey:@"Display Name"] 
														 withOwner:self];
		
		//User icon
		NSString	*userIconName = [participant objectForKey:@"UserIcon Name"];
		if (userIconName){
			[listObject setStatusObject:[loadedPreviewDirectory stringByAppendingPathComponent:[participant objectForKey:@"UserIcon Name"]]
								 forKey:@"UserIconPath"
								 notify:YES];
		}
		[previewListObjectsDict setObject:listObject forKey:UID];
	}
}

#pragma mark WebFrameLoadDelegate
//----WebFrameLoadDelegate
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	webViewIsReady = YES;
}

#pragma mark WebPolicyDelegate
- (void) webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation
		 request:(NSURLRequest *)request frame:(WebFrame *) frame
		decisionListener:(id <WebPolicyDecisionListener>) listener {

	if([[[actionInformation objectForKey:WebActionOriginalURLKey] scheme] isEqualToString:@"about"]  ) {
		[listener use];
	} else {
		NSURL *url = [actionInformation objectForKey:WebActionOriginalURLKey];
		[[NSWorkspace sharedWorkspace] openURL:url];	
		[listener ignore];
	}
}

@end
