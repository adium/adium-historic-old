//
//  ESWebKitMessageViewPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Apr 18 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "ESWebKitMessageViewPreferences.h"
#import "AIWebKitMessageViewPlugin.h"
#import "AIWebKitMessageViewController.h"

#define PREVIEW_FILE	@"Preview"

#define NO_BACKGROUND_ITEM_TITLE		AILocalizedString(@"No Image",nil)
#define DEFAULT_BACKGROUND_ITEM_TITLE   AILocalizedString(@"Default Image",nil)
#define CUSTOM_BACKGROUND_ITEM_TITLE	AILocalizedString(@"Custom...",nil)

#define	PREF_GROUP_DISPLAYFORMAT		@"Display Format"  //To watch when the contact name display format changes

@interface ESWebKitMessageViewPreferences (PRIVATE)
- (void)updatePreview;
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime;
- (void)_updateViewForStyle:(NSBundle *)style variant:(NSString *)variant;
- (void) _loadPreviewFromStylePath:(NSString *)inStylePath;
- (void)_createListObjectsFromDict:(NSDictionary *)previewDict withLoadedPreviewDirectory:(NSString *)loadedPreviewDirectory;
- (void)processNewContent;

- (NSMenu *)_stylesMenu;
- (NSMenu *)_customBackgroundMenu;
- (void)_buildFontMenus;
- (NSMenu *)_fontMenu;
- (NSMenu *)_fontSizeMenu;
- (NSMenu *)backgroundImageTypeMenu;
- (void)_buildTimeStampMenu;
- (void)_buildTimeStampMenu_AddFormat:(NSString *)format;
- (void)_updatePopupMenuSelectionsForStyle:(NSString *)styleName;

- (void)_configureChatPreview;
- (void)_fillContentOfChat:(AIChat *)inChat withDictionary:(NSDictionary *)previewDict fromPath:(NSString *)previewPath;
- (NSMutableDictionary *)_addParticipants:(NSDictionary *)participants toChat:(AIChat *)inChat fromPath:(NSString *)previewPath;
- (void)_applySettings:(NSDictionary *)chatDict toChat:(AIChat *)inChat withParticipants:(NSDictionary *)participants;
- (void)_addContent:(NSArray *)chatArray toChat:(AIChat *)inChat withParticipants:(NSDictionary *)participants;

- (void)updateBackgroundImageCache;

@end

@implementation ESWebKitMessageViewPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Messages);
}
- (NSString *)label{
    return(@"A");
}
- (NSString *)nibName{
    return(@"WebKitPreferencesView");
}

//Configure the preference view
- (void)viewDidLoad
{	
	previewListObjectsDict = nil;
	newContent = [[NSMutableArray alloc] init];
	
	//Configure our view
	[self _configureChatPreview];
	[self _buildTimeStampMenu];
	[fontPreviewField_currentFont setShowFontFace:NO];
	[fontPreviewField_currentFont setShowPointSize:YES];
	[popUp_minimumFontSize setMenu:[self _fontSizeMenu]];
	[popUp_backgroundImageType setMenu:[self backgroundImageTypeMenu]];
	
	[popUp_customBackground setMenu:[self _customBackgroundMenu]];
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
	
	//Observe preference changes and set our initial preferences
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_DISPLAYFORMAT];

	viewIsOpen = YES;
}

- (void)messageStyleXtrasDidChange
{
	if (viewIsOpen){
		NSDictionary *prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
		[popUp_styles setMenu:[self _stylesMenu]];
		
		[popUp_styles selectItemWithTitle:[prefDict objectForKey:KEY_WEBKIT_STYLE]];
		
//		[self preferencesChanged:nil];
	}
}


//Configure the chat preferences preview
- (void)_configureChatPreview
{
	NSDictionary	*previewDict;
	NSString		*previewFilePath;
	NSString		*previewPath;
	
	//Create our fake chat and message controller for the live preview
	previewChat = [[AIChat chatForAccount:nil] retain];
	[previewChat setName:@"Sample Conversation"];
	previewController = [[AIWebKitMessageViewController messageViewControllerForChat:previewChat
																		  withPlugin:plugin] retain];
	
	//Add fake users and content to our chat
	//	previewPath = [[stylePath stringByAppendingPathComponent:PREVIEW_FILE] stringByAppendingPathExtension:@"plist"];
	//	if([[NSFileManager defaultManager] fileExistsAtPath:previewPath]){
	//		previewDict = [NSDictionary dictionaryWithContentsOfFile:previewFilePath];
	//		previewPath = [previewFilePath retain];
	//	}else{
	previewFilePath = [[NSBundle bundleForClass:[self class]] pathForResource:PREVIEW_FILE ofType:@"plist"];
	previewDict = [[[NSDictionary alloc] initWithContentsOfFile:previewFilePath] autorelease];
	previewPath = [previewFilePath stringByDeletingLastPathComponent];
	//	}
	
	//Place the preview chat in our view
	preview = [[previewController messageView] retain];
	
	//Disable drag and drop onto the preview chat - Jeff doesn't need your porn :)
	if ([preview respondsToSelector:@selector(setAllowsDragAndDrop:)]){
		[(ESWebView *)preview setAllowsDragAndDrop:NO];
	}
	
	//Disable forwarding of events so the preferences responder chain works properly
	if([preview respondsToSelector:@selector(setShouldForwardEvents:)]){
		[(ESWebView *)preview setShouldForwardEvents:NO];		
	}
		
	[preview setFrame:[view_previewLocation frame]];
	[[view_previewLocation superview] replaceSubview:view_previewLocation with:preview];
	
	[self _fillContentOfChat:previewChat withDictionary:previewDict fromPath:previewPath];
}

//Close the preference view
- (void)viewWillClose
{
	viewIsOpen = NO;
	
	[[adium preferenceController] unregisterPreferenceObserver:self];
	
	[previewListObjectsDict release]; previewListObjectsDict = nil;
	[previousContent release]; previousContent = nil;
	[newContent release]; newContent = nil;
	[newContentTimer invalidate]; [newContentTimer release]; newContentTimer =nil;
}

- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if(!firstTime){
		[self updatePreview];
	}
}

#pragma mark Changing preferences
//Save changed preference
- (IBAction)changePreference:(id)sender
{
	[[adium preferenceController] delayPreferenceChangedNotifications:YES];

    if(sender == checkBox_showUserIcons){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_WEBKIT_SHOW_USER_ICONS
                                              group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
		
    }else if(sender == popUp_timeStamps){
        [[adium preferenceController] setPreference:[[popUp_timeStamps selectedItem] representedObject]
                                             forKey:KEY_WEBKIT_TIME_STAMP_FORMAT
                                              group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
		
	}else if (sender == popUp_minimumFontSize){
		[[preview preferences] setMinimumFontSize:[[popUp_minimumFontSize selectedItem] tag]];
		[self updatePreview];	
		
	}else if (sender == colorWell_customBackgroundColor){
		NSString	*key = [plugin backgroundColorKeyForStyle:[[popUp_styles selectedItem] title]];

		[[adium preferenceController] setPreference:[[colorWell_customBackgroundColor color] stringRepresentation]
                                             forKey:key
                                              group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
		
	}else if (sender == button_restoreDefaultBackgroundColor){
		NSString	*key = [plugin backgroundColorKeyForStyle:[[popUp_styles selectedItem] title]];
		
		[[adium preferenceController] setPreference:nil
                                             forKey:key
                                              group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
	}else if (sender == popUp_backgroundImageType){
		NSString	*key = [NSString stringWithFormat:@"%@:Type", [plugin backgroundKeyForStyle:[[popUp_styles selectedItem] title]]];
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:[[popUp_backgroundImageType selectedItem] tag]]
										 forKey:key
										  group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];	
		[self updateBackgroundImageCache];
		[self updatePreview];
	}

	[[adium preferenceController] delayPreferenceChangedNotifications:NO];
}


- (void)fontPreviewField:(JVFontPreviewField *)field didChangeToFont:(NSFont *)font
{
	[preview setFontFamily:[font fontName]];
	[[preview preferences] setDefaultFontSize:[font pointSize]];

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
	NSString	*variantKey = [plugin variantKeyForStyle:newStyleName];
	[[adium preferenceController] setPreference:([variant length] ? variant : nil)
										 forKey:variantKey
										  group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
	
	//Clicking a variant won't automatically change the popup's selected item, so manually ensure it is selected.
	[popUp_styles selectItemWithTitle:newStyleName];
	[self updateBackgroundImageCache];
	[self updatePreview];

	[[adium preferenceController] delayPreferenceChangedNotifications:NO];
}

- (IBAction)changeBackground:(id)sender
{
	NSString	*key = [plugin backgroundKeyForStyle:[[popUp_styles selectedItem] title]];
	NSString	*newPreference = nil;
	
	if ([sender tag] == CustomBackground){
		//Prompt the user for the file
		NSOpenPanel *openPanel = [NSOpenPanel openPanel];
		[openPanel setTitle:@"Select Background Image"];
		
		if ([openPanel runModalForTypes:[NSImage imageFileTypes]] == NSOKButton) {
			newPreference = [openPanel filename];
		}else{
			//If the user canceled, we don't want to continue to show the "Custom..." item as the selection in the popUp menu
			//if there is no custom background selected
			if ( !([[adium preferenceController] preferenceForKey:key
															group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY]) ){
				[popUp_customBackground selectItemAtIndex:[popUp_customBackground indexOfItemWithTag:DefaultBackground]];
			}
		}
		
	}else if ([sender tag] == NoBackground){
		//Use @"" to override style-specified backgrounds
		newPreference = @"";
	}

	[[adium preferenceController] setPreference:newPreference
										 forKey:key
										  group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];									
	[self updateBackgroundImageCache];
	[self updatePreview];
}


#pragma mark Preview WebView
- (void)updatePreview
{
	NSString		*styleName;
	NSString		*variant;
	NSBundle		*style;
	
	//Load the style as per preferences
	{
		styleName = [[adium preferenceController] preferenceForKey:KEY_WEBKIT_STYLE
															 group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
		style = [plugin messageStyleBundleWithName:styleName];

		//If the preferred style is unavailable, load the default
		if (!style){
			styleName = AILocalizedString(@"Mockie","Default message style name. Make sure this matches the localized style bundle's name!");
			style = [plugin messageStyleBundleWithName:styleName];
		}
	}

	//Load the variant
	variant = [[adium preferenceController] preferenceForKey:[plugin variantKeyForStyle:styleName]
													   group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
	//Set up the preferences for the style
	[self _updateViewForStyle:style variant:variant];
	
	[(AIWebKitMessageViewController *)previewController forceReload];
	
}
	
- (void)_updateViewForStyle:(NSBundle *)style variant:(NSString *)variant
{
	NSMenu		*submenu;
	
	//Check the proper variant, unchecking any old selection
	NSEnumerator	*enumerator = [[[popUp_styles menu] itemArray] objectEnumerator];
	NSMenuItem		*item;
	while(item = [enumerator nextObject]){
		if (submenu = [item submenu]){
			[submenu setAllMenuItemsToState:NSOffState];
		}
	}
	submenu = [[popUp_styles selectedItem] submenu];
	if (submenu){
		NSString	*variant = [[adium preferenceController] preferenceForKey:[plugin variantKeyForStyle:[style name]]
																		group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
		if ([variant length]){
			[[submenu itemWithTitle:variant] setState:NSOnState];
		}else{
			[[submenu itemAtIndex:0] setState:NSOnState];
		}
	}

	//Set the Show User Icons checkbox (enable/disable as needed, default to checked)
	BOOL showsUserIcons = [plugin boolForKey:@"ShowsUserIcons" style:style variant:variant boolDefault:YES];

	[checkBox_showUserIcons setState:(showsUserIcons ? 
									  [[[adium preferenceController] preferenceForKey:KEY_WEBKIT_SHOW_USER_ICONS
																				group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY] boolValue] : NSOffState)];
	[checkBox_showUserIcons setEnabled:showsUserIcons];
	
	//Setup the Custom Background dropdown (enable/disable as needed, default to "Default")
	BOOL disableCustomBackground = [plugin boolForKey:@"DisableCustomBackground" style:style variant:variant boolDefault:NO];
	
	NSString	*customBackground;
	int			tag;
	NSString	*tempKey = [NSString stringWithFormat:@"%@:Type", [plugin backgroundKeyForStyle:[[popUp_styles selectedItem] title]]];
	customBackground = (disableCustomBackground 
						? nil
						: [[adium preferenceController] preferenceForKey:[plugin backgroundKeyForStyle:[style name]]
																   group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY]);
	
	if (customBackground) {
		tag = (([customBackground length] > 1) ? CustomBackground : NoBackground);
	} else {
		tag = DefaultBackground;
	}
	[popUp_customBackground selectItemAtIndex:[popUp_customBackground indexOfItemWithTag:tag]];
	[popUp_customBackground setEnabled:!disableCustomBackground];
	[popUp_backgroundImageType selectItemAtIndex:[[popUp_backgroundImageType menu] indexOfItemWithTag:[[[adium preferenceController] preferenceForKey:tempKey
																				group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY] intValue]]];
	
	//Setup the Background Color colorwell (enabled/disable as needed, default to the color specified by the styl/variant or to white
	NSColor *backgroundColor;
	backgroundColor = [[[adium preferenceController] preferenceForKey:[plugin backgroundColorKeyForStyle:[style name]]
																group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY] representedColor];
	if (!backgroundColor){
		backgroundColor = [[style objectForInfoDictionaryKey:[NSString stringWithFormat:@"DefaultBackgroundColor:%@",variant]] hexColor];
		if (!backgroundColor){
			backgroundColor = [[style objectForInfoDictionaryKey:@"DefaultBackgroundColor"] hexColor];	
		}
	}
	[colorWell_customBackgroundColor setColor:(backgroundColor ? backgroundColor : [NSColor whiteColor])] ;
	[colorWell_customBackgroundColor setEnabled:!disableCustomBackground];
	[button_restoreDefaultBackgroundColor setEnabled:!disableCustomBackground];
	[popUp_backgroundImageType setEnabled:!disableCustomBackground];
	
	//Font menus
	NSFont		*font = [NSFont cachedFontWithName:[preview fontFamily]
											  size:[[preview preferences] defaultFontSize]];

	[fontPreviewField_currentFont setFont:font];
	[popUp_minimumFontSize selectItemAtIndex:[[popUp_minimumFontSize menu] indexOfItemWithTag:[[preview preferences] minimumFontSize]]];
}

- (void)updateBackgroundImageCache
{
	NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
	NSFileManager	*defaultManager = [NSFileManager defaultManager];
	NSString		*cachedBackgroundKey = [plugin cachedBackgroundKeyForStyle:[prefDict objectForKey:KEY_WEBKIT_STYLE]];

	NSString		*oldCachedBackgroundPath, *currentBackgroundPath;
	NSString		*newCachedBackgroundPath = nil;
	NSString		*newCachedFilename;
	NSNumber		*oldUniqueID, *uniqueID;
	
	//Get the path to where we were caching for this style before
	oldCachedBackgroundPath = [prefDict objectForKey:cachedBackgroundKey];
	
	//Delete the old file
	if(oldCachedBackgroundPath) [defaultManager removeFileAtPath:oldCachedBackgroundPath handler:nil];
	
	//Get the path to the background the user selected
	currentBackgroundPath = [prefDict objectForKey:[plugin backgroundKeyForStyle:[prefDict objectForKey:KEY_WEBKIT_STYLE]]];
	
	//Increment our uniqueID
	if(currentBackgroundPath && [currentBackgroundPath  length]){
		oldUniqueID = [prefDict objectForKey:@"BackgroundUniqueID"];
		uniqueID = [NSNumber numberWithInt:([oldUniqueID intValue]+1)];
		[[adium preferenceController] setPreference:uniqueID
											 forKey:@"BackgroundUniqueID"
											  group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
		
		//Now copy the selected file to our cache after adding the uniqueID to its file name
		newCachedFilename = [[currentBackgroundPath lastPathComponent] stringByAppendingString:[uniqueID stringValue]];
		newCachedBackgroundPath = [[adium cachesPath] stringByAppendingPathComponent:newCachedFilename];
		[defaultManager copyPath:currentBackgroundPath
						  toPath:newCachedBackgroundPath
						 handler:nil];
	}

	[[adium preferenceController] setPreference:newCachedBackgroundPath
										 forKey:cachedBackgroundKey
										  group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
}

#pragma mark Menus
-(NSMenu *)_fontSizeMenu
{
	NSMenu			*menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] init] autorelease];
	NSMenuItem		*menuItem;
	
	int sizes[] = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,18,20,22,24,36,48,64,72,96};
	int loopCounter;
	
	for (loopCounter = 0; loopCounter < 23; loopCounter++){
		menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[[NSNumber numberWithInt:sizes[loopCounter]] stringValue]
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
    BOOL        twentyFourHourTimeIsOff = (![noSecondsNoAMPM isEqualToString:noSecondsAMPM]);
	
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
    NSMenuItem      *menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:dateString 
																					  target:nil
																					  action:nil
																			   keyEquivalent:@""] autorelease];
    
    [menuItem setRepresentedObject:format];
    [[popUp_timeStamps menu] addItem:menuItem];
}

- (NSMenu *)_customBackgroundMenu
{
	NSMenu			*menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] init] autorelease];
	NSMenuItem		*menuItem;
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:NO_BACKGROUND_ITEM_TITLE
																	 target:self
																	 action:@selector(changeBackground:)
															  keyEquivalent:@""] autorelease];
	[menuItem setTag:NoBackground];
	[menu addItem:menuItem];
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:DEFAULT_BACKGROUND_ITEM_TITLE
																	 target:self
																	 action:@selector(changeBackground:)
															  keyEquivalent:@""] autorelease];
	[menuItem setTag:DefaultBackground];
	[menu addItem:menuItem];
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:CUSTOM_BACKGROUND_ITEM_TITLE
																	 target:self
																	 action:@selector(changeBackground:)
															  keyEquivalent:@""] autorelease];
	[menuItem setTag:CustomBackground];
	[menu addItem:menuItem];
	
	return menu;
}

- (NSMenu *)_stylesMenu
{
	NSEnumerator	*enumerator = [[[[plugin availableStyleDictionary] allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] objectEnumerator];
	NSString		*styleName;
	
	NSMenu			*menu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""] autorelease];
	
	while (styleName = [enumerator nextObject]){
		//Create and add the menu item for this style
		NSMenuItem		*menuItem;
		
		menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:styleName target:self action:@selector(changeStyle:) keyEquivalent:@""] autorelease];
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
					subMenu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""] autorelease];
					
					//Add the No Variant menu item
					NSString		*noVariantName = [style objectForInfoDictionaryKey:@"DisplayNameForNoVariant"];
					if (!noVariantName){
						noVariantName = AILocalizedString(@"Normal","Normal style variant menu item");
					}
					subMenuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:noVariantName 
																						target:self
																						action:@selector(changeStyle:)
																				 keyEquivalent:@""] autorelease];
					[subMenuItem setRepresentedObject:[NSDictionary dictionaryWithObjectsAndKeys:styleName, @"styleName", @"", @"variant",nil]];
					[subMenu addItem:subMenuItem];
				}
				
				variant = [[variant lastPathComponent] stringByDeletingPathExtension];
				subMenuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:variant
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

- (NSMenu *)backgroundImageTypeMenu
{
	NSMenu			*backgroundImageTypeMenu = [[[NSMenu allocWithZone:[NSMenu menuZone]] init] autorelease];
	NSMenuItem		*menuItem;
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Fill",nil)
																	 target:nil
																	 action:nil
															  keyEquivalent:@""] autorelease];
	[menuItem setTag:Fill];
	[backgroundImageTypeMenu addItem:menuItem];
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Tile",nil)
																	 target:nil
																	 action:nil
															  keyEquivalent:@""] autorelease];
	[menuItem setTag:Tile];
	[backgroundImageTypeMenu addItem:menuItem];
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Do Not Stretch",nil)
																	 target:nil
																	 action:nil
															  keyEquivalent:@""] autorelease];
	[menuItem setTag:NoStretch];
	[backgroundImageTypeMenu addItem:menuItem];
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Center",nil)
																	 target:nil
																	 action:nil
															  keyEquivalent:@""] autorelease];
	[menuItem setTag:Center];
	[backgroundImageTypeMenu addItem:menuItem];
	
	return backgroundImageTypeMenu;
}


//Fake Conversation ----------------------------------------------------------------------------------------------------
#pragma mark Fake Conversation
//Fill the content of the specified chat using content archived in the dictionary
- (void)_fillContentOfChat:(AIChat *)inChat withDictionary:(NSDictionary *)previewDict fromPath:(NSString *)previewPath
{
	NSDictionary		*listObjects;
	
	//Process and create all participants
	listObjects = [self _addParticipants:[previewDict objectForKey:@"Participants"]
								  toChat:inChat fromPath:previewPath];
	
	//Setup the chat, and its source/destination
	[self _applySettings:[previewDict objectForKey:@"Chat"]
				  toChat:inChat withParticipants:listObjects];
	
	//Add the archived chat content
	[self _addContent:[previewDict objectForKey:@"Preview Messages"]
			   toChat:inChat withParticipants:listObjects];
}

//Add participants
- (NSMutableDictionary *)_addParticipants:(NSDictionary *)participants toChat:(AIChat *)inChat fromPath:(NSString *)previewPath
{
	NSMutableDictionary	*listObjectDict = [NSMutableDictionary dictionary];
	NSEnumerator		*enumerator = [participants objectEnumerator];
	NSDictionary		*participant;
	AIService			*aimService = [[adium accountController] firstServiceWithServiceID:@"AIM"];
	
	while(participant = [enumerator nextObject]){
		NSString		*UID, *alias, *userIconName;
		AIListObject	*listObject;
		
		//Create object
		UID = [participant objectForKey:@"UID"];
		listObject = [[[AIListObject alloc] initWithUID:UID service:aimService] autorelease];
		
		//Display name
		if(alias = [participant objectForKey:@"Display Name"]){
			[[adium notificationCenter] postNotificationName:Contact_ApplyDisplayName
													  object:listObject
													userInfo:[NSDictionary dictionaryWithObject:alias forKey:@"Alias"]];
		}
		
		//User icon
		if(userIconName = [participant objectForKey:@"UserIcon Name"]){
			[listObject setStatusObject:[previewPath stringByAppendingPathComponent:[participant objectForKey:@"UserIcon Name"]]
								 forKey:@"UserIconPath"
								 notify:YES];
		}
		
		[listObjectDict setObject:listObject forKey:UID];
	}
	
	return(listObjectDict);
}

//Chat settings
- (void)_applySettings:(NSDictionary *)chatDict toChat:(AIChat *)inChat withParticipants:(NSDictionary *)participants
{
	NSString			*dateOpened, *type, *name, *UID;
	
	//Date opened
	if(dateOpened = [chatDict objectForKey:@"Date Opened"]){
		[inChat setDateOpened:[NSDate dateWithNaturalLanguageString:dateOpened]];
	}
	
	//Source/Destination
	type = [chatDict objectForKey:@"Type"];
	if([type isEqualToString:@"IM"]){
		if(UID = [chatDict objectForKey:@"Destination UID"]){
			[inChat addParticipatingListObject:[participants objectForKey:UID]];
		}
		if(UID = [chatDict objectForKey:@"Source UID"]){
			[inChat setAccount:(AIAccount *)[participants objectForKey:UID]];
		}
	}else{
		if(name = [chatDict objectForKey:@"Name"]) [inChat setName:name];
	}
	
	//We don't want the interface controller to try to open this fake chat
	[inChat setIsOpen:YES];
}

//Chat content
- (void)_addContent:(NSArray *)chatArray toChat:(AIChat *)inChat withParticipants:(NSDictionary *)participants
{
	NSEnumerator		*enumerator;
	NSDictionary		*messageDict;
	
	enumerator = [chatArray objectEnumerator];
	while(messageDict = [enumerator nextObject]){
		AIContentObject		*content = nil;
		AIListObject		*source;
		NSString			*from, *msgType;
		NSAttributedString  *message;
		
		msgType = [messageDict objectForKey:@"Type"];
		from = [messageDict objectForKey:@"From"];

		source = (from ? [participants objectForKey:from] : nil);

		if([msgType isEqualToString:CONTENT_MESSAGE_TYPE]){
			//Create message content object
			AIListObject		*dest;
			NSString			*to;
			BOOL				outgoing;
			
			message = [NSAttributedString stringWithData:[messageDict objectForKey:@"Message"]];
			to = [messageDict objectForKey:@"To"];
			outgoing = [[messageDict objectForKey:@"Outgoing"] boolValue];
			
			//The other person is always the one we're chatting with right now
			dest = [participants objectForKey:to];
			content = [AIContentMessage messageInChat:inChat
										   withSource:source
										  destination:dest
												 date:[NSDate dateWithNaturalLanguageString:[messageDict objectForKey:@"Date"]]
											  message:message
											autoreply:[[messageDict objectForKey:@"Autoreply"] boolValue]];
			
			//AIContentMessage won't know whether the message is outgoing unless we tell it since neither our source
			//nor our destination are AIAccount objects.
			[content _setIsOutgoing:outgoing];

		}else if([msgType isEqualToString:CONTENT_STATUS_TYPE]){
			//Create status content object
			NSString			*statusMessageType;
			
			message = [[[NSAttributedString alloc] initWithString:[messageDict objectForKey:@"Message"]
													   attributes:[[adium contentController] defaultFormattingAttributes]] autorelease];
			statusMessageType = [messageDict objectForKey:@"Status Message Type"];
			
			//Create our content object
			content = [AIContentStatus statusInChat:inChat
										 withSource:source
										destination:nil
											   date:[NSDate dateWithNaturalLanguageString:[messageDict objectForKey:@"Date"]]
											message:message
										   withType:statusMessageType];
		}

		if(content){			
			[content setTrackContent:NO];
			[content setPostProcessContent:NO];
			
			[[adium contentController] displayContentObject:content];
		}
	}
}


@end
