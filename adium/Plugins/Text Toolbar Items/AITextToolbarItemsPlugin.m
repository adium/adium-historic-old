/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

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

        enabled = (object && [object isKindOfClass:[AIListObject class]] && text);
    }

    [inToolbarItem setEnabled:enabled];
    return(enabled);
}
        
@end
