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

- (NSArray *)updateContact:(AIListContact *)inContact keys:(NSArray *)inModifiedKeys
{
    if([inModifiedKeys containsObject:@"UnviewedContent"] || [inModifiedKeys containsObject:@"Signed On"] || [inModifiedKeys containsObject:@"Signed Off"]){
        if([[inContact statusArrayForKey:@"UnviewedContent"] greatestIntegerValue] || [[inContact statusArrayForKey:@"Signed On"] greatestIntegerValue] || [[inContact statusArrayForKey:@"Signed Off"] greatestIntegerValue]){
            if(![unviewedContactsArray containsObject:inContact]){
                [unviewedContactsArray addObject:inContact];
//                [self _setOverlay]; //Redraw our overlay
            }
            
        }else{
            if([unviewedContactsArray containsObject:inContact]){
                [unviewedContactsArray removeObject:inContact];
//                [self _setOverlay]; //Redraw our overlay
            }
        }

        [self _setOverlay]; //Redraw our overlay
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
        float			dockIconScale;//, iconHeight;
        int			iconHeight;
        float			top, bottom;
        
        //Pre-calc some sizes
        dockIconScale = 1.0 - [[owner dockController] dockIconScale];
        iconHeight = (SMALLESTRADIUS + (RADIUSRANGE * dockIconScale));
        top = 126;
        bottom = top - iconHeight;

        //Set up the string details
        //font = [NSFont labelFontOfSize:(SMALLESTFONTSIZE + (FONTSIZERANGE * dockIconScale))];
        font = [NSFont fontWithName:@"Lucida Grande" size:(SMALLESTFONTSIZE + (FONTSIZERANGE * dockIconScale))];
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
            NSColor		*backColor, *textColor, *borderColor;

            //Create the pill frame
            arcRadius = (iconHeight/2.0); //4
            stringInset = (iconHeight/4.0); //6
            left = 1 + arcRadius;
            right = 127 - arcRadius;
            
            path = [NSBezierPath bezierPath];
            [path setLineWidth:((iconHeight/2.0) * 0.13333)/*(arcRadius * 0.13333)*/];
            //Top
            [path moveToPoint: NSMakePoint(left, top)];
            [path lineToPoint: NSMakePoint(right, top)];
            //Right rounded cap
            [path appendBezierPathWithArcWithCenter:NSMakePoint(right, top - arcRadius) radius:arcRadius startAngle:90 endAngle:0 clockwise:YES];
            [path lineToPoint: NSMakePoint(right + arcRadius, bottom + arcRadius)];
            [path appendBezierPathWithArcWithCenter:NSMakePoint(right, bottom + arcRadius) radius:arcRadius startAngle:0 endAngle:270 clockwise:YES];
            //Bottom
            [path moveToPoint: NSMakePoint(right, bottom)];
            [path lineToPoint: NSMakePoint(left, bottom)];
            //Left rounded cap
            [path appendBezierPathWithArcWithCenter:NSMakePoint(left, bottom + arcRadius) radius:arcRadius startAngle:270 endAngle:180 clockwise:YES];
            [path lineToPoint: NSMakePoint(left - arcRadius, top - arcRadius)];
            [path appendBezierPathWithArcWithCenter:NSMakePoint(left, top - arcRadius) radius:arcRadius startAngle:180 endAngle:90 clockwise:YES];

            //Display
            [image lockFocus];

            if([[contact statusArrayForKey:@"Signed On"] greatestIntegerValue]){ //Signed on
                backColor = [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:0.75];
                textColor = [NSColor colorWithCalibratedRed:0.0 green:0.2 blue:0.0 alpha:1.0];
                borderColor = [NSColor colorWithCalibratedRed:0.0 green:0.3 blue:0.0 alpha:1.0];
                
            }else if([[contact statusArrayForKey:@"Signed Off"] greatestIntegerValue]){ //Signed off
                backColor = [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:0.75];
                textColor = [NSColor colorWithCalibratedRed:0.3 green:0.0 blue:0.0 alpha:1.0];
                borderColor = [NSColor colorWithCalibratedRed:0.3 green:0.0 blue:0.0 alpha:1.0];

            }else{ //Unviewed
                backColor = [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:0.75];
                textColor = [NSColor colorWithCalibratedWhite:0.0 alpha:1.0];
                borderColor = [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:1.0];
                
            }

            [backColor set];
            [path fill];
            [borderColor set];
            [path stroke];

            //Get the contact's display name
            nameString = [[[NSAttributedString alloc] initWithString:[contact displayName] attributes:[NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, paragraphStyle, NSParagraphStyleAttributeName, textColor, NSForegroundColorAttributeName, nil]] autorelease];

            
            [nameString drawInRect:NSMakeRect(0 + stringInset, bottom, 128 - (stringInset * 2), top - bottom)];
            [image unlockFocus];

            //Move down to the next pill
            top -= (iconHeight + 7.0 * dockIconScale);
            bottom = top - iconHeight;
        }
    
        //Set the state
        overlayState = [[AIIconState alloc] initWithImage:image overlay:YES];
        [[owner dockController] setIconState:overlayState];
    }   
}

@end






