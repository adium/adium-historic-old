//
//  ESContactListDisplayFormat.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Aug 11 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIAdium.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "ESContactListDisplayFormatPlugin.h"
#import "ESContactListDisplayFormatPreferences.h"



#define DISPLAYFORMAT_DEFAULT_PREFS		@"Display Format Defaults"

@interface ESContactListDisplayFormatPlugin (PRIVATE)
- (void)updateScanner;
- (void)_applyDisplayFormatToObject:(AIListObject *)inObject delayed:(BOOL)delayed;
@end

@implementation ESContactListDisplayFormatPlugin

- (void)installPlugin
{
    //Register our default preferences
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:DISPLAYFORMAT_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_DISPLAYFORMAT];
    displayFormat = [[[owner preferenceController] preferenceForKey:@"Format String" group:PREF_GROUP_DISPLAYFORMAT object:nil] retain];
    [self updateScanner];
    
    //Register ourself as a handle observer
    [[owner contactController] registerListObjectObserver:self];

    //Observe preferences changes
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(listObjectAttributesChanged:) name:ListObject_AttributesChanged object:nil];
    
    prefs = [[ESContactListDisplayFormatPreferences contactListDisplayFormatPreferencesWithOwner:owner] retain];
}

- (void)uninstallPlugin
{
    [displayFormat release];
    [theScanner release];
    //[[owner contactController] unregisterHandleObserver:self];
}

//Called as contacts are created
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys delayed:(BOOL)delayed silent:(BOOL)silent
{
    if(inModifiedKeys == nil && [inObject isKindOfClass:[AIListContact class]]){ //Only set on contact creation
            [self _applyDisplayFormatToObject:inObject delayed:delayed];
    }

    return(nil);
}

- (void)preferencesChanged:(NSNotification *)notification
{
    if([(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_DISPLAYFORMAT] == 0){
        displayFormat = [[owner preferenceController] preferenceForKey:@"Format String" group:PREF_GROUP_DISPLAYFORMAT object:nil]; //load new displayFormat
        [self updateScanner];
        NSEnumerator * contactEnumerator = [[[owner contactController] allContactsInGroup:nil subgroups:YES] objectEnumerator];
        AIListObject * inObject;
        while (inObject = [contactEnumerator nextObject])
            if ([inObject isKindOfClass:[AIListContact class]])
                [self _applyDisplayFormatToObject:inObject delayed:NO];
    }
}

- (void)listObjectAttributesChanged:(NSNotification *)notification
{
    NSArray	*keys = [[notification userInfo] objectForKey:@"Keys"];
    AIListObject *inObject = [notification object];

    //We only need to redraw if the display name has changed
    if([keys containsObject:@"Display Name"] && [inObject isKindOfClass:[AIListContact class]]){
        [self _applyDisplayFormatToObject:inObject delayed:NO];
    }
}

- (void)updateScanner
{
    numberOfKeywords = 0;
    [theScanner release];
    theScanner = [[NSScanner scannerWithString:displayFormat] retain];
    while(![theScanner isAtEnd]){
        [theScanner scanUpToString:@"<" intoString:nil];

        if([theScanner scanString:@"<" intoString:nil]){
            //--remember where this keyword was--
            keyWordLocation[numberOfKeywords] = [theScanner scanLocation];
            numberOfKeywords++;
        }
    }
}



//Private ---------------------------------------------------------------------------------------
//Apply an alias to an object (Does not save the alias!)
- (void)_applyDisplayFormatToObject:(AIListObject *)inObject delayed:(BOOL)delayed
{
    AIMutableOwnerArray	*displayNameArray;
    NSMutableString * formattedDisplayName = [displayFormat mutableCopy];
    
    displayNameArray = [inObject displayArrayForKey:@"Formatted Display Name"];
        //--fill in the keywords in the string--

        int loop;
        
        for(loop = numberOfKeywords-1;loop >= 0;loop--){
            NSString *keyword;
            //--read the keyword--
            unsigned int loc = keyWordLocation[loop];
            [theScanner setScanLocation:loc];
            [theScanner scanUpToString:@">" intoString:&keyword];
            if([theScanner scanString:@">" intoString:nil]){
                NSRange wordRange;
                unsigned int a = keyWordLocation[loop] -1;
                unsigned int b = [theScanner scanLocation] - keyWordLocation[loop]+1;
                wordRange = NSMakeRange(a, b);

                //--fill in the keyword--
                if([keyword compare:@"Display Name"] == 0){
                    [formattedDisplayName replaceCharactersInRange:wordRange withString:[inObject displayName]];
                }else if([keyword compare:@"Screen Name"] == 0){
                        [formattedDisplayName replaceCharactersInRange:wordRange withString:[inObject UID]];
                }else if([keyword compare:@"Service ID"] == 0){
                        [formattedDisplayName replaceCharactersInRange:wordRange withString:[inObject serviceID]];
                }else if([keyword compare:@"Service Description"] == 0){
                     //   [formattedDisplayName replaceCharactersInRange:wordRange withString:[[inObject service] description]];
                }else{
                    //                   NSLog(@"unknown keyword string");
                }
            }
        
    [displayNameArray setObject:formattedDisplayName withOwner:self]; //Set the new formatted display name
    [[owner contactController] listObjectAttributesChanged:inObject modifiedKeys:[NSArray arrayWithObject:@"Formatted Display Name"] delayed:delayed];
}
}

@end




