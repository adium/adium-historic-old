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

#import "AIContentMessage.h"
#import "AIAccount.h"
#import "AIAdium.h"

@interface AIContentMessage (PRIVATE)
- (id)initWithSource:(id)inSource destination:(id)inDest date:(NSDate *)inDate message:(NSAttributedString *)inMessage;
@end

@implementation AIContentMessage

//Create a content message
+ (id)messageWithSource:(id)inSource destination:(id)inDest date:(NSDate *)inDate message:(NSAttributedString *)inMessage
{
    return([[[self alloc] initWithSource:inSource destination:inDest date:inDate message:inMessage] autorelease]);
}

//Return the type ID of this content
- (NSString *)type
{
    return(CONTENT_MESSAGE_TYPE);
}

//The attributed message contents
- (NSAttributedString *)message{
    return(message);
}

- (void)setMessage:(NSAttributedString *)inMessage{
    if(message != inMessage){
        [message release]; //we should probably hold onto the origional content...
                           //That would allow us to 'refilter' a piece of content to dynamically update the previously displayed messages as preferences are changed... which would be very cool
        message = [inMessage retain];
    }
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
- (id)initWithSource:(id)inSource destination:(id)inDest date:(NSDate *)inDate message:(NSAttributedString *)inMessage;
{
    [super init];
    
//    NSParameterAssert([inSource isKindOfClass:[AIContactHandle class]] || [inSource isKindOfClass:[AIAccount class]]);
    
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
