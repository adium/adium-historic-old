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

#define ADD_LINK_TITLE          AILocalizedString(@"Add Link...",nil)
#define EDIT_LINK_TITLE         AILocalizedString(@"Edit Link...",nil)

@implementation SHLinkManagementPlugin

- (void)installPlugin
{
    menu_AddLink = [[[NSMenuItem alloc] initWithTitle:ADD_LINK_TITLE
                                               target:self
                                               action:@selector(addFormattedLink:)
                                        keyEquivalent:@"["] autorelease];
    [[adium menuController] addMenuItem:menu_AddLink toLocation:LOC_Edit_Bottom];
    
    menu_EditLink = [[[NSMenuItem alloc] initWithTitle:EDIT_LINK_TITLE
                                                target:self
                                                action:@selector(editFormattedLink:)
                                         keyEquivalent:@"]"] autorelease];
    [[adium menuController] addMenuItem:menu_EditLink toLocation:LOC_Edit_Bottom];
    
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:LINK_MANAGEMENT_DEFAULTS forClass:[self class]]
                                          forGroup:PREF_GROUP_LINK_FAVORITES];
    
    preferences = [[SHLinkFavoritesPreferences preferencePane] retain];
}

- (void)uninstallPlugin
{
}

- (IBAction)addFormattedLink:(id)sender
{
    //add a new link
    NSResponder         *responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
    if([responder isKindOfClass:[NSTextView class]]){
        [[[SHLinkEditorWindowController alloc] initAddLinkWindowControllerWithResponder:responder] autorelease];
    }
}

- (IBAction)editFormattedLink:(id)sender
{
    //edit existing link/text
    NSResponder         *responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
    if([responder isKindOfClass:[NSTextView class]]) {
        [[[SHLinkEditorWindowController alloc] initEditLinkWindowControllerWithResponder:responder] autorelease];
    }
}

@end
