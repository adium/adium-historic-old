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

#define PREFERENCE_VIEW_NIB		@"PreferenceView"	//Filename of the preference view nib

@interface AIPreferencePane (PRIVATE)
- (id)initInCategory:(PREFERENCE_CATEGORY)inCategory withDelegate:(id)inDelegate label:(NSString *)inLabel;
- (NSString *)nibName;
- (void)viewDidLoad;
- (void)viewWillClose;
- (void)configureControlDimming;
@end

@implementation AIPreferencePane

//Return a new preference pane
+ (AIPreferencePane *)preferencePane
{
    return([[[self alloc] init] autorelease]);
}

//Return a new preference pane, passing plugin
+ (AIPreferencePane *)preferencePaneForPlugin:(id)inPlugin
{
    return([[[self alloc] initForPlugin:inPlugin] autorelease]);
}


//Init, passing plugin
- (id)initForPlugin:(id)inPlugin
{
    plugin = inPlugin;
    return([self init]);
}

//Init
- (id)init
{
    [super init];
    
    //Init
    view = nil;
    isUpdated = YES;
    
    //Register
    [[adium preferenceController] addPreferencePane:self];
    
    return(self);
}

//TRANSITION ONLY, will be removed
- (BOOL)isUpdated
{
    return(isUpdated);
}

//Compare to another category view (for sorting on the preference window)
- (NSComparisonResult)compare:(AIPreferencePane *)inPane
{
    return([[self label] caseInsensitiveCompare:[inPane label]]);
}

//Returns our view
- (NSView *)view
{
    if(!view){
        //Load and configure our view
        [NSBundle loadNibNamed:[self nibName] owner:self];
        [self viewDidLoad];
        [view setAutoresizingMask:(NSViewMaxYMargin)];
    }
    
    return(view);
}

//Close our view
- (void)closeView
{
    if(isUpdated){
        if(view){
            [self viewWillClose];
            [view release]; view = nil;
        }
    }else{ //TRANSITION ONLY, will be removed
        if([delegate respondsToSelector:@selector(closeViewForPreferencePane:)]){
            //Tell our delegate to close its view
            [delegate closeViewForPreferencePane:self];
        }
        
        [preferenceView release]; preferenceView = nil;
        [view_containerView release]; view_containerView = nil;        
    }
}


//For subclasses -------------------------------------------------------------------------------
//Preference category
- (PREFERENCE_CATEGORY)category
{
    if(isUpdated){
        return(AIPref_Advanced_Other);
    }else{ //TRANSITION ONLY, will be removed
        return(category);
    }
}

//Preference label
- (NSString *)label
{
    if(isUpdated){
        return(@"");
    }else{ //TRANSITION ONLY, will be removed
        return(label);
    }
}

//Nib to load
- (NSString *)nibName
{
    return(@"");    
}

//Configure the preference view
- (void)viewDidLoad
{
    
}

//Preference view is closing
- (void)viewWillClose
{
    
}

//Apply a changed preference
- (IBAction)changePreference:(id)sender
{
    [self configureControlDimming];
}

//Configure control dimming
- (void)configureControlDimming
{
    
}

//Return an array of dictionaries, each dictionary of the form (key, default, group)
- (NSDictionary *)restorablePreferences
{
	return(nil);
}





//--------------Old Code, transition only, will be removed---------
#pragma mark

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
    isUpdated = NO;

    //

    return(self);
}

//
- (void)dealloc
{
    if(!isUpdated) [label release];
    
    [super dealloc];
}

- (NSView *)viewWithContainer:(BOOL)includeContainer
{
    NSParameterAssert(!isUpdated);
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

@end

