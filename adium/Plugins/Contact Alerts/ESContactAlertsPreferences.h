//
//  ESContactAlertsPreferences.h
//  Adium
//
//  Created by Evan Schoenberg on Sun Aug 03 2003.
//

#import <Cocoa/Cocoa.h>

@class AIAdium;
@class ESContactAlertsPlugin;

@interface ESContactAlertsPreferences : NSObject {
    AIAdium			*owner;
    IBOutlet NSView		*view_prefView;
}

+ (ESContactAlertsPreferences *)contactAlertsPreferencesWithOwner:(id)inOwner;

@end
