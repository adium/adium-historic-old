//
//  AISleepNotification.h
//  Adium
//
//  Created by Adam Iser on Sun Jun 29 2003.
//

#import <Foundation/Foundation.h>

//Posted
#define AISystemWillSleep_Notification	@"AISystemWillSleep_Notification"
#define AISystemDidWake_Notification	@"AISystemDidWake_Notification"

//Received
#define AISystemHoldSleep_Notification	@"AISystemHoldSleep_Notification"
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
