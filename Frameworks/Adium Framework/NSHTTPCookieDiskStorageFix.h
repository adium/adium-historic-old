//
//  NSHTTPCookieDiskStorageFix.h
//  Adium
//
//  Created by Evan Schoenberg on 3/25/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*
 * From class-dump of Foundation.framework, OS X10.3.8
 */
@class NSHTTPCookieDiskStoragePrivate;
@interface NSHTTPCookieDiskStorage:NSObject
{
    NSHTTPCookieDiskStoragePrivate *_serverPrivate;
}

- (void)dealloc;
- (void)setCookies:fp8;
- (void)deleteCookies:fp8;
- cookies;
- cookiesMatchingDomain:fp8 path:fp12 secure:(char)fp16;
- init;
- initWithNotificationObject:fp8;

@end

@interface NSHTTPCookieDiskStorageFix : NSHTTPCookieDiskStorage {

}

@end
