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
#import "AIContentObject.h"

@interface AIContentStatus (PRIVATE)
- (id)initWithChat:(AIChat *)inChat source:(id)inSource destination:(id)inDest date:(NSDate *)inDate message:(NSString *)inMessage withType:(NSString *)inStatus;
@end


@implementation AIContentStatus

//Create a new status content object
+ (id)statusInChat:(AIChat *)inChat withSource:(id)inSource destination:(id)inDest date:(NSDate *)inDate message:(NSString *)inMessage withType:(NSString *)inStatus
{
    return([[[self alloc] initWithChat:inChat source:inSource destination:inDest date:inDate message:inMessage withType:inStatus] autorelease]);
}

//Return the type ID of this content
- (NSString *)type
{
    return(CONTENT_STATUS_TYPE);
}

//Return our status message content
- (NSString *)message{
    return(message);
}

//Return the type of status change this is
- (NSString *)status {
	return statusType;
}

- (void)setMessage:(NSString *)inMessage{
    if(message != inMessage){
        [message release]; //we should probably hold onto the original content...
                           //That would allow us to 'refilter' a piece of content to dynamically update the previously displayed messages as preferences are changed... which would be very cool
        message = [inMessage retain];
    }
}

//Return the date and time this message was sent
- (NSDate *)date{
    return(date);
}

// Private ------------------------------------------------------------------------------
//init
- (id)initWithChat:(AIChat *)inChat source:(id)inSource destination:(id)inDest date:(NSDate *)inDate message:(NSString *)inMessage withType:(NSString *)inStatus
{
    [super initWithChat:inChat source:inSource destination:inDest];

	//Filter so that triggers in messages can be resolved
	filterContent = YES;
	//Don't track status changes
	trackContent = NO;

	//plainText = YES;
	
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
	statusType = [inStatus retain];

    return(self);
}

- (void)dealloc
{
    [date release];
    [message release];
	[statusType release];
	
    [super dealloc];
}

@end
