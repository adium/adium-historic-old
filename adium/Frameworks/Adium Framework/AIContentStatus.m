//
//  AIContentStatus.m
//  Adium
//
//  Created by Adam Iser on Fri Apr 04 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

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
