//
//  AISleepNotification.h
//  Adium
//
//  Created by Adam Iser on Sun Jun 29 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#import <Foundation/Foundation.h>

/* Evan: Documentation Note: The @def documentation below doesn't show up in doxygen. Not sure what I'm doing wrong. */

//Posted
/*!
 * @def AISystemWillSleep_Notification
 * @brief Indicates the system will go to sleep
 *
 * This will be posted to the default NSNotificationCenter before the system goes to sleep. To suspend the sleep process, see <tt>AISystemHoldSleep_Notification</tt>.
 */
#define AISystemWillSleep_Notification	@"AISystemWillSleep_Notification"

/*!
 * @def AISystemDidWake_Notification
 * @brief Indicates the system woke from sleep
 *
 * This will be posted to the default NSNotificationCenter when the system wakes from sleep.
 */
#define AISystemDidWake_Notification	@"AISystemDidWake_Notification"

//Received
/*!
 * @def AISystemHoldSleep_Notification
 * @brief Prevent the system from going to sleep temporarily
 *
 * This should be posted to the default NSNotificationCenter to request that the sleep process be suspended.  It should be paired with <tt>AISystemContinueSleep_Notification</tt> to allow the sleep process to resume.
 */
#define AISystemHoldSleep_Notification	@"AISystemHoldSleep_Notification"

/*!
 * @def AISystemContinueSleep_Notification
 * @brief Allow the system to continue going to sleep
 *
 * This should be posted to the default NSNotificationCenter to allow the sleep process to continue.  It is paired with <tt>AISystemHoldSleep_Notification</tt>.
 */
#define AISystemContinueSleep_Notification	@"AISystemContinueSleep_Notification"

/*!
 * @class AISleepNotification
 * @brief Class to notify when the system goes to sleep and wakes from sleep and optionally place a hold on the sleep process.
 *
 * <p><tt>AISleepNotification</tt> posts (on the default NSNotificationCenter) <tt>AISystemWillSleep_Notification</tt> when the system is about to go to sleep, and posts <tt>AISystemDidWake_Notification</tt> when it wakes from sleep.</p>
 * <p>Classes may request that the sleep process be postponed by posting <tt>AISystemHoldSleep_Notification</tt>.  This is most useful in response to the <tt>AISystemWillSleep_Notification</tt> notification.  When sleep should be allowed to continue, <tt>AISystemContinueSleep_Notification</tt> should be posted.  At that time, if no other holders are pending, the system will go to sleep.</p>
*/
@interface AISleepNotification : NSObject {

}

@end
