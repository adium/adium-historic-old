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
	NSMenuItem	*menuItem;
	
	//Setup our preferences
	[[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:LINK_MANAGEMENT_DEFAULTS forClass:[self class]]
                                          forGroup:PREF_GROUP_LINK_FAVORITES];
    preferences = [[SHLinkFavoritesPreferences preferencePane] retain];

    //Add/Edit Link... menu item (edit menu)
    menuItem = [[[NSMenuItem alloc] initWithTitle:EDIT_LINK_TITLE
										   target:self
										   action:@selector(editFormattedLink:)
									keyEquivalent:@"k"] autorelease];
    [[adium menuController] addMenuItem:menuItem toLocation:LOC_Edit_Additions];
    
    //Context menu
    menuItem = [[[NSMenuItem alloc] initWithTitle:EDIT_LINK_TITLE
										   target:self
										   action:@selector(editFormattedLink:)
									keyEquivalent:@""] autorelease];
    [[adium menuController] addContextualMenuItem:menuItem toLocation:Context_TextView_LinkAction];
}

- (void)uninstallPlugin
{
	
}

//
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	//Update the menu item title to reflect its action
	
	
	//Disable the menu item if a text field is not key
	NSResponder	*responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
	return(responder && [responder isKindOfClass:[NSText class]]);
}

//
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
