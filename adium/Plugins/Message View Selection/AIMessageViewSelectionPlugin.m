//
//  AIMessageViewSelectionPlugin.m
//  Adium
//
//  Created by Adam Iser on Fri Sep 26 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIMessageViewSelectionPlugin.h"
#import "AIMessageViewSelectionPreferences.h"

#define MESSAGE_VIEW_DEFAULT_PREFS	@"MessageViewSelectionDefaults"

@interface AIMessageViewSelectionPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation AIMessageViewSelectionPlugin

- (void)installPlugin
{
        
}

@end
