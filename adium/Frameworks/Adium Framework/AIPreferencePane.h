/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import <Cocoa/Cocoa.h>
#import "AIAdium.h"

@class AIPreferencePane;

@interface NSObject(AIPreferencePaneDelegate)
- (NSView *)viewForPreferencePane:(AIPreferencePane *)preferencePane;
- (void)closeViewForPreferencePane:(AIPreferencePane *)preferencePane;
- (void)restoreDefaultsForPreferencePane:(AIPreferencePane *)preferencePane;
@end

@interface AIPreferencePane : NSObject {
    IBOutlet	NSView			*view_containerView;
    IBOutlet	NSView			*view_containerSubView;
    IBOutlet	NSTextField		*textField_title;

    id				delegate;
    PREFERENCE_CATEGORY		category;
    NSString			*label;
    NSView			*preferenceView;
}

+ (AIPreferencePane *)preferencePaneInCategory:(PREFERENCE_CATEGORY)inCategory withDelegate:(id)inDelegate label:(NSString *)inLabel;
- (PREFERENCE_CATEGORY)category;
- (NSString *)label;
- (NSView *)view;
- (void)closeView;

@end
