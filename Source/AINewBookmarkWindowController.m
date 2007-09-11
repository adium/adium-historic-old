#import "AINewBookmarkWindowController.h"
#import "AIBookmarkController.h"
#import "AINewGroupWindowController.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>
#import <Adium/AIServiceMenu.h>
#import <AIInterfaceController.h>
#import <AIAccountController.h>

#define		ADD_BOOKMARK_NIB		@"AddBookmark"
#define		DEFAULT_GROUP_NAME		AILocalizedString(@"Contacts",nil)
@implementation AINewBookmarkWindowController

/*!
 * @brief Prompt for a new bookmark.
 *
 * @param parentWindow Window on which to show as a sheet. Pass nil for a panel prompt.
 */
+(AINewBookmarkWindowController *)promptForNewBookmarkOnWindow:(NSWindow*)parentWindow
{
	AINewBookmarkWindowController *newBookmarkWindowController;
	newBookmarkWindowController= [[self alloc] initWithWindowNibName:ADD_BOOKMARK_NIB];

	if(parentWindow) {
	   [NSApp beginSheet:[newBookmarkWindowController window]
		  modalForWindow:parentWindow
	   	   modalDelegate:self
		  didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			 contextInfo:nil];
	} else {
		[newBookmarkWindowController showWindow:nil];
		[[newBookmarkWindowController window] makeKeyAndOrderFront:nil];
	}
	
	return newBookmarkWindowController;
}

/*!
 *	@brief didEnd selector for the sheet created above, dismisses the sheet
 */
-(void)sheetDidEnd:(NSWindow*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo
{
	[sheet orderOut:nil];
}

/*!
 * @name windowDidLoad
 * @brief the sheet finished loading, populate the group menu with contactlist's groups
 */
-(void)windowDidLoad
{
	[self buildGroupMenu];
}

/*!
 * @name add
 * @brief User pressed ok on sheet - Calls createBookmarkWithInfo: on the delegate class AIBookmarkController, which creates 
 * a new bookmark with the entered name & moves it to the entered group.
 */
- (IBAction)add:(id)sender
{

	[delegate createBookmarkWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:[textField_name stringValue],@"bookmark name",[[popUp_group selectedItem] representedObject],@"bookmark group",nil]];
	[self closeWindow:nil];
}

/*!
 *@brief user pressed cancel on panel -dismisses the sheet
 */
- (IBAction)cancel:(id)sender
{
	[self closeWindow:nil];
}

-(void)setDelegate:(id)newDelegate
{
	if(delegate != newDelegate) {
		[delegate release];
		delegate = [newDelegate retain];
	}
}

-(id)delegate
{
	return delegate;
}

//Add to Group ---------------------------------------------------------------------------------------------------------
#pragma mark Add to Group
/*!
 * @brief Build the menu of available destination groups
 */
- (void)buildGroupMenu
{
	AIListObject	*selectedObject;
	NSMenu			*menu;
	//Rebuild the menu
	menu = [[adium contactController] menuOfAllGroupsInGroup:nil withTarget:self];

	//Add a default group name to the menu if there are no groups listed
	if ([menu numberOfItems] == 0) {
		[menu addItemWithTitle:DEFAULT_GROUP_NAME
						target:self
						action:nil
				 keyEquivalent:@""];
	}
	
	[menu addItem:[NSMenuItem separatorItem]];
	[menu addItemWithTitle:[AILocalizedString(@"New Group",nil) stringByAppendingEllipsis]
					target:self
					action:@selector(newGroup:)
			 keyEquivalent:@""];
	
	//Select the group of the currently selected object on the contact list
	selectedObject = [[adium interfaceController] selectedListObject];
	while (selectedObject && ![selectedObject isKindOfClass:[AIListGroup class]]) {
		selectedObject = [selectedObject containingObject];
	}

	[popUp_group setMenu:menu];

	//If there was no selected group, just select the first item
	if (selectedObject) {
		if (![popUp_group selectItemWithRepresentedObject:selectedObject]) {
			[popUp_group selectItemAtIndex:0];			
		}

	} else {
		[popUp_group selectItemAtIndex:0];
	}
}

/*!
 * @brief Prompt the user to add a new group immediately
 */
- (void)newGroup:(id)sender
{
	AINewGroupWindowController	*newGroupWindowController;
	
	newGroupWindowController = [AINewGroupWindowController promptForNewGroupOnWindow:[self window]];

	//Observe for the New Group window to close
	[[adium notificationCenter] addObserver:self
								   selector:@selector(newGroupDidEnd:) 
									   name:@"NewGroupWindowControllerDidEnd"
									 object:[newGroupWindowController window]];	
}
/*!
 * @name newGroupDidEnd:
 * @brief the New Group sheet has ended, if a new group was created, select it, otherwise
 * select the first group.
 */

- (void)newGroupDidEnd:(NSNotification *)inNotification
{
	NSWindow	*window = [inNotification object];

	if ([[window windowController] isKindOfClass:[AINewGroupWindowController class]]) {
		NSString	*newGroupUID = [[window windowController] newGroupUID];
		AIListGroup *group = [[adium contactController] existingGroupWithUID:newGroupUID];

		//Rebuild the group menu
		[self buildGroupMenu];
		
		/* Select the new group if it exists; otherwise select the first group (so we don't still have New Group... selected).
		 * If the user cancelled, group will be nil since the group doesn't exist.
		 */
		if (![popUp_group selectItemWithRepresentedObject:group]) {
			[popUp_group selectItemAtIndex:0];			
		}
		
		[[self window] performSelector:@selector(makeKeyAndOrderFront:)
							withObject:self
							afterDelay:0];
	}

	//Stop observing
	[[adium notificationCenter] removeObserver:self
										  name:@"NewGroupWindowControllerDidEnd" 
										object:window];
}

/*
 * Validate a menu item
 */
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	NSEnumerator	*enumerator = [[[adium accountController] accountsCompatibleWithService:[menuItem representedObject]] objectEnumerator];
	AIAccount		*account;
	
	while ((account = [enumerator nextObject])) {
		if ([account contactListEditable]) return YES;
	}
	
	return NO;
}

@end
