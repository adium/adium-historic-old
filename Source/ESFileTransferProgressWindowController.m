//
//  ESFileTransferProgressWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on 11/14/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import "ESFileTransferProgressWindowController.h"
#import "ESFileTransferProgressRow.h"

#define FILE_TRANSFER_PROGRESS_NIB			@"FileTransferProgressWindow"
#define KEY_TRANSFER_PROGRESS_WINDOW_FRAME	@"Transfer Progress Window Frame"

@interface ESFileTransferProgressWindowController (PRIVATE)
- (void)addFileTransfer:(ESFileTransfer *)fileTransfer;
- (IBAction)closeWindow:(id)sender;
- (ESFileTransferProgressRow *)previousRow;
- (ESFileTransferProgressRow *)nextRow;
- (void)updateStatusBar;
- (void)reloadAllData;

- (void)_removeFileTransfer:(ESFileTransfer *)inFileTransfer;
- (void)_removeFileTransferRow:(ESFileTransferProgressRow *)progressRow;
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
	
	[[self window] setTitle:AILocalizedString(@"File Transfer Progress",nil)];

	//Configure the scroll view
	[scrollView setHasVerticalScroller:YES];
	[scrollView setHasHorizontalScroller:NO];
	[[scrollView contentView] setCopiesOnScroll:NO];
	if([scrollView respondsToSelector:@selector(setAutohidesScrollers:)]){
		[scrollView setAutohidesScrollers:YES];
	}

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

	[self reloadAllData];
}

//Close the window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

//called as the window closes
- (BOOL)windowShouldClose:(id)sender
{	
	//release the window controller (ourself)
    sharedTransferProgressInstance = nil;
    [self autorelease];

	return(YES);
}

//Called when a progress row has loaded its view and is ready to be added to our window
#pragma mark Progress row addition to the window
- (void)progressRowDidAwakeFromNib:(ESFileTransferProgressRow *)progressRow
{
	if(![progressRows containsObject:progressRow]){
		[progressRows addObject:progressRow];
	}

	[self reloadAllData];
	
	NSClipView	*clipView = [scrollView contentView];
	[clipView scrollToPoint:[clipView constrainScrollPoint:([outlineView rectOfRow:[progressRows indexOfObject:progressRow]].origin)]];
}

#pragma mark Progress row details twiddle
//Called when the file transfer view's twiddle is clicked.
- (void)fileTransferProgressRow:(ESFileTransferProgressRow *)progressRow
			  heightChangedFrom:(float)oldHeight
							 to:(float)newHeight
{
	[self reloadAllData];

	NSClipView	*clipView = [scrollView contentView];	
	[clipView scrollToPoint:[clipView constrainScrollPoint:([outlineView rectOfRow:[progressRows indexOfObject:progressRow]].origin)]];
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

//Add a file transfer's progress row.  This will call back on progressRowDidAwakeFromNib:
- (void)addFileTransfer:(ESFileTransfer *)fileTransfer
{
	ESFileTransferProgressRow *progressRow;

	progressRow = [ESFileTransferProgressRow rowForFileTransfer:fileTransfer withOwner:self];

	//Depending on how the nib is loaded, we may or may not already have called progressRowDidAwakeFromNib:
	//and added the row there.
	if(![progressRows containsObject:progressRow]){
		[progressRows addObject:progressRow];
	}	
}

- (void)_removeFileTransfer:(ESFileTransfer *)inFileTransfer
{
	NSEnumerator				*enumerator = [progressRows objectEnumerator];
	ESFileTransferProgressRow	*row;
	
	while(row = [enumerator nextObject]){
		if([row fileTransfer] == inFileTransfer) break;
	}
	
	if(row) [self _removeFileTransferRow:row];
}

//Remove a file transfer row from the window. This is coupled to the file transfer controller; care must be taken
//that we don't remove a row which is in progress, as this will remove the file transfer controller's tracking of it.
//This must be done so we don't see the file transfer again if the progress window is closed and then reopened.
- (void)_removeFileTransferRow:(ESFileTransferProgressRow *)progressRow
{
	if([progressRow isStopped]){
		ESFileTransfer	*fileTransfer = [progressRow fileTransfer];
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

- (void)outlineViewDeleteSelectedRows:(NSOutlineView *)inOutlineView
{
	unsigned	row = [inOutlineView selectedRow];
	BOOL		didDelete = NO;
	if(row != -1){
		ESFileTransferProgressRow	*progressRow = [inOutlineView itemAtRow:row];
		if([progressRow isStopped]){
			[self _removeFileTransferRow:progressRow];
			didDelete = YES;
		}
	}
	
	//If they tried to delete a row that isn't finished, or we got here with no valid selection, sound the system beep
	if(!didDelete)
		NSBeep();
}

- (void)reloadAllData
{
	[[[[outlineView subviews] copy] autorelease] makeObjectsPerformSelector:@selector(removeFromSuperviewWithoutNeedingDisplay)];
	
	[outlineView reloadData];
}

#pragma mark Window zoom
//Size for window zoom
- (NSRect)windowWillUseStandardFrame:(NSWindow *)inWindow defaultFrame:(NSRect)defaultFrame
{
	NSRect	windowFrame = [inWindow frame];
	NSSize	minSize = [inWindow minSize];
	NSSize	maxSize = [inWindow maxSize];
				
	//Take the desired height and add the parts of the window which aren't in the scrollView.
	int desiredHeight = ([outlineView totalHeight] + (windowFrame.size.height - [scrollView frame].size.height));
	
	//Keep the top-left corner the same
	windowFrame.origin.y = windowFrame.origin.y + windowFrame.size.height - desiredHeight;
	windowFrame.size.height = desiredHeight;
	
	windowFrame.size.width = 300;
	
	//Respect the min and max sizes
	if(windowFrame.size.width < minSize.width) windowFrame.size.width = minSize.width;
	if(windowFrame.size.height < minSize.height) windowFrame.size.height = minSize.height;
	if(windowFrame.size.width > maxSize.width) windowFrame.size.width = maxSize.width;
	if(windowFrame.size.height > maxSize.height) windowFrame.size.height = maxSize.height;
				
    return(windowFrame);
}

@end
