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
#import "AISMViewPlugin.h"
#import "AIAdium.h"
#import "AISMTextView.h"

@implementation AISMViewPlugin

- (void)installPlugin
{
    [[owner interfaceController] registerMessageViewController:self];
}

//returns a NEW message view configured for the specified handle
- (NSView *)messageViewForHandle:(AIContactHandle *)inHandle
{
    AISMTextView	*messageView = [AISMTextView messageTextViewForHandle:inHandle owner:owner];

    return(messageView);
}

@end
