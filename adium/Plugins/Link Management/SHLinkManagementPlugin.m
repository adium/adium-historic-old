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
    //Add Link.. menu item (edit menu)
    menu_AddLink = [[[NSMenuItem alloc] initWithTitle:ADD_LINK_TITLE
                                               target:self
                                               action:@selector(addFormattedLink:)
                                        keyEquivalent:@"["] autorelease];
    [[adium menuController] addMenuItem:menu_AddLink toLocation:LOC_Edit_Bottom];
    
    //contextual menu
#ifdef USE_TEXTVIEW_CONTEXTMENUS
    contextMenu_AddLink = [[menu_AddLink copy] autorelease];
    [contextMenu_AddLink setKeyEquivalent:@""];
    [[adium menuController] addContextualMenuItem:contextMenu_AddLink toLocation:Context_TextView_LinkAction];
#endif
    
    //Edit Link... menu item (edit menu)
    menu_EditLink = [[[NSMenuItem alloc] initWithTitle:EDIT_LINK_TITLE
                                                target:self
                                                action:@selector(editFormattedLink:)
                                         keyEquivalent:@"]"] autorelease];
    [[adium menuController] addMenuItem:menu_EditLink toLocation:LOC_Edit_Bottom];
    
    //context menu
#ifdef USE_TEXTVIEW_CONTEXTMENUS
    contextMenu_EditLink = [[menu_EditLink copy] autorelease];
    [contextMenu_EditLink setKeyEquivalent:@""];
    [[adium menuController] addContextualMenuItem:contextMenu_EditLink toLocation:Context_TextView_LinkAction];
#endif
    
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
