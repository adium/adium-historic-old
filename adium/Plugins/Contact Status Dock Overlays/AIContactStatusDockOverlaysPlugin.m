//
//  AIContactStatusDockOverlaysPlugin.m
//  Adium
//
//  Created by Adam Iser on Fri Apr 25 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIContactStatusDockOverlaysPlugin.h"
#import "AIAdium.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>

@interface AIContactStatusDockOverlaysPlugin (PRIVATE)
- (void)_setOverlay;
@end

@implementation AIContactStatusDockOverlaysPlugin
- (void)installPlugin
{
    //init
    unviewedContactsArray = [[NSMutableArray alloc] init];
    overlayState = nil;

    //Register as a contact observer (So we can catch the unviewed content status flag)
    [[owner contactController] registerContactObserver:self];
}

- (void)uninstallPlugin
{

}

- (NSArray *)updateContact:(AIListContact *)inContact handle:(AIHandle *)inHandle keys:(NSArray *)inModifiedKeys
{
    if([inModifiedKeys containsObject:@"UnviewedContent"]){
        if([[inContact statusArrayForKey:@"UnviewedContent"] greatestIntegerValue]){
            if(![unviewedContactsArray containsObject:inContact]){
                [unviewedContactsArray addObject:inContact];
                [self _setOverlay]; //Redraw our overlay
            }
            
        }else{
            if([unviewedContactsArray containsObject:inContact]){
                [unviewedContactsArray removeObject:inContact];
                [self _setOverlay]; //Redraw our overlay
            }
        }

    }

    return(nil);
}

#define SMALLESTRADIUS		14
#define RADIUSRANGE		32
#define SMALLESTFONTSIZE	13
#define FONTSIZERANGE		26

//
- (void)_setOverlay
{
    //Remove & release the current overlay state
    if(overlayState){
        [[owner dockController] removeIconState:overlayState];
        [overlayState release]; overlayState = nil;
    }

    //Create & set the new overlay state
    if([unviewedContactsArray count] != 0){
        NSMutableParagraphStyle	*paragraphStyle = [[[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
        NSEnumerator		*enumerator;
        AIListContact		*contact;
        NSImage			*image;
        NSFont			*font;
        float			dockIconScale, iconHeight;
        float			top, bottom;
        
        //Pre-calc some sizes
        dockIconScale = 1.0 - [[owner dockController] dockIconScale];
        iconHeight = (SMALLESTRADIUS + (RADIUSRANGE * dockIconScale));
        top = 128;
        bottom = top - iconHeight;

        //Set up the string details
        font = [NSFont labelFontOfSize:(SMALLESTFONTSIZE + (FONTSIZERANGE * dockIconScale))];
        [paragraphStyle setLineBreakMode:NSLineBreakByClipping];
        [paragraphStyle setAlignment:NSCenterTextAlignment];
        
        //Create our image
        image = [[[NSImage alloc] initWithSize:NSMakeSize(128,128)] autorelease];
    
        //Draw overlays for each contact
        enumerator = [unviewedContactsArray reverseObjectEnumerator];
        while((contact = [enumerator nextObject]) && top >= 0 && bottom < 128){
            float		left, right, arcRadius, stringInset;
            NSAttributedString	*nameString;
            NSBezierPath	*path;

            //Get the contact's display name
            nameString = [[[NSAttributedString alloc] initWithString:[contact displayName] attributes:[NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, paragraphStyle, NSParagraphStyleAttributeName, nil]] autorelease];

            //Create the pill frame
            arcRadius = (iconHeight/4.0);
            stringInset = (iconHeight/6.0);
            left = arcRadius;
            right = 128 - arcRadius;
            
            path = [NSBezierPath bezierPath];
            [path setLineWidth:(arcRadius * 0.13333)];
            //Top
            [path moveToPoint: NSMakePoint(left, top)];
            [path lineToPoint: NSMakePoint(right, top)];
            //Right rounded cap
            [path appendBezierPathWithArcWithCenter:NSMakePoint(right, top - arcRadius) radius:arcRadius startAngle:90 endAngle:0 clockwise:YES];
            [path lineToPoint: NSMakePoint(right + arcRadius, bottom + arcRadius)];
            [path appendBezierPathWithArcWithCenter:NSMakePoint(right, bottom + arcRadius) radius:arcRadius startAngle:0 endAngle:270 clockwise:YES];
            //Bottom
            [path lineToPoint: NSMakePoint(left, bottom)];
            //Left rounded cap
            [path appendBezierPathWithArcWithCenter:NSMakePoint(left, bottom + arcRadius) radius:arcRadius startAngle:270 endAngle:180 clockwise:YES];
            [path lineToPoint: NSMakePoint(left - arcRadius, top - arcRadius)];
            [path appendBezierPathWithArcWithCenter:NSMakePoint(left, top - arcRadius) radius:arcRadius startAngle:180 endAngle:90 clockwise:YES];

            //Display
            [image lockFocus];
            	[[NSColor colorWithCalibratedWhite:1.0 alpha:0.7] set];
            	[path fill];

            	[[NSColor colorWithCalibratedWhite:0.0 alpha:0.6] set];
            	[path stroke];

            	[nameString drawInRect:NSMakeRect(0 + stringInset, bottom, 128 - (stringInset * 2), top - bottom)];
            [image unlockFocus];

            //Move down to the next pill
            top -= (iconHeight + 5.0 * dockIconScale);
            bottom = top - iconHeight;
        }
    
        //Set the state
        overlayState = [[AIIconState alloc] initWithImage:image overlay:YES];
        [[owner dockController] setIconState:overlayState];
    }   
}

@end






