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
    [toolbarItem setImage:[AIImageUtilities imageNamed:@"Bold_Off" forClass:[self class]]];
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
    NSFontManager		*fontManager = [NSFontManager sharedFontManager];
    NSView<AITextEntryView>	*textEntryView;
    NSMutableAttributedString	*text;
    NSFont			*currentFont;
    NSRange			selectedRange;
    NSRange			effectiveRange;
    BOOL			makingBold;
    
    //Get the text entry view and text
    textEntryView = [[toolbarItem configurationObjects] objectForKey:@"TextEntryView"];
    text = [[textEntryView attributedString] mutableCopy];
    selectedRange = [textEntryView selectedRange];

    //Figure out if we'll be adding bold, or removing bold
    currentFont = [text attribute:NSFontAttributeName atIndex:selectedRange.location effectiveRange:nil];
    makingBold = !([fontManager traitsOfFont:currentFont] & NSBoldFontMask);
    
    //Change the text
    effectiveRange = selectedRange;
    while(effectiveRange.location < (selectedRange.location + selectedRange.length) ){
        currentFont = [text attribute:NSFontAttributeName atIndex:effectiveRange.location effectiveRange:&effectiveRange];

        if(makingBold){ //Make the font bold
            currentFont = [fontManager convertFont:currentFont toHaveTrait:NSBoldFontMask];
        }else{ //make the font non-bold
            currentFont = [fontManager convertFont:currentFont toNotHaveTrait:NSBoldFontMask];
        }

        //Apply the new attributes
        [text addAttribute:NSFontAttributeName
                     value:currentFont
                     range:NSIntersectionRange(effectiveRange, selectedRange)];
        effectiveRange.location += effectiveRange.length;
    }

    //Apply the changes
    [textEntryView setAttributedString:text]; 
}

- (void)configureToolbarItem:(AIMiniToolbarItem *)inToolbarItem forObjects:(NSDictionary *)inObjects
{

}
        
@end
