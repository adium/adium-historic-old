//
//  CBApplicationAdditions.h
//  Adium XCode
//
//  Created by Colin Barrett on Fri Nov 28 2003.
//

@interface NSApplication (CBApplicationAdditions)
- (BOOL)isOnPantherOrBetter;
- (BOOL)isOnJaguarOrBetter;
- (BOOL)isWebKitAvailable;
- (BOOL)isURLLoadingAvailable;
@end
