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

#import "AICursorAdditions.h"
#import "AIImageUtilities.h"

@implementation NSCursor (AICursorAdditions)

//I'm passing [AIImageUtilities class] to imageNamed:forClass so the image is loaded from the AIUtilities framework.  Since this class consists of additions to NSCursor, using [self class] will search for the image in NSCursor's framework's bundle, which is wrong.

+ (NSCursor *)openGrabHandCursor
{
    static NSCursor 	*openGrabHandCursor = nil;

    if(!openGrabHandCursor){
        openGrabHandCursor = [[NSCursor alloc] initWithImage:[AIImageUtilities imageNamed:@"OpenGrabHandCursor" forClass:[AIImageUtilities class]] hotSpot:NSMakePoint(8,8)];
    }

    return(openGrabHandCursor);
}

+ (NSCursor *)closedGrabHandCursor
{
    static NSCursor 	*closedGrabHandCursor = nil;

    if(!closedGrabHandCursor){
        closedGrabHandCursor = [[NSCursor alloc] initWithImage:[AIImageUtilities imageNamed:@"ClosedGrabHandCursor" forClass:[AIImageUtilities class]] hotSpot:NSMakePoint(8,8)];
    }

    return(closedGrabHandCursor);
}

+ (NSCursor *)handPointCursor
{
    static NSCursor 	*handPointCursor = nil;

    if(!handPointCursor){
        handPointCursor = [[NSCursor alloc] initWithImage:[AIImageUtilities imageNamed:@"HandPointCursor" forClass:[AIImageUtilities class]] hotSpot:NSMakePoint(5,0)];
    }

    return(handPointCursor);
}


@end
