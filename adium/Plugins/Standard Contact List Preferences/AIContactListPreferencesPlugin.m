//
//  AIContactListPreferencesPlugin.m
//  Adium
//
//  Created by Vinay Venkatesh on Mon Dec 16 2002.
//  Copyright (c) 2002 Vinay Venkatesh. All rights reserved.
//

#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAccountListPreferencesPlugin.h"
#import "AIAdium.h"
//#import "AIAccountController.h"
#import "AIPreferenceController.h"

#import "AIContactListPreferencesPlugin.h"

#define	CONTACT_PREFERENCE_GROUP			@"ContactList Preferences"	//Group Name

#define	CONTACT_PREFERENCE_VIEW_NIB			@"ContactListPrefView"		//Nib Filename
#define	CONTACT_GENERAL_PREFERENCE_TITLE	@"Contact List: General"	//Title for General Prefs
#define	CONTACT_GROUPS_PREFERENCE_TITLE	@"Contact List: Groups"		//Title for General Prefs
#define	CONTACT_CONTACTS_PREFERENCE_TITLE	@"Contact List: Contacts"	//Title for General Prefs


@interface AIContactListPreferencesPlugin (_private)
- (void) _buildFontMenus;
- (void) _buildFontMenuFor: (NSPopUpButton*)inFontPopUp;
- (void) _buildFontFaceMenus;
- (void) _buildFontFaceMenuFor:(NSPopUpButton *)inFacePopUp using:(NSPopUpButton *)inFamilyPopUp;

- (void) _writePrefs;
- (void) _loadPrefs;
@end
#pragma mark -
@implementation AIContactListPreferencesPlugin

// init the account view controller
- (void)installPlugin
{
    AIPreferenceController	*preferenceController;

    
    //init
    preferenceController = [owner preferenceController];

    //Install the preference view
    [NSBundle loadNibNamed:CONTACT_PREFERENCE_VIEW_NIB owner:self];

    [preferenceController addPreferenceView:[[AIPreferenceViewController controllerWithName:CONTACT_GENERAL_PREFERENCE_TITLE
                                                                               categoryName:PREFERENCE_CATEGORY_INTERFACE
                                                                                       view:general_contact_PrefView] retain]];

    [preferenceController addPreferenceView:[[AIPreferenceViewController controllerWithName:CONTACT_GROUPS_PREFERENCE_TITLE
                                                                               categoryName:PREFERENCE_CATEGORY_INTERFACE
                                                                                       view:group_contact_PrefView] retain]];

    [preferenceController addPreferenceView:[[AIPreferenceViewController controllerWithName:CONTACT_CONTACTS_PREFERENCE_TITLE
                                                                               categoryName:PREFERENCE_CATEGORY_INTERFACE
                                                                                       view:contact_contact_PrefView] retain]];
    //initialize values
    [self _buildFontMenus];
    [self _buildFontFaceMenus]; // eventually this happens after prefs are loaded.
}

@end
#pragma mark -
@implementation AIContactListPreferencesPlugin (General)
- (IBAction) setDefaultFontPopups: (id)sender
{
    if (sender == generalFontPopUp)
    {
        [self _buildFontFaceMenuFor: generalFacePopUp
                              using: generalFontPopUp];
    }
    else if (sender == generalFacePopUp)
    {

    }
    else if (sender == generalSizePopUp)
    {

    }
    [self _writePrefs];
    /* write the font info to prefs */
}
- (IBAction) setBackgroundColor: (id)sender
{
    [[owner preferenceController] setPreference: [sender color] forKey:CL_CLBGCOLOR_PREFKEY group:CONTACT_PREFERENCE_GROUP];
}

- (IBAction) gridOptions: (id)sender
{

}

- (IBAction) sortingOptions: (id)sender
{

}

- (IBAction) setAutoResize: (id)sender
{

}
@end
#pragma mark -
@implementation AIContactListPreferencesPlugin (Groups)
- (IBAction) setGroupColor: (id)sender
{

}

- (IBAction) setGroupUsesCustomFont: (id)sender
{

}
- (IBAction) setGroupCustomFontPopups: (id)sender
{
    if (sender == groupFontPopUp)
    {
        [self _buildFontFaceMenuFor: groupFacePopUp
                              using: groupFontPopUp];
    }
    else if (sender == groupFacePopUp)
    {

    }
    else if (sender == groupSizePopUp)
    {

    }    
}

- (IBAction) setShowSpecialGroups: (id)sender
{

}
- (IBAction) hideEmptyGroups: (id)sender
{

}
@end
#pragma mark -
@implementation AIContactListPreferencesPlugin (Contacts)
- (IBAction) contactDisplayOptions: (id)sender
{

}

- (IBAction) setContactSignedOnUsesCustomFont: (id)sender
{

}
- (IBAction) setContactSignedOnCustomFontPopups: (id)sender
{
    if (sender == contactSignedOnFontPopUp)
    {
        [self _buildFontFaceMenuFor: contactSignedOnFacePopUp
                              using: contactSignedOnFontPopUp];
    }
    else if (sender == contactSignedOnFacePopUp)
    {

    }
    else if (sender == contactSignedOnSizePopUp)
    {

    }    
}

- (IBAction) setContactSignedOffUsesCustomFont: (id)sender
{

}
- (IBAction) setContactSignedOffCustomFontPopups: (id)sender
{
    if (sender == contactSignedOffFontPopUp)
    {
        [self _buildFontFaceMenuFor: contactSignedOffFacePopUp
                              using: contactSignedOffFontPopUp];
    }
    else if (sender == contactSignedOffFacePopUp)
    {

    }
    else if (sender == contactSignedOffSizePopUp)
    {

    }    
}

- (IBAction) setDisplayMouseOver: (id)sender
{

}

- (IBAction) setContactMouseOverUsesCustomFont: (id)sender
{

}
- (IBAction) setContactMouseOverCustomFontPopups: (id)sender
{
    if (sender == contactMouseOverFontPopUp)
    {
        [self _buildFontFaceMenuFor: contactMouseOverFacePopUp
                              using: contactMouseOverFontPopUp];
    }
    else if (sender == contactMouseOverFacePopUp)
    {

    }
    else if (sender == contactMouseOverSizePopUp)
    {

    }
}

- (IBAction) setMouseOverColors: (id)sender
{

}
@end
#pragma mark -
@implementation AIContactListPreferencesPlugin (_private)
// build and load menus for fonts
- (void) _buildFontMenus
{
    [self _buildFontMenuFor: generalFontPopUp];
    [self _buildFontMenuFor: groupFontPopUp];
    [self _buildFontMenuFor: contactSignedOnFontPopUp];
    [self _buildFontMenuFor: contactSignedOffFontPopUp];
    [self _buildFontMenuFor: contactMouseOverFontPopUp];
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

//builds the font face menus depending on what fonts are selected
- (void) _buildFontFaceMenus
{
    [self _buildFontFaceMenuFor: generalFacePopUp
                          using: generalFontPopUp];
    [self _buildFontFaceMenuFor: groupFacePopUp
                          using: groupFontPopUp];
    [self _buildFontFaceMenuFor: contactSignedOnFacePopUp
                          using: contactSignedOnFontPopUp];
    [self _buildFontFaceMenuFor: contactSignedOffFacePopUp
                          using: contactSignedOffFontPopUp];
    [self _buildFontFaceMenuFor: contactMouseOverFacePopUp
                          using: contactMouseOverFontPopUp];
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

- (void) _writePrefs
{
}
- (void) _loadPrefs
{
}
@end
