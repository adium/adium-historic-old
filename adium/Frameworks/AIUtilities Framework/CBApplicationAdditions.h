//
//  CBApplicationAdditions.h
//  Adium
//
//  Created by Colin Barrett on Fri Nov 28 2003.
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
@end
