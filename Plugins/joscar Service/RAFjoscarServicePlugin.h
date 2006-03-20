//
//  RAFjoscarPlugin.h
//  Adium
//
//  Created by Augie Fackler on 11/18/05.
//

#import <Adium/AIPlugin.h>
#import "RAFjoscarAIMService.h"
#import "RAFjoscarDotMacService.h"
#import "RAFjoscarICQService.h"

@interface RAFjoscarServicePlugin : AIPlugin {
	RAFjoscarAIMService *joscarAIMService;
	RAFjoscarDotMacService *joscarDotMacService;
	RAFjoscarICQService *joscarICQService;
}

@end
