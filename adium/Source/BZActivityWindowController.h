//
//  BZActivityWindowController.h
//  Adium
//
//  Created by Mac-arena the Bored Zo on Sat May 08 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "BZProgressTracker.h"
#import "BZProgressView.h"

#define TABLE_VIEW_ONLY_COLUMN @"TASK"

@interface BZActivityWindowController: NSWindowController {
	NSMutableArray          *progressViews;
	NSMutableDictionary     *toolbarItems;

	IBOutlet NSTableView    *table;
	IBOutlet AIAdium        *owner;
}

- (void)initController;

//add a tracker to the status window. the tracker must not be nil and must not
//  already be under watch. returns whether those conditions were satisfied.
//note that updateProgressTracker: (see below) will be called implicitly.
- (BOOL)addProgressTracker:(id <BZProgressTracker>)tracker;

//remove a tracker from the status window. obviously, if the tracker is nil or
//  not under watch, nothing will happen.
- (void)removeProgressTracker:(id <BZProgressTracker>)tracker;

//causes the window to request updated status from a tracker.
- (void)updateProgressTracker:(id <BZProgressTracker>)tracker;

- (IBAction)spawn:sender;

@end

//------------------------------------------------------------------------------

@interface BZActivityWindowController(PRIVATE)

- (void)updateProgressTracker:(id <BZProgressTracker>)tracker withViewIndex:(int)index;
- (void)removeProgressTracker:(id <BZProgressTracker>)tracker withViewIndex:(int)index;

@end

//------------------------------------------------------------------------------

//this symbol is provided so you can simply grep for it and thus locate all the
//  places where new toolbar items need to be added.
#define ADD_TOOLBAR_ITEMS_HERE /*new toolbar items should be inserted here, among other places.*/


#define TOOLBAR_ITEM_PAUSE_ID  @"com.adiumX.activity_window.toolbar.pause"
#define TOOLBAR_ITEM_CANCEL_ID @"com.adiumX.activity_window.toolbar.cancel"
#define TOOLBAR_ITEM_REVEAL_ID @"com.adiumX.activity_window.toolbar.reveal"
#define TOOLBAR_ITEM_DELETE_ID @"com.adiumX.activity_window.toolbar.delete"
ADD_TOOLBAR_ITEMS_HERE

//these labels appear in the toolbar.
#define TOOLBAR_ITEM_PAUSE_LABEL  @"Pause"
#define TOOLBAR_ITEM_RESUME_LABEL @"Resume"
#define TOOLBAR_ITEM_START_LABEL  @"Start"
#define TOOLBAR_ITEM_CANCEL_LABEL @"Cancel"
#define TOOLBAR_ITEM_REVEAL_LABEL @"Reveal"
#define TOOLBAR_ITEM_DELETE_LABEL @"Delete"
ADD_TOOLBAR_ITEMS_HERE

//these labels appear in the Configure Toolbar sheet.
#define TOOLBAR_ITEM_PAUSE_RESUME_CONFIGURE_LABEL  @"Pause/Resume"
#define TOOLBAR_ITEM_START_CANCEL_CONFIGURE_LABEL  @"Start/Cancel"
#define TOOLBAR_ITEM_REVEAL_CONFIGURE_LABEL        @"Reveal"
#define TOOLBAR_ITEM_DELETE_CONFIGURE_LABEL        @"Delete"
ADD_TOOLBAR_ITEMS_HERE

#define TOOLBAR_ITEM_PAUSE_IMAGE_NAME  @"pause"
#define TOOLBAR_ITEM_RESUME_IMAGE_NAME @"start"
#define TOOLBAR_ITEM_START_IMAGE_NAME  @"start"
#define TOOLBAR_ITEM_CANCEL_IMAGE_NAME @"stop"
#define TOOLBAR_ITEM_REVEAL_IMAGE_NAME @"reveal"
#define TOOLBAR_ITEM_DELETE_IMAGE_NAME @"delete"
ADD_TOOLBAR_ITEMS_HERE

//it should be noted that while Start (as opposed to Resume) appears on the Cancel
//  button, the action for Start is pauseOrResume:.
#define TOOLBAR_ITEM_PAUSE_ACTION  @selector(pauseOrResume:)
#define TOOLBAR_ITEM_CANCEL_ACTION @selector(cancel:)
#define TOOLBAR_ITEM_REVEAL_ACTION @selector(reveal:)
#define TOOLBAR_ITEM_DELETE_ACTION @selector(delete:)
ADD_TOOLBAR_ITEMS_HERE

@interface BZActivityWindowController(BZActivityWindowToolbarDelegate)

//translate toolbar item IDs into human-readable items.
- (NSString *)labelForIdentifier:(NSString *)identifier;
- (NSImage *)imageForIdentifier:(NSString *)identifier;
- (SEL)actionForIdentifier:(NSString *)identifier;

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)identifier willBeInsertedIntoToolbar:(BOOL)flag;
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar;
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar;

- (BOOL)cancel:sender;
- (BOOL)pauseOrResume:sender;
- (BOOL)reveal:sender;
- (BOOL)delete:sender;
ADD_TOOLBAR_ITEMS_HERE

@end

//------------------------------------------------------------------------------

@interface BZActivityWindowController(BZActivityWindowTableViewDelegate)

- (void)tableViewSelectionDidChange:(NSNotification *)notification;

@end

//------------------------------------------------------------------------------

@interface DummyTracker: NSObject <BZProgressTracker>
{
	enum ProgressState progressState;
	BZActivityWindowController *myController;
	NSTimer *progressTimer;
	float current;
	struct {
		unsigned reserved   :29;
		unsigned autodelete :1;
		unsigned autostop   :1;
		unsigned autostart  :1;
	} flags;
}

- (NSString *)name;
- (NSString *)type;

- (float)maximum;
- (float)current;
- (float)speed;

- initWithActivityWindowController:(BZActivityWindowController *)controller autostart:(BOOL)autostart autostop:(BOOL)autostop autodelete:(BOOL)autodelete;
- (void)setActivityWindowController:controller;

- (BOOL)canCancel;
- (BOOL)cancel;
- (BOOL)canPause;
- (BOOL)pause;
- (BOOL)canResume;
- (BOOL)resume;
- (BOOL)canStart;
- (BOOL)start;
- (BOOL)canReveal;
- (BOOL)reveal;
- (BOOL)canDelete;
- (BOOL)prepareForDelete;

- (enum ProgressState)progressState;

@end

//additions to NS{,Mutable}Array so we can easily search our array of progress
//  views by tracker.
@interface NSArray(BZProgressViewArray)

- (BOOL)containsProgressViewWithTracker:(id <BZProgressTracker>)tracker;
- (int)indexOfProgressViewWithTracker:(id <BZProgressTracker>)tracker;

@end

@interface NSMutableArray(BZProgressViewMutableArray)

- (void)removeProgressViewWithTracker:(id <BZProgressTracker>)tracker;

@end
