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

#import <Cocoa/Cocoa.h>

@interface AIEditStateWindowController : AIWindowController {
	IBOutlet	NSButton		*checkbox_available;
	IBOutlet	NSScrollView	*scrollView_available;
	IBOutlet	NSTextView		*textView_available;

	IBOutlet	NSButton		*checkbox_away;
	IBOutlet	NSScrollView	*scrollView_away;
	IBOutlet	NSTextView		*textView_away;

	IBOutlet	NSButton		*checkbox_autoReply;
	IBOutlet	NSButton		*checkbox_customAutoReply;
	IBOutlet	NSScrollView	*scrollView_autoReply;
	IBOutlet	NSTextView		*textView_autoReply;

	IBOutlet	NSButton		*checkbox_idle;
	IBOutlet	NSBox			*box_idle;
	IBOutlet	NSTextField		*textField_idleMinutes;
	IBOutlet	NSTextField		*textField_idleHours;

	IBOutlet	NSButton		*checkbox_invisible;
	
	NSDictionary	*originalState;
	id				target;
}

+ (void)editCustomState:(NSDictionary *)state onWindow:(id)parentWindow notifyingTarget:(id)inTarget;

- (IBAction)cancel:(id)sender;
- (IBAction)okay:(id)sender;
- (IBAction)statusControlChanged:(id)sender;
- (void)updateControlVisibilityAndResizeWindow;

- (void)configureForState:(NSDictionary *)state;
- (NSDictionary *)currentConfiguration;

@end

@interface NSObject (AICustomStatusWindowTarget)
- (void)customStatusState:(NSDictionary *)originalState changedTo:(NSDictionary *)newState;
@end
