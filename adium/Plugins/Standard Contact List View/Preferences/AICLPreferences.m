//
//  AICLPreferences.m
//  Adium
//
//  Created by Vinay Venkatesh on Wed Dec 18 2002.
//  Copyright (c) 2002 Vinay Venkatesh. All rights reserved.
//

#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAccountListPreferencesPlugin.h"
#import "AIAdium.h"

#import "AICLPreferences.h"


#define CL_PREF_NIB		@"AICLPrefView"
#define CL_PREF_TITLE	@"Contact List"

@interface AICLPreferences (_private)
- (void) _buildFontMenuFor: (NSPopUpButton*)inFontPopUp;
- (void) _buildFontFaceMenuFor:(NSPopUpButton *)inFacePopUp using:(NSPopUpButton *)inFamilyPopUp;
@end
#pragma mark -
@implementation AICLPreferences
- (void) initialize: (id) preferenceController
{
    [preferenceController addPreferenceView:[[AIPreferenceViewController controllerWithName:CL_PREF_TITLE
                                                                               categoryName:PREFERENCE_CATEGORY_INTERFACE
                                                                                       view:prefView] retain]];
    //initialize values
    [self _buildFontMenuFor: fontPopUp];
    [self _buildFontFaceMenuFor: facePopUp using: fontPopUp]; // eventually this happens after prefs are loaded.
}

- (void) fontPopUps: (id) sender
{

}
@end
#pragma mark -
@implementation AICLPreferences (_private)
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
