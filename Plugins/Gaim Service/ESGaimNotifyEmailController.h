//
//  ESGaimNotifyEmailController.h
//  Adium
//
//  Created by Evan Schoenberg on Fri May 28 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "CBGaimServicePlugin.h"

@interface ESGaimNotifyEmailController : NSObject {

}

+ (void *)handleNotifyEmails:(size_t)count detailed:(BOOL)detailed subjects:(const char **)subjects froms:(const char **)froms tos:(const char **)tos urls:(const char **)urls;
+ (void)showNotifyEmailWindowWithMessage:(NSAttributedString *)inMessage URLString:(NSString *)inURLString;

@end
