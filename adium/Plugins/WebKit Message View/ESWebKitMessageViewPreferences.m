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
- (void)_buildTimeStampMenu;
- (void)_buildTimeStampMenu_AddFormat:(NSString *)format;
- (NSMenu *)_stylesMenu;
- (void)updatePreview;
- (void) _loadPreviewFromStylePath:(NSString *)inStylePath;
- (void)_createListObjectsFromDict:(NSDictionary *)previewDict withLoadedPreviewDirectory:(NSString *)loadedPreviewDirectory;
- (void)processNewContent;
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
	[popUp_styles setMenu:[self _stylesMenu]];
	
	{
		NSDictionary *prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
		
		[checkBox_showUserIcons setState:[[prefDict objectForKey:KEY_WEBKIT_SHOW_USER_ICONS] boolValue]];
		
		[popUp_timeStamps selectItemWithRepresentedObject:[prefDict objectForKey:KEY_WEBKIT_TIME_STAMP_FORMAT]];
		if (![popUp_timeStamps selectedItem]){
			[popUp_timeStamps selectItem:[popUp_timeStamps lastItem]];
		}
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
	}
	
	[self updatePreview];
}

- (IBAction)changeStyle:(id)sender
{
	NSDictionary *newStyleDict = [sender representedObject];
	
	NSString	*newStylePath = [newStyleDict objectForKey:@"stylePath"];
	[[adium preferenceController] setPreference:newStylePath
										 forKey:KEY_WEBKIT_STYLE
										  group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
	
	//If we were passed a variant as well, we want to change the variant preference for this style.
	//A variant of @"" indicates the user selected the normal view.
	//A variant of nil means that the user selected the menu item (rather than a submenu item); we should therefore
	//leave the variant preference alone - this will let the previously selected variant be selected automatically
	NSString	*variant = [newStyleDict objectForKey:@"variant"];
	if (variant){
		NSString	*style = [[newStylePath lastPathComponent] stringByDeletingPathExtension];
		[[adium preferenceController] setPreference:[variant length] ? variant : nil
											 forKey:[plugin keyForDesiredVariantOfStyle:style]
											  group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
	}
	
	[self updatePreview];	
}

#pragma mark Menus
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

#pragma mark Preview WebView
- (void)updatePreview
{
	NSString	*basePath, *headerHTML, *footerHTML, *templateHTML;
	NSString	*desiredStyle, *desiredVariant, *CSS;
	NSBundle	*style;
	
	//We aren't ready for that kind of commitment yet...
	webViewIsReady = NO;
	
	//Load the style as per preferences
	desiredStyle = [[adium preferenceController] preferenceForKey:KEY_WEBKIT_STYLE
																		 group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
	[stylePath release];
	style = [plugin messageStyleBundleWithName:desiredStyle];
	
	//If the preferred style is unavailable, load Smooth Operator
	if (!style){
		desiredStyle = @"Smooth Operator";
		style = [plugin messageStyleBundleWithName:desiredStyle];
	}
	stylePath = [[style resourcePath] retain];
	
	desiredVariant = [[adium preferenceController] preferenceForKey:[plugin keyForDesiredVariantOfStyle:desiredStyle]
																		   group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];			
	if (desiredVariant){
		CSS = [[NSString stringWithFormat:@"Variants/%@.css",desiredVariant] retain];
	}else{
		CSS = [@"main.css" retain];
	}
	
	basePath = [[NSURL fileURLWithPath:stylePath] absoluteString];	
	headerHTML = [NSString stringWithContentsOfFile:[stylePath stringByAppendingPathComponent:@"Header.html"]];
	footerHTML = [NSString stringWithContentsOfFile:[stylePath stringByAppendingPathComponent:@"Footer.html"]];
	
	//Load the template, and fill it up
	templateHTML = [NSString stringWithContentsOfFile:[stylePath stringByAppendingPathComponent:@"Template.html"]];
	templateHTML = [NSString stringWithFormat:templateHTML, basePath, CSS, headerHTML, footerHTML];
    	
	//Feed it to the webview
	[[preview mainFrame] loadHTMLString:templateHTML baseURL:nil];
	
	//Load and process the Preview file (using the style's own if possible, otherwise using Adium's)
	[self _loadPreviewFromStylePath:stylePath];
}

//Our job here is to take a fake conversation and display it by adding it to the WebView
- (void) _loadPreviewFromStylePath:(NSString *)inStylePath
{
	NSString		*previewFilePath = [[inStylePath stringByAppendingPathComponent:PREVIEW_FILE] stringByAppendingPathExtension:@"plist"];
	NSString		*loadedPreviewDirectory = nil;
	NSDictionary	*previewDict;
	
	//Load from the style if possible; otherwise use the bundle's own preview.plist
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
	
	//Load and display the desired content objects
	NSDictionary		*chatDict = [previewDict objectForKey:@"Preview Messages"];
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
