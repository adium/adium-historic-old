//
//  SHLinkManagementPlugin.m
//  Adium
//
//  Created by Stephen Holt on Fri Apr 16 2004.

#import "SHLinkManagementPlugin.h"
#import "SHLinkEditorWindowController.h"
#import "SHLinkFavoritesManageView.h"
#import "SHLinkFavoritesPreferences.h"
#import "SHAutoValidatingTextView.h"

#define EDIT_LINK_TITLE         AILocalizedString(@"Add/Edit Link...",nil)

@implementation SHLinkManagementPlugin

- (void)installPlugin
{
    //Add/Edit Link... menu item (edit menu)
    menu_EditLink = [[[NSMenuItem alloc] initWithTitle:EDIT_LINK_TITLE
                                                target:self
                                                action:@selector(editFormattedLink:)
                                         keyEquivalent:@"k"] autorelease];
    [[adium menuController] addMenuItem:menu_EditLink toLocation:LOC_Edit_Additions];
    
    //context menu
    contextMenu_EditLink = [[menu_EditLink copy] autorelease];
    [contextMenu_EditLink setKeyEquivalent:@""];
    [[adium menuController] addContextualMenuItem:contextMenu_EditLink toLocation:Context_TextView_LinkAction];
    
    if(![[adium preferenceController] preferenceForKey:INITAL_FAVES group:PREF_GROUP_GENERAL]){
        [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:LINK_MANAGEMENT_DEFAULTS forClass:[self class]]
                                          forGroup:PREF_GROUP_LINK_FAVORITES];
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:YES] forKey:INITAL_FAVES group:PREF_GROUP_GENERAL];
    }
    
    preferences = [[SHLinkFavoritesPreferences preferencePane] retain];
}

- (void)uninstallPlugin
{
}

- (IBAction)editFormattedLink:(id)sender
{
    //edit existing link/text
    NSResponder *responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
    if([responder isKindOfClass:[NSTextView class]] && [(NSTextView *)responder isEditable]){
        if([(NSTextView *)responder selectedRange].length != 0) {
            [[SHLinkEditorWindowController alloc] initEditLinkWindowControllerWithResponder:responder];
        }else{ //if nothing selected, add link.
            [[SHLinkEditorWindowController alloc] initAddLinkWindowControllerWithResponder:responder];
        }
    }
}

@end
