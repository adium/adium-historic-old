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

#import "AIDockBehaviorPlugin.h"
#import "AIDockController.h"
#import "ESContactAlertsController.h"
#import "ESDockAlertDetailPane.h"
#import <AIUtilities/ESImageAdditions.h>

#define DOCK_BEHAVIOR_ALERT_SHORT	@"Bounce the dock icon"
#define DOCK_BEHAVIOR_ALERT_LONG	@"Bounce the dock icon %@"

@interface AIDockBehaviorPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
- (void)eventNotification:(NSNotification *)notification;
- (BOOL)_upgradeCustomDockBehavior;
@end

/*!
 * @class AIDockBehaviorPlugin
 * @brief Bounce Dock action component
 */
@implementation AIDockBehaviorPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
	//Install our contact alert
	[[adium contactAlertsController] registerActionID:DOCK_BEHAVIOR_ALERT_IDENTIFIER withHandler:self];
}

/*!
 * @brief Short description
 * @result A short localized description of the action
 */
- (NSString *)shortDescriptionForActionID:(NSString *)actionID
{
	return(DOCK_BEHAVIOR_ALERT_SHORT);
}

/*!
 * @brief Long description
 * @result A longer localized description of the action which should take into account the details dictionary as appropraite.
 */
- (NSString *)longDescriptionForActionID:(NSString *)actionID withDetails:(NSDictionary *)details
{
	int behavior = [[details objectForKey:KEY_DOCK_BEHAVIOR_TYPE] intValue];
	return([NSString stringWithFormat:DOCK_BEHAVIOR_ALERT_LONG, [[[adium dockController] descriptionForBehavior:behavior] lowercaseString]]);
}

/*!
 * @brief Image
 */
- (NSImage *)imageForActionID:(NSString *)actionID
{
	return([NSImage imageNamed:@"DockAlert" forClass:[self class]]);
}

/*!
 * @brief Details pane
 * @result An <tt>AIModularPane</tt> to use for configuring this action, or nil if no configuration is possible.
 */
- (AIModularPane *)detailsPaneForActionID:(NSString *)actionID
{
	return([ESDockAlertDetailPane actionDetailsPane]);
}

/*!
 * @brief Perform an action
 *
 * Bounce the dock icon
 *
 * @param actionID The ID of the action to perform
 * @param listObject The listObject associated with the event triggering the action. It may be nil
 * @param details If set by the details pane when the action was created, the details dictionary for this particular action
 * @param eventID The eventID which triggered this action
 * @param userInfo Additional information associated with the event; userInfo's type will vary with the actionID.
 */
- (void)performActionID:(NSString *)actionID forListObject:(AIListObject *)listObject withDetails:(NSDictionary *)details triggeringEventID:(NSString *)eventID userInfo:(id)userInfo
{
	[[adium dockController] performBehavior:[[details objectForKey:KEY_DOCK_BEHAVIOR_TYPE] intValue]];
}

/*!
 * @brief Allow multiple actions?
 *
 * If this method returns YES, every one of this action associated with the triggering event will be executed.
 * If this method returns NO, only the first will be.
 *
 * Don't allow multiple dock actions to occur.  While a series of "Bounce every 5 seconds," "Bounce every 10 seconds,"
 * and so on actions could be combined sanely, a series of "Bounce once" would make the dock go crazy.
 */
- (BOOL)allowMultipleActionsWithID:(NSString *)actionID
{
	return(NO);
}

@end

