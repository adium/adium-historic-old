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

#import "AIPreferenceController.h"

@class AIPreferencePane;

@interface NSObject(AIPreferencePaneDelegate)   //Will be removed, transition only
- (NSView *)viewForPreferencePane:(AIPreferencePane *)preferencePane;
- (void)closeViewForPreferencePane:(AIPreferencePane *)preferencePane;
@end

@interface AIPreferencePane : AIModularPane {    
	NSMutableDictionary *restoreDict;		// Dictionary of restorable defaults and their groups

    
	IBOutlet	NSView			*view_containerView;    //### TRANSITION ONLY, will be removed
    IBOutlet	NSView			*view_containerSubView; //### TRANSITION ONLY, will be removed
    IBOutlet	NSTextField		*textField_title;       //### TRANSITION ONLY, will be removed
    id					delegate;           			//### TRANSITION ONLY, will be removed
    PREFERENCE_CATEGORY category;           			//### TRANSITION ONLY, will be removed
    NSString			*label;             			//### TRANSITION ONLY, will be removed
    NSView				*preferenceView;    			//### TRANSITION ONLY, will be removed
    BOOL				isUpdated;          			//### TRANSITION ONLY, will be removed
}

+ (AIPreferencePane *)preferencePane;
+ (AIPreferencePane *)preferencePaneForPlugin:(id)inPlugin;
- (PREFERENCE_CATEGORY)category;
- (NSDictionary *)restorablePreferences;

//Will be removed, transition only
//### TRANSITION ONLY, will be removed//### TRANSITION ONLY, will be removed//### TRANSITION ONLY, will be removed
+ (AIPreferencePane *)preferencePaneInCategory:(PREFERENCE_CATEGORY)inCategory withDelegate:(id)inDelegate label:(NSString *)inLabel;
- (PREFERENCE_CATEGORY)category;
- (NSView *)viewWithContainer:(BOOL)includeContainer;
- (BOOL)isUpdated;

@end
