//
//  AIContactListPreferencesPlugin.h
//  Adium
//
//  Created by Vinay Venkatesh on Mon Dec 16 2002.
//  Copyright (c) 2002 Vinay Venkatesh. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define CL_CLBGCOLOR_PREFKEY	@"CL_CLBGCOLOR"
@class AIAccountController, AIAccount;

@interface AIContactListPreferencesPlugin : AIPlugin {

    AIPreferenceViewController	*preferenceView;

    //General IBOutlets
    IBOutlet 	NSView			*general_contact_PrefView;

    IBOutlet	NSPopUpButton	*generalFontPopUp;
    IBOutlet	NSPopUpButton	*generalFacePopUp;
    IBOutlet	NSPopUpButton	*generalSizePopUp;

    IBOutlet	NSColorWell		*generalBackgroundColor;

    IBOutlet	NSButton		*generalEnableGrid;
    IBOutlet	NSButton		*generalEnableAlternatingGrid;
    IBOutlet	NSColorWell		*generalAlternatingColor;
    
    IBOutlet	NSButton		*generalAlphabetizeContactList;
    IBOutlet	NSButton		*generalSortIdleAwayContactList;
    IBOutlet	NSButton		*generalAutoResizeContactList;

    //Groups
    IBOutlet 	NSView			*group_contact_PrefView;
    
    IBOutlet	NSColorWell		*groupGroupColor;

    IBOutlet	NSButton		*groupUseCustomFont;
    IBOutlet	NSPopUpButton	*groupFontPopUp;
    IBOutlet	NSPopUpButton	*groupFacePopUp;
    IBOutlet	NSPopUpButton	*groupSizePopUp;
    
    IBOutlet	NSButton		*groupShowChats;
    IBOutlet	NSButton		*groupShowStrangers;
    IBOutlet	NSButton		*groupShowOffline;
    IBOutlet	NSButton		*groupHideEmpty;



    //Contacts
    IBOutlet 	NSView			*contact_contact_PrefView;
    
    IBOutlet	NSButton		*contactShowStatusIcons;
    IBOutlet	NSButton		*contactAllowNameColoring;

    IBOutlet	NSButton		*contactUseCustomSignedOnFont;
    IBOutlet	NSPopUpButton	*contactSignedOnFontPopUp;
    IBOutlet	NSPopUpButton	*contactSignedOnFacePopUp;
    IBOutlet	NSPopUpButton	*contactSignedOnSizePopUp;
    
    IBOutlet	NSButton		*contactUseCustomSignedOffFont;
    IBOutlet	NSPopUpButton	*contactSignedOffFontPopUp;
    IBOutlet	NSPopUpButton	*contactSignedOffFacePopUp;
    IBOutlet	NSPopUpButton	*contactSignedOffSizePopUp;
    
    IBOutlet	NSButton		*contactDisplayMouseOver;

    IBOutlet	NSButton		*contactUseCustomMouseOverFont;
    IBOutlet	NSPopUpButton	*contactMouseOverFontPopUp;
    IBOutlet	NSPopUpButton	*contactMouseOverFacePopUp;
    IBOutlet	NSPopUpButton	*contactMouseOverSizePopUp;

    IBOutlet	NSColorWell		*contactMouseOverBGColor;
    IBOutlet	NSColorWell		*contactMouseOverFGColor;
}
@end
#pragma mark -
@interface AIContactListPreferencesPlugin (General)
- (IBAction) setDefaultFontPopups: (id)sender;
- (IBAction) setBackgroundColor: (id)sender;

- (IBAction) gridOptions: (id)sender;						//show grid, alternating grid, grid color

- (IBAction) sortingOptions: (id)sender;					//alphabetize, sort idle and away

- (IBAction) setAutoResize: (id)sender;
@end
#pragma mark -
@interface AIContactListPreferencesPlugin (Groups)
- (IBAction) setGroupColor: (id)sender;

- (IBAction) setGroupUsesCustomFont: (id)sender;
- (IBAction) setGroupCustomFontPopups: (id)sender;

- (IBAction) setShowSpecialGroups: (id)sender;
- (IBAction) hideEmptyGroups: (id)sender;
@end
#pragma mark -
@interface AIContactListPreferencesPlugin (Contacts)
- (IBAction) contactDisplayOptions: (id)sender;			//show status icons, allow name coloring

- (IBAction) setContactSignedOnUsesCustomFont: (id)sender;
- (IBAction) setContactSignedOnCustomFontPopups: (id)sender;

- (IBAction) setContactSignedOffUsesCustomFont: (id)sender;
- (IBAction) setContactSignedOffCustomFontPopups: (id)sender;

- (IBAction) setDisplayMouseOver: (id)sender;

- (IBAction) setContactMouseOverUsesCustomFont: (id)sender;
- (IBAction) setContactMouseOverCustomFontPopups: (id)sender;

- (IBAction) setMouseOverColors: (id)sender;
@end