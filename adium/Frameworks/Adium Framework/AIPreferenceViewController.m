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

#import "AIPreferenceViewController.h"

#define PREFERENCE_VIEW_NIB		@"PreferenceView"	//Filename of the preference view nib

@interface AIPreferenceViewController (PRIVATE)
- (id)initWithName:(NSString *)inName categoryName:(NSString *)inCategoryName view:(NSView *)preferenceView delegate:(id <AIPreferenceViewControllerDelegate>)inDelegate;
- (NSString *)name;
- (NSView *)view;
- (NSString *)categoryName;
- (IBAction)restoreDefaults:(id)sender;
@end

@implementation AIPreferenceViewController

//Create a new preference view controller (without delegate)
+ (AIPreferenceViewController *)controllerWithName:(NSString *)inName categoryName:(NSString *)inCategoryName view:(NSView *)inView
{
    return([[[self alloc] initWithName:inName categoryName:inCategoryName view:inView delegate:nil] autorelease]);
}

//Create a new preference view controller (with delegate)
+ (AIPreferenceViewController *)controllerWithName:(NSString *)inName categoryName:(NSString *)inCategoryName view:(NSView *)inView delegate:(id <AIPreferenceViewControllerDelegate>)inDelegate
{
    return([[[self alloc] initWithName:inName categoryName:inCategoryName view:inView delegate:inDelegate] autorelease]);
}


//Accessors
- (NSString *)name{
    return(name);
}

- (NSView *)view{
    return(view_containerView);
}

- (NSString *)categoryName{
    return(categoryName);
}

- (int)desiredHeight{
    return(desiredHeight);
}

- (id <AIPreferenceViewControllerDelegate>)delegate{
    return(delegate);
}

//Compare to another category view (for sorting on the preference window)
- (NSComparisonResult)compare:(AIPreferenceViewController *)inView
{
    return([name caseInsensitiveCompare:[inView name]]);
}

//Configure for an object
- (void)configureForObject:(id)inObject
{
    if(delegate){
        [delegate configurePreferenceViewController:self forObject:inObject];
    }    
}


//Private ---------------------------------------------------------------------------------------
//init
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
	
	//Make the Restore Defaults button active (FIXME)
	// [button_restoreDefaults setEnabled:YES];
	
    return(self);
}

- (void)dealloc
{
    [name release];
    [categoryName release];
    [delegate release];
    
    [super dealloc];
}


@end

