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
- (void)addToFlashArray:(AIContactHandle *)inHandle;
- (void)removeFromFlashArray:(AIContactHandle *)inHandle;
@end

@implementation AIStatusCirclesPlugin

- (void)installPlugin
{
    [[owner contactController] registerHandleObserver:self];

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

- (NSArray *)updateHandle:(AIContactHandle *)inHandle keys:(NSArray *)inModifiedKeys
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
        iconArray = [inHandle displayArrayForKey:@"Left View"];
        statusCircle = [iconArray objectWithOwner:self];
        if(!statusCircle){
            statusCircle = [AIStatusCircle statusCircle];
            [statusCircle setFlashColor:[NSColor orangeColor]];
            [iconArray addObject:statusCircle withOwner:self];
        }

        //Get all the values
        away = [[inHandle statusArrayForKey:@"Away"] greatestIntegerValue];
        idle = [[inHandle statusArrayForKey:@"Idle"] greatestIntegerValue];
        warning = [[inHandle statusArrayForKey:@"Warning"] greatestIntegerValue];
        online = [[inHandle statusArrayForKey:@"Online"] greatestIntegerValue];
        unviewedContent = [[inHandle statusArrayForKey:@"UnviewedContent"] greatestIntegerValue];
        unrespondedContent = [[inHandle statusArrayForKey:@"UnrespondedContent"] greatestIntegerValue];
        signedOn = [[inHandle statusArrayForKey:@"Signed On"] greatestIntegerValue];
        
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

        //Set the circle state
        if(!unviewedContent){
            [statusCircle setState:(unrespondedContent ? AICircleDot : AICircleNormal)];
        }else{
            [statusCircle setState:[[owner interfaceController] flashState]];
        }

        modifiedAttributes = [NSArray arrayWithObject:@"Left View"];
    }

    //Update our flash array (To reflect unviewed content)
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

//Flash all handles with unviewed content
- (void)flash:(int)value
{
    NSEnumerator	*enumerator;
    AIContactHandle	*handle;
    AIStatusCircle	*statusCircle;

    enumerator = [flashingContactArray objectEnumerator];
    while((handle = [enumerator nextObject])){
        //Set the status circle to the correct state
        statusCircle = [[handle displayArrayForKey:@"Left View"] objectWithOwner:self];
        [statusCircle setState:((value % 2) ? AICircleFlashA: AICircleFlashB)];

        //Force a redraw
        [[owner notificationCenter] postNotificationName:Contact_AttributesChanged object:handle userInfo:[NSDictionary dictionaryWithObject:[NSArray arrayWithObject:@"Left View"] forKey:@"Keys"]];
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
