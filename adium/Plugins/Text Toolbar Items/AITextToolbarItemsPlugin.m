//
//  AITextFormattingToolbarItemsPlugin.m
//  Adium
//
//  Created by Adam Iser on Sun Dec 22 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "AITextToolbarItemsPlugin.h"
#import "AIAdium.h"
#import <AIUtilities/AIUtilities.h>


@implementation AITextToolbarItemsPlugin

- (void)installPlugin
{
    AIMiniToolbarItem	*toolbarItem;

    //Bold
    toolbarItem = [[AIMiniToolbarItem alloc] initWithIdentifier:@"Bold"];
    [toolbarItem setImage:[AIImageUtilities imageNamed:@"bold" forClass:[self class]]];
    [toolbarItem setTarget:self];
    [toolbarItem setAction:@selector(bold:)];
    [toolbarItem setToolTip:@"Bold"];
    [toolbarItem setEnabled:YES];
    [toolbarItem setPaletteLabel:@"Bold text"];
    [toolbarItem setAllowsDuplicatesInToolbar:NO];
    [[AIMiniToolbarCenter defaultCenter] registerItem:[toolbarItem autorelease]];
    
}

- (IBAction)bold:(AIMiniToolbarItem *)toolbarItem
{
    NSView<AITextEntryView>	*text = [[toolbarItem configurationObjects] objectForKey:@"TextEntryView"];

    NSLog(@"%@",text);
//    [text setSelectedTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:]];
    
    /*
    - (NSAttributedString *)attributedString;
    - (void)setAttributedString:(NSAttributedString *)inAttributedString;
    - (NSRange)selectedRange;
    - (void)setSelectedRange:(NSRange)inRange;
    - (void)setSelectedTextAttributes:(NSDictionary *)attributeDictionary;
    - (NSDictionary *)selectedTextAttributes;
*/    
}

- (void)configureToolbarItem:(AIMiniToolbarItem *)inToolbarItem forObjects:(NSDictionary *)inObjects
{
/*    NSString	*identifier = [inToolbarItem identifier];

    if([identifier compare:@"NewMessage"] == 0){
        AIContactObject		*handle = [inObjects objectForKey:@"ContactObject"];

        if(handle && [handle isKindOfClass:[AIContactHandle class]]){
            [inToolbarItem setEnabled:YES];
        }else{
            [inToolbarItem setEnabled:NO];
        }

    }*/
}
        
@end
