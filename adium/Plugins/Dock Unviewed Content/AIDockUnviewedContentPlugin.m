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

#import "AIDockUnviewedContentPlugin.h"


@implementation AIDockUnviewedContentPlugin

- (void)installPlugin
{
    //init
    unviewedObjectsArray = [[NSMutableArray alloc] init];
    unviewedState = NO;

    //Register as a contact observer (So we can catch the unviewed content status flag)
    [[adium contactController] registerListObjectObserver:self];

}

- (void)uninstallPlugin
{

}


- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys delayed:(BOOL)delayed silent:(BOOL)silent
{
    if([inModifiedKeys containsObject:@"UnviewedContent"]){
        if([[inObject statusArrayForKey:@"UnviewedContent"] greatestIntegerValue]){
            //If this is the first contact with unviewed content, animate the dock
            if(!unviewedState){
                [[adium dockController] setIconStateNamed:@"Alert"];
                unviewedState = YES;
            }

            [unviewedObjectsArray addObject:inObject];

        }else{
            if([unviewedObjectsArray containsObject:inObject]){
                [unviewedObjectsArray removeObject:inObject];

                //If there are no more contacts with unviewed content, stop animating the dock
                if([unviewedObjectsArray count] == 0 && unviewedState){
                    [[adium dockController] removeIconStateNamed:@"Alert"];
                    unviewedState = NO;
                }
            }
        }

    }

    return(nil);
}

@end
