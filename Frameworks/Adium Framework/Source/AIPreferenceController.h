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

#import "AIObject.h"
#import "AIPreferenceControllerProtocol.h"

@protocol AIController;

@interface AIPreferenceController : AIObject <AIPreferenceController> {
	NSString				*userDirectory;
	
	NSMutableArray			*paneArray;						//Loaded preference panes
	NSMutableDictionary		*observers;						//Preference change observers

	NSMutableDictionary		*defaults;						//Preference defaults
	NSMutableDictionary		*prefCache;						//Preference cache
	NSMutableDictionary		*prefWithDefaultsCache;			//Preference cache with defaults included
	
	NSMutableDictionary		*objectDefaults;				//Object specific defaults
	NSMutableDictionary		*objectPrefCache;				//Object specific preferences cache
	NSMutableDictionary		*objectPrefWithDefaultsCache;	//Object specific preferences cache with defaults included

	int						preferenceChangeDelays;			//Number of active delays (0 = not delayed)
	NSMutableSet			*delayedNotificationGroups;  	//Groups with delayed changes
}

@end


