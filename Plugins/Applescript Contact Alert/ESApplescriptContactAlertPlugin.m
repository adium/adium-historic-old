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

#import "ESApplescriptContactAlertPlugin.h"
#import "ESContactAlertsController.h"
#import "ESPanelApplescriptDetailPane.h"
#import <AIUtilities/ESImageAdditions.h>

#define APPLESCRIPT_ALERT_SHORT AILocalizedString(@"Run an Applescript",nil)
#define APPLESCRIPT_ALERT_LONG AILocalizedString(@"Run the Applescript \"%@\"","%@ will be replaced by the name of the applescript to run.")

/*
 * @class ESApplescriptContactAlertPlugin
 * @brief Component which provides a "Run an Applescript" Action
 */
@implementation ESApplescriptContactAlertPlugin

- (void)installPlugin
{
    //Install our contact alert
	[[adium contactAlertsController] registerActionID:APPLESCRIPT_CONTACT_ALERT_IDENTIFIER withHandler:self];
}

//Run Applescript Alert -------------------------------------------------------------------------------------------------
#pragma mark Run Applescript Alert
- (NSString *)shortDescriptionForActionID:(NSString *)actionID
{
	return(APPLESCRIPT_ALERT_SHORT);
}

- (NSString *)longDescriptionForActionID:(NSString *)actionID withDetails:(NSDictionary *)details
{
	NSString	*scriptName = [[[details objectForKey:KEY_APPLESCRIPT_TO_RUN] lastPathComponent] stringByDeletingPathExtension];
	
	if(scriptName && [scriptName length]){
		return([NSString stringWithFormat:APPLESCRIPT_ALERT_LONG, scriptName]);
	}else{
		return(APPLESCRIPT_ALERT_SHORT);
	}
}

- (NSImage *)imageForActionID:(NSString *)actionID
{
	return([NSImage imageNamed:@"ApplescriptAlert" forClass:[self class]]);
}

- (AIModularPane *)detailsPaneForActionID:(NSString *)actionID
{
	return([ESPanelApplescriptDetailPane actionDetailsPane]);
}

- (void)performActionID:(NSString *)actionID forListObject:(AIListObject *)listObject withDetails:(NSDictionary *)details triggeringEventID:(NSString *)eventID userInfo:(id)userInfo
{
	NSURL 			*scriptURL;
	NSAppleScript   *script;
	
	scriptURL = [NSURL fileURLWithPath:[details objectForKey:KEY_APPLESCRIPT_TO_RUN]];
	script = [[NSAppleScript alloc] initWithContentsOfURL:scriptURL error:nil];
	
	[script executeAndReturnError:nil];
	[script release];
}

- (BOOL)allowMultipleActionsWithID:(NSString *)actionID
{
	return(YES);
}

@end
