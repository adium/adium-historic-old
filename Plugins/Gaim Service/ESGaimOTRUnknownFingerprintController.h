//
//  ESGaimOTRUnknownFingerprintController.h
//  Adium
//
//  Created by Evan Schoenberg on 2/9/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ESGaimOTRUnknownFingerprintController : NSObject {

}

+ (void)showUnknownFingerprintPromptForUsername:(const char *)who
									   protocol:(const char *)protocol
										   hash:(const char *)hash
								   responseInfo:(NSDictionary *)responseInfo;

@end
