/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "ESFileTransferProgressRow.h"
#import "ESFileTransferProgressView.h"
#import "ESFileTransferProgressWindowController.h"
#import <AIUtilities/AIVariableHeightOutlineView.h>
#import <AIUtilities/BZGenericViewCell.h>
#import <Adium/ESFileTransfer.h>

#define FILE_TRANSFER_PROGRESS_NIB			@"FileTransferProgressWindow"
#define KEY_TRANSFER_PROGRESS_WINDOW_FRAME	@"Transfer Progress Window Frame"

@interface ESFileTransferProgressWindowController (PRIVATE)
- (void)addFileTransfer:(ESFileTransfer *)fileTransfer;
- (ESFileTransferProgressRow *)previousRow;
- (ESFileTransferProgressRow *)nextRow;
- (void)updateStatusBar;
- (void)reloadAllData;
- (void)_removeFileTransfer:(ESFileTransfer *)inFileTransfer;
- (ESFileTransferProgressRow *)existingRowForFileTransfer:(ESFileTransfer *)inFileTransfer;
@end

@interface ESFileTransferController (PRIVATE)
- (void)_removeFileTransfer:(ESFileTransfer *)fileTransfer;
@end

@implementation ESFileTransferProgressWindowController

static ESFileTransferProgressWindowController *sharedTransferProgressInstance = nil;

//Return the shared contact info window
#pragma mark Class Methods
+ (id)showFileTransferProgressWindow
{
    //Create the window
    if(!sharedTransferProgressInstance){
        sharedTransferProgressInstance = [[self alloc] initWithWindowNibName:FILE_TRANSFER_PROGRESS_NIB];
	}
	
	//Configure and show window
	[sharedTransferProgressInstance showWindow:nil];
	[[sharedTransferProgressInstance window] orderFront:nil];
	
	return (sharedTransferProgressInstance);
}

//Close the info window
+ (void)closeTransferProgressWindow
{
    if(sharedTransferProgressInstance){
        [sharedTransferProgressInstance closeWindow:nil];
    }
}

+ (void)removeFileTransfer:(ESFileTransfer *)inFileTransfer
{
    if(sharedTransferProgressInstance){
        [sharedTransferProgressInstance _removeFileTransfer:inFileTransfer];
    }	
}
//init
#pragma mark Basic window controller functionality
- (id)initWithWindowNibName:(NSString *)windowNibName
{    
    [super initWithWindowNibName:windowNibName];
	
	progressRows = [[NSMutableArray alloc] init];
	
    return(self);    
}

- (void)dealloc
{
	[[adium notificationCenter] removeObserver:self];

	[progressRows release]; progressRows = nil;
    [super dealloc];
}	

//
- (NSString *)adiumFrameAutosaveName
{
	return(KEY_TRANSFER_PROGRESS_WINDOW_FRAME);
}

//Setup the window before it is displayed
- (void)windowDidLoad
{    
	NSEnumerator	*enumerator;
	ESFileTransfer	*fileTransfer;
	
	[super windowDidLoad];
	
	//Set the localized title
	[[self window] setTitle:AILocalizedString(@"File Transfers",nil)];

	//There's already a menu item in the Window menu; no reason to duplicate it
	[[self window] setExcludedFromWindowsMenu:YES];

	//Configure the scroll view
	[scrollView setHasVerticalScroller:YES];
	[scrollView setHasHorizontalScroller:NO];
	[[scrollView contentView] setCopiesOnScroll:NO];
	if([scrollView respondsToSelector:@selector(setAutohidesScrollers:)]){
		[scrollView setAutohidesScrollers:YES];
	}

	//Configure the outline view
	BZGenericViewCell	*cell = [[[BZGenericViewCell alloc] init] autorelease];
	[cell setDrawsGradientHighlight:YES];
	[[[outlineView tableColumns] objectAtIndex:0] setDataCell:cell];

	[outlineView sizeLastColumnToFit];
	[outlineView setAutoresizesSubviews:YES];
	[outlineView setAutoresizesAllColumnsToFit:YES];
	[outlineView setDrawsAlternatingRows:YES];
	[outlineView setDataSource:self];
	[outlineView setDelegate:self];

	//Observe for new file transfers
	[[adium notificationCenter] addObserver:self
                                   selector:@selector(newFileTransfer:)
                                       name:FileTransfer_NewFileTransfer
									 object:nil];	

	//Create progress rows for all existing file transfers	
	enumerator = [[[adium fileTransferController] fileTransferArray] objectEnumerator];
	while(fileTransfer = [enumerator nextObject]){
		[self addFileTransfer:fileTransfer];
	}

	//Update our status bar
	[self updateStatusBar];

	//Go time
	[self reloadAllData];
}

//called as the window closes
- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
		
	//release the window controller (ourself)
    sharedTransferProgressInstance = nil;
    [self autorelease];
}

//Called when a progress row has loaded its view and is ready to be added to our window
#pragma mark Progress row addition to the window
- (void)progressRowDidAwakeFromNib:(ESFileTransferProgressRow *)progressRow
{
	if(![progressRows containsObject:progressRow]){
		[progressRows addObject:progressRow];
	}

	[self reloadAllData];

	[outlineView scrollRectToVisible:[outlineView rectOfRow:[progressRows indexOfObject:progressRow]]];	
}

#pragma mark Progress row details twiddle
//Called when the file transfer view's twiddle is clicked.
- (void)fileTransferProgressRow:(ESFileTransferProgressRow *)progressRow
			  heightChangedFrom:(float)oldHeight
							 to:(float)newHeight
{
	[self reloadAllData];

	[outlineView scrollRectToVisible:[outlineView rectOfRow:[progressRows indexOfObject:progressRow]]];
}

#pragma mark Adding file transfers
//Notification of a new file transfer; add it to the window
- (void)newFileTransfer:(NSNotification *)notification
{
	ESFileTransfer	*fileTransfer;
	
	if(fileTransfer = [notification object]){
		[self addFileTransfer:fileTransfer];
	}
}

//Add a file transfer's progress row if we don't already have one for the fileTransfer.
//This will call back on progressRowDidAwakeFromNib: if it adds a new row.
- (void)addFileTransfer:(ESFileTransfer *)inFileTransfer
{
	ESFileTransferProgressRow *progressRow;
	
	if(!(progressRow = [self existingRowForFileTransfer:inFileTransfer])){
		progressRow = [ESFileTransferProgressRow rowForFileTransfer:inFileTransfer withOwner:self];
		
		//Depending on how the nib is loaded, we may or may not already have called progressRowDidAwakeFromNib:
		//and added the row there.
		if(![progressRows containsObject:progressRow]){
			[progressRows addObject:progressRow];
		}
	}
}

- (void)_removeFileTransfer:(ESFileTransfer *)inFileTransfer
{
	ESFileTransferProgressRow	*row;
	
	if(row = [self existingRowForFileTransfer:inFileTransfer]) [self _removeFileTransferRow:row];
}

- (ESFileTransferProgressRow *)existingRowForFileTransfer:(ESFileTransfer *)inFileTransfer
{
	NSEnumerator				*enumerator = [progressRows objectEnumerator];
	ESFileTransferProgressRow	*row;
		
	while(row = [enumerator nextObject]){
		if([row fileTransfer] == inFileTransfer) break;
	}
	
	return(row);
}

//Remove a file transfer row from the window. This is coupled to the file transfer controller; care must be taken
//that we don't remove a row which is in progress, as this will remove the file transfer controller's tracking of it.
//This must be done so we don't see the file transfer again if the progress window is closed and then reopened.
- (void)_removeFileTransferRow:(ESFileTransferProgressRow *)progressRow
{
	ESFileTransfer	*fileTransfer = [progressRow fileTransfer];

	if([fileTransfer isStopped]){
		NSClipView		*clipView = [scrollView contentView];
		unsigned		row;
		
		//Protect
		[progressRow retain];
		
		//Remove the row from our array, and its file transfer from the fileTransferController
		row = [progressRows indexOfObject:progressRow];
		[progressRows removeObject:progressRow];
		[[adium fileTransferController] _removeFileTransfer:fileTransfer];
		
		//Refresh the outline view
		[self reloadAllData];
		
		//Determine the row to reselect.  If the current row is valid, keep it.  If it isn't, use the last row.
		if(row >= [progressRows count]){
			row = [progressRows count] - 1;
		}
		[clipView scrollToPoint:[clipView constrainScrollPoint:([outlineView rectOfRow:row].origin)]];
		
		//Clean up
		[progressRow release];
		
		[self updateStatusBar];
	}
}
							   
#pragma mark Status bar
//Called when a progress row changes its type, typically from Unknown to either Incoming or Outgoing
- (void)progressRowDidChangeType:(ESFileTransferProgressRow *)progressRow
{
	[self updateStatusBar];
}

//Update the status bar at the bottom of the window
- (void)updateStatusBar
{
	NSString	*statusBarString;
	NSString	*downloadsString = nil;
	NSString	*uploadsString = nil;
	unsigned	downloads = 0;
	unsigned	uploads = 0;

	NSEnumerator				*enumerator = [progressRows objectEnumerator];
	ESFileTransferProgressRow	*aRow;
	while(aRow = [enumerator nextObject]){
		FileTransferType type = [aRow type];
		if(type == Incoming_FileTransfer){
			downloads++;
		}else if(type == Outgoing_FileTransfer){
			uploads++;
		}
	}

	if(downloads > 0){
		if(downloads == 1)
			downloadsString = AILocalizedString(@"1 download",nil);
		else
			downloadsString = [NSString stringWithFormat:AILocalizedString(@"%i downloads","(number) downloads"), downloads];
	}

	if(uploads > 0){
		if(uploads == 1)
			uploadsString = AILocalizedString(@"1 upload",nil);
		else
			uploadsString = [NSString stringWithFormat:AILocalizedString(@"%i uploads","(number) uploads"), downloads];		
	}

	if(downloadsString && uploadsString){
		statusBarString = [NSString stringWithFormat:@"%@; %@",downloadsString,uploadsString];
	}else if(downloadsString){
		statusBarString = downloadsString;
	}else if(uploadsString){
		statusBarString = uploadsString;
	}else{
		statusBarString = @"";
	}

	[textField_statusBar setStringValue:statusBarString];
}

#pragma mark OutlineView dataSource
- (id)outlineView:(NSOutlineView *)inOutlineView child:(int)index ofItem:(id)item
{
	if(index < [progressRows count]) {
		return([progressRows objectAtIndex:index]);
	} else {
		return nil;
	}	
}

- (int)outlineView:(NSOutlineView *)inOutlineView numberOfChildrenOfItem:(id)item
{
	return([progressRows count]);
}

//No items are expandable for the outline view
- (BOOL)outlineView:(NSOutlineView *)inOutlineView isItemExpandable:(id)item
{
	return(NO);
}

//We don't use object values
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	return(@"");
}

//Each row should be the height of its item's view
- (int)outlineView:(NSOutlineView *)inOutlineView heightForItem:(id)item atRow:(int)row
{
	return([[(ESFileTransferProgressRow *)item view] frame].size.height);
}

//Before a cell is display, set its embedded view
- (void)outlineView:(NSOutlineView *)inOutlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	[cell setEmbeddedView:[(ESFileTransferProgressRow *)item view]];
}

#pragma mark Outline view delegate
- (void)outlineViewDeleteSelectedRows:(NSOutlineView *)inOutlineView
{
	int		row = [inOutlineView selectedRow];
	BOOL	didDelete = NO;
	if(row != -1){
		ESFileTransferProgressRow	*progressRow = [inOutlineView itemAtRow:row];
		if([[progressRow fileTransfer] isStopped]){
			[self _removeFileTransferRow:progressRow];
			didDelete = YES;
		}
	}
	
	//If they tried to delete a row that isn't finished, or we got here with no valid selection, sound the system beep
	if(!didDelete)
		NSBeep();
}

- (void)outlineViewSelectionIsChanging:(NSNotification *)notification
{
	NSOutlineView	*inOutlineView = [notification object];
	
	int	row = [inOutlineView selectedRow];
	if(row != -1){
		[inOutlineView setNeedsDisplayInRect:[inOutlineView rectOfRow:row]];
	}
}

- (NSMenu *)outlineView:(NSOutlineView *)inOutlineView menuForEvent:(NSEvent *)inEvent
{
	NSMenu	*menu = nil;
    NSPoint	location;
    int		row;
	
    //Get the clicked item
    location = [inOutlineView convertPoint:[inEvent locationInWindow] 
								  fromView:[[inOutlineView window] contentView]];
    row = [inOutlineView rowAtPoint:location];

	if(row != -1){
		ESFileTransferProgressRow	*progressRow = [inOutlineView itemAtRow:row];
		menu = [progressRow menuForEvent:inEvent];
	}
	
	return(menu);
}

- (void)reloadAllData
{
	[[[[outlineView subviews] copy] autorelease] makeObjectsPerformSelector:@selector(removeFromSuperviewWithoutNeedingDisplay)];
	
	[outlineView reloadData];
	
	NSRect	outlineFrame = [outlineView frame];
	int		totalHeight = [outlineView totalHeight];
	
	if(outlineFrame.size.height != totalHeight){
		outlineFrame.size.height = totalHeight;
		[outlineView setFrame:outlineFrame];
		[outlineView setNeedsDisplay:YES];
	}
}

#pragma mark Window zoom
//Size for window zoom
- (NSRect)windowWillUseStandardFrame:(NSWindow *)inWindow defaultFrame:(NSRect)defaultFrame
{
	NSRect	oldWindowFrame = [inWindow frame];
	NSRect	windowFrame = oldWindowFrame;
	NSSize	minSize = [inWindow minSize];
	NSSize	maxSize = [inWindow maxSize];
				
	//Take the desired height and add the parts of the window which aren't in the scrollView.
	int desiredHeight = ([outlineView totalHeight] + (windowFrame.size.height - [scrollView frame].size.height));
	
	windowFrame.size.height = desiredHeight;	
	windowFrame.size.width = 300;
	
	//Respect the min and max sizes
	if(windowFrame.size.width < minSize.width) windowFrame.size.width = minSize.width;
	if(windowFrame.size.height < minSize.height) windowFrame.size.height = minSize.height;
	if(windowFrame.size.width > maxSize.width) windowFrame.size.width = maxSize.width;
	if(windowFrame.size.height > maxSize.height) windowFrame.size.height = maxSize.height;
	
	//Keep the top-left corner the same
	windowFrame.origin.y = oldWindowFrame.origin.y + oldWindowFrame.size.height - windowFrame.size.height;

    return(windowFrame);
}

@end
