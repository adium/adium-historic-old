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

@class AIPreferencePane, AIAdium;

@interface NSObject(AIPreferencePaneDelegate)   //Will be removed, transition only
- (NSView *)viewForPreferencePane:(AIPreferencePane *)preferencePane;
- (void)closeViewForPreferencePane:(AIPreferencePane *)preferencePane;
- (void)restoreDefaultsForPreferencePane:(AIPreferencePane *)preferencePane;
@end

@interface AIPreferencePane : NSObject {
    AIAdium                             *owner;
    
    IBOutlet	NSView			*view_containerView;    //Will be removed, transition only
    IBOutlet	NSView			*view_containerSubView; //Will be removed, transition only
    IBOutlet	NSTextField		*textField_title;       //Will be removed, transition only 

    id				delegate;           //Will be removed, transition only
    PREFERENCE_CATEGORY		category;           //Will be removed, transition only
    NSString			*label;             //Will be removed, transition only
    NSView			*preferenceView;    //Will be removed, transition only
    BOOL                        isUpdated;          //Will be removed, transition only
    
    IBOutlet    NSView                  *view;
}

+ (AIPreferencePane *)preferencePaneWithOwner:(id)inOwner;
- (NSComparisonResult)compare:(AIPreferencePane *)inPane;
- (NSView *)view;
- (void)closeView;
- (PREFERENCE_CATEGORY)category;
- (NSString *)label;
- (IBAction)changePreference:(id)sender;
- (void)configureControlDimming;
- (id)initWithOwner:(id)inOwner;


//Will be removed, transition only
+ (AIPreferencePane *)preferencePaneInCategory:(PREFERENCE_CATEGORY)inCategory withDelegate:(id)inDelegate label:(NSString *)inLabel;
- (PREFERENCE_CATEGORY)category;
- (NSView *)viewWithContainer:(BOOL)includeContainer;
- (BOOL)isUpdated;

@end
