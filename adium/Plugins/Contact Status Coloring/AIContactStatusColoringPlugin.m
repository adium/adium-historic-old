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

#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AIContactStatusColoringPlugin.h"
#import "AIAdium.h"

@interface AIContactStatusColoringPlugin (PRIVATE)
- (void)applyColorToHandle:(AIContactHandle *)inHandle;
- (void)addToFlashArray:(AIContactHandle *)inHandle;
- (void)removeFromFlashArray:(AIContactHandle *)inHandle;
@end

@implementation AIContactStatusColoringPlugin

- (void)installPlugin
{
    [[owner contactController] registerHandleObserver:self];

    flashingContactArray = [[NSMutableArray alloc] init];
}

- (void)uninstallPlugin
{
    //[[owner contactController] unregisterHandleObserver:self];
}

- (NSArray *)updateHandle:(AIContactHandle *)inHandle keys:(NSArray *)inModifiedKeys
{
    NSArray		*modifiedAttributes = nil;

    if(	inModifiedKeys == nil || 
        [inModifiedKeys containsObject:@"Away"] || 
        [inModifiedKeys containsObject:@"Idle"] || 
        [inModifiedKeys containsObject:@"Warning"] ||
        [inModifiedKeys containsObject:@"Online"] ||
        [inModifiedKeys containsObject:@"UnviewedContent"] ||
        [inModifiedKeys containsObject:@"Signed On"] ||
        [inModifiedKeys containsObject:@"Signed Off"]){

        //Update the handle's text color
        [self applyColorToHandle:inHandle];
        modifiedAttributes = [NSArray arrayWithObject:@"Text Color"];
    }

    //Update our flash array
    if(inModifiedKeys == nil || [inModifiedKeys containsObject:@"UnviewedContent"]){
        int unviewedContent = [[inHandle statusArrayForKey:@"UnviewedContent"] greatestIntegerValue];

        if(unviewedContent && ![flashingContactArray containsObject:inHandle]){ //Start flashing
            [self addToFlashArray:inHandle];
        }else if(!unviewedContent && [flashingContactArray containsObject:inHandle]){ //Stop flashing
            [self removeFromFlashArray:inHandle];
        }
    }

    return(modifiedAttributes);
}

//Applies the correct text color to the passed handle
- (void)applyColorToHandle:(AIContactHandle *)inHandle
{
    AIMutableOwnerArray		*colorArray = [inHandle displayArrayForKey:@"Text Color"];
    int				away, idle, warning, online, unviewedContent, signedOn, signedOff;
    NSColor			*color = nil;

    //Get all the values
    away = [[inHandle statusArrayForKey:@"Away"] greatestIntegerValue];
    idle = [[inHandle statusArrayForKey:@"Idle"] greatestIntegerValue];
    warning = [[inHandle statusArrayForKey:@"Warning"] greatestIntegerValue];
    online = [[inHandle statusArrayForKey:@"Online"] greatestIntegerValue];
    unviewedContent = [[inHandle statusArrayForKey:@"UnviewedContent"] greatestIntegerValue];
    signedOn = [[inHandle statusArrayForKey:@"Signed On"] greatestIntegerValue];
    signedOff = [[inHandle statusArrayForKey:@"Signed Off"] greatestIntegerValue];

    //Remove the existing color
    [colorArray removeObjectsWithOwner:self];

    //Determine the correct color
    if(unviewedContent && ([[owner interfaceController] flashState] % 2)){
        color = [NSColor orangeColor];
    }else if(signedOff){
        color = [NSColor colorWithCalibratedRed:(102.0/255.0) green:(0.0/255.0) blue:(0.0/255.0) alpha:1.0];
    }else if(!online){
        color = [NSColor colorWithCalibratedRed:(68.0/255.0) green:(0.0/255.0) blue:(1.0/255.0) alpha:1.0];
    }else if(signedOn){
        color = [NSColor colorWithCalibratedRed:(0.0/255.0) green:(0.0/255.0) blue:(102.0/255.0) alpha:1.0];
    }else if(idle && away){
        color = [NSColor colorWithCalibratedRed:(89.0/255.0) green:(89.0/255.0) blue:(59.0/255.0) alpha:1.0];
    }else if(idle){
        color = [NSColor colorWithCalibratedRed:(67.0/255.0) green:(67.0/255.0) blue:(67.0/255.0) alpha:1.0];
    }else if(away){
        color = [NSColor colorWithCalibratedRed:(66.0/255.0) green:(66.0/255.0) blue:(0.0/255.0) alpha:1.0];
    }

    //Add the new color
    if(color){
        [colorArray addObject:color withOwner:self];
    }
}

//Flash all handles with unviewed content
- (void)flash:(int)value
{
    NSEnumerator	*enumerator;
    AIContactHandle	*handle;

    enumerator = [flashingContactArray objectEnumerator];
    while((handle = [enumerator nextObject])){
        [self applyColorToHandle:handle];
        
        //Force a redraw
        [[owner notificationCenter] postNotificationName:Contact_AttributesChanged object:handle userInfo:[NSDictionary dictionaryWithObject:[NSArray arrayWithObject:@"Text Color"] forKey:@"Keys"]];
    }
}

//Add a handle to the flash array
- (void)addToFlashArray:(AIContactHandle *)inHandle
{
    //Ensure that we're observing the flashing
    if([flashingContactArray count] == 0){
        [[owner interfaceController] registerFlashObserver:self];
    }

    //Add the contact to our flash array
    [flashingContactArray addObject:inHandle];
    [self flash:[[owner interfaceController] flashState]];
}

//Remove a handle from the flash array
- (void)removeFromFlashArray:(AIContactHandle *)inHandle
{
    //Remove the contact from our flash array
    [flashingContactArray removeObject:inHandle];

    //If we have no more flashing contacts, stop observing the flashes
    if([flashingContactArray count] == 0){
        [[owner interfaceController] unregisterFlashObserver:self];
    }
}

@end
