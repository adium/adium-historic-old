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
#import "AIStatusCirclesPlugin.h"
#import "AIStatusCircle.h"
#import "AIAdium.h"

@interface AIStatusCirclesPlugin (PRIVATE)
- (NSString *)idleStringForSeconds:(int)seconds;
- (void)addToFlashArray:(AIListContact *)inContact;
- (void)removeFromFlashArray:(AIListContact *)inContact;
@end

@implementation AIStatusCirclesPlugin

- (void)installPlugin
{
    [[owner contactController] registerContactObserver:self];

    flashingContactArray = [[NSMutableArray alloc] init];
}

- (void)uninstallPlugin
{
    //[[owner contactController] unregisterHandleObserver:self];
}

- (void)dealloc
{
    [super dealloc];
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
        [inModifiedKeys containsObject:@"UnrespondedContent"] ||
        [inModifiedKeys containsObject:@"Signed On"] /*||
        [inModifiedKeys containsObject:@"Signed Off"]*/){

        AIMutableOwnerArray	*iconArray;
        AIStatusCircle		*statusCircle;
        NSColor			*circleColor;
        int			away, idle, warning, online, unviewedContent, unrespondedContent, signedOn;
        
        //Get the status circle
        iconArray = [inContact displayArrayForKey:@"Left View"];
        statusCircle = [iconArray objectWithOwner:self];
        if(!statusCircle){
            statusCircle = [AIStatusCircle statusCircle];
            [statusCircle setFlashColor:[NSColor orangeColor]];
            [iconArray setObject:statusCircle withOwner:self];
        }

        //Get all the values
        away = [[inContact statusArrayForKey:@"Away"] greatestIntegerValue];
        idle = [[inContact statusArrayForKey:@"Idle"] greatestIntegerValue];
        warning = [[inContact statusArrayForKey:@"Warning"] greatestIntegerValue];
        online = [[inContact statusArrayForKey:@"Online"] greatestIntegerValue];
        unviewedContent = [[inContact statusArrayForKey:@"UnviewedContent"] greatestIntegerValue];
        unrespondedContent = [[inContact statusArrayForKey:@"UnrespondedContent"] greatestIntegerValue];
        signedOn = [[inContact statusArrayForKey:@"Signed On"] greatestIntegerValue];
        
        //Set the circle color
        if(!online){
            circleColor = [NSColor colorWithCalibratedRed:(178.0/255.0) green:(0.0/255.0) blue:(0.0/255.0) alpha:1.0];
        }else if(signedOn){
            circleColor = [NSColor colorWithCalibratedRed:(102.0/255.0) green:(102.0/255.0) blue:(229.0/255.0) alpha:1.0];
        }else if(idle && away){
            circleColor = [NSColor colorWithCalibratedRed:(229.0/255.0) green:(229.0/255.0) blue:(153.0/255.0) alpha:1.0];
        }else if(idle){
            circleColor = [NSColor colorWithCalibratedRed:(204.0/255.0) green:(204.0/255.0) blue:(204.0/255.0) alpha:1.0];
        }else if(away){
            circleColor = [NSColor colorWithCalibratedRed:(229.0/255.0) green:(229.0/255.0) blue:(102.0/255.0) alpha:1.0];
        }else{
            circleColor = [NSColor colorWithCalibratedRed:(255.0/255.0) green:(255.0/255.0) blue:(255.0/255.0) alpha:1.0];
        }
        [statusCircle setColor:circleColor];

        //Embedded idle time
        if(idle){
            [statusCircle setStringContent:[self idleStringForSeconds:idle]];
        }else{
            [statusCircle setStringContent:nil];
        }

        //Set the circle state
        if(!unviewedContent){
            [statusCircle setState:(unrespondedContent ? AICircleDot : AICircleNormal)];
        }else{
            [statusCircle setState:(([[owner interfaceController] flashState] % 2) ? AICircleFlashA: AICircleFlashB)];
        }

        modifiedAttributes = [NSArray arrayWithObject:@"Left View"];
    }

    //Update our flash array (To reflect unviewed content)
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

//Flash all handles with unviewed content
- (void)flash:(int)value
{
    NSEnumerator	*enumerator;
    AIListContact	*contact;
    AIStatusCircle	*statusCircle;

    enumerator = [flashingContactArray objectEnumerator];
    while((contact = [enumerator nextObject])){
        //Set the status circle to the correct state
        statusCircle = [[contact displayArrayForKey:@"Left View"] objectWithOwner:self];
        [statusCircle setState:((value % 2) ? AICircleFlashA: AICircleFlashB)];

        //Force a redraw
        [[owner notificationCenter] postNotificationName:Contact_AttributesChanged object:contact userInfo:[NSDictionary dictionaryWithObject:[NSArray arrayWithObject:@"Left View"] forKey:@"Keys"]];
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

//
- (NSString *)idleStringForSeconds:(int)seconds
{
    NSString	*idleString;

    if(seconds >= 600){
        idleString = [NSString stringWithFormat:@"%ih",seconds / 60];
    }else if(seconds >= 60){
        idleString = [NSString stringWithFormat:@"%i:%02i",seconds / 60, seconds % 60];
    }else{
        idleString = [NSString stringWithFormat:@"%i",seconds];
    }

    return(idleString);
}


@end
