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

/*
    Assists with loading images from an auxiliary bundle.
*/

//Includes
#import "AIImageUtilities.h"
//Framework Includes

//Private methods
@interface AIImageUtilities (PRIVATE)

@end

@implementation AIImageUtilities

//-------------------
//  Public Methods
//-----------------------
// Returns an image from the owners bundle with the specified name
+ (NSImage *)imageNamed:(NSString *)name forClass:(Class)inClass
{
    NSBundle	*ownerBundle;
    NSString	*imagePath;
    NSImage	*image;

    //Get the bundle
    ownerBundle = [NSBundle bundleForClass:inClass];

    //Open the image
    imagePath = [ownerBundle pathForImageResource:name];    
    image = [[NSImage alloc] initWithContentsOfFile:imagePath];

    return([image autorelease]);
}

@end
