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

#import "AIService.h"
#import "AIAdium.h"

@interface AIService (PRIVATE)
- (id)initWithOwner:(id)inOwner;
@end

@implementation AIService

//Create a new service
+ (AIService *)serviceWithOwner:(id)inOwner
{
    return([[[self alloc] initWithOwner:inOwner] autorelease]);
}

//Functions for subclasses to override
- (id)accountWithProperties:(NSDictionary *)inProperties owner:(id)inOwner{ return(nil); }
- (NSString *)identifier{ return(nil); }
- (NSString *)description{ return(nil); }
- (AIServiceType *)handleServiceType{ return(nil); }
- (void)initService{ }


//Private ---------------------------------------------------------------------------
//init
- (id)initWithOwner:(id)inOwner
{
    [super init];
    
    owner = [inOwner retain];

    [self initService];


    return(self);
}

- (void)dealloc
{
    [owner release];

    [super dealloc];
}

@end
