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

@interface AISleepNotification : NSObject {

}

@end
