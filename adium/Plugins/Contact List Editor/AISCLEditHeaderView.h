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

#import <Cocoa/Cocoa.h>


//General
#define LABEL_X_OFFSET		1		//The X offset of the entire label block (padding to the left)
#define LABEL_Y_OFFSET		1    		//The Y offset of the entire label block (padding on the bottom)
#define LABEL_ROTATION		55		//Rotation of the column labels
#define LABEL_LENGTH		180		//Divider line length
#define LABEL_SIZE		10		//Font size of column labels

//Color
#define COLOR_X_OFFSET		-6		//X (diagonal) offset of the color behind labels
#define COLOR_Y_OFFSET		-8		//Y offset (tied directly to X offset, since we're diagonal)
#define COLOR_HEIGHT		12		//Pixel height of the color behind labels
#define COLOR_LENGTH		180		//Pixel length of the color behind labels

//Text
#define NAME_X_OFFSET		-1		//X (diagonal) offset of the label text
#define NAME_Y_OFFSET		-1		//Y offset (tied directly to X offset, since we're diagonal)
#define NAME_HEIGHT		12		//Pixel height of the label text
#define NAME_LENGTH		180		//Pixel length of the label text

@class AIAlternatingRowOutlineView;

@interface AISCLEditHeaderView : NSView {

}

- (void)configureForAccounts:(NSArray *)accountArray view:(AIAlternatingRowOutlineView *)outlineView;

@end
