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

    //Underline
    toolbarItem = [[AIMiniToolbarItem alloc] initWithIdentifier:@"Underline"];
    [toolbarItem setImage:[AIImageUtilities imageNamed:@"Bold_On" forClass:[self class]]];
    [toolbarItem setTarget:self];
    [toolbarItem setAction:@selector(underline:)];
    [toolbarItem setToolTip:@"Underline"];
    [toolbarItem setEnabled:YES];
    [toolbarItem setDelegate:self];
    [toolbarItem setPaletteLabel:@"Underline text"];
    [toolbarItem setAllowsDuplicatesInToolbar:NO];
    [[AIMiniToolbarCenter defaultCenter] registerItem:[toolbarItem autorelease]];
}

- (void)uninstallPlugin
{
    //[[AIMiniToolbarCenter defaultCenter] unregisterItem:[toolbarItem autorelease]];
}

- (void)setTag:(int)inTag
{
    tag = inTag;    
}
- (int)tag{
    return(tag);
}

- (IBAction)bold:(AIMiniToolbarItem *)toolbarItem
{
    NSFontManager	*fontManager = [NSFontManager sharedFontManager];

    [self setTag:NSBoldFontMask];
    if([fontManager traitsOfFont:[fontManager selectedFont]] & NSBoldFontMask){
        [fontManager removeFontTrait:self];
    }else{
        [fontManager addFontTrait:self];
    }
}

- (IBAction)italic:(AIMiniToolbarItem *)toolbarItem
{
    NSFontManager	*fontManager = [NSFontManager sharedFontManager];
    
    [self setTag:NSItalicFontMask];
    if([fontManager traitsOfFont:[fontManager selectedFont]] & NSItalicFontMask){
        [fontManager removeFontTrait:self];
    }else{
        [fontManager addFontTrait:self];
    }
}

- (IBAction)underline:(AIMiniToolbarItem *)toolbarItem
{
    NSResponder	*responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];

    if(responder && [responder isKindOfClass:[NSText class]]){
        [(NSText *)responder underline:nil];
    }
}

- (BOOL)configureToolbarItem:(AIMiniToolbarItem *)inToolbarItem forObjects:(NSDictionary *)inObjects
{
    NSString	*identifier = [inToolbarItem identifier];
    BOOL	enabled = YES;

    if([identifier compare:@"Bold"] == 0 || [identifier compare:@"Italic"] == 0){
        AIListObject		*object = [inObjects objectForKey:@"ContactObject"];
        NSText<AITextEntryView>	*text = [inObjects objectForKey:@"TextEntryView"];

        enabled = (object && [object isKindOfClass:[AIListContact class]] && text);
    }

    [inToolbarItem setEnabled:enabled];
    return(enabled);
}
        
@end
