/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

@interface AITextToolbarItemsPlugin (PRIVATE)
- (void)convertString:(NSMutableAttributedString *)text toHave:(BOOL)applyTrait trait:(int)trait inRange:(NSRange)targetRange;
- (BOOL)string:(NSAttributedString *)text containsTrait:(int)trait inRange:(NSRange)targetRange;
@end


@implementation AITextToolbarItemsPlugin

- (void)installPlugin
{
#if 0
    NSToolbarItem   *toolbarItem;
    
    //Bold
    toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:@"Bold"
							  label:@"Bold"
						   paletteLabel:@"Bold text"
							toolTip:@"Bold text"
							 target:self
						settingSelector:@selector(setImage:)
						    itemContent:[NSImage imageNamed:@"Bold_Off" forClass:[self class]]
							 action:@selector(bold:)
							   menu:nil];
    [[adium toolbarController] registerToolbarItem:toolbarItem forToolbarType:@"TextEntry"];
    
    //Italic
    toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:@"Italic"
							  label:@"Italic"
						   paletteLabel:@"Italic text"
							toolTip:@"Italic text"
							 target:self
						settingSelector:@selector(setImage:)
						    itemContent:[NSImage imageNamed:@"Bold_On" forClass:[self class]]
							 action:@selector(italic:)
							   menu:nil];
    [[adium toolbarController] registerToolbarItem:toolbarItem forToolbarType:@"TextEntry"];
    
    //Italic
    toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:@"Underline"
							  label:@"Underline"
						   paletteLabel:@"Underline text"
							toolTip:@"Underline text"
							 target:self
						settingSelector:@selector(setImage:)
						    itemContent:[NSImage imageNamed:@"Bold_On" forClass:[self class]]
							 action:@selector(underline:)
							   menu:nil];
    [[adium toolbarController] registerToolbarItem:toolbarItem forToolbarType:@"TextEntry"];
#endif
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

#if 0 
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

    if([identifier isEqualToString:@"Bold"] || [identifier isEqualToString:@"Italic"] || [identifier isEqualToString::@"Underline"]){
        AIListObject			*object = [inObjects objectForKey:@"ContactObject"];
        NSText<AITextEntryView>	*text = [inObjects objectForKey:@"TextEntryView"];

        enabled = (object && [object isKindOfClass:[AIListObject class]] && text);
    }

    [inToolbarItem setEnabled:enabled];
    return(enabled);
}
#endif
        
@end
