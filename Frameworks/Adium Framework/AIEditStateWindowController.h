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

#import "AIWindowController.h"
#import "AIStatus.h"

@class AIAccount, ESTextViewWithPlaceholder, AIService, AIAutoScrollView, AISendingTextView;

@interface AIEditStateWindowController : AIWindowController {
	IBOutlet	NSTextField		*label_state;
	IBOutlet	NSPopUpButton	*popUp_state;
	BOOL		needToRebuildPopUpState;
	
	IBOutlet	NSTextField		*label_statusMessage;
	IBOutlet	NSBox			*box_statusMessage;
	IBOutlet	AISendingTextView	*textView_statusMessage;
	IBOutlet	AIAutoScrollView	*scrollView_statusMessage;

	IBOutlet	NSButton		*checkbox_autoReply;
	IBOutlet	NSButton		*checkbox_customAutoReply;
	IBOutlet	AIAutoScrollView	*scrollView_autoReply;
	IBOutlet	AISendingTextView	*textView_autoReply;

	IBOutlet	NSButton		*checkbox_idle;
	IBOutlet	NSBox			*box_idle;
	IBOutlet	NSTextField		*textField_idleMinutes;
	IBOutlet	NSTextField		*textField_idleHours;

	IBOutlet	NSButton		*checkbox_invisible;
	
	IBOutlet	NSButton		*button_save;
	IBOutlet	NSButton		*button_cancel;
	IBOutlet	NSButton		*button_OK;

	AIStatus	*originalStatusState;
	AIAccount	*account;
	id			target;
}

+ (void)editCustomState:(AIStatus *)inStatusState forType:(AIStatusType)inStatusType andAccount:(AIAccount *)inAccount onWindow:(id)parentWindow notifyingTarget:(id)inTarget;

- (IBAction)cancel:(id)sender;
- (IBAction)okay:(id)sender;
- (IBAction)statusControlChanged:(id)sender;
- (void)updateControlVisibilityAndResizeWindow;

- (void)configureForState:(AIStatus *)state;
- (AIStatus *)currentConfiguration;

@end

@interface NSObject (AICustomStatusWindowTarget)
- (void)customStatusState:(AIStatus *)originalState changedTo:(AIStatus *)newState forAccount:(AIAccount *)account;
@end
