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

#import "AIContentMessage.h"
#import "AIContentObject.h"
#import "AIAccount.h"

@interface AIContentMessage (PRIVATE)
- (id)initWithChat:(AIChat *)inChat
			source:(id)inSource
	   destination:(id)inDest
			  date:(NSDate *)inDate
		   message:(NSAttributedString *)inMessage
		 autoreply:(BOOL)inAutoreply;
@end

@implementation AIContentMessage

//Create a content message
+ (id)messageInChat:(AIChat *)inChat
		 withSource:(id)inSource
		destination:(id)inDest
			   date:(NSDate *)inDate
			message:(NSAttributedString *)inMessage
		  autoreply:(BOOL)inAutoReply
{
    return([[[self alloc] initWithChat:inChat
								source:inSource
						   destination:inDest
								  date:inDate
							   message:inMessage
							 autoreply:inAutoReply] autorelease]);
}

//Content Identifier
- (NSString *)type
{
    return(CONTENT_MESSAGE_TYPE);
}

//Init
- (id)initWithChat:(AIChat *)inChat
			source:(id)inSource
	   destination:(id)inDest
			  date:(NSDate *)inDate
		   message:(NSAttributedString *)inMessage
		 autoreply:(BOOL)inAutoReply
{
    [super initWithChat:inChat source:inSource destination:inDest date:inDate message:inMessage];
    	
    isAutoreply = inAutoReply;
	
    return(self);
}

//This message was automatically generated
- (void)setIsAutoreply:(BOOL)inAutoreply{
	isAutoreply = inAutoreply;
}
- (BOOL)isAutoreply{
    return(isAutoreply);
}

@end
