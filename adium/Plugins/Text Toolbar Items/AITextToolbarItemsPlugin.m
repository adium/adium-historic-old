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

@interface AITextToolbarItemsPlugin (PRIVATE)
- (void)convertString:(NSMutableAttributedString *)text toHave:(BOOL)applyTrait trait:(int)trait inRange:(NSRange)targetRange;
- (BOOL)string:(NSAttributedString *)text containsTrait:(int)trait inRange:(NSRange)targetRange;
@end


@implementation AITextToolbarItemsPlugin

- (void)installPlugin
{
    AIMiniToolbarItem	*toolbarItem;

    //Bold
    toolbarItem = [[AIMiniToolbarItem alloc] initWithIdentifier:@"Bold"];
    [toolbarItem setImage:[AIImageUtilities imageNamed:@"Bold_Off" forClass:[self class]]];
    [toolbarItem setTarget:self];
    [toolbarItem setAction:@selector(bold:)];
    [toolbarItem setToolTip:@"Bold"];
    [toolbarItem setEnabled:YES];
    [toolbarItem setDelegate:self];
    [toolbarItem setPaletteLabel:@"Bold text"];
    [toolbarItem setAllowsDuplicatesInToolbar:NO];
    [[AIMiniToolbarCenter defaultCenter] registerItem:[toolbarItem autorelease]];

    //Italic
    toolbarItem = [[AIMiniToolbarItem alloc] initWithIdentifier:@"Italic"];
    [toolbarItem setImage:[AIImageUtilities imageNamed:@"Bold_On" forClass:[self class]]];
    [toolbarItem setTarget:self];
    [toolbarItem setAction:@selector(italic:)];
    [toolbarItem setToolTip:@"Italic"];
    [toolbarItem setEnabled:YES];
    [toolbarItem setDelegate:self];
    [toolbarItem setPaletteLabel:@"Italic text"];
    [toolbarItem setAllowsDuplicatesInToolbar:NO];
    [[AIMiniToolbarCenter defaultCenter] registerItem:[toolbarItem autorelease]];
}

- (void)uninstallPlugin
{
    //[[AIMiniToolbarCenter defaultCenter] unregisterItem:[toolbarItem autorelease]];
}

- (IBAction)bold:(AIMiniToolbarItem *)toolbarItem
{
    NSView<AITextEntryView>	*textEntryView;
    NSMutableAttributedString	*text;
    NSRange			selectedRange;
    BOOL			currentState;

    //Get the text
    textEntryView = [[toolbarItem configurationObjects] objectForKey:@"TextEntryView"];
    text = [[textEntryView attributedString] mutableCopy];
    selectedRange = [textEntryView selectedRange];
    
    //Change the attribute
    currentState = [self string:text containsTrait:NSBoldFontMask inRange:selectedRange];
    [self convertString:text
                 toHave:(!currentState)
                  trait:NSBoldFontMask
                inRange:selectedRange];
    
    //Apply the changes
    [textEntryView setAttributedString:text]; 
}

- (IBAction)italic:(AIMiniToolbarItem *)toolbarItem
{
    NSView<AITextEntryView>	*textEntryView;
    NSMutableAttributedString	*text;
    NSRange			selectedRange;
    BOOL			currentState;

    //Get the text
    textEntryView = [[toolbarItem configurationObjects] objectForKey:@"TextEntryView"];
    text = [[textEntryView attributedString] mutableCopy];
    selectedRange = [textEntryView selectedRange];

    //Change the attribute
    currentState = [self string:text containsTrait:NSItalicFontMask inRange:selectedRange];
    [self convertString:text
                 toHave:(!currentState)
                  trait:NSItalicFontMask
                inRange:selectedRange];

    //Apply the changes
    [textEntryView setAttributedString:text];
}




- (BOOL)string:(NSAttributedString *)text containsTrait:(int)trait inRange:(NSRange)targetRange 
{
    NSFontManager	*fontManager = [NSFontManager sharedFontManager];
    NSFont		*currentFont = [text attribute:NSFontAttributeName atIndex:targetRange.location effectiveRange:nil];

    return([fontManager traitsOfFont:currentFont] & trait);
}

- (void)convertString:(NSMutableAttributedString *)text toHave:(BOOL)applyTrait trait:(int)trait inRange:(NSRange)targetRange 
{
    NSFontManager	*fontManager = [NSFontManager sharedFontManager];
    NSFont		*currentFont;
    NSRange		effectiveRange;
    
    //Change the text
    effectiveRange = targetRange;
    while(effectiveRange.location < (targetRange.location + targetRange.length) ){
        currentFont = [text attribute:NSFontAttributeName atIndex:effectiveRange.location effectiveRange:&effectiveRange];

        if(applyTrait){ //Apply the trait
            currentFont = [fontManager convertFont:currentFont toHaveTrait:trait];
        }else{ //remove the trait
            currentFont = [fontManager convertFont:currentFont toNotHaveTrait:trait];
        }

        //Apply the new attributes
        [text addAttribute:NSFontAttributeName
                     value:currentFont
                     range:NSIntersectionRange(effectiveRange, targetRange)];
        effectiveRange.location += effectiveRange.length;
    }
}

- (BOOL)configureToolbarItem:(AIMiniToolbarItem *)inToolbarItem forObjects:(NSDictionary *)inObjects
{
    NSString	*identifier = [inToolbarItem identifier];
    BOOL	enabled = YES;

    if([identifier compare:@"Bold"] == 0 || [identifier compare:@"Italic"] == 0){
        AIListObject		*object = [inObjects objectForKey:@"ContactObject"];
        NSView<AITextEntryView>	*text = [inObjects objectForKey:@"TextEntryView"];

        enabled = (object && [object isKindOfClass:[AIListContact class]] && text);
    }

    [inToolbarItem setEnabled:enabled];
    return(enabled);
}
        
@end
