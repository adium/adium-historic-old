//
//  AISMPreferences.m
//  Adium
//
//  Created by Adam Iser on Wed Jan 22 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AISMPreferences.h"
#import "AISMViewPlugin.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>

#define AISM_PREFIX_COLORS		@"PrefixColors"

#define AISM_PREF_NIB			@"AISMPrefView"
#define AISM_PREF_TITLE_PREFIX		@"Message Prefixes"
#define AISM_PREF_TITLE_TIMES		@"Message Time Stamps"
#define AISM_PREF_TITLE_GRID		@"Message Gridding"

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
 
+ (AISMPreferences *)messageViewPreferencesWithOwner:(id)inOwner
{
    return([[[self alloc] initWithOwner:inOwner] autorelease]);
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    
    if(sender == button_setPrefixFont){
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
    AIPreferenceViewController	*preferenceViewController;

    [super init];

    owner = [inOwner retain];

    prefixColors = [[NSDictionary dictionaryNamed:AISM_PREFIX_COLORS forClass:[self class]] retain];

    //Load the pref view nib
    [NSBundle loadNibNamed:AISM_PREF_NIB owner:self];

    //Install our preference views
    //Prefixes
    preferenceViewController = [AIPreferenceViewController controllerWithName:AISM_PREF_TITLE_PREFIX categoryName:PREFERENCE_CATEGORY_MESSAGES view:view_prefixes];
    [[owner preferenceController] addPreferenceView:preferenceViewController];

    //TimeStamps
    preferenceViewController = [AIPreferenceViewController controllerWithName:AISM_PREF_TITLE_TIMES categoryName:PREFERENCE_CATEGORY_MESSAGES view:view_timeStamps];
    [[owner preferenceController] addPreferenceView:preferenceViewController];

    //Gridding
    preferenceViewController = [AIPreferenceViewController controllerWithName:AISM_PREF_TITLE_GRID categoryName:PREFERENCE_CATEGORY_MESSAGES view:view_gridding];
    [[owner preferenceController] addPreferenceView:preferenceViewController];

    
    //Load the preferences, and configure our view
    preferenceDict = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_STANDARD_MESSAGE_DISPLAY] retain];
    [self configureView];

    return(self);
}

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

    [self configureControlDimming];
}

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





