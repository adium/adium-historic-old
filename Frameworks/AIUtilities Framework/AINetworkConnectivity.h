//
//  AINetworkConnectivity.h
//  AIUtilities.framework
//
//  Created by Evan Schoenberg on 8/17/04.
//

#import <Cocoa/Cocoa.h>

#define	AINetwork_ConnectivityChanged	@"AINetwork_ConnectivityChanged"

/*!
 * @class AINetworkConnectivity
 * @brief Class to notify of changes in Internet availability.
 * 
 * <tt>AINetworkConnectivity</tt> posts a notification, <tt>AINetwork_ConnectivityChanged</tt>, on the default NSNotificationCenter when it detects that Internet network connectivity has changed.  The object of this notification is an <tt>NSNumber</tt> which has a boolValue of <b>YES</b> if the Internet is now available or <b>NO</b> if the Internet is no longer available.
*/
@interface AINetworkConnectivity : NSObject {

}

/*!
 * @brief Report on current network connectivity
 *
 * This method provides a means for checking the current network connectivity.  It will return the same result as the last <tt>AINetwork_ConnectivityChanged</tt> notification did.  The notification should be relied upon whenever possible; this method exists primarily to assist in debugging.
 * @return YES if the network is reachable; NO if it is not
 */
+ (BOOL)networkIsReachable;

+ (void)refreshReachabilityAndNotify;

@end

