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

#import "AIFramedMiniToolbarButton.h"
#import <AIUtilities/AIUtilities.h>


@interface AIFramedMiniToolbarButton (PRIVATE)
- (id)initWithImage:(NSImage *)inImage forToolbarItem:(AIMiniToolbarItem *)inToolbarItem;
- (id)copyWithZone:(NSZone *)zone;
- (NSMenu *)menuForEvent:(NSEvent *)event;
- (void)mouseDown:(NSEvent *)theEvent;
- (void)drawRect:(NSRect)rect;
@end


@implementation AIFramedMiniToolbarButton

//Create a new mini toolbar button
+ (AIFramedMiniToolbarButton *)framedMiniToolbarButtonWithImage:(NSImage *)inImage forToolbarItem:(AIMiniToolbarItem *)inToolbarItem
{
    return([[[self alloc] initWithImage:inImage forToolbarItem:inToolbarItem] autorelease]);
}

//Private --------------------------------------------------------------------------------
- (id)initWithImage:(NSImage *)inImage forToolbarItem:(AIMiniToolbarItem *)inToolbarItem
{
    NSSize	imageSize = [inImage size];
    
    [super initWithFrame:NSMakeRect(0, 0, imageSize.width, imageSize.height)];
    
    toolbarItem = [inToolbarItem retain];
    
    //config
    [super setTarget:self];
    [super setAction:@selector(click:)];
    [self setImage:inImage];
    [self setTitle:@""];
    [self setAlternateTitle:@""];
    [self setImagePosition:NSImageOnly];
    [self setButtonType:NSMomentaryChangeButton];
    [self setBordered:NO];

    return(self);
}

- (void)dealloc
{
    [toolbarItem release];

    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
    AIFramedMiniToolbarButton	*newItem = [[AIFramedMiniToolbarButton alloc] initWithImage:[self image] forToolbarItem:toolbarItem];   
      
    [newItem setTitle:[self title]];
    [newItem setAlternateTitle:[self alternateTitle]];
    [newItem setImagePosition:[self imagePosition]];
    [newItem setBordered:[self isBordered]];

    return(newItem);
}


//Pass contextual menu events on through to the toolbar
- (NSMenu *)menuForEvent:(NSEvent *)event
{
    if([[self superview] isKindOfClass:[AIMiniToolbar class]]){
        return([(AIMiniToolbar *)[self superview] menuForEvent:event]);
    }else{
        return([super menuForEvent:event]);
    }
}

//Initiate a drag if command is held while clicking
- (void)mouseDown:(NSEvent *)theEvent
{
    AIMiniToolbar	*toolbar = (AIMiniToolbar *)[self superview];

    if(![[AIMiniToolbarCenter defaultCenter] customizing:toolbar]){
        if([theEvent modifierFlags] & NSCommandKeyMask){
            [toolbar initiateDragWithEvent:theEvent];
        }else{
            [super mouseDown:theEvent];
        }
    }else{
        [toolbar initiateDragWithEvent:theEvent];
    }
}

- (IBAction)click:(id)sender
{
    //Invoke our target, passing it the toolbar item that was pressed
    [[toolbarItem target] performSelector:[toolbarItem action] withObject:toolbarItem];
}


- (void)drawRect:(NSRect)rect
{
    AIMiniToolbar *toolbar = (AIMiniToolbar *)[self superview];
    
    if([[AIMiniToolbarCenter defaultCenter] customizing:toolbar]){
        [[NSColor grayColor] set];
        [NSBezierPath strokeRect:rect];
    }
    
    [super drawRect:rect];
}






@end
