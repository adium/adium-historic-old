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

#import "AIContentStatus.h"


@interface AIContentStatus (PRIVATE)
- (id)initWithSource:(id)inSource destination:(id)inDest date:(NSDate *)inDate message:(NSString *)inMessage;
@end


@implementation AIContentStatus

//Create a new status content object
+ (id)statusWithSource:(id)inSource destination:(id)inDest date:(NSDate *)inDate message:(NSString *)inMessage
{
    return([[[self alloc] initWithSource:inSource destination:inDest date:inDate message:inMessage] autorelease]);
}

//Return the type ID of this content
- (NSString *)type
{
    return(CONTENT_STATUS_TYPE);
}

- (BOOL)filterObject
{
    return(YES); //Staus content can pass through the content filters (I'm sure something will want to filter them in the future)
}

- (BOOL)trackObject
{
    return(YES); //Status content should be tracked by the contact
}

//Return our status message content
- (NSString *)message{
    return(message);
}

//Message source (may return a contact handle, or an account)
- (id)source{
    return(source);
}

//Message destination (may return a contact handle, or an account(
- (id)destination{
    return(destination);
}

//Return the date and time this message was sent
- (NSDate *)date{
    return(date);
}

// Private ------------------------------------------------------------------------------
//init
- (id)initWithSource:(id)inSource destination:(id)inDest date:(NSDate *)inDate message:(NSString *)inMessage
{
    [super init];

    //Store source and dest
    source = [inSource retain];
    destination = [inDest retain];

    //Store the date and message
    if(!date){
        date = [[NSDate date] retain];
    }else{
        date = [inDate retain];
    }
    message = [inMessage retain];

    return(self);
}

- (void)dealloc
{
    [source release];
    [destination release];
    [date release];
    [message release];

    [super dealloc];
}

@end
