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


#import "BGEmoticonPackTableView.h"

@implementation BGEmoticonPackTableView

//Filter keydowns looking for the delete key (to delete the current selection)
- (void)keyDown:(NSEvent *)theEvent
{
        NSString	*charString = [theEvent charactersIgnoringModifiers];
        unichar	pressedChar = 0;
        
        //Get the pressed character
        if([charString length] == 1) pressedChar = [charString characterAtIndex:0];
        
        //Check if 'delete' was pressed (and should also check for the cmmd key)
        // BRACKET WITH A WARNING DIALOG!
        if(pressedChar == NSDeleteFunctionKey || pressedChar == 127){ //Delete
            // Tell preferences to move the actual packs to the trash
            AIEmoticonPreferences *emoticonPrefs = [self dataSource];
            [emoticonPrefs moveSelectedPacksToTrash]; 
        }
        else{
            [super keyDown:theEvent]; //Pass the key event on
        }        
}

@end
