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

#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AISCLEditHeaderView.h"
#import "AIContactListEditorWindowController.h"

@implementation AISCLEditHeaderView

- (void)configureForAccounts:(NSArray *)accountArray view:(AIAlternatingRowOutlineView *)outlineView
{
    NSArray		*subviewArray;
    AIColoredBoxView	*dividerBox;
    int			loop;
    
    //Remove any header text
    subviewArray = [self subviews];
    while([subviewArray count] > 0){
        [[subviewArray objectAtIndex:0] removeFromSuperview];
    }

    //Add a column for each account
    for(loop = 0;loop < [accountArray count] + 1;loop++){
        NSTextField		*textField;
        AIColoredBoxView	*coloredBox;
        NSBox			*seperator;
        NSRect			frame;
        
        if(loop != 0){
            AIAccount		*account = [accountArray objectAtIndex:(loop-1)];

            //Colored backing
            frame = NSMakeRect(LABEL_X_OFFSET + COLOR_X_OFFSET + ((loop) * (SUB_COLUMN_WIDTH + [outlineView intercellSpacing].width)),
                            LABEL_Y_OFFSET + COLOR_Y_OFFSET,
                            COLOR_LENGTH,
                            COLOR_HEIGHT);
            coloredBox = [[[AIColoredBoxView alloc] initWithFrame:frame] autorelease];
            if(![outlineView firstColumnColored]){
                if(loop % 2) [coloredBox setColor:[outlineView backgroundColor]];
                else [coloredBox setColor:[outlineView alternatingColumnColor]];
            }else{
                if(loop % 2) [coloredBox setColor:[outlineView alternatingColumnColor]];
                else [coloredBox setColor:[outlineView backgroundColor]];
            }
            [self addSubview:coloredBox];
            [coloredBox setFrameRotation:LABEL_ROTATION];
    
            //Diagonal header
            frame = NSMakeRect(LABEL_X_OFFSET + NAME_X_OFFSET + ((loop) * (SUB_COLUMN_WIDTH + [outlineView intercellSpacing].width)),
                            LABEL_Y_OFFSET + NAME_Y_OFFSET,
                            NAME_LENGTH,
                            NAME_HEIGHT);
            textField = [[[NSTextField alloc] initWithFrame:frame] autorelease];
            [textField setStringValue:[account accountDescription]];
            [textField setFont:[NSFont labelFontOfSize:LABEL_SIZE]];
            [textField setDrawsBackground:NO];
            [textField setBordered:YES];
            [textField setBezeled:NO];
            [textField setEditable:NO];
            [textField setSelectable:NO];
            [self addSubview:textField];
            [textField setFrameRotation:LABEL_ROTATION];
        }

        //Line
	seperator = [[[NSBox alloc] init] autorelease];
        [seperator setBoxType:NSBoxSeparator];

        [self addSubview:seperator];
        [seperator setFrame:NSMakeRect(LABEL_X_OFFSET + ((loop) * (SUB_COLUMN_WIDTH + [outlineView intercellSpacing].width)), LABEL_Y_OFFSET, LABEL_LENGTH, 1)];
        [seperator setFrameRotation:LABEL_ROTATION];
    }

    //Bottom Line
    dividerBox = [[[AIColoredBoxView alloc] initWithFrame:NSMakeRect(0, 0, [self frame].size.width, 1)] autorelease];
    [dividerBox setColor:[NSColor lightGrayColor]];
    [dividerBox	setAutoresizingMask:NSViewWidthSizable];
    [self addSubview:dividerBox];
    
    //Force a redisplay
//    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)rect
{
    static NSColor *color;

    //Fill the rect with aqua stripes
    [[NSColor windowBackgroundColor] set];
    [NSBezierPath fillRect:rect];

    //Soften the stripes by painting 50% white over them
    if(!color){
        color = [[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:0.5] retain];
    }
    [color set];
    [NSBezierPath fillRect:rect];

    //Draw our contents
    [super drawRect:rect];
    
    //Draw a faint gray line at the bottom of our view
//    [[NSColor grayColor] set];
//    [NSBezierPath strokeLineFromPoint:NSMakePoint(0,0) toPoint:NSMakePoint(rect.size.width, 0)];
}

- (void)dealloc
{
    [super dealloc];
}

@end
