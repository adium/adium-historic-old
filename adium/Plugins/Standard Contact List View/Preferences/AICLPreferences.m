//
//  AICLPreferences.m
//  Adium
//
//  Created by Vinay Venkatesh on Wed Dec 18 2002.
//  Copyright (c) 2002 Vinay Venkatesh. All rights reserved.
//

#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>

#import "AIAdium.h"

#import "AIPreferenceController.h"

#import "AICLPreferences.h"


#define CL_PREF_NIB		@"AICLPrefView"
#define CL_PREF_TITLE	@"Contact List"

@interface AICLPreferences (_private)
- (void) _prefsChangedNotify;
- (void) _buildFontMenuFor: (NSPopUpButton*)inFontPopUp;
- (void) _buildFontFaceMenuFor:(NSPopUpButton *)inFacePopUp using:(NSPopUpButton *)inFamilyPopUp;
- (void) _loadPrefs;
@end
#pragma mark -
@implementation AICLPreferences
- (void) initialize: (id) _preferenceController
{
    preferenceController = [_preferenceController retain];
    [preferenceController addPreferenceView:[[AIPreferenceViewController controllerWithName:CL_PREF_TITLE
                                                                               categoryName:PREFERENCE_CATEGORY_INTERFACE
                                                                                       view:prefView] retain]];
    //initialize values
    [self _buildFontMenuFor: fontPopUp];
    [self _loadPrefs];
}

- (void) setCLController: (id) foo
{
    if (parentPlugin != nil)
        [parentPlugin release];
    parentPlugin = [foo retain];
}

- (void) fontPopUps: (id) sender
{
    if (sender == fontPopUp)
    {
        [self _buildFontFaceMenuFor: facePopUp
                              using: fontPopUp];
    }
    else if (sender == facePopUp)
    {

    }
    else if (sender == sizePopUp)
    {

    }
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
        [[fontPopUp selectedItem] title], @"FONT",
        [[facePopUp selectedItem] title], @"FACE",
        [NSNumber numberWithInt:[[[sizePopUp selectedItem] title] intValue]], @"SIZE",
        nil];

    [preferenceController setPreference: dict forKey:CL_DEFAULT_FONT group:CL_PREFERENCE_GROUP];
    [self _prefsChangedNotify];
}

- (void) gridOptions: (id) sender
{
    if (sender == enableGridSwitch)
    {
        [preferenceController setPreference: [NSNumber numberWithBool:[sender state]] forKey:CL_ENABLE_GRID group:CL_PREFERENCE_GROUP];

        [alternatingGridSwitch setEnabled:[sender state]];
        [gridColorWell setEnabled:[sender state]];
        [gridColorLabel setEnabled:[sender state]];
    }
    else if (sender == alternatingGridSwitch)
    {
        [preferenceController setPreference: [NSNumber numberWithBool:[sender state]] forKey: CL_ALTERNATING_GRID group: CL_PREFERENCE_GROUP];        
    }
    [self _prefsChangedNotify];
}

- (void) colorAndOpacity: (id) sender
{
    if (sender == backgroundColorWell)	// iacas - 12/22/2002 - kinda lame to be pulling these into the same action, isn't it???
    {
        float red, green, blue, alpha;
        [[[sender color] colorUsingColorSpaceName:@"NSCalibratedRGBColorSpace"] getRed:&red green:&green blue:&blue alpha:&alpha];

        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithFloat: red], @"RED",
            [NSNumber numberWithFloat: green], @"GREEN",
            [NSNumber numberWithFloat: blue], @"BLUE",
            [NSNumber numberWithFloat: alpha], @"ALPHA",
            nil];

        [preferenceController setPreference: dict
                                     forKey: CL_BACKGROUND_COLOR
                                      group: CL_PREFERENCE_GROUP];
    }
    else if (sender == gridColorWell)
    {
        float red, green, blue, alpha;
        [[[sender color] colorUsingColorSpaceName:@"NSCalibratedRGBColorSpace"] getRed:&red green:&green blue:&blue alpha:&alpha];

        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithFloat: red], @"RED",
            [NSNumber numberWithFloat: green], @"GREEN",
            [NSNumber numberWithFloat: blue], @"BLUE",
            [NSNumber numberWithFloat: alpha], @"ALPHA",
            nil];

        [preferenceController setPreference: dict
                                     forKey: CL_GRID_COLOR
                                      group: CL_PREFERENCE_GROUP];        
    }
    else if (sender == opacitySlider)
    {
        [opacityPercentLabel setStringValue:[NSString stringWithFormat:@"%d", [[NSNumber numberWithFloat:([sender floatValue]*100)] intValue]]];
        [preferenceController setPreference: [NSNumber numberWithFloat:[sender floatValue]]
                                     forKey: CL_OPACITY
                                      group: CL_PREFERENCE_GROUP];
    }


    [self _prefsChangedNotify];
}
@end
#pragma mark -
@implementation AICLPreferences (_private)
- (void) _prefsChangedNotify
{
    if (parentPlugin != nil)
        [parentPlugin prefsChanged: nil];
}

- (void) _loadPrefs
{
    NSDictionary* dict = [preferenceController preferencesForGroup: CL_PREFERENCE_GROUP];

    [fontPopUp selectItemWithTitle:[[dict objectForKey: CL_DEFAULT_FONT] objectForKey: @"FONT"]];
    [self _buildFontFaceMenuFor: facePopUp using: fontPopUp];
    
    [facePopUp selectItemWithTitle:[[dict objectForKey: CL_DEFAULT_FONT] objectForKey: @"FACE"]];
    [sizePopUp selectItemWithTitle:[NSString stringWithFormat:@"%d", [[[dict objectForKey: CL_DEFAULT_FONT] objectForKey: @"SIZE"] intValue]]];

    [alternatingGridSwitch setState:[[dict objectForKey: CL_ALTERNATING_GRID] boolValue]];
    
    [backgroundColorWell setColor:[NSColor colorWithCalibratedRed:[[[dict objectForKey: CL_BACKGROUND_COLOR] objectForKey:@"RED"] floatValue]
                                                            green:[[[dict objectForKey: CL_BACKGROUND_COLOR] objectForKey:@"GREEM"] floatValue]
                                                             blue:[[[dict objectForKey: CL_BACKGROUND_COLOR] objectForKey:@"BLUE"] floatValue]
                                                            alpha:[[[dict objectForKey: CL_BACKGROUND_COLOR] objectForKey:@"ALPHA"] floatValue]]];

    [gridColorWell setColor: [NSColor colorWithCalibratedRed:[[[dict objectForKey: CL_GRID_COLOR] objectForKey:@"RED"] floatValue]
                                                       green:[[[dict objectForKey: CL_GRID_COLOR] objectForKey:@"GREEM"] floatValue]
                                                        blue:[[[dict objectForKey: CL_GRID_COLOR] objectForKey:@"BLUE"] floatValue]
                                                       alpha:[[[dict objectForKey: CL_GRID_COLOR] objectForKey:@"ALPHA"] floatValue]]];

}

- (void) _buildFontMenuFor: (NSPopUpButton*)inFontPopUp
{
    NSArray 	*sortedFonts;
    NSMenu		*fontMenu = [[NSMenu alloc] initWithTitle:@"Fonts"];
    int			loop;

    sortedFonts = [[[NSFontManager sharedFontManager] availableFontFamilies] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

    for(loop = 0;loop < [sortedFonts count];loop++){

        [[fontMenu addItemWithTitle:[sortedFonts objectAtIndex:loop]
                             action:nil
                      keyEquivalent:@""] setTarget:self];
    }

    [inFontPopUp setMenu: fontMenu];
}

- (void) _buildFontFaceMenuFor:(NSPopUpButton *)inFacePopUp using:(NSPopUpButton *)inFamilyPopUp
{
    NSString	*selectedFamily;
    NSString	*selectedFace;
    NSArray 	*fontFaces;
    NSMenu		*faceMenu = [[NSMenu alloc] initWithTitle:@"Faces"];
    int		loop;

    //--remember the currently selected font face--
    selectedFace = [[inFacePopUp titleOfSelectedItem] retain];

    //--get the family--
    selectedFamily = [inFamilyPopUp titleOfSelectedItem];

    //--build a sorted face list--
    fontFaces = [[NSFontManager sharedFontManager] availableMembersOfFontFamily:selectedFamily];

    //--create the menu--
    [inFacePopUp removeAllItems];
    for(loop = 0;loop < [fontFaces count];loop++){
        [[faceMenu addItemWithTitle:[[fontFaces objectAtIndex:loop] objectAtIndex:1]
                             action:nil
                      keyEquivalent:@""] setTarget:self];
    }
    [inFacePopUp setMenu:faceMenu];
    //--reselect the font face--
    if(selectedFace != nil && [inFacePopUp itemWithTitle:selectedFace] != nil){
        [inFacePopUp selectItemWithTitle:selectedFace];
    }else{
        if([inFacePopUp numberOfItems] != 0) {
            [inFacePopUp selectItemAtIndex:0];
        }
    }
    [selectedFace release];
}
@end
