//
//  AIColorSelectionPopUpButton.m
//  Adium
//
//  Created by Adam Iser on Sun Oct 05 2003.
//

#import "AIColorSelectionPopUpButton.h"

#define COLOR_SAMPLE_WIDTH		24
#define COLOR_SAMPLE_HEIGHT		12
#define SAMPLE_FRAME_DARKEN		0.3
#define COLOR_CUSTOM_TITLE		@"Custom…"

@interface AIColorSelectionPopUpButton (PRIVATE)
- (void)_init;
- (void)_buildColorMenu;
- (NSImage *)_sampleImageForColor:(NSColor *)inColor;
- (void)_setCustomColor:(NSColor *)inColor;
@end

@implementation AIColorSelectionPopUpButton

- (id)initWithCoder:(NSCoder *)aDecoder
{
    [super initWithCoder:aDecoder];
    [self _init];
    return(self);
}

- (id)initWithFrame:(NSRect)buttonFrame pullsDown:(BOOL)flag
{
    [super initWithFrame:buttonFrame pullsDown:flag];
    [self _init];
    return(self);
}

- (void)_init
{
    //
    availableColors = nil;
    customColor = nil;
    
    //Create the custom menu item
    customMenuItem = [[NSMenuItem alloc] initWithTitle:COLOR_CUSTOM_TITLE target:self action:@selector(openColorPanel:) keyEquivalent:@""];

    //Setup our default colors
    customColor = [[NSColor blackColor] retain];
    [self setAvailableColors:[NSArray arrayWithObjects:@"Black",[NSColor blackColor],@"White",[NSColor whiteColor],@"Red", [NSColor redColor], @"Blue", [NSColor blueColor], @"Green", [NSColor greenColor], @"Yellow", [NSColor yellowColor], nil]];
}

- (void)dealloc
{
    [availableColors release];
    [customColor release];
    [customMenuItem release];
    
    [super dealloc];
}

//The currently selected color
- (void)setColor:(NSColor *)inColor
{
    NSEnumerator	*enumerator;
    NSString		*label;

    //search for a preset
    enumerator = [availableColors objectEnumerator];
    while((label = [enumerator nextObject])){
        if([[enumerator nextObject] equalToRGBColor:inColor]) break;
    }

    //Select
    if(label){
        [self selectItemWithTitle:label];
    }else{
        [self _setCustomColor:inColor];
        [self selectItem:customMenuItem];
    }
}
- (NSColor *)color
{
    return([[self selectedItem] representedObject]);
}

//Set the available pre-set color choices.  Array should be alternating labels and colors (NSString, NSColor, NSString, NSColor, NSString, ...)
- (void)setAvailableColors:(NSArray *)inColors
{
    if(inColors != availableColors){
        [availableColors release];
        availableColors = [inColors retain];

        [self _buildColorMenu];
    }
}

//Opens the color panel
- (void)openColorPanel:(id)sender
{
    [[NSColorPanel sharedColorPanel] setTarget:self];
    [[NSColorPanel sharedColorPanel] setAction:@selector(customColorChanged:)];
    [[NSColorPanel sharedColorPanel] setColor:customColor];
    [[NSColorPanel sharedColorPanel] makeKeyAndOrderFront:nil];
}

//Color panel color was changed
- (void)customColorChanged:(id)sender
{
    if([self selectedItem] == customMenuItem){
        [self _setCustomColor:[[[[NSColorPanel sharedColorPanel] color] copy] autorelease]];
        [[self target] performSelector:[self action] withObject:self];
    }
}

//Set the current custom color
- (void)_setCustomColor:(NSColor *)inColor
{
    if(customColor != inColor){
        [customColor release]; customColor = [inColor retain];
        [customMenuItem setRepresentedObject:customColor];
        [customMenuItem setImage:[self _sampleImageForColor:customColor]];
    }
}

//Build a menu of colors
- (void)_buildColorMenu
{
    NSMenuItem		*menuItem;
    NSEnumerator	*enumerator;
    NSColor		*color;
    NSString		*label;

    //Empty our menu
    if(![self menu]){
        [self setMenu:[[[NSMenu alloc] init] autorelease]]; //Make sure we have a menu
    }
    [self removeAllItems];
    
    //Colors
    enumerator = [availableColors objectEnumerator];
    while((label = [enumerator nextObject])){
        color = [enumerator nextObject];

        //Create the menu item
        menuItem = [[[NSMenuItem alloc] initWithTitle:label target:nil action:nil keyEquivalent:@""] autorelease];
        [menuItem setRepresentedObject:color];
        [menuItem setImage:[self _sampleImageForColor:color]];
        [[self menu] addItem:menuItem];
    }

    //Custom
    [[self menu] addItem:[NSMenuItem separatorItem]];
    [[self menu] addItem:customMenuItem];
    [customMenuItem setImage:[self _sampleImageForColor:customColor]];
}

//Returns a sample square image for the color
- (NSImage *)_sampleImageForColor:(NSColor *)inColor
{
    NSImage	*image;
    NSRect	imageRect;
    
    //Create the sample image
    imageRect = NSMakeRect(0, 0, COLOR_SAMPLE_WIDTH, COLOR_SAMPLE_HEIGHT);
    image = [[[NSImage alloc] initWithSize:imageRect.size] autorelease];

    [image lockFocus];
    [inColor set];
    [NSBezierPath fillRect:imageRect];
    [[inColor darkenBy:SAMPLE_FRAME_DARKEN] set];
    [NSBezierPath strokeRect:imageRect];
    [image unlockFocus];

    return(image);
}

@end




