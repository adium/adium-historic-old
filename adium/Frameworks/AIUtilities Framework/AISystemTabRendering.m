//
//  AISystemTabRendering.m
//  Adium
//
//  Created by Adam Iser on Mon Jan 06 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AISystemTabRendering.h"

static NSImage		*tabFrontLeft;
static NSImage		*tabFrontMiddle;
static NSImage		*tabFrontRight;
static NSImage		*tabBackLeft;
static NSImage		*tabBackMiddle;
static NSImage		*tabBackRight;
static NSImage		*tabPushLeft;
static NSImage		*tabPushMiddle;
static NSImage		*tabPushRight;
static NSImage		*tabBackground;
static int		labelSize;


@interface AISystemTabRendering (PRIVATE)
+ (NSImage *)leftCapFromScratchImage:(NSImage *)inScratchImage;
+ (NSImage *)middleFromScratchImage:(NSImage *)inScratchImage;
+ (NSImage *)rightCapFromScratchImage:(NSImage *)inScratchImage;
+ (NSImage *)backgroundFromScratchImage:(NSImage *)inScratchImage;
@end


@implementation AISystemTabRendering

#define TAB_CAP_WIDTH		14		//Width of a tab cap
#define TAB_HEIGHT		25		//Height of the tab
#define TAB_TOTAL_HEIGHT	27	//Total height of the tabs (including all padded space)

#define TAB_LEFT_JUNK		20		//Junk area consists of the tabView frame and any extra spacing
#define TAB_RIGHT_JUNK		20		//
#define TAB_BOTTOM_JUNK		20		//

#define TAB_LEFT_OFFSET		2		//Additional offset to the individual tab cap
#define TAB_RIGHT_OFFSET	-5		//Additional offset to the individual tab cap

#define TAB_BACK_BOTTOM_OFFSET	2		//Additional offset to the tab background and divider
#define TAB_BACKGROUND_WIDTH	256		//Render size of the tab backgound

+ (void)initialize
{
    AIFakeWindow	*window;
    AIFakeTabView	*tabView;
    AIFakeTabViewItem	*tabItem;
    NSRect		tabViewRect = NSMakeRect(0,0,0,0);
    NSImage		*tabScratchImage;

    //Create a system tabView and tabViewItem (with a long, empty label)
    tabView = [[[AIFakeTabView alloc] initWithFrame:NSMakeRect(0,0,100,1000)] autorelease]; //Arbitrarily large rect
    [tabView setTabViewType:NSTopTabsBezelBorder];
    [tabView setControlSize:NSSmallControlSize];

    tabItem = [[[AIFakeTabViewItem alloc] initWithIdentifier:@"Temp"] autorelease];
    [tabItem setLabel:@"                                   "];
    [tabView addTabViewItem:tabItem];

    //Get the size of our label, and calculate the required tab view size
    labelSize = [tabItem sizeOfLabel:NO].width;
    tabViewRect.size.width = TAB_LEFT_JUNK + TAB_CAP_WIDTH + labelSize + TAB_CAP_WIDTH + TAB_RIGHT_JUNK;
    tabViewRect.size.height = TAB_BOTTOM_JUNK + TAB_HEIGHT;

    //Create a window, tabView, and scratch image (of the calculated size) to hold this tabView item
    window = [[[AIFakeWindow alloc] initWithContentRect:tabViewRect styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO] autorelease];
    [[window contentView] addSubview:tabView];
    [tabView setFrame:tabViewRect];

    //Pre-render the front tab images --------------------------------------------------
    tabScratchImage = [[[NSImage alloc] initWithSize:tabViewRect.size] autorelease];
    [tabScratchImage setFlipped:YES];
    [tabScratchImage lockFocus];
    [window setIsKey:YES];
    [tabItem setState:NSSelectedTab];
    [tabView drawRect:tabViewRect];
    [tabScratchImage unlockFocus];

    tabFrontLeft = [[self leftCapFromScratchImage:tabScratchImage] retain];
    tabFrontMiddle = [[self middleFromScratchImage:tabScratchImage] retain];
    tabFrontRight = [[self rightCapFromScratchImage:tabScratchImage] retain];

    //Pre-render the back tab images --------------------------------------------------
    tabScratchImage = [[[NSImage alloc] initWithSize:tabViewRect.size] autorelease];
    [tabScratchImage setFlipped:YES];
    [tabScratchImage lockFocus];
    [window setIsKey:YES];
    [tabItem setState:NSBackgroundTab];
    [tabView drawRect:tabViewRect];
    [tabScratchImage unlockFocus];

    tabBackLeft = [[self leftCapFromScratchImage:tabScratchImage] retain];
    tabBackMiddle = [[self middleFromScratchImage:tabScratchImage] retain];
    tabBackRight = [[self rightCapFromScratchImage:tabScratchImage] retain];

    //Pre-render the pushed tab images --------------------------------------------------
    tabScratchImage = [[[NSImage alloc] initWithSize:tabViewRect.size] autorelease];
    [tabScratchImage setFlipped:YES];
    [tabScratchImage lockFocus];
    [window setIsKey:YES];
    [tabItem setState:NSPressedTab];
    [tabView drawRect:tabViewRect];
    [tabScratchImage unlockFocus];

    tabPushLeft = [[self leftCapFromScratchImage:tabScratchImage] retain];
    tabPushMiddle = [[self middleFromScratchImage:tabScratchImage] retain];
    tabPushRight = [[self rightCapFromScratchImage:tabScratchImage] retain];

    //Pre-render the tab background -----------------------------------------------------
    [tabView removeTabViewItem:tabItem];
    
    [window makeKeyAndOrderFront:nil]; [window retain];

    tabViewRect = NSMakeRect(0, 0, TAB_LEFT_JUNK + TAB_BACKGROUND_WIDTH + TAB_RIGHT_JUNK, TAB_BOTTOM_JUNK + TAB_TOTAL_HEIGHT);
    tabScratchImage = [[[NSImage alloc] initWithSize:tabViewRect.size] autorelease];
    [tabScratchImage setFlipped:YES];
    [tabScratchImage lockFocus];
    [window setIsKey:YES];
    [tabItem setState:NSPressedTab];
    [tabView drawRect:tabViewRect];
    [tabScratchImage unlockFocus];

    tabBackground = [[self backgroundFromScratchImage:tabScratchImage] retain];
}


+ (NSImage *)tabFrontLeft{
    return(tabFrontLeft);
}
+ (NSImage *)tabFrontMiddle{
    return(tabFrontMiddle);
}
+ (NSImage *)tabFrontRight{
    return(tabFrontRight);
}

+ (NSImage *)tabBackLeft{
    return(tabBackLeft);
}
+ (NSImage *)tabBackMiddle{
    return(tabBackMiddle);
}
+ (NSImage *)tabBackRight{
    return(tabBackRight);
}

+ (NSImage *)tabPushLeft{
    return(tabPushLeft);
}
+ (NSImage *)tabPushMiddle{
    return(tabPushMiddle);
}
+ (NSImage *)tabPushRight{
    return(tabPushRight);
}

+ (NSImage *)tabBackground{
    return(tabBackground);
}


// Private --------------------------------------------------------------------------------
//Returns the left tab cap from a scratch image
+ (NSImage *)leftCapFromScratchImage:(NSImage *)inScratchImage
{
    NSImage	*newImage;

    newImage = [[NSImage alloc] initWithSize:NSMakeSize(TAB_CAP_WIDTH, TAB_HEIGHT)];
    [newImage lockFocus];
    [inScratchImage compositeToPoint:NSMakePoint(0,0)
                            fromRect:NSMakeRect(TAB_LEFT_JUNK + TAB_LEFT_OFFSET, TAB_BOTTOM_JUNK, TAB_CAP_WIDTH, TAB_HEIGHT)
                           operation:NSCompositeSourceOver];
    [newImage unlockFocus];

    return([newImage autorelease]);
}

//Returns the middle tab section from a scratch image
+ (NSImage *)middleFromScratchImage:(NSImage *)inScratchImage
{
    NSImage	*newImage;

    newImage = [[NSImage alloc] initWithSize:NSMakeSize(labelSize, TAB_HEIGHT)];
    [newImage lockFocus];
    [inScratchImage compositeToPoint:NSMakePoint(0,0)
                            fromRect:NSMakeRect(TAB_LEFT_JUNK + TAB_LEFT_OFFSET + TAB_CAP_WIDTH, TAB_BOTTOM_JUNK, labelSize, TAB_HEIGHT)
                           operation:NSCompositeSourceOver];
    [newImage unlockFocus];

    return([newImage autorelease]);
}

//Returns the tight tab cap from a scratch image
+ (NSImage *)rightCapFromScratchImage:(NSImage *)inScratchImage
{
    NSImage	*newImage;

    newImage = [[NSImage alloc] initWithSize:NSMakeSize(TAB_CAP_WIDTH, TAB_HEIGHT)];
    [newImage lockFocus];
    [inScratchImage compositeToPoint:NSMakePoint(0,0)
                            fromRect:NSMakeRect(TAB_LEFT_JUNK + TAB_LEFT_OFFSET + TAB_CAP_WIDTH + labelSize + TAB_RIGHT_OFFSET, TAB_BOTTOM_JUNK, TAB_CAP_WIDTH, TAB_HEIGHT)
                           operation:NSCompositeSourceOver];
    [newImage unlockFocus];

    return([newImage autorelease]);
}

//Returns the tight tab cap from a scratch image
+ (NSImage *)backgroundFromScratchImage:(NSImage *)inScratchImage
{
    NSImage	*newImage;

    newImage = [[NSImage alloc] initWithSize:NSMakeSize(TAB_CAP_WIDTH, TAB_HEIGHT)];
    [newImage lockFocus];
    [inScratchImage compositeToPoint:NSMakePoint(0,0)
                            fromRect:NSMakeRect(TAB_LEFT_JUNK, TAB_BOTTOM_JUNK + TAB_BACK_BOTTOM_OFFSET, TAB_BACKGROUND_WIDTH, TAB_TOTAL_HEIGHT)
                           operation:NSCompositeSourceOver];
    [newImage unlockFocus];

    return([newImage autorelease]);
}


@end

//These classes allow us to trick the tab view into rendering different types of tabs :)
@implementation AIFakeTabView

@end

@implementation AIFakeTabViewItem

- (void)setState:(NSTabState)inTabState
{
    tabState = inTabState;
}

- (NSTabState)tabState
{
    return(tabState);
}

@end

@implementation AIFakeWindow

- (void)setIsKey:(BOOL)inIsKey
{
    isKey = inIsKey;
}

- (BOOL)isKeyWindow
{
    return(isKey);
}

@end
