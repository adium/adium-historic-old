//
//  BZActivityWindowController.m
//  Adium
//
//  Created by Mac-arena the Bored Zo on Sat May 08 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "BZActivityWindowController.h"

#define STATUS_WINDOW_MENU_ITEM_NAME @"Activity"
#define STATUS_WINDOW_TOOLBAR_ID     @"com.adiumX.activity_window.toolbar"

@implementation BZActivityWindowController

- (void)initController
{
	progressViews = [[NSMutableArray alloc] initWithCapacity:0];
	if(progressViews) {
		[[table tableColumnWithIdentifier:TABLE_VIEW_ONLY_COLUMN] setDataCell:[[[BZGenericViewCell alloc] init] autorelease]];
		[table setAutoresizesSubviews:YES];

		//prepare a toolbar so the user can do things with the status items.
		{
			NSToolbar     *toolbar = [[NSToolbar alloc] initWithIdentifier:STATUS_WINDOW_TOOLBAR_ID];
			[toolbar setDelegate:self];
			[toolbar setAllowsUserCustomization:YES];
			[toolbar setAutosavesConfiguration:YES];
			[[self window] setToolbar:toolbar];
			[toolbar release];
		}

		//set up our menu item.
		NSMenuItem *showMeMenuItem = [[NSMenuItem alloc] initWithTitle:STATUS_WINDOW_MENU_ITEM_NAME action:@selector(showWindow:) keyEquivalent:@""];
		[showMeMenuItem setTarget:self];
		[[[AIObject sharedAdiumInstance] menuController] addMenuItem:showMeMenuItem toLocation:LOC_Window_Auxiliary];
	}
}

- (BOOL)addProgressTracker:(id <BZProgressTracker>)tracker
{
	BOOL successful = tracker && ![progressViews containsProgressViewWithTracker:tracker];
	if(successful) {
		NSRect frame = NSZeroRect;
		frame.size.height = [BZProgressView height];
		BZProgressView *progressView = [[BZProgressView alloc] initWithTracker:tracker inFrame:frame];
		if(progressView) {
			int newIdx = [progressViews count];
			[table addSubview:progressView];
			[progressViews addObject:progressView];
			[self updateProgressTracker:tracker withViewIndex:newIdx];

			[progressView release];
		}
	}
	return successful;
}

- (void)removeProgressTracker:(id <BZProgressTracker>)tracker
{
	int idx = [progressViews indexOfProgressViewWithTracker:tracker];
	if(idx != NSNotFound) {
		[self removeProgressTracker:tracker withViewIndex:idx];
		return;

		BZProgressView *progressView = [progressViews objectAtIndex:idx];
		[progressViews removeObjectAtIndex:idx];
		[progressView removeFromSuperview];
		[table reloadData];
	}
}

- (void)updateProgressTracker:(id <BZProgressTracker>)tracker
{
	int idx = [progressViews indexOfProgressViewWithTracker:tracker];
	if(idx != NSNotFound) [self updateProgressTracker:tracker withViewIndex:idx];
}

//debugging method. this can be hooked up to a button to cause three trackers
// (that don't track any real processes) to be created.
- (IBAction)spawn:sender
{
	DummyTracker *dummy = [[DummyTracker alloc] initWithActivityWindowController:self autostart:NO autostop:NO autodelete:NO];
	[self addProgressTracker:dummy];
	[dummy release];

	dummy = [[DummyTracker alloc] initWithActivityWindowController:self autostart:NO autostop:YES autodelete:NO];
	[self addProgressTracker:dummy];
	[dummy release];

	dummy = [[DummyTracker alloc] initWithActivityWindowController:self autostart:NO autostop:YES autodelete:YES];
	[self addProgressTracker:dummy];
	[dummy release];

	[table reloadData];
}

- tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(int)row
{
	if(row < [progressViews count]) {
		return [progressViews objectAtIndex:row];
	} else {
		return nil;
	}
}

- (int)numberOfRowsInTableView:(NSTableView *)view
{
	return [progressViews count];
}

@end

//------------------------------------------------------------------------------

@implementation BZActivityWindowController(PRIVATE)

- (void)updateProgressTracker:(id <BZProgressTracker>)tracker withViewIndex:(int)index
{
	BZProgressView *progressView = [progressViews objectAtIndex:index];
	
	if(tracker) {
		[progressView updateWithTracker:tracker];
	} else {
		[progressView update];
	}
	
	if(index == [table selectedRow]) {
		//update the toolbar, as the state of the selection (i.e. this item) may
		//  have changed.
		NSToolbar *toolbar = [[self window] toolbar];
		NSEnumerator *itemsEnum = [[toolbar items] objectEnumerator];
		NSToolbarItem *item;
		while(item = [itemsEnum nextObject]) {
			[self toolbar:toolbar itemForItemIdentifier:[item itemIdentifier] willBeInsertedIntoToolbar:NO];
			//note that if this returns a new toolbar item, we're screwed.
		}
	}
}

- (void)removeProgressTracker:(id <BZProgressTracker>)tracker withViewIndex:(int)index
{
	if([tracker canCancel]) [tracker cancel];
	BZProgressView *progressView = [progressViews objectAtIndex:index];
	[progressView removeFromSuperview];
	[progressViews removeObjectAtIndex:index];
	[table reloadData];
}

@end

//------------------------------------------------------------------------------

@implementation BZActivityWindowController(BZActivityWindowToolbarDelegate)

//translate toolbar item IDs into human-readable objects.
- (NSString *)labelForIdentifier:(NSString *)identifier
{
	NSString *label;
	if([identifier isEqualToString:TOOLBAR_ITEM_PAUSE_ID]) {
		label = TOOLBAR_ITEM_PAUSE_LABEL;
		int idx = [table selectedRow];
		if(idx >= 0) {
			id <BZProgressTracker> tracker = [[progressViews objectAtIndex:idx] tracker];
			enum ProgressState progressState = [tracker progressState];
			if(progressState == ProgressState_Paused) {
				label = TOOLBAR_ITEM_RESUME_LABEL;
			}
		}
	} else if([identifier isEqualToString:TOOLBAR_ITEM_CANCEL_ID]) {
		label = TOOLBAR_ITEM_CANCEL_LABEL;
		int idx = [table selectedRow];
		if(idx >= 0) {
			id <BZProgressTracker> tracker = [[progressViews objectAtIndex:idx] tracker];
			enum ProgressState progressState = [tracker progressState];
			if(progressState == ProgressState_Stopped) {
				label = TOOLBAR_ITEM_START_LABEL;
			}
		}
	} else if([identifier isEqualToString:TOOLBAR_ITEM_REVEAL_ID]) {
		label = TOOLBAR_ITEM_REVEAL_LABEL;
	} else if([identifier isEqualToString:TOOLBAR_ITEM_DELETE_ID]) {
		label = TOOLBAR_ITEM_DELETE_LABEL;
	ADD_TOOLBAR_ITEMS_HERE
	} else {
		label = nil;
	}
	if(label) label = [NSString stringWithString:label];
	return label;
}
- (NSString *)configureLabelForIdentifier:(NSString *)identifier
{
	NSString *label;
	if([identifier isEqualToString:TOOLBAR_ITEM_PAUSE_ID]) {
		label = TOOLBAR_ITEM_PAUSE_RESUME_CONFIGURE_LABEL;
	} else if([identifier isEqualToString:TOOLBAR_ITEM_CANCEL_ID]) {
		label = TOOLBAR_ITEM_START_CANCEL_CONFIGURE_LABEL;
	} else if([identifier isEqualToString:TOOLBAR_ITEM_REVEAL_ID]) {
		label = TOOLBAR_ITEM_REVEAL_CONFIGURE_LABEL;
	} else if([identifier isEqualToString:TOOLBAR_ITEM_DELETE_ID]) {
		label = TOOLBAR_ITEM_DELETE_CONFIGURE_LABEL;
	ADD_TOOLBAR_ITEMS_HERE
	} else {
		label = nil;
	}
	if(label) label = [NSString stringWithString:label];
	return label;
}
- (NSImage *)imageForIdentifier:(NSString *)identifier
{
	NSImage *image = nil;
	
	NSString *imageName;
	if([identifier isEqualToString:TOOLBAR_ITEM_PAUSE_ID]) {
		imageName = TOOLBAR_ITEM_PAUSE_IMAGE_NAME;
		int idx = [table selectedRow];
		if(idx >= 0) {
			id <BZProgressTracker> tracker = [[progressViews objectAtIndex:idx] tracker];
			enum ProgressState progressState = [tracker progressState];
			if(progressState == ProgressState_Paused) {
				imageName = TOOLBAR_ITEM_RESUME_IMAGE_NAME;
			}
		}
		image = [NSImage imageNamed:imageName];
	} else if([identifier isEqualToString:TOOLBAR_ITEM_CANCEL_ID]) {
		imageName = TOOLBAR_ITEM_CANCEL_IMAGE_NAME;
		int idx = [table selectedRow];
		if(idx >= 0) {
			id <BZProgressTracker> tracker = [[progressViews objectAtIndex:idx] tracker];
			enum ProgressState progressState = [tracker progressState];
			if(progressState == ProgressState_Stopped) {
				imageName = TOOLBAR_ITEM_START_IMAGE_NAME;
			}
		}
		image = [NSImage imageNamed:imageName];
	} else if([identifier isEqualToString:TOOLBAR_ITEM_REVEAL_ID]) {
		image = [NSImage imageNamed:TOOLBAR_ITEM_REVEAL_IMAGE_NAME];
	} else if([identifier isEqualToString:TOOLBAR_ITEM_DELETE_ID]) {
		image = [NSImage imageNamed:TOOLBAR_ITEM_DELETE_IMAGE_NAME];
	ADD_TOOLBAR_ITEMS_HERE
	}
	return image;
}
- (SEL)actionForIdentifier:(NSString *)identifier
{
	SEL action;
	if([identifier isEqualToString:TOOLBAR_ITEM_PAUSE_ID]) {
		action = TOOLBAR_ITEM_PAUSE_ACTION;
	} else if([identifier isEqualToString:TOOLBAR_ITEM_CANCEL_ID]) {
		action = TOOLBAR_ITEM_CANCEL_ACTION;
		int idx = [table selectedRow];
		if(idx >= 0) {
			id <BZProgressTracker> tracker = [[progressViews objectAtIndex:idx] tracker];
			enum ProgressState progressState = [tracker progressState];
			if(progressState == ProgressState_Stopped) {
				action = TOOLBAR_ITEM_PAUSE_ACTION; //pause/resume, also used for start
			}
		}
	} else if([identifier isEqualToString:TOOLBAR_ITEM_REVEAL_ID]) {
		action = TOOLBAR_ITEM_REVEAL_ACTION;
	} else if([identifier isEqualToString:TOOLBAR_ITEM_DELETE_ID]) {
		action = TOOLBAR_ITEM_DELETE_ACTION;
	ADD_TOOLBAR_ITEMS_HERE
	} else {
		action = nil;
	}
	return action;
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)identifier willBeInsertedIntoToolbar:(BOOL)flag
{
	if(toolbarItems == nil) toolbarItems = [[NSMutableDictionary alloc] init];
	NSToolbarItem *item = [toolbarItems objectForKey:identifier];
	if(item == nil) {
		if([identifier isEqualToString:TOOLBAR_ITEM_PAUSE_ID]
		|| [identifier isEqualToString:TOOLBAR_ITEM_CANCEL_ID]
		|| [identifier isEqualToString:TOOLBAR_ITEM_REVEAL_ID]
		|| [identifier isEqualToString:TOOLBAR_ITEM_DELETE_ID]
		ADD_TOOLBAR_ITEMS_HERE) {
			[AIToolbarUtilities addToolbarItemToDictionary:toolbarItems
											withIdentifier:identifier
													 label:[self labelForIdentifier:identifier]
											  paletteLabel:[self configureLabelForIdentifier:identifier]
												   toolTip:nil /*handle this in the future*/
													target:self
										   settingSelector:@selector(setImage:)
											   itemContent:[self imageForIdentifier:identifier]
													action:[self actionForIdentifier:identifier]
													  menu:nil];
			item = [toolbarItems objectForKey:identifier];
		}
	} else {
		//update it
		[item setLabel:[self labelForIdentifier:identifier]];
		[item setPaletteLabel:[self configureLabelForIdentifier:identifier]];
		[item setToolTip:nil]; /*handle this in the future*/
		[item setTarget:self];
		[item setImage:[self imageForIdentifier:identifier]];
		[item setAction:[self actionForIdentifier:identifier]];
	}		
	return item;
}
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
	return [NSArray arrayWithObjects:TOOLBAR_ITEM_PAUSE_ID, TOOLBAR_ITEM_CANCEL_ID, TOOLBAR_ITEM_REVEAL_ID, TOOLBAR_ITEM_DELETE_ID, NSToolbarSeparatorItemIdentifier, NSToolbarSpaceItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, NSToolbarCustomizeToolbarItemIdentifier, nil];
	ADD_TOOLBAR_ITEMS_HERE
}
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
	return [NSArray arrayWithObjects:TOOLBAR_ITEM_PAUSE_ID, TOOLBAR_ITEM_CANCEL_ID, NSToolbarFlexibleSpaceItemIdentifier, TOOLBAR_ITEM_REVEAL_ID, NSToolbarFlexibleSpaceItemIdentifier, TOOLBAR_ITEM_DELETE_ID, nil];
	ADD_TOOLBAR_ITEMS_HERE
}
- (BOOL)validateToolbarItem:(NSToolbarItem *)item
{
	int selectedRow = [table selectedRow];
	id <BZProgressTracker> tracker = nil;
	if(selectedRow >= 0) {
		tracker = [[progressViews objectAtIndex:selectedRow] tracker];
	}

	BOOL canDoIt = NO;
	//we can't put this into a separate method because that requires using
	//  NSInvocation and NSMethodSignature (or s/BOOL/NSValue/). blah. --boredzo
	if(tracker) {
		NSString *identifier = [item itemIdentifier];
		if([identifier isEqualToString:TOOLBAR_ITEM_PAUSE_ID]) {
			canDoIt = ([tracker canPause]  || ([tracker canResume]));
		} else if([identifier isEqualToString:TOOLBAR_ITEM_CANCEL_ID]) {
			canDoIt = ([tracker canCancel] || ([tracker canStart]));
		} else if([identifier isEqualToString:TOOLBAR_ITEM_REVEAL_ID]) {
			canDoIt = [tracker canReveal];
		} else if([identifier isEqualToString:TOOLBAR_ITEM_DELETE_ID]) {
			canDoIt = YES;
		}
		ADD_TOOLBAR_ITEMS_HERE
	}
	return canDoIt;
}

- (BOOL)cancel:sender
{
	int index = [table selectedRow];
	NSAssert(index >= 0, @"No selection, and yet the cancel button was enabled?");
	id <BZProgressTracker> tracker = [[progressViews objectAtIndex:index] tracker];
	BOOL success = NO;
	if(tracker) {
		success = [tracker cancel];

		//we want to update the pause button according to the new state of the tracker.
		//for example, if the cancel succeeded, 'Pause' should change to 'Start'.
		NSString *identifier = TOOLBAR_ITEM_PAUSE_ID;
		NSToolbarItem *toolbarItem = [toolbarItems objectForKey:identifier];
		
		[toolbarItem setLabel:[self labelForIdentifier:identifier]];
		[toolbarItem setImage:[self imageForIdentifier:identifier]];

		[self updateProgressTracker:tracker];
		[table reloadData];
	}
	return success;
}
- (BOOL)pauseOrResume:sender
{
	int index = [table selectedRow];
	NSAssert(index >= 0, @"No selection, and yet the pause button was enabled?");
	id <BZProgressTracker> tracker = [[progressViews objectAtIndex:index] tracker];
	BOOL success = NO;
	if(tracker) {
		enum ProgressState progressState = [tracker progressState];

		if(progressState == ProgressState_Paused) {
			success = [tracker resume];
		} else if(progressState == ProgressState_Stopped) {
			success = [tracker start];
		} else {
			success = [tracker pause];
		}

		NSString *identifier = TOOLBAR_ITEM_PAUSE_ID;
		NSToolbarItem *toolbarItem = [toolbarItems objectForKey:identifier];

		[toolbarItem setLabel:[self labelForIdentifier:identifier]];
		[toolbarItem setImage:[self imageForIdentifier:identifier]];

		[self updateProgressTracker:tracker];
		[table reloadData];
	}
	return success;
}
- (BOOL)reveal:sender
{
	int index = [table selectedRow];
	NSAssert(index >= 0, @"No selection, and yet the reveal button was enabled?");
	id <BZProgressTracker> tracker = [[progressViews objectAtIndex:index] tracker];
	BOOL success = NO;
	if(tracker) {
		success = [tracker reveal];
		[table reloadData];
	}
	return success;
}
- (BOOL)delete:sender
{
	int index = [table selectedRow];
	NSAssert(index >= 0, @"No selection, and yet the delete button was enabled?");
	BZProgressView *progressView = [progressViews objectAtIndex:index];
	id <BZProgressTracker> tracker = [progressView tracker];
	int returnCode = NSRunAlertPanel(AILocalizedString(@"Activity Window deletion-confirmation title", NULL),
		AILocalizedString(@"Activity Window deletion-confirmation message format", NULL), 
		AILocalizedString(@"OK", NULL),
		nil,
		AILocalizedString(@"Cancel", NULL),
		[tracker type], [tracker name]);
	if(returnCode == NSAlertDefaultReturn) {
		[self removeProgressTracker:tracker withViewIndex:index];
		if([progressViews count] < 1) {
			//we deleted the last item, so we need to set the cell's object value to
			//  nil so that the progress view (and its associated tracker) gets
			//  dealloced.
			[[[table tableColumnWithIdentifier:TABLE_VIEW_ONLY_COLUMN] dataCell] setObjectValue:nil];
		}
		return YES;
	}
	return NO;
}
ADD_TOOLBAR_ITEMS_HERE

@end

//------------------------------------------------------------------------------

@implementation BZActivityWindowController(BZActivityWindowTableViewDelegate)

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	NSTableView *touchedTable = [notification object];
	if(touchedTable) {
		int selection = [touchedTable selectedRow];
		if(selection >= 0) {
			[self updateProgressTracker:nil withViewIndex:selection];
		}
	}
}

@end

//------------------------------------------------------------------------------

@implementation DummyTracker

- (NSString *)name
{
	return @"Money transfer";
}
- (NSString *)type
{
	return @"DummyTracker";
}

- (float)maximum
{
	return 100.0;
}
- (float)current
{
	return current;
}
- (float)speed
{
	return 5.0;
}

- (NSString *)unit
{
	return [NSString stringWithString:@"zorkmids"];
}

- initWithActivityWindowController:(BZActivityWindowController *)controller autostart:(BOOL)autostart autostop:(BOOL)autostop autodelete:(BOOL)autodelete
{
	self = [super init];
	if(self) {
		[self setActivityWindowController:controller];
	}
	current = 0.0;
	progressState = ProgressState_Stopped;

	flags.reserved   = 0;
	flags.autostart  = autostart;
	flags.autostop   = autostop;
	flags.autodelete = autodelete;

	if(flags.autostart) [self start];

	return self;
}
- (void)setActivityWindowController:controller
{
	myController = controller;
}
- (void)dealloc
{
	NSLog(@"tracker %p deallocing!\n", self);
	[super dealloc];
}

- (BOOL)canCancel
{
	return progressState != ProgressState_Stopped && progressState != ProgressState_Stopping;
}
- (BOOL)cancel
{
	NSLog(@"Cancelled %p\n", self);
	[progressTimer invalidate]; [progressTimer release]; progressTimer = nil;
	progressState = ProgressState_Stopped;
	current = 0.0;
	return YES;
}
- (BOOL)canPause
{
	return (progressState != ProgressState_Paused && progressState != ProgressState_Stopped && progressState != ProgressState_Stopping);
}
- (BOOL)pause
{
	NSLog(@"Paused %p\n", self);
	[progressTimer invalidate]; [progressTimer release]; progressTimer = nil;
	progressState = ProgressState_Paused;
	return YES;
}
- (BOOL)canResume
{
	return progressState == ProgressState_Paused;
}
- (BOOL)resume
{
	NSLog(@"Resumed %p\n", self);
	progressState = ProgressState_Working;
	progressTimer = [[NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(incrProgress:) userInfo:nil repeats:YES] retain];
	[[NSRunLoop currentRunLoop] addTimer:progressTimer forMode:NSDefaultRunLoopMode];
	return YES;
}
- (BOOL)canStart
{
	return progressState == ProgressState_Stopped;
}
- (BOOL)start
{
	NSLog(@"Started %p\n", self);
	current = 0.0;
	return [self resume];
}
- (BOOL)canReveal
{
	return YES;
}
- (BOOL)reveal
{
	NSLog(@"Revealed %p\n", self);
	NSBeep();
	return YES;
}

- (enum ProgressState)progressState
{
	return progressState;
}

- (void)incrProgress:(NSTimer *)timer
{
	float oldCurrent = current;
	if(current == [self maximum]) {
		if(flags.autostop) {
			[self cancel];
			current = oldCurrent; //cancelling sets this to 0, so we restore it.
			if(flags.autodelete) {
				[myController removeProgressTracker:self];
				return;
			}
		} else {
			current = 0.0;
		}
	} else {
		current += [self speed];
	}
	[myController updateProgressTracker:self];
}

@end

@implementation NSArray(BZProgressViewArray)

- (BOOL)containsProgressViewWithTracker:(id <BZProgressTracker>)tracker
{
	return [self indexOfProgressViewWithTracker:tracker] != NSNotFound;
}

- (int)indexOfProgressViewWithTracker:(id <BZProgressTracker>)tracker
{
	NSEnumerator *selfEnum = [self objectEnumerator];
	int idx = 0;
	id object;
	while(object = [selfEnum nextObject]) {
		if([object respondsToSelector:@selector(tracker)] && ([object tracker] == tracker)) {
			return idx;
		}
		++idx;
	}
	return NSNotFound;
}

@end

@implementation NSMutableArray(BZProgressViewMutableArray)

- (void)removeProgressViewWithTracker:(id <BZProgressTracker>)tracker
{
	int idx = [self indexOfProgressViewWithTracker:tracker];
	if(idx < [self count]) [self removeObjectAtIndex:idx];
}

@end
