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

#import "AIAccount.h"
#import "AIEditStateWindowController.h"
#import "AIStatus.h"
#import "AIStatusController.h"
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIAutoScrollView.h>
#import <AIUtilities/AISendingTextView.h>
#import <AIUtilities/AIWindowAdditions.h>

#define CONTROL_SPACING			8
#define WINDOW_HEIGHT_PADDING	60

@interface AIEditStateWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName forType:(AIStatusType)inStatusType andAccount:(AIAccount *)inAccount customState:(AIStatus *)inStatusState notifyingTarget:(id)inTarget;
- (id)_positionControl:(id)control relativeTo:(id)guide height:(int *)height;
- (void)configureStateMenu;
- (void)hideSaveCheckbox;
@end

/*!
 * @class AIEditStateWindowController
 * @brief Interface for editing a status state
 *
 * This class provides an interface for editing a status state dictionary's properties.
 */
@implementation AIEditStateWindowController

/*!
 * @brief Open a custom state editor window or sheet
 *
 * Open either a sheet or window containing a state editor.  The state editor will be primed with the passed state
 * dictionary.  When the user successfully closes the editor, the target will be notified and passed the updated
 * state dictionary
 * @param inStatusState Initial AIStatus
 * @param inStatusType AIStatusType to use initially if inStatusState is nil
 * @param inAccount The account which to configure the custom state window; nil to configure globally
 * @param allowSave YES if the save checkbox should be shown; NO if it should not
 * @param parentWindow Parent window for a sheet, nil for a stand alone editor
 * @param inTarget Target object to notify when editing is complete
 */
+ (id)editCustomState:(AIStatus *)inStatusState forType:(AIStatusType)inStatusType andAccount:(AIAccount *)inAccount withSaveOption:(BOOL)allowSave onWindow:(id)parentWindow notifyingTarget:(id)inTarget
{
	AIEditStateWindowController	*controller;
	
	controller = [[self alloc] initWithWindowNibName:@"EditStateSheet" forType:inStatusType andAccount:inAccount customState:inStatusState notifyingTarget:inTarget];
	
	if(!allowSave){
		[controller hideSaveCheckbox];
	}

	if(parentWindow){
		[NSApp beginSheet:[controller window]
		   modalForWindow:parentWindow
			modalDelegate:controller
		   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			  contextInfo:nil];
	}else{
		[controller showWindow:nil];
		[[controller window] makeKeyAndOrderFront:nil];
		[NSApp activateIgnoringOtherApps:YES];
	}

	return controller;
}

/*!
 * Init the window controller
 */
- (id)initWithWindowNibName:(NSString *)windowNibName forType:(AIStatusType)inStatusType andAccount:(AIAccount *)inAccount customState:(AIStatus *)inStatusState notifyingTarget:(id)inTarget
{
    [super initWithWindowNibName:windowNibName];

	originalStatusState = [inStatusState retain];
	workingStatusState = (originalStatusState ? [originalStatusState mutableCopy] : [[AIStatus statusOfType:inStatusType] retain]);

	target = inTarget;
	
	account = [inAccount retain];
	
	return(self);
}

/*!
 * Deallocate
 */
- (void)dealloc
{
	[originalStatusState release];
	[workingStatusState release];
	[account release];

	[super dealloc];
}

/*!
 * @brief Configure the window after it loads
 */
- (void)windowDidLoad
{
	//Center our window if we're not a sheet (or opening a sheet failed)
	[[self window] betterCenter];

	[scrollView_statusMessage setAutoHideScrollBar:YES];
	[scrollView_statusMessage setAlwaysDrawFocusRingIfFocused:YES];
	[textView_statusMessage setTarget:self action:@selector(okay:)];
	[textView_statusMessage setSendOnReturn:YES];
	[textView_statusMessage setSendOnEnter:NO];

	[scrollView_autoReply setAutoHideScrollBar:YES];
	[scrollView_autoReply setAlwaysDrawFocusRingIfFocused:YES];
	[textView_autoReply setTarget:self action:@selector(okay:)];
	[textView_autoReply setSendOnReturn:YES];
	[textView_autoReply setSendOnEnter:NO];
	
	[self configureStateMenu];

	//Configure our editor for the passed state
	[self configureForState:workingStatusState];
}

/*!
 * @brief Configure the state menu with a fresh menu of active statuses
 */
- (void)configureStateMenu
{
	[popUp_state setMenu:[[adium statusController] menuOfStatusesForService:(account ? [account service] : nil)
																 withTarget:self]];
	needToRebuildPopUpState = NO;	
}

/*!
 * @brief Called before the window is closed
 *
 * As our window is closing, we auto-release this window controller instance.  This allows our editor to function
 * independently without needing a separate object to retain and release it.
 * We always allow our window to close, so always return YES from this method
 */
- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
	[self autorelease];
}

/*!
 * Invoked as the sheet closes, dismiss the sheet
 */
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:nil];
}


//Behavior -------------------------------------------------------------------------------------------------------------
#pragma mark Behavior
/*!
 * @brief Okay
 *
 * Save changes, notify our target of the new configuration, and close the editor.
 */
- (IBAction)okay:(id)sender
{
	if(target && [target respondsToSelector:@selector(customStatusState:changedTo:forAccount:)]){
		//Perform on a delay so the sheet can beging closing immediately.
		[self performSelector:@selector(notifyOfStateChange)
				   withObject:nil
				   afterDelay:0];
	}
	
	[self closeWindow:nil];
}

/*!
 * @brief Notify our target of the state changing
 *
 * Called by -[self okay:]
 */
- (void)notifyOfStateChange
{
	[target customStatusState:originalStatusState changedTo:[self currentConfiguration] forAccount:account];
}

/*!
 * @brief Cancel
 *
 * Close the editor without saving changes.
 */
- (IBAction)cancel:(id)sender
{
	[self closeWindow:nil];
}

/*
 * @brief Update the display of the status's title in the window
 */
- (void)updateTitleDisplay
{
	[textField_title setStringValue:[workingStatusState title]];
}

/*!
 * @brief Invoked when a control value is changed
 *
 * Invoked with the user changes the value of an editor control.  In response, we update control visibility and
 * resize the window.
 */
- (IBAction)statusControlChanged:(id)sender
{
	if(sender == checkbox_autoReply){
		[workingStatusState setHasAutoReply:[checkbox_autoReply state]];
		
	}else if(sender == checkbox_customAutoReply){
		[workingStatusState setAutoReplyIsStatusMessage:![checkbox_customAutoReply state]];	
	}else if(sender == checkbox_idle){
		[workingStatusState setShouldForceInitialIdleTime:[checkbox_idle state]];
	}
	
	[self updateControlVisibilityAndResizeWindow];
	[self updateTitleDisplay];
}

/*
 * @brief NSTextField changed
 */
- (void)controlTextDidChange:(NSNotification *)notification
{
	id sender = [notification object];

	if(sender == textField_title){
		NSString	*newTitle = [textField_title stringValue];
		
		if([newTitle length]) [workingStatusState setTitle:newTitle];
	}
}

/*
 * @brief NSTextView changed
 */
- (void)textDidChange:(NSNotification *)notification
{
	id sender = [notification object];

	if(sender == textView_statusMessage){
		[workingStatusState setStatusMessage:[[[textView_statusMessage textStorage] copy] autorelease]];
		
	}else if(sender == textView_autoReply){
		[workingStatusState setAutoReply:[[[textView_autoReply textStorage] copy] autorelease]];
		
	}
	
	[self updateTitleDisplay];
}

/*
 * @brief NSTextField ended editing
 *
 * If our title is cleared out, restore it to using the default title for the rest of the configuration
 */
- (void)controlTextDidEndEditing:(NSNotification *)notification
{
	id sender = [notification object];

	if(sender == textField_title){
		NSString	*newTitle = [textField_title stringValue];
		
		//Set to nil if the field is cleared to get back to the automatically generated value
		if(![newTitle length]){
			[workingStatusState setTitle:nil];
			
			[self updateTitleDisplay];
		}
	}
}

/*!
 * @brief Invoked when a new status type is selected
 */
- (IBAction)selectStatus:(id)sender
{
	NSDictionary	*stateDict = [[popUp_state selectedItem] representedObject];
	if(stateDict){
		[workingStatusState setStatusType:[[stateDict objectForKey:KEY_STATUS_TYPE] intValue]];
		[workingStatusState setStatusName:[stateDict objectForKey:KEY_STATUS_NAME]];
	}

	[self updateTitleDisplay];
}

/*!
 * @brief Update control visibility and resize the editor window
 *
 * This method updates control visibility (When checkboxes are off we hide the controls below them) and resizes the
 * window to fit just the remaining visible controls.
 */
- (void)updateControlVisibilityAndResizeWindow
{
	//Visibility
	[scrollView_autoReply setHidden:(![checkbox_autoReply state] || ![checkbox_customAutoReply state])];
	[checkbox_customAutoReply setHidden:![checkbox_autoReply state]];
	[box_idle setHidden:![checkbox_idle state]];
	
	//Sizing
	//XXX - This is quick & dirty -ai
	id	current = box_title;
	int	height = WINDOW_HEIGHT_PADDING + [current frame].size.height;

	current = [self _positionControl:box_separatorLine relativeTo:current height:&height];
	current = [self _positionControl:box_state relativeTo:current height:&height];	
	current = [self _positionControl:box_statusMessage relativeTo:current height:&height];
	current = [self _positionControl:checkbox_autoReply relativeTo:current height:&height];
	current = [self _positionControl:checkbox_customAutoReply relativeTo:current height:&height];
	current = [self _positionControl:scrollView_autoReply relativeTo:current height:&height];
	current = [self _positionControl:checkbox_idle relativeTo:current height:&height];
	current = [self _positionControl:box_idle relativeTo:current height:&height];
	
	[[self window] setContentSize:NSMakeSize([[[self window] contentView] frame].size.width, height)
						  display:YES
						  animate:NO];
}

/*!
 * @brief Position a control
 *
 * Position the passed control relative to another control in the editor window, keeping track of total control
 * height.  If the passed control is hidden, it won't be positioned or influence the total height at all.
 * @param control The control to reposition
 * @param guide The control we're positoining relative to
 * @param height A pointer to the total control height, which will be updated to include control
 * @return Returns control if it's visible, otherwise returns guide
 */
- (id)_positionControl:(id)control relativeTo:(id)guide height:(int *)height
{
	if(![control isHidden]){
		NSRect	frame = [control frame];
		
		//Position this control relative to the one above it
		frame.origin.y = [guide frame].origin.y - CONTROL_SPACING - frame.size.height;
		
		[control setFrame:frame];
		(*height) += frame.size.height + CONTROL_SPACING;
		
		return(control);
	}else{
		return(guide);
	}
}


//Configuration --------------------------------------------------------------------------------------------------------
#pragma mark Configuration
/*!
 * @brief Configure the editor for a state
 *
 * Configured the editor's controls to represent the passed state dictionary.
 * @param state A NSDictionary containing status state keys and values
 */
- (void)configureForState:(AIStatus *)statusState
{
	//State menu
	NSString	*description;
	int			index;

	if(needToRebuildPopUpState){
		[self configureStateMenu];
	}

	description = [[adium statusController] descriptionForStateOfStatus:statusState];
	index = (description ? [popUp_state indexOfItemWithTitle:description] : -1);
	if(index != -1){
		[popUp_state selectItemAtIndex:index];

	}else{
		if(description){
			[popUp_state setTitle:[NSString stringWithFormat:@"%@ (%@)",
				description,
				AILocalizedString(@"No compatible accounts connected",nil)]];

		}else{
			[popUp_state setTitle:AILocalizedString(@"Unknown",nil)];			
		}

		needToRebuildPopUpState = YES;
	}

	//Toggles
	[checkbox_idle setState:[statusState shouldForceInitialIdleTime]];
	[checkbox_autoReply setState:[statusState hasAutoReply]];
	[checkbox_customAutoReply setState:![statusState autoReplyIsStatusMessage]];
	
	//Strings
	[[textView_statusMessage textStorage] setAttributedString:[statusState statusMessage]];
	[[textView_autoReply textStorage] setAttributedString:[statusState autoReply]];

	//Idle start
	double	idleStart = [statusState forcedInitialIdleTime];
	[textField_idleMinutes setStringValue:[NSString stringWithFormat:@"%i",(int)(idleStart/60)]];
	[textField_idleHours setStringValue:[NSString stringWithFormat:@"%i",(int)(idleStart/3600)]];

	//Update visiblity and size
	[self updateControlVisibilityAndResizeWindow];
	
	//Update our title
	[self updateTitleDisplay];
}

/*!
 * @brief Returns the current state
 *
 * Builds and returns a state dictionary representation of the current editor values.  If no controls have been
 * modified since the editor was configured, the returned state will be identical in content to the one passed
 * to configureForState:.
 */
- (AIStatus *)currentConfiguration
{
	double		idleStart = [textField_idleHours intValue]*3600 + [textField_idleMinutes intValue]*60;
	
	[workingStatusState setMutabilityType:(([checkBox_save isHidden] || [checkBox_save state] == NSOnState) ?
										   AIEditableStatusState :
										   AITemporaryEditableStatusState)];

	[workingStatusState setForcedInitialIdleTime:idleStart];

	//Set the title if necessary
	if(![[workingStatusState title] isEqualToString:[textField_title stringValue]]){
		[workingStatusState setTitle:[textField_title stringValue]];
	}

	return(workingStatusState);
}

- (void)hideSaveCheckbox
{
	//Ensure the window is loaded
	[self window];

	[checkBox_save setHidden:YES];
}

@end

