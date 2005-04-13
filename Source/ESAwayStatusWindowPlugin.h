//
//  ESAwayStatusWindowPlugin.h
//  Adium
//
//  Created by Evan Schoenberg on 4/12/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import <Adium/AIPlugin.h>

@protocol AIListObjectObserver;

@interface ESAwayStatusWindowPlugin : AIPlugin<AIListObjectObserver> {
	BOOL			showStatusWindow;
	NSMutableSet	*awayAccounts;
}

@end
