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
- (void)applyColorToContact:(AIListContact *)inContact;
- (void)addToFlashArray:(AIListContact *)inContact;
- (void)removeFromFlashArray:(AIListContact *)inContact;
@end

@implementation AIContactStatusColoringPlugin

- (void)installPlugin
{
    [[owner contactController] registerContactObserver:self];

    flashingContactArray = [[NSMutableArray alloc] init];
}

- (void)uninstallPlugin
{
    //[[owner contactController] unregisterHandleObserver:self];
}

- (NSArray *)updateContact:(AIListContact *)inContact handle:(AIHandle *)inHandle keys:(NSArray *)inModifiedKeys
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
        [self applyColorToContact:inContact];
        modifiedAttributes = [NSArray arrayWithObject:@"Text Color"];
    }

    //Update our flash array
    if(inModifiedKeys == nil || [inModifiedKeys containsObject:@"UnviewedContent"]){
        int unviewedContent = [[inContact statusArrayForKey:@"UnviewedContent"] greatestIntegerValue];

        if(unviewedContent && ![flashingContactArray containsObject:inContact]){ //Start flashing
            [self addToFlashArray:inContact];
        }else if(!unviewedContent && [flashingContactArray containsObject:inContact]){ //Stop flashing
            [self removeFromFlashArray:inContact];
        }
    }

    return(modifiedAttributes);
}

//Applies the correct text color to the passed contact
- (void)applyColorToContact:(AIListContact *)inContact
{
    AIMutableOwnerArray		*colorArray = [inContact displayArrayForKey:@"Text Color"];
    AIMutableOwnerArray		*invertedColorArray = [inContact displayArrayForKey:@"Inverted Text Color"];
    int				away, idle, warning, online, unviewedContent, signedOn, signedOff;
    NSColor			*color = nil, *invertedColor = nil;

    //Get all the values
    away = [[inContact statusArrayForKey:@"Away"] greatestIntegerValue];
    idle = [[inContact statusArrayForKey:@"Idle"] greatestIntegerValue];
    warning = [[inContact statusArrayForKey:@"Warning"] greatestIntegerValue];
    online = [[inContact statusArrayForKey:@"Online"] greatestIntegerValue];
    unviewedContent = [[inContact statusArrayForKey:@"UnviewedContent"] greatestIntegerValue];
    signedOn = [[inContact statusArrayForKey:@"Signed On"] greatestIntegerValue];
    signedOff = [[inContact statusArrayForKey:@"Signed Off"] greatestIntegerValue];

    //Determine the correct color
    if(unviewedContent && ([[owner interfaceController] flashState] % 2)){
        color = [NSColor colorWithCalibratedRed:(255.0/255.0) green:(127.0/255.0) blue:(0.0/255.0) alpha:1.0];
        invertedColor = [NSColor colorWithCalibratedRed:(255.0/255.0) green:(223.0/255.0) blue:(191.0/255.0) alpha:1.0];
    }else if(signedOff){
        color = [NSColor colorWithCalibratedRed:(102.0/255.0) green:(0.0/255.0) blue:(0.0/255.0) alpha:1.0];
        invertedColor = [NSColor colorWithCalibratedRed:(255.0/255.0) green:(216.0/255.0) blue:(216.0/255.0) alpha:1.0];
    }else if(!online){
        color = [NSColor colorWithCalibratedRed:(68.0/255.0) green:(0.0/255.0) blue:(0.0/255.0) alpha:1.0];
        invertedColor = [NSColor colorWithCalibratedRed:(255.0/255.0) green:(216.0/255.0) blue:(216.0/255.0) alpha:1.0];
    }else if(signedOn){
        color = [NSColor colorWithCalibratedRed:(0.0/255.0) green:(0.0/255.0) blue:(102.0/255.0) alpha:1.0];
        invertedColor = [NSColor colorWithCalibratedRed:(216.0/255.0) green:(216.0/255.0) blue:(255.0/255.0) alpha:1.0];
    }else if(idle != 0 && away){
        color = [NSColor colorWithCalibratedRed:(89.0/255.0) green:(89.0/255.0) blue:(59.0/255.0) alpha:1.0];
        invertedColor = [NSColor colorWithCalibratedRed:(216.0/255.0) green:(216.0/255.0) blue:(143.0/255.0) alpha:1.0];
    }else if(idle != 0){
        color = [NSColor colorWithCalibratedRed:(67.0/255.0) green:(67.0/255.0) blue:(67.0/255.0) alpha:1.0];
        invertedColor = [NSColor colorWithCalibratedRed:(216.0/255.0) green:(216.0/255.0) blue:(216.0/255.0) alpha:1.0];
    }else if(away){
        color = [NSColor colorWithCalibratedRed:(66.0/255.0) green:(66.0/255.0) blue:(0.0/255.0) alpha:1.0];
        invertedColor = [NSColor colorWithCalibratedRed:(255.0/255.0) green:(255.0/255.0) blue:(191.0/255.0) alpha:1.0];
    }

    //Add the new color
    [colorArray setObject:color withOwner:self];
    [invertedColorArray setObject:invertedColor withOwner:self];
}

//Flash all handles with unviewed content
- (void)flash:(int)value
{
    NSEnumerator	*enumerator;
    AIListContact	*contact;

    enumerator = [flashingContactArray objectEnumerator];
    while((contact = [enumerator nextObject])){
        [self applyColorToContact:contact];
        
        //Force a redraw
        [[owner notificationCenter] postNotificationName:Contact_AttributesChanged object:contact userInfo:[NSDictionary dictionaryWithObject:[NSArray arrayWithObject:@"Text Color"] forKey:@"Keys"]];
    }
}

//Add a handle to the flash array
- (void)addToFlashArray:(AIListContact *)inContact
{
    //Ensure that we're observing the flashing
    if([flashingContactArray count] == 0){
        [[owner interfaceController] registerFlashObserver:self];
    }

    //Add the contact to our flash array
    [flashingContactArray addObject:inContact];
    [self flash:[[owner interfaceController] flashState]];
}

//Remove a handle from the flash array
- (void)removeFromFlashArray:(AIListContact *)inContact
{
    //Remove the contact from our flash array
    [flashingContactArray removeObject:inContact];

    //If we have no more flashing contacts, stop observing the flashes
    if([flashingContactArray count] == 0){
        [[owner interfaceController] unregisterFlashObserver:self];
    }
}

@end
