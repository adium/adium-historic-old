//
//  AINetworkConnectivity.h
//  AIUtilities.framework
//
//  Created by Evan Schoenberg on 8/17/04.
//

#import <Cocoa/Cocoa.h>

#define	AINetwork_ConnectivityChanged	@"AINetwork_ConnectivityChanged"

@interface AINetworkConnectivity : NSObject {

}

+ (BOOL)networkIsReachable;
+ (void)refreshReachabilityAndNotify;

@end

