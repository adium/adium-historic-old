//
//  AIDefaultFormattingPlugin.m
//  Adium
//
//  Created by Adam Iser on Thu May 22 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIDefaultFormattingPlugin.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AIAdium.h"

#define DEFAULT_FORMATTING_DEFAULT_PREFS	@"FormattingDefaults"
#define PREF_GROUP_FORMATTING			@"Formatting"

#define KEY_FORMATTING_FONT			@"Default Font"
#define KEY_FORMATTING_TEXT_COLOR		@"Default Text Color"
#define KEY_FORMATTING_BACKGROUND_COLOR		@"Default Background Color"
#define KEY_FORMATTING_SUBBACKGROUND_COLOR	@"Default SubBackground Color"

@interface AIDefaultFormattingPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
- (void)_resetFormattingInView:(NSText<AITextEntryView> *)inTextEntryView;
@end

@implementation AIDefaultFormattingPlugin

- (void)installPlugin
{
    //Register as an entry filter
    [[owner contentController] registerTextEntryFilter:self];

    //Register our default preferences
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:DEFAULT_FORMATTING_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_FORMATTING];

    //Observe
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];
}

- (void)stringAdded:(NSString *)inString toTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
    //Ignored
}

- (void)contentsChangedInTextEntryView:(NSText<AITextEntryView> *)inTextEntryView
{
    [self _resetFormattingInView:inTextEntryView]; //Set the formatting to default
}

- (void)preferencesChanged:(NSNotification *)notification
{
/*    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_DOCK_BEHAVIOR] == 0){
        NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_DOCK_BEHAVIOR];

    }*/
}



// Private --------------------------------------------------------------------------
//Resets all the text in an entry view to the default values\
- (void)_resetFormattingInView:(NSText<AITextEntryView> *)inTextEntryView
{
    NSMutableAttributedString	*contents;
    NSDictionary		*prefDict;
    NSDictionary		*attributes;
    NSColor			*textColor;
    NSColor			*backgroundColor;
    NSColor			*subBackgroundColor;
    NSFont			*font;

    //Get the prefs
    prefDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_FORMATTING];
    font = [[prefDict objectForKey:KEY_FORMATTING_FONT] representedFont];
    textColor = [[prefDict objectForKey:KEY_FORMATTING_TEXT_COLOR] representedColor];
    backgroundColor = [[prefDict objectForKey:KEY_FORMATTING_BACKGROUND_COLOR] representedColor];
    subBackgroundColor = [[prefDict objectForKey:KEY_FORMATTING_SUBBACKGROUND_COLOR] representedColor];

    //Setup the attributes
    if(!subBackgroundColor){
        attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, textColor, NSForegroundColorAttributeName, backgroundColor, AIBodyColorAttributeName, nil];
    }else{
        attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, textColor, NSForegroundColorAttributeName, backgroundColor, AIBodyColorAttributeName, subBackgroundColor, NSBackgroundColorAttributeName, nil];
    }

    //Apply the attributes to the existing content
    contents = [[inTextEntryView attributedString] mutableCopy];
    [contents setAttributes:attributes range:NSMakeRange(0,[contents length])];
    [inTextEntryView setAttributedString:contents];

    //Set them as the typing attributes for all new text
    [inTextEntryView setTypingAttributes:attributes];
}


@end
