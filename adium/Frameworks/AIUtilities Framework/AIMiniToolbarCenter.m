/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AIMiniToolbarCenter.h"
#import "AIMiniToolbarItem.h"
#import "AIVerticallyCenteredTextCell.h"

#define MINI_TOOLBAR_CUSTOMIZE_NIB	@"MiniToolbarCustomize"	//Filename of the minitoolbar nib

@interface AIMiniToolbarCenter (PRIVATE)
- (id)init;
- (void)dragItem:(NSNumber *)inRow;
@end

@implementation AIMiniToolbarCenter

static AIMiniToolbarCenter *defaultCenter = nil;
+ (id)defaultCenter
{
    if(!defaultCenter){
        defaultCenter = [[self alloc] init];
    }
    
    return(defaultCenter);
}

//Return the 'AIMiniToolbarItem's for the specified toolbar
- (NSArray *)itemsForToolbar:(NSString *)inType
{
    return([toolbarDict objectForKey:inType]);
}

//Set the toolbar item identifiers associated with a toolbar
- (void)setItems:(NSArray *)inItems forToolbar:(NSString *)inType
{
    //Change the items
    [toolbarDict setObject:inItems forKey:inType];

    //Send out a notification
    [[NSNotificationCenter defaultCenter] postNotificationName:AIMiniToolbar_ItemsChanged object:inType userInfo:nil];
}

//Register a toolbar item
- (void)registerItem:(AIMiniToolbarItem *)inItem
{
    [itemDict setObject:inItem forKey:[inItem identifier]];
}

//Returns a new instance of the specifed toolbar item
- (AIMiniToolbarItem *)itemWithIdentifier:(NSString *)inIdentifier
{
    return([[[itemDict objectForKey:inIdentifier] copy] autorelease]);
}

//Show the customization palette
- (IBAction)customizeToolbars:(id)sender
{
    NSArray		*itemArray;
    NSEnumerator	*enumerator;
    AIMiniToolbarItem	*toolbarItem;
    
    //Load the customization nib
    [NSBundle loadNibNamed:MINI_TOOLBAR_CUSTOMIZE_NIB owner:self];
    [[tableView_items tableColumnWithIdentifier:@"icon"] setDataCell:[[[NSImageCell alloc] init] autorelease]];
    [[tableView_items tableColumnWithIdentifier:@"label"] setDataCell:[[[AIVerticallyCenteredTextCell alloc] init] autorelease]];
 
    //Turn customization mode on
    customizing = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:AIMiniToolbar_RefreshItem object:nil];

    //Build an array of views for every available toolbar item
    if(itemImageArray) [itemImageArray release];
    itemImageArray = [[NSMutableArray alloc] init];
    itemArray = [itemDict allValues];
    enumerator = [itemArray objectEnumerator];
    while((toolbarItem = [enumerator nextObject])){
        NSView	*itemView = [toolbarItem view];
        NSRect	itemFrame = [itemView frame];
        NSImage	*itemImage = [[NSImage alloc] initWithSize:itemFrame.size];
        
        [itemImage lockFocus];
            [itemView drawRect:NSMakeRect(0, 0, itemFrame.size.width, itemFrame.size.height)];
        [itemImage unlockFocus];

        [itemImageArray addObject:[itemImage autorelease]];
    }

    //Display the customization palette
    [panel_customization makeKeyAndOrderFront:nil];
}

//Returns yes if the toolbars are being customized
- (BOOL)customizing{
    return(customizing);
}

//Closes the customization palette
- (IBAction)endCustomization:(id)sender
{
    //Turn customization mode off
    customizing = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:AIMiniToolbar_RefreshItem object:nil];

    //Release the array of views
    [itemImageArray release]; itemImageArray = nil;

    //Close the customization palette
    [panel_customization orderOut:nil];
    [panel_customization autorelease]; panel_customization = nil;
}

- (BOOL)windowShouldClose:(id)sender
{
    [self endCustomization:nil];

    return(YES);
}

// Private ---------------------------------------------------------------------------
- (id)init
{
    [super init];
    
    toolbarDict = [[NSMutableDictionary alloc] init];
    itemDict = [[NSMutableDictionary alloc] init];
    customizing = NO;
    
    return(self);
}

- (void)dealloc
{
    [itemImageArray release];
    [toolbarDict release];
    [itemDict release];

    [super dealloc];
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    return([itemDict count]);
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    NSString	*identifier = [tableColumn identifier];

    if([identifier compare:@"icon"] == 0){
        return([itemImageArray objectAtIndex:row]);
    }else if([identifier compare:@"label"] == 0){
        return([[[itemDict allValues] objectAtIndex:row] paletteLabel]);
    }else{
        return([[itemDict allValues] objectAtIndex:row]);
    }
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row
{
    return(NO);
}

- (void)dragItemAtRow:(int)dragRow fromPoint:(NSPoint)inLocation withEvent:(NSEvent *)inEvent
{
    NSImage		*image, *opaqueImage;
    NSPasteboard	*pboard;
    AIMiniToolbarItem	*dragItem;
    NSSize		imageSize;
    
    dragItem = [[itemDict allValues] objectAtIndex:dragRow];
    image = [itemImageArray objectAtIndex:dragRow];

    //Put information on the pasteboard
    pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
    [pboard declareTypes:[NSArray arrayWithObjects:MINI_TOOLBAR_ITEM_DRAGTYPE,nil] owner:self];
    [pboard setString:[dragItem identifier] forType:MINI_TOOLBAR_ITEM_DRAGTYPE];

    //Create an image of the item
    imageSize = [image size];
    opaqueImage = [[[NSImage alloc] initWithSize:imageSize] autorelease];
    [opaqueImage setBackgroundColor:[NSColor clearColor]];
    [opaqueImage lockFocus];
        [image dissolveToPoint:NSMakePoint(0,0) fraction:0.7];
    [opaqueImage unlockFocus];

    //Initiate the drag
    [tableView_items dragImage:opaqueImage
                    at:NSMakePoint(inLocation.x - (imageSize.width/2.0), inLocation.y + (imageSize.height/2.0) )
                offset:NSMakeSize(0,0)
                 event:inEvent pasteboard:pboard source:self slideBack:YES];
}



@end
