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
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>

#define AISM_PREFIX_COLORS		@"PrefixColors"

#define AISM_PREF_NIB			@"AISMPrefView"
#define AISM_PREF_TITLE_PREFIX		@"Message Prefixes"
#define AISM_PREF_TITLE_TIMES		@"Message Time Stamps"
#define AISM_PREF_TITLE_GRID		@"Message Gridding"
#define AISM_PREF_TITLE_ALIAS		@"Message Alias"

#define COLOR_SAMPLE_WIDTH		16
#define COLOR_SAMPLE_HEIGHT		10

@interface AISMPreferences (PRIVATE)
- (void)changeFont:(id)sender;
- (id)initWithOwner:(id)inOwner;
- (void)showFont:(NSFont *)inFont inField:(NSTextField *)inTextField;
- (void)configureView;
- (void)configureControlDimming;
- (void)buildColorMenu:(NSPopUpButton *)inMenu;
@end

@implementation AISMPreferences
//
+ (AISMPreferences *)messageViewPreferencesWithOwner:(id)inOwner
{
    return([[[self alloc] initWithOwner:inOwner] autorelease]);
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == button_setPrefixFont){
        NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];
        NSFontManager	*fontManager = [NSFontManager sharedFontManager];
        NSFont		*selectedFont = [[preferenceDict objectForKey:KEY_SMV_PREFIX_FONT] representedFont];

        //In order for the font panel to work, we must be set as the window's delegate
        [[textField_prefixFontName window] setDelegate:self];

        //Setup and show the font panel
        [[textField_prefixFontName window] makeFirstResponder:[textField_prefixFontName window]];
        [fontManager setSelectedFont:selectedFont isMultiple:NO];
        [fontManager orderFrontFontPanel:self];

    }else if(sender == checkBox_showTimeStamps){
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SMV_SHOW_TIME_STAMPS
                                              group:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];

    }else if(sender == checkBox_showSeconds){
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SMV_SHOW_TIME_SECONDS
                                              group:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];

    }else if(sender == checkBox_hideDuplicateTimeStamps){
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SMV_HIDE_DUPLICATE_TIME_STAMPS
                                              group:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];

    }else if(sender == checkBox_hideDuplicatePrefixes){
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SMV_HIDE_DUPLICATE_PREFIX
                                              group:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];

    }else if(sender == checkBox_displayGridlines){
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SMV_DISPLAY_GRID_LINES
                                              group:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];

    }else if(sender == checkBox_senderGradient){
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SMV_DISPLAY_SENDER_GRADIENT
                                              group:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];

    }else if(sender == slider_gridDarkness){
        [[owner preferenceController] setPreference:[NSNumber numberWithFloat:[sender floatValue]]
                                             forKey:KEY_SMV_GRID_DARKNESS
                                              group:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];

    }else if(sender == slider_gradientDarkness){
        [[owner preferenceController] setPreference:[NSNumber numberWithFloat:[sender floatValue]]
                                             forKey:KEY_SMV_SENDER_GRADIENT_DARKNESS
                                              group:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];

    }else if(sender == popUp_incomingPrefix){
        NSDictionary	*colorDict = [prefixColors objectForKey:[[sender selectedItem] representedObject]];

        [[owner preferenceController] setPreference:[[sender selectedItem] representedObject]
                                             forKey:KEY_SMV_INCOMING_PREFIX_COLOR_NAME
                                              group:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];
        [[owner preferenceController] setPreference:[colorDict objectForKey:@"Light"]
                                             forKey:KEY_SMV_INCOMING_PREFIX_LIGHT_COLOR
                                              group:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];
        [[owner preferenceController] setPreference:[colorDict objectForKey:@"Dark"]
                                             forKey:KEY_SMV_INCOMING_PREFIX_COLOR
                                              group:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];
        
    }else if(sender == popUp_outgoingPrefix){
        NSDictionary	*colorDict = [prefixColors objectForKey:[[sender selectedItem] representedObject]];

        [[owner preferenceController] setPreference:[[sender selectedItem] representedObject]
                                             forKey:KEY_SMV_OUTGOING_PREFIX_COLOR_NAME
                                              group:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];
        [[owner preferenceController] setPreference:[colorDict objectForKey:@"Light"]
                                             forKey:KEY_SMV_OUTGOING_PREFIX_LIGHT_COLOR
                                              group:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];
        [[owner preferenceController] setPreference:[colorDict objectForKey:@"Dark"]
                                             forKey:KEY_SMV_OUTGOING_PREFIX_COLOR
                                              group:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];

    }else if(sender == textField_alias){
        [[owner preferenceController] setPreference:[sender stringValue]
                                             forKey:KEY_SMV_OUTGOING_ALIAS
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
    [[owner preferenceController] setPreference:[contactListFont stringRepresentation] forKey:KEY_SMV_PREFIX_FONT group:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];
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
    [[owner preferenceController] addPreferencePane:prefixesPane];

    //TimeStamps
    timeStampsPane = [[AIPreferencePane preferencePaneInCategory:AIPref_Messages_Display withDelegate:self label:AISM_PREF_TITLE_TIMES] retain];
    [[owner preferenceController] addPreferencePane:timeStampsPane];

    //Gridding
    griddingPane = [[AIPreferencePane preferencePaneInCategory:AIPref_Messages_Display withDelegate:self label:AISM_PREF_TITLE_GRID] retain];
    [[owner preferenceController] addPreferencePane:griddingPane];

    //Aliases
    aliasPane = [[AIPreferencePane preferencePaneInCategory:AIPref_Accounts_Profile withDelegate:self label:AISM_PREF_TITLE_ALIAS] retain];
    [[owner preferenceController] addPreferencePane:aliasPane];

    return(self);
}

//
- (void)dealloc
{
    [prefixesPane release];
    [timeStampsPane release];
    [griddingPane release];
    [aliasPane release];

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
    }else if(preferencePane == griddingPane){
        return(view_gridding);
    }else{// if(preferencePane == aliasPane){
        return(view_alias);
    }
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
    NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_STANDARD_MESSAGE_DISPLAY];

    //Font
    [self showFont:[[preferenceDict objectForKey:KEY_SMV_PREFIX_FONT] representedFont] inField:textField_prefixFontName];

    //Checkboxes
    [checkBox_showTimeStamps setState:[[preferenceDict objectForKey:KEY_SMV_SHOW_TIME_STAMPS] boolValue]];
    [checkBox_showSeconds setState:[[preferenceDict objectForKey:KEY_SMV_SHOW_TIME_SECONDS] boolValue]];
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

    //Text fields
    [textField_alias setStringValue:[preferenceDict objectForKey:KEY_SMV_OUTGOING_ALIAS]];
    
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

@end


