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

#import "AIPreferencePane.h"
#import <AIUtilities/AIUtilities.h>

#define PREFERENCE_VIEW_NIB		@"PreferenceView"	//Filename of the preference view nib

@interface AIPreferencePane (PRIVATE)
- (id)initInCategory:(PREFERENCE_CATEGORY)inCategory withDelegate:(id)inDelegate label:(NSString *)inLabel;
@end

@implementation AIPreferencePane

//Create a new preference view controller
+ (AIPreferencePane *)preferencePaneInCategory:(PREFERENCE_CATEGORY)inCategory withDelegate:(id)inDelegate label:(NSString *)inLabel
{
    return([[[self alloc] initInCategory:inCategory withDelegate:inDelegate label:inLabel] autorelease]);
}

//init
- (id)initInCategory:(PREFERENCE_CATEGORY)inCategory withDelegate:(id)inDelegate label:(NSString *)inLabel
{
    [super init];

    //Init
    delegate = inDelegate;
    category = inCategory;
    label = [inLabel retain];

//    NSLog(@"Init Preference Pane (%@, %i)",delegate, category);

    //

    return(self);
}

//
- (void)dealloc
{
    [label release];
    
    [super dealloc];
}

//
- (PREFERENCE_CATEGORY)category
{
    return(category);
}

- (NSString *)label
{
    return(label);
}

//Compare to another category view (for sorting on the preference window)
- (NSComparisonResult)compare:(AIPreferencePane *)inPane
{
    return([label caseInsensitiveCompare:[inPane label]]);
}

- (NSView *)view
{
    //Setup the view
    if(!view_containerView){
        //Get the preference view from our delegate
        preferenceView = [delegate viewForPreferencePane:self];

        //Load the container view from our nib
        [NSBundle loadNibNamed:PREFERENCE_VIEW_NIB owner:self];

        //Configure the view
        [preferenceView setAutoresizingMask:NSViewNotSizable];
        {
            NSRect	containerFrame = [view_containerView frame];

            //Make the container view the correct height to fit the new preference view
            containerFrame.size.height -= [view_containerSubView frame].size.height;
            containerFrame.size.height += [preferenceView frame].size.height;
            [view_containerView setFrame:containerFrame];

            //Add the preference view to the container
            [view_containerSubView addSubview:preferenceView];
            [preferenceView setFrameOrigin:NSMakePoint(0,0)];

            //Set the label
            [textField_title setStringValue:label];
        }
    }
    
    return(view_containerView);
}



/*
- (id)initWithName:(NSString *)inName categoryName:(NSString *)inCategoryName view:(NSView *)preferenceView delegate:(id <AIPreferenceViewControllerDelegate>)inDelegate
{
    [super init];
    
    name = [inName retain];
    categoryName = [inCategoryName retain];
    delegate = [inDelegate retain];
    
    //Load the container view from our nib
    if(![NSBundle loadNibNamed:PREFERENCE_VIEW_NIB owner:self]){
        NSLog(@"couldn't load preference view nib");
    }

    //Configure the view
    [preferenceView setAutoresizingMask:NSViewNotSizable];
    {
        NSRect	containerFrame = [view_containerView frame];
 
        //Set our colored box to a sexy blue
        //[view_coloredBox setColor:[NSColor colorWithCalibratedRed:(66.0/255.0) green:(132.0/255.0) blue:(217.0/255.0) alpha:0.4]];
        
        //Make the container view the correct height to fit the new preference view
        containerFrame.size.height -= [view_containerSubView frame].size.height;
        containerFrame.size.height += [preferenceView frame].size.height;
        [view_containerView setFrame:containerFrame];

        //Add the preference view to the container
        [view_containerSubView addSubview:preferenceView];
        [preferenceView setFrameOrigin:NSMakePoint(0,0)];
    }
    
    desiredHeight = [view_containerView frame].size.height;
    [textField_title setStringValue:name];
    
    return(self);
}*/

/*- (int)desiredHeight{
return(desiredHeight);
}*/

/*- (id <AIPreferenceViewControllerDelegate>)delegate{
return(delegate);
}*/



//Configure for an object
/*- (void)configureForObject:(id)inObject
{
    if(delegate){
        [delegate configurePreferenceViewController:self forObject:inObject];
    }
}*/


//Create a new preference view controller (with delegate)
/*+ (AIPreferenceViewController *)controllerWithName:(NSString *)inName categoryName:(NSString *)inCategoryName view:(NSView *)inView delegate:(id <AIPreferenceViewControllerDelegate>)inDelegate
{
    return([[[self alloc] initWithName:inName categoryName:inCategoryName view:inView delegate:inDelegate] autorelease]);
}*/



@end

