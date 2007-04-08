//
//  ESIRCLibgaimServicePlugin.h
//  Adium
//
//  Created by Evan Schoenberg on 3/4/06.
//

#import <Cocoa/Cocoa.h>
#import <Adium/AIPlugin.h>
#import <AdiumLibgaim/AILibgaimPlugin.h>

@class ESIRCService;

@interface ESIRCLibgaimServicePlugin : AIPlugin <AILibgaimPlugin> {
	ESIRCService *ircService;
}

@end
