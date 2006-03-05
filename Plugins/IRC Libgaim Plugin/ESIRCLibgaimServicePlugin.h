//
//  ESIRCLibgaimServicePlugin.h
//  Adium
//
//  Created by Evan Schoenberg on 3/4/06.
//

#import <Cocoa/Cocoa.h>
#import "AILibgaimPlugin.h"

@class ESIRCService;

@interface ESIRCLibgaimServicePlugin : NSObject <AILibgaimPlugin> {
	ESIRCService *ircService;
}

@end
