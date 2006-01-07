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

#import "AIPreferencePane.h"

#define PREFERENCE_VIEW_NIB		@"PreferenceView"	//Filename of the preference view nib

@implementation AIPreferencePane

//Return a new preference pane
+ (AIPreferencePane *)preferencePane
{
    return [[[self alloc] init] autorelease];
}

//Return a new preference pane, passing plugin
+ (AIPreferencePane *)preferencePaneForPlugin:(id)inPlugin
{
    return [[[self alloc] initForPlugin:inPlugin] autorelease];
}

//Init
- (id)init
{
	if ((self = [super init])) {
		[[adium preferenceController] addPreferencePane:self];
	}
	return self;
}

- (void)dealloc
{
	[restoreDict release];

	[super dealloc];
}

//as far as I can tell, -[NSPreferencePane compare:] compares nib names.
//this does the same thing, but case-insensitively.
- (NSComparisonResult)caseInsensitiveCompare:(id)other
{
	NSString *nibName = [self label];
	if ([other isKindOfClass:[NSString class]]) {
		return [nibName caseInsensitiveCompare:other];
	} else {
		return [nibName caseInsensitiveCompare:[other label]];
	}
}

//For subclasses -------------------------------------------------------------------------------
//Preference category
- (PREFERENCE_CATEGORY)category
{
	return AIPref_Advanced;
}

//Return an image for these preferences (advanced only)
- (NSImage *)image
{
	return nil;
}

@end

