//
//  CBApplicationAdditions.h
//  Adium
//
//  Created by Colin Barrett on Fri Nov 28 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

@interface NSApplication (CBApplicationAdditions)
+ (BOOL)isOnTigerOrBetter;
- (BOOL)isOnTigerOrBetter;

+ (BOOL)isOnPantherOrBetter;
- (BOOL)isOnPantherOrBetter;

+ (BOOL)isOnJaguarOrBetter;
- (BOOL)isOnJaguarOrBetter;

- (BOOL)isWebKitAvailable;
- (BOOL)isURLLoadingAvailable;
- (NSString *)applicationVersion;

@end
