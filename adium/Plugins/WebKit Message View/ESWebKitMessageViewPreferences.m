//
//  ESWebKitMessageViewPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Apr 18 2004.
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
- (void)preferencesChanged:(NSNotification *)notification;
- (void)_updateViewForStyle:(NSBundle *)style variant:(NSString *)variant;
- (void) _loadPreviewFromStylePath:(NSString *)inStylePath;
- (void)_createListObjectsFromDict:(NSDictionary *)previewDict withLoadedPreviewDirectory:(NSString *)loadedPreviewDirectory;
- (void)processNewContent;

- (NSMenu *)_stylesMenu;
- (NSMenu *)_customBackgroundMenu;
- (void)_buildFontMenus;
- (NSMenu *)_fontMenu;
- (NSMenu *)_fontSizeMenu;
- (void)_buildTimeStampMenu;
- (void)_buildTimeStampMenu_AddFormat:(NSString *)format;
- (void)_updatePopupMenuSelectionsForStyle:(NSString *)styleName;

- (void)_configureChatPreview;
- (void)_fillContentOfChat:(AIChat *)inChat withDictionary:(NSDictionary *)previewDict fromPath:(NSString *)previewPath;
- (NSMutableDictionary *)_addParticipants:(NSDictionary *)participants toChat:(AIChat *)inChat fromPath:(NSString *)previewPath;
- (void)_applySettings:(NSDictionary *)chatDict toChat:(AIChat *)inChat withParticipants:(NSDictionary *)participants;
- (void)_addContent:(NSDictionary *)chatDict toChat:(AIChat *)inChat withParticipants:(NSDictionary *)participants;



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
	[[adium notificationCenter] addObserver:self 
								   selector:@selector(preferencesChanged:)
									   name:Preference_GroupChanged
									 object:nil];
	[self preferencesChanged:nil];
}


//Configure the chat preferences preview
- (void)_configureChatPreview
{
	NSDictionary	*previewDict;
	NSString		*previewFilePath;
	NSString		*previewPath;
	
	//Create our fake chat and message controller for the live preview
	previewChat = [[AIChat chatForAccount:nil initialStatusDictionary:nil] retain];
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
	previewPath = [[previewFilePath stringByDeletingLastPathComponent] retain];
	//	}
	[self _fillContentOfChat:previewChat withDictionary:previewDict fromPath:previewPath];
	
	//Place the preview chat in our view
	preview = [[previewController messageView] retain];
	[preview setFrame:[view_previewLocation frame]];
	[[view_previewLocation superview] replaceSubview:view_previewLocation with:preview];
}

//Close the preference view
- (void)viewWillClose
{
    [[adium notificationCenter] removeObserver:self];
	
	//Stop being the webView's baby's daddy; the webView may attempt callbacks shortly after we close
	[preview setFrameLoadDelegate:nil];
	[preview setPolicyDelegate:nil];
	[preview setUIDelegate:nil];
	
	[previewListObjectsDict release]; previewListObjectsDict = nil;
	[previousContent release]; previousContent = nil;
	[newContent release]; newContent = nil;
	[newContentTimer invalidate]; [newContentTimer release]; newContentTimer =nil;
}

- (void)preferencesChanged:(NSNotification *)notification
{
	if(notification == nil ||
	   [(NSString *)[[notification userInfo] objectForKey:@"Group"] isEqualToString:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY] ||
	   [(NSString *)[[notification userInfo] objectForKey:@"Group"] isEqualToString:PREF_GROUP_DISPLAYFORMAT]){

		[self updatePreview];
	}
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
	}
}


- (void)fontPreviewField:(JVFontPreviewField *)field didChangeToFont:(NSFont *)font
{
//	[[adium preferenceController] setPreference:[contactListFont stringRepresentation] forKey:KEY_FORMATTING_FONT group:PREF_GROUP_FORMATTING];

	
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
		//Use @"A" since there's no way that would be a file name but we need something that isn't just whitespace to
		//override style-specified backgrounds
		newPreference = @"A";
	}

	[[adium preferenceController] setPreference:newPreference
										 forKey:key
										  group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];	
	
	[self updatePreview];
}

#pragma mark Preview WebView
- (void)updatePreview
{
	NSString		*styleName, *CSS;
	NSString		*variant;
	NSBundle		*style;
	NSString		*loadedPreviewDirectory = nil;
	NSDictionary	*previewDict;
		
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
	
	//Font menus
	NSFont		*font = [NSFont cachedFontWithName:[preview fontFamily]
											  size:[[preview preferences] defaultFontSize]];

	[fontPreviewField_currentFont setFont:font];
	[popUp_minimumFontSize selectItemAtIndex:[[popUp_minimumFontSize menu] indexOfItemWithTag:[[preview preferences] minimumFontSize]]];
}

#pragma mark Menus
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
    NSMenuItem      *menuItem = [[[NSMenuItem alloc] initWithTitle:dateString target:nil action:nil keyEquivalent:@""] autorelease];
    
    [menuItem setRepresentedObject:format];
    [[popUp_timeStamps menu] addItem:menuItem];
}

- (NSMenu *)_customBackgroundMenu
{
	NSMenu			*menu = [[[NSMenu alloc] init] autorelease];
	NSMenuItem		*menuItem;
	
	menuItem = [[[NSMenuItem alloc] initWithTitle:NO_BACKGROUND_ITEM_TITLE
										   target:self
										   action:@selector(changeBackground:)
									keyEquivalent:@""] autorelease];
	[menuItem setTag:NoBackground];
	[menu addItem:menuItem];
	
	menuItem = [[[NSMenuItem alloc] initWithTitle:DEFAULT_BACKGROUND_ITEM_TITLE
										   target:self
										   action:@selector(changeBackground:)
									keyEquivalent:@""] autorelease];
	[menuItem setTag:DefaultBackground];
	[menu addItem:menuItem];
	
	menuItem = [[[NSMenuItem alloc] initWithTitle:CUSTOM_BACKGROUND_ITEM_TITLE
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
	
	while(participant = [enumerator nextObject]){
		NSString		*UID, *alias, *userIconName;
		AIListObject	*listObject;
		
		//Create object
		UID = [participant objectForKey:@"UID"];
		listObject = [[[AIListObject alloc] initWithUID:UID
											  serviceID:@"AIM"] autorelease];
		
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
	NSEnumerator		*enumerator;
	NSDictionary		*messageDict, *participant;
	
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
}

//Chat content
- (void)_addContent:(NSDictionary *)chatDict toChat:(AIChat *)inChat withParticipants:(NSDictionary *)participants
{
	NSString			*dateOpened, *type, *name, *UID;
	NSEnumerator		*enumerator;
	NSDictionary		*messageDict, *participant;
	
	enumerator = [chatDict objectEnumerator];
	while(messageDict = [enumerator nextObject]){
		NSString 		*msgType = [messageDict objectForKey:@"Type"];
		AIContentObject	*content = nil;
		
		if([msgType isEqualToString:CONTENT_MESSAGE_TYPE]){
			AIListObject	*dest, *source;
			
			//Create message content object
			NSAttributedString  *message =[NSAttributedString stringWithData:[messageDict objectForKey:@"Message"]];
			NSString			*from = [messageDict objectForKey:@"From"];
			NSString			*to = [messageDict objectForKey:@"To"];
			BOOL				outgoing = [[messageDict objectForKey:@"Outgoing"] boolValue];
			
			//The other person is always the one we're chatting with right now
			dest = [participants objectForKey:to];
			source =  [participants objectForKey:from];
			content = [AIContentMessage messageInChat:nil
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
			NSString		*message = [messageDict objectForKey:@"Message"];
			NSString		*statusMessageType = [messageDict objectForKey:@"Status Message Type"];
			NSString		*from = [messageDict objectForKey:@"From"];
			AIListObject	*source = (from ? [participants objectForKey:from] : nil);
			
			//Create our content object
			content = [AIContentStatus statusInChat:nil
										 withSource:source
										destination:nil
											   date:[NSDate dateWithNaturalLanguageString:[messageDict objectForKey:@"Date"]]
											message:[NSAttributedString stringWithString:message]
										   withType:statusMessageType];
			
		}
		
		if(content) [inChat addContentObject:content];
	}
}


@end
