//
//  AIMessageTabViewItem.m
//  Adium
//
//  Created by Adam Iser on Sun Jan 05 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIMessageTabViewItem.h"
#import "AIMessageViewController.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>

@interface AIMessageTabViewItem (PRIVATE)
- (id)initWithIdentifier:(id)identifier messageView:(AIMessageViewController *)inMessageView;
- (void)drawLabel:(BOOL)shouldTruncateLabel inRect:(NSRect)labelRect;
- (NSSize)sizeOfLabel:(BOOL)computeMin;
- (NSAttributedString *)attributedLabelString;
@end

@implementation AIMessageTabViewItem
//
+ (AIMessageTabViewItem *)messageTabViewItemWithIdentifier:(id)identifier messageView:(AIMessageViewController *)inMessageView
{
    return([[[self alloc] initWithIdentifier:identifier messageView:inMessageView] autorelease]);
}

//init
- (id)initWithIdentifier:(id)identifier messageView:(AIMessageViewController *)inMessageView
{
    [super initWithIdentifier:identifier];

    messageView = [inMessageView retain];
    
    //Set our contents
    [self setView:[messageView view]];
    
    return(self);
}

//Make this container active
- (void)makeActive:(id)sender
{
    NSTabView	*tabView = [self tabView];
    NSWindow	*window	= [tabView window];
    
    if([tabView selectedTabViewItem] != self){
        [tabView selectTabViewItem:self]; //Select our tab
    }

    if(![window isKeyWindow]){
        [window makeKeyAndOrderFront:nil]; //Bring our window to the front        
    }
}

- (void)setAccountSelectionMenuVisible:(BOOL)visible
{
    [messageView setAccountSelectionMenuVisible:YES];
}

//Close this container
- (void)close:(id)sender
{
    [[self tabView] removeTabViewItem:self];
}

//Drawing
- (void)drawLabel:(BOOL)shouldTruncateLabel inRect:(NSRect)labelRect
{    
    [[self attributedLabelString] drawInRect:labelRect];
}

- (NSSize)sizeOfLabel:(BOOL)computeMin
{
    return([[self attributedLabelString] size]);
}

//
- (NSString *)labelString
{
    return([[messageView handle] displayName]);
}

//
- (NSAttributedString *)attributedLabelString
{
    AIContactHandle	*handle = [messageView handle];
    NSFont		*font = [NSFont systemFontOfSize:11];
    NSAttributedString	*displayName;
    NSColor		*textColor;

    
    //Color
    textColor = [[handle displayArrayForKey:@"Text Color"] averageColor];
    if(!textColor){
        textColor = [NSColor blackColor];
    }

    //Name
    displayName = [[NSAttributedString alloc] initWithString:[handle displayName] attributes:[NSDictionary dictionaryWithObjectsAndKeys:textColor,NSForegroundColorAttributeName,font,NSFontAttributeName,nil]];

    return([displayName autorelease]);
}

@end
