/* 
Adium, Copyright 2001-2005, Adam Iser
 
 This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 General Public License as published by the Free Software Foundation; either version 2 of the License,
 or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 Public License for more details.
 
 You should have received a copy of the GNU General Public License along with this program; if not,
 write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIEditStateWindowController.h"

#define CONTROL_SPACING			8
#define WINDOW_HEIGHT_PADDING	90

@interface AIEditStateWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName customState:(AIStatus *)inState notifyingTarget:(id)inTarget;
- (id)_positionControl:(id)control relativeTo:(id)guide height:(int *)height;
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
 * @param state Initial state dictionary
 * @param parentWindow Parent window for a sheet, nil for a stand alone editor
 * @param inTarget Target object to notify when editing is complete
 */
+ (void)editCustomState:(AIStatus *)statusState onWindow:(id)parentWindow notifyingTarget:(id)inTarget
{
	AIEditStateWindowController	*controller;
	
	controller = [[self alloc] initWithWindowNibName:@"EditStateSheet" customState:statusState notifyingTarget:inTarget];
	
	if(parentWindow){
		[NSApp beginSheet:[controller window]
		   modalForWindow:parentWindow
			modalDelegate:controller
		   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			  contextInfo:nil];
	}else{
		[controller showWindow:nil];
	}
}

/*!
 * Init the window controller
 */
- (id)initWithWindowNibName:(NSString *)windowNibName customState:(AIStatus *)inStatusState notifyingTarget:(id)inTarget
{
    [super initWithWindowNibName:windowNibName];

	originalStatusState = [inStatusState retain];
	target = inTarget;
	
	return(self);
}

/*!
 * Deallocate
 */
- (void)dealloc
{
	[originalStatusState release];
	[super dealloc];
}

/*!
 * Configure the window after it loads
 */
- (void)windowDidLoad
{
	//Center our window if we're not a sheet (or opening a sheet failed)
	[[self window] center];
	
	[popUp_state setMenu:[[adium statusController] menuOfStatusesWithTarget:self]];

	//Configure our editor for the passed state
	[self configureForState:originalStatusState];
}

/*!
 * @brief Called before the window is closed
 *
 * As our window is closing, we auto-release this window controller instance.  This allows our editor to function
 * independently without needing a separate object to retain and release it.
 * We always allow our window to close, so always return YES from this method
 */
- (BOOL)windowShouldClose:(id)sender
{
	[self autorelease];
    return(YES);
}

/*!
 * Invoked as the sheet closes, dismiss the sheet
 */
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:nil];
}

/*!
 * Prevent the system from cascading our windows, since it interferes with window position memory
 */
- (BOOL)shouldCascadeWindows
{
    return(NO);
}

/*!
 * @brief Close the editor
 *
 * Close the editor window or sheet.  The editor will close and clean itself up automatically.
 */
- (IBAction)closeWindow:(id)sender
{
	if([self windowShouldClose:nil]){
		if([[self window] isSheet]){
			[NSApp endSheet:[self window]];
		}else{
			[[self window] close];
		}
	}
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
	if(target && [target respondsToSelector:@selector(customStatusState:changedTo:)]){
		[target customStatusState:originalStatusState changedTo:[self currentConfiguration]];
	}
	
	[self closeWindow:nil];
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

/*!
 * @brief Invoked when a control value is changed
 *
 * Invoked with the user changes the value of an editor control.  In response, we update control visibility and
 * resize the window.
 */
- (IBAction)statusControlChanged:(id)sender
{
	[self updateControlVisibilityAndResizeWindow];
}

- (IBAction)selectStatus:(id)sender
{
	
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
	id	current = popUp_state;
	int	height = WINDOW_HEIGHT_PADDING + [current frame].size.height;

	current = [self _positionControl:box_statusMessage relativeTo:current height:&height];
	current = [self _positionControl:checkbox_autoReply relativeTo:current height:&height];
	current = [self _positionControl:checkbox_customAutoReply relativeTo:current height:&height];
	current = [self _positionControl:scrollView_autoReply relativeTo:current height:&height];
	current = [self _positionControl:checkbox_invisible relativeTo:current height:&height];
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
	//Toggles
	[checkbox_invisible setState:[statusState invisible]];
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
	AIStatus	*statusState;
	double		idleStart = [textField_idleHours intValue]*3600 + [textField_idleMinutes intValue]*60;
	
	statusState = (originalStatusState ? [[originalStatusState copy] autorelease] : [AIStatus status]);
	[statusState setMutabilityTpye:AIEditableState];
	
	//XXX
	/*[statusState setTitle:]*/
	[statusState setStatusMessageData:[[textView_statusMessage textStorage] dataRepresentation]];
	[statusState setAutoReplyData:[[textView_autoReply textStorage] dataRepresentation]];
	[statusState setHasAutoReply:[checkbox_autoReply state]];
	[statusState setAutoReplyIsStatusMessage:![checkbox_customAutoReply state]];
	[statusState setInvisible:[checkbox_invisible state]];
	[statusState setShouldForceInitialIdleTime:[checkbox_idle state]];
	[statusState setForcedInitialIdleTime:idleStart];

	NSDictionary	*stateDict = [[popUp_state selectedItem] representedObject];
	if(stateDict){
		[statusState setStatusType:[[stateDict objectForKey:KEY_STATUS_TYPE] intValue]];
		[statusState setStatusName:[stateDict objectForKey:KEY_STATUS_NAME]];
	}

	return(statusState);
}

@end

