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

#import "AISMPreferences.h"
#import "AISMViewPlugin.h"

@interface AISMPreferences (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
- (void)_buildTimeStampMenu;
- (void)_buildTimeStampMenu_AddFormat:(NSString *)format;
- (void)_buildPrefixFormatMenu;
- (void)_buildPrefixFormatMenu_AddFormat:(NSString *)format withTitle:(NSString *)title;
@end

@implementation AISMPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Messages_Display);
}
- (NSString *)label{
    return(@"Message Display");
}
- (NSString *)nibName{
    return(@"AISMPrefView");
}

//Configure the preference view
- (void)viewDidLoad
{
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self _buildTimeStampMenu];
    [self _buildPrefixFormatMenu];
    [self preferencesChanged:nil];
}

//Close the preference view
- (void)viewWillClose
{
    [[adium notificationCenter] removeObserver:self];
}

//Reflect new preferences in view
- (void)preferencesChanged:(NSNotification *)notification
{
	if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_SOUNDS] == 0){
		NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];
		
		//Disable and uncheck show user icons when not using an inline prefix
		if([[preferenceDict objectForKey:KEY_SMV_PREFIX_INCOMING] rangeOfString:@"%m"].location != NSNotFound){
			[checkBox_showUserIcons setState:NSOffState];
			[checkBox_showUserIcons setEnabled:NO];
		}else{
			[checkBox_showUserIcons setState:[[preferenceDict objectForKey:KEY_SMV_SHOW_USER_ICONS] boolValue]];
			[checkBox_showUserIcons setEnabled:YES];
		}
		[checkBox_ignoreTextStyles setState:[[preferenceDict objectForKey:KEY_SMV_IGNORE_TEXT_STYLES] boolValue]];
		
		[checkBox_combineMessages setState:[[preferenceDict objectForKey:KEY_SMV_COMBINE_MESSAGES] boolValue]];
		
		[popUp_timeStamps selectItemWithRepresentedObject:[preferenceDict objectForKey:KEY_SMV_TIME_STAMP_FORMAT]];
		if (![popUp_timeStamps selectedItem])
			[popUp_timeStamps selectItem:[popUp_timeStamps lastItem]];
		
		[popUp_prefixFormat selectItemWithRepresentedObject:[preferenceDict objectForKey:KEY_SMV_PREFIX_INCOMING]];	
	}
}
    
//Save changed preference
- (IBAction)changePreference:(id)sender
{
    if(sender == checkBox_showUserIcons){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SMV_SHOW_USER_ICONS
                                              group:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];

    }else if(sender == checkBox_combineMessages){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SMV_COMBINE_MESSAGES
                                              group:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];

    }else if(sender == checkBox_ignoreTextStyles){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SMV_IGNORE_TEXT_STYLES
                                              group:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];
	}else if(sender == popUp_timeStamps){
        [[adium preferenceController] setPreference:[[popUp_timeStamps selectedItem] representedObject]
                                             forKey:KEY_SMV_TIME_STAMP_FORMAT
                                              group:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];
        
    }else if(sender == popUp_prefixFormat){
        [[adium preferenceController] delayPreferenceChangedNotifications:YES];
        [[adium preferenceController] setPreference:[[popUp_prefixFormat selectedItem] representedObject]
                                             forKey:KEY_SMV_PREFIX_INCOMING
                                              group:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];
        [[adium preferenceController] setPreference:[[popUp_prefixFormat selectedItem] representedObject]
                                             forKey:KEY_SMV_PREFIX_OUTGOING
                                              group:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];
        [[adium preferenceController] delayPreferenceChangedNotifications:NO];
        
    }
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

//Build the prefix selection menu
- (void)_buildPrefixFormatMenu
{
    //Empty the menu
    [popUp_prefixFormat removeAllItems];
    
    [self _buildPrefixFormatMenu_AddFormat:@"%a%r" withTitle:@"Alias"];
    [self _buildPrefixFormatMenu_AddFormat:@"?a%a (?a%n?a)?a%r" withTitle:@"Alias (User Name)"];
    [self _buildPrefixFormatMenu_AddFormat:@"%n%r" withTitle:@"User Name"];
    [self _buildPrefixFormatMenu_AddFormat:@"%n?a (%a)?a%r" withTitle:@"User Name (Alias)"];
    
    [[popUp_prefixFormat menu] addItem:[NSMenuItem separatorItem]];
    
    [self _buildPrefixFormatMenu_AddFormat:@"%a%r: %m" withTitle:@"Alias: Message"];
    [self _buildPrefixFormatMenu_AddFormat:@"%n%r: %m" withTitle:@"User Name: Message"];
    [self _buildPrefixFormatMenu_AddFormat:@"(%t) %a%r: %m" withTitle:@"(Time) Alias: Message"];
    [self _buildPrefixFormatMenu_AddFormat:@"(%t) %n%r: %m" withTitle:@"(Time) User Name: Message"];
    [self _buildPrefixFormatMenu_AddFormat:@"%a (%t)%r: %m" withTitle:@"Alias (Time): Message"];
    [self _buildPrefixFormatMenu_AddFormat:@"%n (%t)%r: %m" withTitle:@"User Name (Time): Message"];
}

//Add a prefix format to the menu
- (void)_buildPrefixFormatMenu_AddFormat:(NSString *)format withTitle:(NSString *)title
{
    NSMenuItem      *menuItem = [[[NSMenuItem alloc] initWithTitle:title target:nil action:nil keyEquivalent:@""] autorelease];
    
    [menuItem setRepresentedObject:format];
    [[popUp_prefixFormat menu] addItem:menuItem];
}

/*
//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == button_setPrefixFont){
        NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];
        NSFontManager	*fontManager = [NSFontManager sharedFontManager];
        NSFont		*selectedFont = [[preferenceDict objectForKey:KEY_SMV_PREFIX_FONT] representedFont];

        //In order for the font panel to work, we must be set as the window's delegate
        [[textField_prefixFontName window] setDelegate:self];

        //Setup and show the font panel
        [[textField_prefixFontName window] makeFirstResponder:[textField_prefixFontName window]];
        [fontManager setSelectedFont:selectedFont isMultiple:NO];
        [fontManager orderFrontFontPanel:self];

    }else if(sender == checkBox_showTimeStamps){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SMV_SHOW_TIME_STAMPS
                                              group:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];

    }else if(sender == checkBox_showSeconds){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SMV_SHOW_TIME_SECONDS
                                              group:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];

    }else if(sender == checkBox_showAmPm){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SMV_SHOW_AMPM
                                              group:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];
    }else if(sender == checkBox_hideDuplicateTimeStamps){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SMV_HIDE_DUPLICATE_TIME_STAMPS
                                              group:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];

    }else if(sender == checkBox_hideDuplicatePrefixes){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SMV_HIDE_DUPLICATE_PREFIX
                                              group:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];

    }else if(sender == checkBox_displayGridlines){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SMV_DISPLAY_GRID_LINES
                                              group:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];

    }else if(sender == checkBox_senderGradient){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SMV_DISPLAY_SENDER_GRADIENT
                                              group:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];

    }else if(sender == slider_gridDarkness){
        [[adium preferenceController] setPreference:[NSNumber numberWithFloat:[sender floatValue]]
                                             forKey:KEY_SMV_GRID_DARKNESS
                                              group:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];

    }else if(sender == slider_gradientDarkness){
        [[adium preferenceController] setPreference:[NSNumber numberWithFloat:[sender floatValue]]
                                             forKey:KEY_SMV_SENDER_GRADIENT_DARKNESS
                                              group:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];

    }else if(sender == popUp_incomingPrefix){
        NSDictionary	*colorDict = [prefixColors objectForKey:[[sender selectedItem] representedObject]];

        [[adium preferenceController] setPreference:[[sender selectedItem] representedObject]
                                             forKey:KEY_SMV_INCOMING_PREFIX_COLOR_NAME
                                              group:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];
        [[adium preferenceController] setPreference:[colorDict objectForKey:@"Light"]
                                             forKey:KEY_SMV_INCOMING_PREFIX_LIGHT_COLOR
                                              group:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];
        [[adium preferenceController] setPreference:[colorDict objectForKey:@"Dark"]
                                             forKey:KEY_SMV_INCOMING_PREFIX_COLOR
                                              group:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];
        
    }else if(sender == popUp_outgoingPrefix){
        NSDictionary	*colorDict = [prefixColors objectForKey:[[sender selectedItem] representedObject]];

        [[adium preferenceController] setPreference:[[sender selectedItem] representedObject]
                                             forKey:KEY_SMV_OUTGOING_PREFIX_COLOR_NAME
                                              group:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];
        [[adium preferenceController] setPreference:[colorDict objectForKey:@"Light"]
                                             forKey:KEY_SMV_OUTGOING_PREFIX_LIGHT_COLOR
                                              group:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];
        [[adium preferenceController] setPreference:[colorDict objectForKey:@"Dark"]
                                             forKey:KEY_SMV_OUTGOING_PREFIX_COLOR
                                              group:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];

    }

    
    [self configureControlDimming];
}


//Private ---------------------------------------------------------------------------
//Called in response to a font panel change
- (void)changeFont:(id)sender
{
    NSFontManager	*fontManager = [NSFontManager sharedFontManager];
    NSFont		*contactListFont = [fontManager convertFont:[fontManager selectedFont]];

    //Update the displayed font string & preferences
    [self showFont:contactListFont inField:textField_prefixFontName];
    [[adium preferenceController] setPreference:[contactListFont stringRepresentation] forKey:KEY_SMV_PREFIX_FONT group:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];
}

//init
- (id)initWithOwner:(id)inOwner
{
    //Init
    [super init];
    owner = [inOwner retain];
    prefixColors = [[NSDictionary dictionaryNamed:AISM_PREFIX_COLORS forClass:[self class]] retain];

    //Register our preference panes
    //Prefixes
    prefixesPane = [[AIPreferencePane preferencePaneInCategory:AIPref_Messages_Display withDelegate:self label:AISM_PREF_TITLE_PREFIX] retain];
    [[adium preferenceController] addPreferencePane:prefixesPane];

    //TimeStamps
    timeStampsPane = [[AIPreferencePane preferencePaneInCategory:AIPref_Messages_Display withDelegate:self label:AISM_PREF_TITLE_TIMES] retain];
    [[adium preferenceController] addPreferencePane:timeStampsPane];

    //Gridding
    griddingPane = [[AIPreferencePane preferencePaneInCategory:AIPref_Messages_Display withDelegate:self label:AISM_PREF_TITLE_GRID] retain];
    [[adium preferenceController] addPreferencePane:griddingPane];

    return(self);
}

//
- (void)dealloc
{
    [prefixesPane release];
    [timeStampsPane release];
    [griddingPane release];

    [super dealloc];
}

//Return the view for our preference pane
- (NSView *)viewForPreferencePane:(AIPreferencePane *)preferencePane
{
    //Make sure our nib is loaded
    if(!view_prefixes){
        [NSBundle loadNibNamed:AISM_PREF_NIB owner:self];

        //Configure our views
        [self configureView];
    }
    
    //Return the correct view
    if(preferencePane == prefixesPane){
        return(view_prefixes);
    }else if(preferencePane == timeStampsPane){
        return(view_timeStamps);
    }else{ //if(preferencePane == griddingPane){
        return(view_gridding);
    }
}

//Clean up our preference pane
- (void)closeViewForPreferencePane:(AIPreferencePane *)preferencePane
{
    [view_prefixes release]; view_prefixes = nil;
    [view_timeStamps release]; view_timeStamps = nil;
    [view_gridding release]; view_gridding = nil;
}

//Display the font name in our text field
- (void)showFont:(NSFont *)inFont inField:(NSTextField *)inTextField
{
    if(inFont){
        [inTextField setStringValue:[NSString stringWithFormat:@"%@ %g", [inFont fontName], [inFont pointSize]]];
    }else{
        [inTextField setStringValue:@""];
    }
}

//Configures our view for the current preferences
- (void)configureView
{
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];

    //Font
    [self showFont:[[preferenceDict objectForKey:KEY_SMV_PREFIX_FONT] representedFont] inField:textField_prefixFontName];

    //Checkboxes
    [checkBox_showTimeStamps setState:[[preferenceDict objectForKey:KEY_SMV_SHOW_TIME_STAMPS] boolValue]];
    [checkBox_showSeconds setState:[[preferenceDict objectForKey:KEY_SMV_SHOW_TIME_SECONDS] boolValue]];

    //enabled/disable based on whether the time string even contains an AM/PM field - check should be off if disabled
    if ([[NSDateFormatter localizedDateFormatStringShowingSeconds:YES showingAMorPM:YES] rangeOfString:@"%p"].location == NSNotFound) {
	[checkBox_showAmPm setEnabled:NO];
	[checkBox_showAmPm setState:NSOffState];
    } else {
	[checkBox_showAmPm setEnabled:YES];
	[checkBox_showAmPm setState:[[preferenceDict objectForKey:KEY_SMV_SHOW_AMPM] boolValue]];
    }
	    
    [checkBox_hideDuplicateTimeStamps setState:[[preferenceDict objectForKey:KEY_SMV_HIDE_DUPLICATE_TIME_STAMPS] boolValue]];
    [checkBox_hideDuplicatePrefixes setState:[[preferenceDict objectForKey:KEY_SMV_HIDE_DUPLICATE_PREFIX] boolValue]];
    [checkBox_displayGridlines setState:[[preferenceDict objectForKey:KEY_SMV_DISPLAY_GRID_LINES] boolValue]];
    [checkBox_senderGradient setState:[[preferenceDict objectForKey:KEY_SMV_DISPLAY_SENDER_GRADIENT] boolValue]];

    //Colors
    [self buildColorMenu:popUp_incomingPrefix];
    [popUp_incomingPrefix selectItemWithRepresentedObject:[preferenceDict objectForKey:KEY_SMV_INCOMING_PREFIX_COLOR_NAME]];
    [self buildColorMenu:popUp_outgoingPrefix];
    [popUp_outgoingPrefix selectItemWithRepresentedObject:[preferenceDict objectForKey:KEY_SMV_OUTGOING_PREFIX_COLOR_NAME]];

    //Sliders
    [slider_gridDarkness setFloatValue:[[preferenceDict objectForKey:KEY_SMV_GRID_DARKNESS] floatValue]];
    [slider_gradientDarkness setFloatValue:[[preferenceDict objectForKey:KEY_SMV_SENDER_GRADIENT_DARKNESS] floatValue]];
    
    [self configureControlDimming];
}

//Build a menu of colors
- (void)buildColorMenu:(NSPopUpButton *)inMenu
{
    NSEnumerator	*enumerator;
    NSString		*key;

    [inMenu removeAllItems];

    enumerator = [[prefixColors allKeys] objectEnumerator];
    while((key = [enumerator nextObject])){
        NSMenuItem	*menuItem;
        NSColor		*color, *lightColor;
        NSImage		*image;
        NSRect		imageRect;

        //Create the menu item and get the color
        menuItem = [[[NSMenuItem alloc] initWithTitle:key target:nil action:nil keyEquivalent:@""] autorelease];
        //The action is set on our popUp button, and not the individual menu items.  If we were to set the action on our menu items, the menu items would be passed to the preferenceChanged: method as sender, making it harder to determine which menu was altered.
        [menuItem setRepresentedObject:key];
        color = [[[prefixColors objectForKey:key] objectForKey:@"Dark"] representedColor];
        lightColor = [[[prefixColors objectForKey:key] objectForKey:@"Light"] representedColor];
        
        //Create the sample image
        imageRect = NSMakeRect(0, 0, COLOR_SAMPLE_WIDTH, COLOR_SAMPLE_HEIGHT);
        image = [[[NSImage alloc] initWithSize:imageRect.size] autorelease];
        [image lockFocus];

            [color set];
            imageRect.size.width /= 2;
            [NSBezierPath fillRect:imageRect];

            [lightColor set];
            imageRect.origin.x += imageRect.size.width;
            [NSBezierPath fillRect:imageRect];

            //Draw a frame
            imageRect.origin.x -= imageRect.size.width;
            imageRect.size.width *= 2;
            [[color darkenBy:0.2] set];
            [NSBezierPath strokeRect:imageRect];

            [image unlockFocus];
        [menuItem setImage:image];

        [[inMenu menu] addItem:menuItem];
    }
}

//Enable/disable controls that are available/unavailable
- (void)configureControlDimming
{
    //Gridding
    [slider_gridDarkness setEnabled:[checkBox_displayGridlines state]];
    [slider_gradientDarkness setEnabled:[checkBox_senderGradient state]];

    //TimeStamps
    [checkBox_hideDuplicateTimeStamps setEnabled:[checkBox_showTimeStamps state]];
    [checkBox_showSeconds setEnabled:[checkBox_showTimeStamps state]];
}
*/
@end


