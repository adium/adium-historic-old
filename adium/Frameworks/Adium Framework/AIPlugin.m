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

#import "AIPlugin.h"
#import "AIAdium.h"

@interface AIPlugin (PRIVATE)
- (id)initWithOwner:(id)inOwner;
- (void)installPlugin;
@end

@implementation AIPlugin

//Return a new instance of the plugin
+ (id)newInstanceOfPluginWithOwner:(id)inOwner
{
    return([[[self alloc] initWithOwner:inOwner] autorelease]);
}

//Init the plugin
- (id)initWithOwner:(id)inOwner
{
    [super init];
    owner = [inOwner retain]; //Retain the owner

    //Install the plugin
    [self installPlugin];

    return(self);
}

- (void)dealloc
{
    [owner release];

    [super dealloc];
}

//Install the plugin
- (void)installPlugin
{
}

- (void)uninstallPlugin
{
}

@end
