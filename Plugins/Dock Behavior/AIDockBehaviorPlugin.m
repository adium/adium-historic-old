/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AIDockBehaviorPlugin.h"
#import "AIDockBehaviorPreferences.h"
#import "ESDockAlertDetailPane.h"

#define DOCK_BEHAVIOR_ALERT_SHORT	@"Bounce the dock icon"
#define DOCK_BEHAVIOR_ALERT_LONG	@"Bounce the dock icon %@"

@interface AIDockBehaviorPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
- (void)eventNotification:(NSNotification *)notification;
- (BOOL)_upgradeCustomDockBehavior;
@end

@implementation AIDockBehaviorPlugin

- (void)installPlugin
{
	//Install our contact alert
	[[adium contactAlertsController] registerActionID:DOCK_BEHAVIOR_ALERT_IDENTIFIER withHandler:self];
}

- (void)uninstallPlugin
{

}

//Bounce Dock Alert ----------------------------------------------------------------------------------------------------
#pragma mark Bounce Dock Alert
- (NSString *)shortDescriptionForActionID:(NSString *)actionID
{
	return(DOCK_BEHAVIOR_ALERT_SHORT);
}

- (NSString *)longDescriptionForActionID:(NSString *)actionID withDetails:(NSDictionary *)details
{
	int behavior = [[details objectForKey:KEY_DOCK_BEHAVIOR_TYPE] intValue];
	return([NSString stringWithFormat:DOCK_BEHAVIOR_ALERT_LONG, [[[adium dockController] descriptionForBehavior:behavior] lowercaseString]]);
}

- (NSImage *)imageForActionID:(NSString *)actionID
{
	return([NSImage imageNamed:@"DockAlert" forClass:[self class]]);
}

- (AIModularPane *)detailsPaneForActionID:(NSString *)actionID
{
	return([ESDockAlertDetailPane actionDetailsPane]);
}

- (void)performActionID:(NSString *)actionID forListObject:(AIListObject *)listObject withDetails:(NSDictionary *)details triggeringEventID:(NSString *)eventID userInfo:(id)userInfo
{
	[[adium dockController] performBehavior:[[details objectForKey:KEY_DOCK_BEHAVIOR_TYPE] intValue]];
}

- (BOOL)allowMultipleActionsWithID:(NSString *)actionID
{
	return(NO);
}

@end

