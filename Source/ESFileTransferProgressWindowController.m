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
	
	return (sharedTransferProgressInstance);
}

//Close the info window
+ (void)closeTransferProgressWindow
{
    if(sharedTransferProgressInstance){
        [sharedTransferProgressInstance closeWindow:nil];
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
	
	//Configure the scroll view
	[scrollView setHasVerticalScroller:YES];
	[scrollView setHasHorizontalScroller:NO];	
	if([scrollView respondsToSelector:@selector(setAutohidesScrollers:)]){
		[scrollView setAutohidesScrollers:YES];
	}
	
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
#warning This entire function will not be needed if using a proper table; simply reload the table data here
- (void)progressRowDidAwakeFromNib:(ESFileTransferProgressRow *)progressRow
{
	NSLog(@"**** progressRowDidAwakeFromNib %@ -- %@",progressRow,[progressRow view]);
	
	NSView			*newProgressView = [progressRow view];
	NSRect			currentViewFrame = [view frame];
	NSRect			newProgressViewFrame = [newProgressView frame];

	unsigned int	indexOfNewRow = [progressRows indexOfObject:progressRow];
	
	float			desiredOrigin;
	float			desiredWidth;
	
	if(indexOfNewRow == 0){
		desiredOrigin = (currentViewFrame.size.height+currentViewFrame.origin.y) - newProgressViewFrame.size.height;
	}else{
		NSRect	previousProgressViewFrame = [[(ESFileTransferProgressRow *)[progressRows objectAtIndex:(indexOfNewRow - 1)] view] frame];
		desiredOrigin = (previousProgressViewFrame.origin.y - newProgressViewFrame.size.height);
	}

	desiredWidth = currentViewFrame.size.width;

	NSLog(@"current height: %f - current origin: %f = %f ; compare to content height %f",
		  currentViewFrame.size.height,
		  currentViewFrame.origin.y,
		  (currentViewFrame.size.height - currentViewFrame.origin.y),
		  [scrollView contentSize].height);

	if((currentViewFrame.size.height - currentViewFrame.origin.y) > [scrollView contentSize].height){				
//#warning Magic number.  I do not understand why rows are shifting 15 pixels wider after the first.
		NSLog(@"+++ %f - %f = %f",
			  desiredWidth,
			  [NSScroller scrollerWidthForControlSize:[[scrollView verticalScroller] controlSize]],
			  desiredWidth-[NSScroller scrollerWidthForControlSize:[[scrollView verticalScroller] controlSize]]);
		
		desiredWidth -= [NSScroller scrollerWidthForControlSize:[[scrollView verticalScroller] controlSize]];
	}
	
	NSLog(@"+++ desiredWidth for %@ at %i is %f",progressRow,indexOfNewRow,desiredWidth);
	
	//Add the progress view to our view
	[view addSubview:newProgressView];

	//Increase the containing view's frame by the height of the view we will be adding
	if(desiredOrigin < 0){
		currentViewFrame.size.height -= desiredOrigin;	/* Height increases by the amount needed */
		currentViewFrame.origin.y += desiredOrigin;		/* Origin decreases by the amount needed */
		NSLog(@"desiredOrigin < 0 so Positioning %@ setFrame: %@ [was %@] in windowframe %@",view,NSStringFromRect(currentViewFrame),NSStringFromRect([view frame]),NSStringFromRect([[view window] frame]));
		[view setFrame:currentViewFrame];
		desiredOrigin = 0;								/* We are now supposed to be lined up with the y origin */
	}
	
	//Position it at the bottom
	newProgressViewFrame.origin = NSMakePoint(0,desiredOrigin);
	
	//And with the appropriate width
	newProgressViewFrame.size.width = desiredWidth;
	
	NSLog(@"!!! Positioning %@ setFrame: %@",newProgressView,NSStringFromRect(newProgressViewFrame));
	[newProgressView setFrame:newProgressViewFrame];
	[newProgressView setNeedsDisplay:YES];

	[view setNeedsDisplay:YES];
	NSLog(@"Done.");
}

#pragma mark Progress row details twiddle
//Called when the file transfer view's twiddle is clicked.
- (void)fileTransferProgressRow:(ESFileTransferProgressRow *)inRow
			  heightChangedFrom:(float)oldHeight
							 to:(float)newHeight
{
	NSRect			currentViewFrame = [view frame];
	unsigned int	progressRowsCount = [progressRows count];
	unsigned int	indexOfNewRow = [progressRows indexOfObject:inRow];
	unsigned int	index;
	float			heightDifference = (newHeight - oldHeight);
	
	//Modify the contianing view's frame for the new height
	currentViewFrame.size.height += heightDifference;
	currentViewFrame.origin.y -= heightDifference;
	
	//Move each view which is below this new view down by the change in height
	for(index = indexOfNewRow+1; index < progressRowsCount; index++){
		ESFileTransferProgressView	*thisRowView = [(ESFileTransferProgressRow *)[progressRows objectAtIndex:index] view];
		NSRect	thisRowFrame = [thisRowView frame];
		
		thisRowFrame.origin.y -= heightDifference;
		NSLog(@"%@ now has an origin of %f after being changed by %f",thisRowView,thisRowFrame.origin.y,heightDifference);
		
#if 0
		//If this pushes the current row outside the view's frame, increase the size of the view as needed
		if(thisRowFrame.origin.y < 0){
			
			currentViewFrame.size.height -= thisRowFrame.origin.y;	/* Height increases by the amount needed */
			currentViewFrame.origin.y += thisRowFrame.origin.y;		/* Origin decreases by the amount needed */
			
			thisRowFrame.origin.y = 0;								/* We are now supposed to be lined up with the y origin */			
		}
#endif
		[thisRowView setFrame:thisRowFrame];
	}
	
	NSLog(@"Changing %@ from %@ to %@",view,NSStringFromRect([view frame]),NSStringFromRect(currentViewFrame));
	[view setFrame:currentViewFrame];
	
	//Display immediately to avoid flickering
	[view display];
}


#pragma mark Adding file transfers
//Notification of a new file transfer; add it to the window
- (void)newFileTransfer:(NSNotification *)notification
{
	ESFileTransfer	*fileTransfer = [notification object];
	
	if(fileTransfer){
		[self addFileTransfer:fileTransfer];
	}
}

- (void)addFileTransfer:(ESFileTransfer *)fileTransfer
{
	ESFileTransferProgressRow *progressRow;
	
	progressRow = [ESFileTransferProgressRow rowForFileTransfer:fileTransfer withOwner:self];
	[progressRows addObject:progressRow];
}

#pragma mark Selecting rows
//Used by rows to request becoming the selected row (after a mouseDown or key event);
- (void)setSelectedRow:(ESFileTransferProgressRow *)inRow
{
	if(inRow != selectedRow){
		[selectedRow setIsSelected:NO];
		
		[selectedRow release]; selectedRow = [inRow retain];
		[inRow setIsSelected:YES];
	}
}
//Handle up and down for changing the selected row.
//XXX toDo - also handle delete, either here or in the view itself
- (void)keyDown:(NSEvent *)inEvent
{
	NSString *charactersIgnoringModifiers = [inEvent charactersIgnoringModifiers];
	BOOL	handled = NO;
	
	if([charactersIgnoringModifiers length]) {
		unichar		 inChar = [charactersIgnoringModifiers characterAtIndex:0];
		if(inChar == NSUpArrowFunctionKey){
			[self setSelectedRow:[self previousRow]];
			handled = YES;
			
		}else if(inChar == NSDownArrowFunctionKey){
			[self setSelectedRow:[self nextRow]];
			handled = YES;
		}
	}
	
	//Send key down events to the currently selected row (to support the delete key, for example)
	if(!handled){
		[super keyDown:inEvent];
	}
}

//Previous visible row, which is one closer to 0 in our index, the top of the list
- (ESFileTransferProgressRow *)previousRow
{
	unsigned index = (selectedRow ? [progressRows indexOfObject:selectedRow] : NSNotFound);
	if((index != NSNotFound) && (index > 0)){
		return([progressRows objectAtIndex:(index - 1)]);
		
	}else{
		//With no valid selected row, start at the bottom
		return([progressRows count] ? [progressRows lastObject] : nil);
	}
}


//Next visible row, which is one closer to the end of our index, the bottom of the list
- (ESFileTransferProgressRow *)nextRow
{
	unsigned index = (selectedRow ? [progressRows indexOfObject:selectedRow] : NSNotFound);
	if((index != NSNotFound) && ((index + 1) < [progressRows count])){
		return([progressRows objectAtIndex:(index + 1)]);
		
	}else{
		//With no valid selected row, start at the top
		return([progressRows count] ? [progressRows objectAtIndex:0] : nil);
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
	unsigned	downloads = 0;
	unsigned	uploads = 0;
	NSString	*statusBarString;
	
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
	
	if(downloads && uploads){
		statusBarString = [NSString stringWithFormat:AILocalizedString(@"%i downloads; %i uploads","(number) downloads; (number) uploads"),
			downloads, uploads];
	}else if(downloads){
		statusBarString = [NSString stringWithFormat:AILocalizedString(@"%i downloads","(number) downloads"), downloads];
	}else if(uploads){
		statusBarString = [NSString stringWithFormat:AILocalizedString(@"%i uploads","(number) uploads"), uploads];
	}else{
		statusBarString = @"";
	}
	
	[textField_statusBar setStringValue:statusBarString];
}
@end
