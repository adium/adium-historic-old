//
//  SHAOLamerKillerPlugin.m
//  Adium
//
//  Created by Stephen Holt on Tue Jul 13 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "SHAOLamerKillerPlugin.h"


@implementation SHAOLamerKillerPlugin

- (void)installPlugin
{
    [[adium contentController] registerContentFilter:self ofType:AIFilterContent direction:AIFilterOutgoing];
    
    stringShitlist = [[NSArray alloc] initWithObjects:@" a/s/l",@" u",@" r",@" omg",@" pic",@" mby",@" 2nite",@" cos",@" coz",@" 2day",
                                                      @" waz",@" 4ever",@" B4",@" GR8",@" L8R",@" THX",@" THKS",@" lyk",
                                                      @" wut",@" asl",@" ic",@" pen0r",@" vagin0r",@" pr0n",@" fer",@" ffs",@" sif",
                                                      @" 2morrow",@" 2marro",@" k",@" OMGWTFBBQ",@" OMGHI2U",@" ur",@" NE1", @" "nil];
    killCount = 0;
}

- (void)uninstallPlugin
{
}

- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString context:(id)context
{
    if(inAttributedString && [inAttributedString length]){
        NSString *localString = [inAttributedString string];
    
        NSEnumerator *enumerator = [stringShitlist objectEnumerator];
        NSString *killString;
        NSRange killRange;

        while(killString = [enumerator nextObject]){
            killRange = [[localString lowercaseString] rangeOfString:[killString lowercaseString]];
            if(NSNotFound != killRange.location){
                killCount++;
                NSLog(@"\"%@\" found, killCount now: %i",killString,killCount);
            }
        }
    }
    
    if(killCount <= 25){
        return inAttributedString;
    }else{
        return [NSAttributedString stringWithString:@"This user is too lame to type out whole words.  Please stop talking to this person, if you care about your intelligence."];
    }
}

@end
