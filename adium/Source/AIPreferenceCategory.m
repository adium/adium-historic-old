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

// $Id: AIPreferenceCategory.m,v 1.6 2003/12/08 05:32:09 jmelloy Exp $

#import "AIPreferenceCategory.h"
#import "AIFlippedCategoryView.h"
#import "AIPreferenceViewController.h"

@interface AIPreferenceCategory (PRIVATE)
- (AIPreferenceCategory *)initWithName:(NSString *)inName image:(NSImage *)inImage;
@end

@implementation AIPreferenceCategory

//Return a new preference category
+ (AIPreferenceCategory *)categoryWithName:(NSString *)inName image:(NSImage *)inImage
{
    return([[[self alloc] initWithName:inName image:inImage] autorelease]);
}

//Return the name of this category
- (NSString *)name{
    return(name);
}

//Return the image associated with this category
- (NSImage *)image{
    return(image);
}

//Add a preference view
- (void)addView:(AIPreferenceViewController *)inView
{
    [viewArray addObject:inView]; 

    [self buildContents];
}

- (NSArray *)viewArray
{
    return(viewArray);
}

//Removes and re-inserts all preference views.  Call after adding/removing a view.
- (void)buildContents
{
    NSEnumerator		*enumerator;
    AIPreferenceViewController	*preferenceView;

    //Remove any current views
    [contentView removeAllSubviews];
    
    //Sort the views (alphabetically)
    [viewArray sortUsingSelector:@selector(compare:)];    
    
    //Add them all back
    enumerator = [viewArray objectEnumerator];
    while((preferenceView = [enumerator nextObject])){
        [contentView addSubview:[preferenceView view]];
    }
}

//Sizes and positions the preference views.  (Call after collapsing/expanding a view)
- (void)sizeAndPositionContents
{
    NSEnumerator		*enumerator;
    AIPreferenceViewController	*preferenceView;
    int				desiredHeight;
    int 			offset = 0;
    int				width = FIXED_CATEGORY_WIDTH;

    enumerator = [viewArray objectEnumerator];
    while((preferenceView = [enumerator nextObject])){
        //Size this view
        desiredHeight = [preferenceView desiredHeight];  
        [[preferenceView view] setFrameOrigin:NSMakePoint(0,offset)];      

        width = [[preferenceView view] frame].size.width;
        offset += desiredHeight;
    }    
    
    [contentView setFrame:NSMakeRect(0,0,width,offset)];
}

//Return this category's content view
- (NSView *)contentView
{
    [self sizeAndPositionContents];

    return(contentView);
}

//Configure the category for an object
- (void)configureForObject:(id)inObject
{
    NSEnumerator		*enumerator;
    AIPreferenceViewController	*view;

    enumerator = [viewArray objectEnumerator];
    while((view = [enumerator nextObject])){
        [view configureForObject:inObject];
    }
}


//Private ----------------------------------------------------------------------
- (AIPreferenceCategory *)initWithName:(NSString *)inName image:(NSImage *)inImage
{
    [super init];
    
    name = [inName retain];
    image = [inImage retain];
    viewArray = [[NSMutableArray alloc] init];
    contentView = [[AIFlippedCategoryView alloc] init];

    return(self);
}

- (void)dealloc
{
    [viewArray release];
    [contentView release];
    [name release];
    [image release];

    [super dealloc];
}

@end
