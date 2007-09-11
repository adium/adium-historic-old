//
//  AIContactVisibility.h
//  Adium
//
//  Created by Andre Cohen on 8/5/07.
//

#import <Cocoa/Cocoa.h>
#import <Adium/AIPlugin.h>
#import <Adium/AIListObject.h>
#import "AIContactControllerProtocol.h"

@interface AIContactVisibilityPlugin : AIPlugin <AIListObjectObserver> {
	NSMenuItem	*alwaysVisible;
}

- (void)updateVisible:(id)sender;

@end
