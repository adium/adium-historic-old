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

#import "AIPreferencePane.h"

#define PREFERENCE_VIEW_NIB		@"PreferenceView"	//Filename of the preference view nib

@interface AIPreferencePane (PRIVATE)
- (id)initInCategory:(PREFERENCE_CATEGORY)inCategory withDelegate:(id)inDelegate label:(NSString *)inLabel;
- (NSString *)nibName;
- (void)viewDidLoad;
- (void)viewWillClose;
- (void)configureControlDimming;
@end

@implementation AIPreferencePane

//Return a new preference pane
+ (AIPreferencePane *)preferencePane
{
    return([[[self alloc] init] autorelease]);
}

//Return a new preference pane, passing plugin
+ (AIPreferencePane *)preferencePaneForPlugin:(id)inPlugin
{
    return([[[self alloc] initForPlugin:inPlugin] autorelease]);
}

//Init
- (id)init
{
    [super init];
	[[adium preferenceController] addPreferencePane:self];
    return(self);
}


//For subclasses -------------------------------------------------------------------------------
//Preference category
- (PREFERENCE_CATEGORY)category
{
	return(AIPref_Advanced_Other);
}

//Return an array of dictionaries, each dictionary of the form (key, default, group)
- (NSDictionary *)restorablePreferences
{
	return(nil);
}


@end

