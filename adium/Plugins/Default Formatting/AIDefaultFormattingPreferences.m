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

#import "AIDefaultFormattingPreferences.h"
#import "AIDefaultFormattingPlugin.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"

#define	DEFAULT_FORMATTING_PREF_NIB		@"DefaultFormattingPrefs"
#define DEFAULT_FORMATTING_PREF_TITLE		@"Default message style"

@interface AIDefaultFormattingPreferences (PRIVATE)
- (void)showFont:(NSFont *)inFont inField:(NSTextField *)inTextField;
- (void)configureView;
- (id)initWithOwner:(id)inOwner;
- (void)changeFont:(id)sender;
@end

@implementation AIDefaultFormattingPreferences
//
+ (AIDefaultFormattingPreferences *)defaultFormattingPreferencesWithOwner:(id)inOwner
{
    return([[[self alloc] initWithOwner:inOwner] autorelease]);
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == button_setFont){
        NSFontManager	*fontManager = [NSFontManager sharedFontManager];
        NSFont		*selectedFont = [[preferenceDict objectForKey:KEY_FORMATTING_FONT] representedFont];
    
        //In order for the font panel to work, we must be set as the window's delegate
        [[textField_desiredFont window] setDelegate:self];
    
        //Setup and show the font panel
        [[textField_desiredFont window] makeFirstResponder:[textField_desiredFont window]];
        [fontManager setSelectedFont:selectedFont isMultiple:NO];
        [fontManager orderFrontFontPanel:self];
    
    }else if(sender == colorWell_textColor){
        [[owner preferenceController] setPreference:[[colorWell_textColor color] stringRepresentation]
                                            forKey:KEY_FORMATTING_TEXT_COLOR
                                            group:PREF_GROUP_FORMATTING];
    
    }else if(sender == colorWell_backgroundColor){
        [[owner preferenceController] setPreference:[[colorWell_backgroundColor color] stringRepresentation]
                                            forKey:KEY_FORMATTING_BACKGROUND_COLOR
                                            group:PREF_GROUP_FORMATTING];
    
    }
}

//Private ---------------------------------------------------------------------------
//init
- (id)initWithOwner:(id)inOwner
{
    AIPreferenceViewController	*preferenceViewController;

    [super init];
    owner = [inOwner retain];

    //Load the pref view nib
    [NSBundle loadNibNamed:DEFAULT_FORMATTING_PREF_NIB owner:self];

    //Install our preference view
    preferenceViewController = [AIPreferenceViewController controllerWithName:DEFAULT_FORMATTING_PREF_TITLE categoryName:PREFERENCE_CATEGORY_MESSAGES view:view_prefView];
    [[owner preferenceController] addPreferenceView:preferenceViewController];

    //Load our preferences and configure the view
    preferenceDict = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_FORMATTING] retain];
    [self configureView];

    return(self);
}

//Called in response to a font panel change
- (void)changeFont:(id)sender
{
    NSFontManager	*fontManager = [NSFontManager sharedFontManager];
    NSFont		*contactListFont = [fontManager convertFont:[fontManager selectedFont]];

    //Update the displayed font string & preferences
    [self showFont:contactListFont inField:textField_desiredFont];
    [[owner preferenceController] setPreference:[contactListFont stringRepresentation] forKey:KEY_FORMATTING_FONT group:PREF_GROUP_FORMATTING];
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
    [self showFont:[[preferenceDict objectForKey:KEY_FORMATTING_FONT] representedFont] inField:textField_desiredFont];

    //Text
    [colorWell_textColor setColor:[[preferenceDict objectForKey:KEY_FORMATTING_TEXT_COLOR] representedColor]];

    //Background
    [colorWell_backgroundColor setColor:[[preferenceDict objectForKey:KEY_FORMATTING_BACKGROUND_COLOR] representedColor]];
}


@end



