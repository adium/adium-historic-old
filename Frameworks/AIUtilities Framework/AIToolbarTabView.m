/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

/* AIToolbarTabView

	This is a special tab view subclass that's useful in creating preference-type windows.  The tabview will
	automatically create a window toolbar and add an toolbar item for each tab it contains.  The tabview
	delegate will be asked for the toolbar images.

	This class also contains methods for auto-sizing the parent window based on the selected tab.  The delegate
	is asked for the window size, and this tabview takes care of the animation.
	
*/

#import "AIToolbarTabView.h"

@interface AIToolbarTabView (PRIVATE)
- (void)installToolbarItems;
@end

@implementation AIToolbarTabView

- (void)awakeFromNib
{
	//
    toolbarItems = [[NSMutableDictionary dictionary] retain];
	oldHeight = 100; //Height of the original tab view content
	
	//Create our toolbar
	NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:@"ToolbarTabView"] autorelease];
    [toolbar setDelegate:self];
    [toolbar setAllowsUserCustomization:NO];
    [toolbar setAutosavesConfiguration:NO];
	
	[self installToolbarItems];
    [[self window] setToolbar:toolbar];
}

//Dealloc
- (void)dealloc
{
	[toolbarItems release];
	
	[super dealloc];
}


//Toolbar --------------------------------------------------------------------------------------------------------------
#pragma mark Toolbar
//Install a toolbar item for each tab view item we contain
- (void)installToolbarItems
{	
	if([[self delegate] respondsToSelector:@selector(tabView:imageForTabViewItem:)]){
		int	i;

		for(i = 0; i < [self numberOfTabViewItems]; i++){
			NSTabViewItem	*tabViewItem = [self tabViewItemAtIndex:i];
			NSString 		*identifier = [tabViewItem identifier];
			NSString		*label = [tabViewItem label];
			
			if(![toolbarItems objectForKey:identifier]){
				[AIToolbarUtilities addToolbarItemToDictionary:toolbarItems
												withIdentifier:identifier
														 label:label
												  paletteLabel:label
													   toolTip:label
														target:self
											   settingSelector:@selector(setImage:)
												   itemContent:[[self delegate] tabView:self
																	imageForTabViewItem:tabViewItem]
														action:@selector(selectCategory:)
														  menu:NULL];
			}
		}

		[[[self window] toolbar] setConfigurationFromDictionary:toolbarItems];
	}
}

//Select the category that invoked this method
- (IBAction)selectCategory:(id)sender
{
    //Take focus away from any controls to ensure that they register changes and save
    [[self window] makeFirstResponder:self];
    [self selectTabViewItemWithIdentifier:[sender itemIdentifier]];
}

//Enable all categories
- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    return(YES);
}

//Access to our toolbar items
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
	 itemForItemIdentifier:(NSString *)itemIdentifier
 willBeInsertedIntoToolbar:(BOOL)flag
{
    return([AIToolbarUtilities toolbarItemFromDictionary:toolbarItems withIdentifier:itemIdentifier]);
}

//Default set (All items, sorted by name)
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return([[toolbarItems allKeys] sortedArrayUsingSelector:@selector(compare:)]);
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return([self toolbarDefaultItemIdentifiers:toolbar]);
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
    return([self toolbarDefaultItemIdentifiers:toolbar]);
}


//Window Resizing ------------------------------------------------------------------------------------------------------
#pragma mark Window Resizing
//Resize our window when the tabview selection changes
- (void)selectTabViewItem:(NSTabViewItem *)tabViewItem
{
	if(tabViewItem != [self selectedTabViewItem] && [self respondsToSelector:@selector(setHidden:)]) [self setHidden:YES];
	
	//Select
	[super selectTabViewItem:tabViewItem];
	
	//Resize the window
	if([[self delegate] respondsToSelector:@selector(tabView:heightForTabViewItem:)]){
		int		height = [[self delegate] tabView:self heightForTabViewItem:tabViewItem];
		
		BOOL	isVisible = [[self window] isVisible];
		NSRect 	frame = [[self window] frame];
		
		//Factor out old view's height, factor in new view's height		
		frame.size.height += (height - oldHeight);
		frame.origin.y -= (height - oldHeight);
		oldHeight = height;
		
		[[self window] setFrame:frame display:isVisible animate:isVisible];		
	}
	
	if([self respondsToSelector:@selector(setHidden:)]) [self setHidden:NO];
}

@end
