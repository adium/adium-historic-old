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

#define ADD_LINK_TITLE			AILocalizedString(@"Add Link...",nil)
#define EDIT_LINK_TITLE			AILocalizedString(@"Edit Link...",nil)

@interface SHLinkManagementPlugin (PRIVATE)
- (BOOL)textViewSelectionIsLink:(NSTextView *)textView;
@end

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

//Update our add/edit link menu item
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	NSResponder	*responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
	if(responder && [responder isKindOfClass:[NSTextView class]]){
		//Update the menu item's title to reflect the current action
		[menuItem setTitle:([self textViewSelectionIsLink:(NSTextView *)responder] ? EDIT_LINK_TITLE : ADD_LINK_TITLE)];

		return(YES);
	}else{
		return(NO); //Disable the menu item if a text field is not key
	}
	
}

//Add or edit a link
- (IBAction)editFormattedLink:(id)sender
{
	NSWindow	*keyWindow = [[NSApplication sharedApplication] keyWindow];
    NSResponder *responder = [keyWindow firstResponder];
	
    if([responder isKindOfClass:[NSTextView class]] && [(NSTextView *)responder isEditable]){
		[SHLinkEditorWindowController showLinkEditorForResponder:responder
														onWindow:keyWindow
												   showFavorites:YES];
    }
}

//Returns YES if a link is under the selection of the passed text view
- (BOOL)textViewSelectionIsLink:(NSTextView *)textView
{
	id		selectedLink = nil;
	
	if([[textView textStorage] length] &&
	   [textView selectedRange].location != NSNotFound &&
	   [textView selectedRange].location != [[textView textStorage] length]){
		NSRange selectionRange = [textView selectedRange];
		selectedLink = [[textView textStorage] attribute:NSLinkAttributeName
												 atIndex:selectionRange.location
										  effectiveRange:&selectionRange];
	}
	
	return(selectedLink != nil);
}

@end
