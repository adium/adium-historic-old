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
- (id)initWithIdentifier:(id)identifier messageView:(AIMessageViewController *)inMessageView owner:(id)inOwner;
- (void)drawLabel:(BOOL)shouldTruncateLabel inRect:(NSRect)labelRect;
- (NSSize)sizeOfLabel:(BOOL)computeMin;
- (NSAttributedString *)attributedLabelString;
@end

@implementation AIMessageTabViewItem
//
+ (AIMessageTabViewItem *)messageTabViewItemWithIdentifier:(id)identifier messageView:(AIMessageViewController *)inMessageView owner:(id)inOwner
{
    return([[[self alloc] initWithIdentifier:identifier messageView:inMessageView owner:inOwner] autorelease]);
}

//init
- (id)initWithIdentifier:(id)identifier messageView:(AIMessageViewController *)inMessageView owner:(id)inOwner
{
    [super initWithIdentifier:identifier];

    messageView = [inMessageView retain];
    owner = [inOwner retain];

    //Observer
    [[owner notificationCenter] addObserver:self selector:@selector(contactAttributesChanged:) name:Contact_AttributesChanged object:nil];
    
    //Set our contents
    [self setView:[messageView view]];
    
    return(self);
}

//
- (void)dealloc
{
    [[owner notificationCenter] removeObserver:self name:Contact_AttributesChanged object:nil];
    [owner release];
    
    [super dealloc];
}

//Redisplay the modified object
- (void)contactAttributesChanged:(NSNotification *)notification
{
    //We only need to redraw if the text color has changed
    if([[[notification userInfo] objectForKey:@"Keys"] containsObject:@"Text Color"]){
        //This should really be optimized and cleaned up.  Right now we're assuming the tab view's delegate is our custom tabs, and telling them to display - obviously not the best solution, but good enough for now.
        [[[self tabView] delegate] setNeedsDisplay:YES];
    }
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

//Called when our tab is selected
- (void)tabViewItemWasSelected
{
    //Ensure our entry view is first responder
    [messageView makeTextEntryViewFirstResponder];
}

//
- (AIMessageViewController *)messageViewController
{
    return(messageView);
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
    return([[messageView contact] displayName]);
}

//
- (NSAttributedString *)attributedLabelString
{
    AIListContact	*contact = [messageView contact];
    NSFont		*font = [NSFont systemFontOfSize:11];
    NSAttributedString	*displayName;
    NSColor		*textColor;

    
    //Color
    textColor = [[contact displayArrayForKey:@"Text Color"] averageColor];
    if(!textColor){
        textColor = [NSColor blackColor];
    }

    //Name
    displayName = [[NSAttributedString alloc] initWithString:[contact displayName] attributes:[NSDictionary dictionaryWithObjectsAndKeys:textColor,NSForegroundColorAttributeName,font,NSFontAttributeName,nil]];

    return([displayName autorelease]);
}

@end
