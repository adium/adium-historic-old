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
    preferenceView = nil;

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

- (NSView *)viewWithContainer:(BOOL)includeContainer
{
    //Setup the view
    if(!view_containerView && [delegate respondsToSelector:@selector(viewForPreferencePane:)]){
        //Get the preference view from our delegate
        preferenceView = [[delegate viewForPreferencePane:self] retain];

        if(includeContainer){
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
        }else{
            view_containerView = [preferenceView retain];
        }
    }
    
    return(view_containerView);
}

- (void)closeView
{
    if([delegate respondsToSelector:@selector(closeViewForPreferencePane:)]){
        //Tell our delegate to close its view
        [delegate closeViewForPreferencePane:self];
    }

    [preferenceView release]; preferenceView = nil;
    [view_containerView release]; view_containerView = nil;
}

@end

