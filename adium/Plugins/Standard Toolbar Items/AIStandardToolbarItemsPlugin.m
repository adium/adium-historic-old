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

#import "AIStandardToolbarItemsPlugin.h"
#import "AIFramedMiniToolbarButton.h"

@implementation AIStandardToolbarItemsPlugin

- (void)installPlugin
{
    //Space
/*    toolbarItem = [[AIMiniToolbarItem alloc] initWithIdentifier:@"Space"];
    [toolbarItem setView:[AIFramedMiniToolbarButton framedMiniToolbarButtonWithImage:[AIImageUtilities imageNamed:@"space" forClass:[self class]] forToolbarItem:toolbarItem]];
    [toolbarItem setTarget:nil];
    [toolbarItem setAction:nil];
    [toolbarItem setToolTip:@""];
    [toolbarItem setEnabled:YES];
    [toolbarItem setPaletteLabel:@"Space"];
    [toolbarItem setAllowsDuplicatesInToolbar:YES];
    [[AIMiniToolbarCenter defaultCenter] registerItem:[toolbarItem autorelease]];

    //Flexible Space
    toolbarItem = [[AIMiniToolbarItem alloc] initWithIdentifier:@"FlexibleSpace"];
    [toolbarItem setView:[AIFramedMiniToolbarButton framedMiniToolbarButtonWithImage:[AIImageUtilities imageNamed:@"space" forClass:[self class]] forToolbarItem:toolbarItem]];
    [toolbarItem setTarget:nil];
    [toolbarItem setAction:nil];
    [toolbarItem setToolTip:@""];
    [toolbarItem setEnabled:YES];
    [toolbarItem setPaletteLabel:@"Flexible Space"];
    [toolbarItem setFlexibleWidth:YES];
    [toolbarItem setAllowsDuplicatesInToolbar:YES];
    [[AIMiniToolbarCenter defaultCenter] registerItem:[toolbarItem autorelease]];
*/
    //Divider
/*    toolbarItem = [[AIMiniToolbarItem alloc] initWithIdentifier:@"Divider"];
    [toolbarItem setImage:[AIImageUtilities imageNamed:@"divider" forClass:[self class]]];
    [toolbarItem setTarget:nil];
    [toolbarItem setAction:nil];
    [toolbarItem setToolTip:@""];
    [toolbarItem setEnabled:YES];
    [toolbarItem setPaletteLabel:@"Separator"];
    [toolbarItem setAllowsDuplicatesInToolbar:YES];
    [[AIMiniToolbarCenter defaultCenter] registerItem:[toolbarItem autorelease]];
*/

    
    //New Message
    NSToolbarItem   *toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:@"NewMessage"
									   label:@"Message"
								    paletteLabel:@"Message"
									 toolTip:@"Message"
									  target:self
								 settingSelector:@selector(setImage:)
								     itemContent:[AIImageUtilities imageNamed:@"message" forClass:[self class]]
									  action:@selector(newMessage:)
									    menu:nil];
    [[adium toolbarController] registerToolbarItem:toolbarItem forToolbarType:@"ListObject"];

    //Close Message
/*    toolbarItem = [[AIMiniToolbarItem alloc] initWithIdentifier:@"CloseMessage"];
    [toolbarItem setImage:[AIImageUtilities imageNamed:@"close" forClass:[self class]]];
    [toolbarItem setTarget:self];
    [toolbarItem setAction:@selector(closeMessage:)];
    [toolbarItem setEnabled:YES];
    [toolbarItem setToolTip:@"Close message"];
    [toolbarItem setPaletteLabel:@"Close message"];
    [toolbarItem setDelegate:self];
    [[AIMiniToolbarCenter defaultCenter] registerItem:[toolbarItem autorelease]];
*/
    //Send Message
/*    toolbarItem = [[AIMiniToolbarItem alloc] initWithIdentifier:@"SendMessage"];
    [toolbarItem setImage:[AIImageUtilities imageNamed:@"message" forClass:[self class]]];
    [toolbarItem setTarget:self];
    [toolbarItem setAction:@selector(sendMessage:)];
    [toolbarItem setEnabled:YES];
    [toolbarItem setToolTip:@"Send message"];
    [toolbarItem setPaletteLabel:@"Send message"];
    [toolbarItem setDelegate:self];
    [[AIMiniToolbarCenter defaultCenter] registerItem:[toolbarItem autorelease]];

    //Send Message (button)
    toolbarItem = [[AIMiniToolbarItem alloc] initWithIdentifier:@"SendMessageButton"];
    [toolbarItem setImage:[AIImageUtilities imageNamed:@"sendButton" forClass:[self class]]];
    [toolbarItem setTarget:self];
    [toolbarItem setAction:@selector(sendMessage:)];
    [toolbarItem setEnabled:YES];
    [toolbarItem setToolTip:@"Send message"];
    [toolbarItem setPaletteLabel:@"Send message (button)"];
    [toolbarItem setDelegate:self];
    [[AIMiniToolbarCenter defaultCenter] registerItem:[toolbarItem autorelease]];
*/
}

- (void)uninstallPlugin
{
    //unregister items
}

- (IBAction)newMessage:(AIMiniToolbarItem *)toolbarItem
{
    AIListObject	*object = [[adium contactController] selectedListObject];

    if([object isKindOfClass:[AIListContact class]]){
		AIChat  *chat = [[adium contentController] openChatWithContact:(AIListContact *)object];
        [[adium interfaceController] setActiveChat:chat];
    }
	
}

- (IBAction)sendMessage:(AIMiniToolbarItem *)toolbarItem
{
    NSDictionary	*objects = [toolbarItem configurationObjects];
    AIChat		*chat = [objects objectForKey:@"Chat"];

    if(chat){
        [[adium notificationCenter] postNotificationName:Interface_SendEnteredMessage object:chat userInfo:nil];
    }
}

- (IBAction)closeMessage:(AIMiniToolbarItem *)toolbarItem
{
    NSDictionary	*objects = [toolbarItem configurationObjects];
    AIChat		*chat = [objects objectForKey:@"Chat"];

    if(chat){
        [[adium interfaceController] closeChat:chat];
    }
}

- (BOOL)configureToolbarItem:(AIMiniToolbarItem *)inToolbarItem forObjects:(NSDictionary *)inObjects
{
    NSString	*identifier = [inToolbarItem identifier];
    BOOL	enabled = YES;

    if([identifier compare:@"NewMessage"] == 0){
        AIListObject		*object = [inObjects objectForKey:@"ContactObject"];
        NSText<AITextEntryView>	*text = [inObjects objectForKey:@"TextEntryView"];

        enabled = (object && [object isKindOfClass:[AIListContact class]] && !text);

    }else if([identifier compare:@"SendMessage"] == 0 || [identifier compare:@"SendMessageButton"] == 0){
        AIListObject		*object = [inObjects objectForKey:@"ContactObject"];
        NSText<AITextEntryView>	*text = [inObjects objectForKey:@"TextEntryView"];

        enabled = (text && [text availableForSending] && object && [object isKindOfClass:[AIListObject class]]);

    }

    [inToolbarItem setEnabled:enabled];
    return(enabled);
}


@end





