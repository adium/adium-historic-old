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
#import "AIStatusOverlayPreferences.h"
#import "AIAdium.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>

#define DOCK_OVERLAY_DEFAULT_PREFS	@"DockOverlayDefaults"
#define SMALLESTRADIUS			15
#define RADIUSRANGE			36
#define SMALLESTFONTSIZE		14
#define FONTSIZERANGE			30

@interface AIContactStatusDockOverlaysPlugin (PRIVATE)
- (void)_setOverlay;
- (NSImage *)overlayImageFlash:(BOOL)flash;
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation AIContactStatusDockOverlaysPlugin
- (void)installPlugin
{
    //init
    unviewedObjectsArray = [[NSMutableArray alloc] init];
    overlayState = nil;

    //Install our preference view and register our default prefs
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:DOCK_OVERLAY_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_DOCK_OVERLAYS];
    preferences = [[AIStatusOverlayPreferences statusOverlayPreferencesWithOwner:owner] retain];

    //Register as a contact observer (So we can catch the unviewed content status flag)
    [[owner contactController] registerListObjectObserver:self];

    //Prefs
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];
        
    //Observe
}

- (void)preferencesChanged:(NSNotification *)notification
{
///*
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:@"Contact Status Coloring"] == 0){
        NSDictionary	*prefDict = [[owner preferenceController] preferencesForGroup:@"Contact Status Coloring"];
	
        //Snatch colors from status coloring plugin's prefs    
        signedOffColor = [[[prefDict objectForKey:@"Signed Off Color"] representedColor] retain];
        signedOnColor = [[[prefDict objectForKey:@"Signed On Color"] representedColor] retain];
        unviewedContentColor = [[[prefDict objectForKey:@"Unviewed Content Color"] representedColor] retain];

        backSignedOffColor = [[[prefDict objectForKey:@"Signed Off Label Color"] representedColor] retain];
        backSignedOnColor = [[[prefDict objectForKey:@"Signed On Label Color"] representedColor] retain];
        backUnviewedContentColor = [[[prefDict objectForKey:@"Unviewed Content Label Color"] representedColor] retain];
    }
 //*/
    
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_DOCK_OVERLAYS] == 0){
        NSDictionary	*prefDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_DOCK_OVERLAYS];

        //
        showStatus = [[prefDict objectForKey:KEY_DOCK_SHOW_STATUS] boolValue];
        showContent = [[prefDict objectForKey:KEY_DOCK_SHOW_CONTENT] boolValue];
        overlayPosition = [[prefDict objectForKey:KEY_DOCK_OVERLAY_POSITION] boolValue];        

        //Reset our overlay
        [unviewedObjectsArray removeAllObjects];
        [self _setOverlay];
    }
    
}

- (void)uninstallPlugin
{

}

- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys delayed:(BOOL)delayed silent:(BOOL)silent
{
    if(showStatus || showContent){ //Skip this entirely if overlays are off

        if([inModifiedKeys containsObject:@"UnviewedContent"] || [inModifiedKeys containsObject:@"Signed On"] || [inModifiedKeys containsObject:@"Signed Off"]){

            if((showContent && [[inObject statusArrayForKey:@"UnviewedContent"] greatestIntegerValue]) ||
               (showStatus && [[inObject statusArrayForKey:@"Signed On"] greatestIntegerValue]) ||
               (showStatus && [[inObject statusArrayForKey:@"Signed Off"] greatestIntegerValue])){

                if(![unviewedObjectsArray containsObject:inObject]){
                    [unviewedObjectsArray addObject:inObject];
                }

            }else{
                if([unviewedObjectsArray containsObject:inObject]){
                    [unviewedObjectsArray removeObject:inObject];
                }
            }

            [self _setOverlay]; //Redraw our overlay
        }
        
    }

    return(nil);
}

//
- (void)_setOverlay
{
    //Remove & release the current overlay state
    if(overlayState){
        [[owner dockController] removeIconState:overlayState];
        [overlayState release]; overlayState = nil;
    }

    //Create & set the new overlay state
    if([unviewedObjectsArray count] != 0){
        NSImage	*image1 = [self overlayImageFlash:NO];
        NSImage	*image2 = [self overlayImageFlash:YES];

        //Set the state
        overlayState = [[AIIconState alloc] initWithImages:[NSArray arrayWithObjects:image1,image2,nil] delay:0.5 looping:YES overlay:YES];
        [[owner dockController] setIconState:overlayState];
    }   
}

//
- (NSImage *)overlayImageFlash:(BOOL)flash
{
    NSMutableParagraphStyle	*paragraphStyle = [[[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
    NSEnumerator		*enumerator;
    AIListContact		*contact;
    NSImage			*image;
    NSFont			*font;
    float			dockIconScale;
    int				iconHeight;
    float			top, bottom;

    //Pre-calc some sizes
    dockIconScale = 1.0 - [[owner dockController] dockIconScale];
    iconHeight = (SMALLESTRADIUS + (RADIUSRANGE * dockIconScale));
    if(overlayPosition){
        top = 126;
        bottom = top - iconHeight;
    }else{
        bottom = 0;
        top = bottom + iconHeight;
    }

    //Set up the string details
    font = [NSFont boldSystemFontOfSize:(SMALLESTFONTSIZE + (FONTSIZERANGE * dockIconScale))];
    [paragraphStyle setLineBreakMode:NSLineBreakByClipping];
    [paragraphStyle setAlignment:NSCenterTextAlignment];

    //Create our image
    image = [[[NSImage alloc] initWithSize:NSMakeSize(128,128)] autorelease];

    //Draw overlays for each contact
    enumerator = [unviewedObjectsArray reverseObjectEnumerator];
    while((contact = [enumerator nextObject]) && top >= 0 && bottom < 128){
        float			left, right, arcRadius, stringInset;
        NSAttributedString	*nameString;
        NSBezierPath		*path;
        NSColor			*backColor = nil, *textColor = nil, *borderColor = nil;

        //Create the pill frame
        arcRadius = (iconHeight/2.0);
        stringInset = (iconHeight/4.0);
        left = 1 + arcRadius;
        right = 127 - arcRadius;

        path = [NSBezierPath bezierPath];
        [path setLineWidth:((iconHeight/2.0) * 0.13333)];
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

/*
        //Get our colors
        if(!([[contact statusArrayForKey:@"UnviewedContent"] greatestIntegerValue] && flash)){
            backColor = [[contact displayArrayForKey:@"Label Color"] averageColor];
            textColor = [[contact displayArrayForKey:@"Text Color"] averageColor];
        }
 */
	
        if([[contact statusArrayForKey:@"UnviewedContent"] greatestIntegerValue]){ //Unviewed
	    if(flash){
                backColor = [NSColor whiteColor];
                textColor = [NSColor blackColor];
            }else{
                backColor = backUnviewedContentColor;
                textColor = unviewedContentColor;
            }
        }else if([[contact statusArrayForKey:@"Signed On"] greatestIntegerValue]){ //Signed on
            backColor = backSignedOnColor;
            textColor = signedOnColor;

        }else if([[contact statusArrayForKey:@"Signed Off"] greatestIntegerValue]){ //Signed off
            backColor = backSignedOffColor;
            textColor = signedOffColor;
	    
        }

	if(!backColor){
	    backColor = [NSColor whiteColor];
	}
	if(!textColor){
	    textColor = [NSColor blackColor];
	}

        //Lighten/Darken the back color slightly
        if([backColor colorIsDark]){
            backColor = [backColor darkenBy:-0.15];
            borderColor = [backColor darkenBy:-0.3];
        }else{
            backColor = [backColor darkenBy:0.15];
            borderColor = [backColor darkenBy:0.3];
        }

        //Draw
        [backColor set];
        [path fill];
        [borderColor set];
        [path stroke];

        //Get the contact's display name
        nameString = [[[NSAttributedString alloc] initWithString:[contact displayName] attributes:[NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, paragraphStyle, NSParagraphStyleAttributeName, textColor, NSForegroundColorAttributeName, nil]] autorelease];
        [nameString drawInRect:NSMakeRect(0 + stringInset, bottom + 1, 128 - (stringInset * 2), top - bottom)];

        [image unlockFocus];

        //Move up or down to the next pill
        if(overlayPosition){
            top -= (iconHeight + 7.0 * dockIconScale);
            bottom = top - iconHeight;
        }else{
            bottom += (iconHeight + 7.0 * dockIconScale);
            top = bottom + iconHeight;
        }
    }
    
    return(image);
}

@end




