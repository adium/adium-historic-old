//
//  AITextForcingPlugin.m
//  Adium
//
//  Created by Adam Iser on Tue Jan 21 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AITextForcingPlugin.h"
#import "AIAdium.h"
#import <AIUtilities/AIUtilities.h>
#import "AITextForcingPreferences.h"

#define TEXT_FORCING_DEFAULT_PREFS	@"TextForcingDefaults"

@interface AITextForcingPlugin (PRIVATE)
- (void)filterContentObject:(id <AIContentObject>)inObject;
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation AITextForcingPlugin

- (void)installPlugin
{
    //init
    forceFont = NO;
    forceText = NO;
    forceBackground = NO;
    force_desiredFont = nil;
    force_desiredTextColor = nil;
    force_desiredBackgroundColor = nil;

    //Register our default preferences
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:TEXT_FORCING_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_TEXT_FORCING];

    [self preferencesChanged:nil];
    
    //Our preference view
    preferences = [[AITextForcingPreferences textForcingPreferencesWithOwner:owner] retain];

    //Register our content filter
    [[owner contentController] registerIncomingContentFilter:self];
    
    //Observe
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
}

- (void)filterContentObject:(id <AIContentObject>)inObject
{
    if([[inObject type] compare:CONTENT_MESSAGE_TYPE] == 0){
        AIContentMessage		*contentMessage = (AIContentMessage *)inObject;
        NSMutableAttributedString	*message = [[contentMessage message] mutableCopy];

//        NSLog(@"Filter \"%@\"",[message string]);    

        //Optimize this...

        if(forceFont){
            [message addAttribute:NSFontAttributeName value:force_desiredFont range:NSMakeRange(0, [message length])];
            [contentMessage setMessage:message];
        }
        if(forceText){
            [message addAttribute:NSForegroundColorAttributeName value:force_desiredTextColor range:NSMakeRange(0, [message length])];
            [contentMessage setMessage:message];
        }
        if(forceBackground){
            //Add the forced body color
            [message addAttribute:AIBodyColorAttributeName value:force_desiredBackgroundColor range:NSMakeRange(0, [message length])];
            //Remove any 'sub-background' colors
            [message removeAttribute:NSBackgroundColorAttributeName range:NSMakeRange(0, [message length])];

            [contentMessage setMessage:message];
        }
        
    }
}

- (void)preferencesChanged:(NSNotification *)notification
{
    //Optimize this...

    if([(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_TEXT_FORCING] == 0){
        NSDictionary	*prefDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_TEXT_FORCING];

        //Release the old values..


        //Cache the preference values
        forceFont = [[prefDict objectForKey:KEY_FORCE_FONT] boolValue];
        forceText = [[prefDict objectForKey:KEY_FORCE_TEXT_COLOR] boolValue];
        forceBackground = [[prefDict objectForKey:KEY_FORCE_BACKGROUND_COLOR] boolValue];

        force_desiredFont = [[[prefDict objectForKey:KEY_FORCE_DESIRED_FONT] representedFont] retain];
        force_desiredTextColor = [[[prefDict objectForKey:KEY_FORCE_DESIRED_TEXT_COLOR] representedColor] retain];
        force_desiredBackgroundColor = [[[prefDict objectForKey:KEY_FORCE_DESIRED_BACKGROUND_COLOR] representedColor] retain];
    }
}

@end





