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

#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"
#import "AIDockIconPreferences.h"
#import "AIDockIconSelectionPlugin.h"

#define PREF_GROUP_DOCK_ICON		@"Dock Icon"

@interface AIDockIconPreferences (PRIVATE)
- (void)configureForSelectedIcon:(NSDictionary *)iconDict;
- (void)_buildIconArray;
- (NSDictionary *)_iconInArrayNamed:(NSString *)name;
- (void)setupPreferenceView;
- (void)animate:(NSTimer *)timer;
- (void)_startAnimating;
- (void)_stopAnimating;
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation AIDockIconPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Dock);
}
- (NSString *)label{
    return(@"Dock Icon");
}
- (NSString *)nibName{
    return(@"IconSelectionPrefs");
}

//Setup our preference view
- (void)viewDidLoad
{
    NSEnumerator	*enumerator;
    NSTableColumn	*column;

    cycle = 0;
    animationTimer = nil;

    //Configure the table view
    [tableView_icons setIntercellSpacing:NSMakeSize(4,2)];
    [tableView_icons setTarget:self];
    [tableView_icons setAction:@selector(selectIcon:)];

    //Set all column data cells to image cells
    enumerator = [[tableView_icons tableColumns] objectEnumerator];
    while((column = [enumerator nextObject])){
        IKTableImageCell	*cell = [[[IKTableImageCell alloc] init] autorelease];
        [cell setImageScaling:NSScaleProportionally];

        [column setDataCell:cell];
    }
    
    //Load our icons
    [self _buildIconArray];
    
    //Observe preference changes
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];
    
    //Start animating
    [self _startAnimating];
}

//Preference view is closing
- (void)viewWillClose
{
    [iconArray release]; iconArray = nil;
    [previewStateArray release]; previewStateArray = nil;
    
    //Stop animating
    [self _stopAnimating];
    
    //
    [[owner notificationCenter] removeObserver:self];
}

//Preferences have changed
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_GENERAL] == 0){
        NSDictionary 	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_GENERAL];
        NSDictionary	*iconDict;
        NSString	*iconName;

        //Set the selected icon
        iconName = [preferenceDict objectForKey:KEY_ACTIVE_DOCK_ICON];
        iconDict = [self _iconInArrayNamed:iconName];
        [self configureForSelectedIcon:iconDict];
        
    }
}

//Start animating
- (void)_startAnimating
{
    if(!animationTimer){
        animationTimer = [[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(animate:) userInfo:nil repeats:YES] retain];
    }
}

- (void)_stopAnimating
{
    if(animationTimer){
        [animationTimer invalidate];
        [animationTimer release];
        animationTimer = nil;
    }
}

//Configures our view for the passed icon being selected
- (void)configureForSelectedIcon:(NSDictionary *)iconDict
{
    NSDictionary	*iconPackDict;
    NSDictionary	*descriptionDict, *stateDict;
    NSString		*title, *creator;
    NSEnumerator	*previewEnumerator, *stateEnumerator;
    NSArray		*stateArray;
    NSString		*state;
    NSArray		*previewArray;
    
    //Remember this as selected
    selectedIcon = iconDict;

    //
    iconPackDict = [[owner dockController] iconPackAtPath:[iconDict objectForKey:@"Path"]];

    //-- Display the icon pack information --
    descriptionDict = [iconPackDict objectForKey:@"Description"];
        //Title
        title = [descriptionDict objectForKey:@"Title"];
        [textField_title setStringValue:(title ? title : @"")];
        //Description
        creator = [descriptionDict objectForKey:@"Creator"];
        [textField_creator setStringValue:(creator ? creator : @"")];
        //Link
//        link = [descriptionDict objectForKey:@"LinkURL"];
//        [textField_link setStringValue:(link ? link : @"")];

    //Display the icon state previews
    stateDict = [iconPackDict objectForKey:@"State"];

    //Create a new preview state array
    [previewStateArray release]; previewStateArray = [[NSMutableArray alloc] init];

    //Generate each preview
    previewArray = [[NSDictionary dictionaryNamed:@"IconPreviewList" forClass:[self class]] objectForKey:@"Preview"];
    previewEnumerator = [previewArray objectEnumerator];
    while((stateArray = [previewEnumerator nextObject])){
        NSMutableArray	*tempArray;
        AIIconState	*tempIconState;

        //Build an array of all the states we want to composite for this preview
        tempArray = [NSMutableArray array];
        stateEnumerator = [stateArray objectEnumerator];
        while((state = [stateEnumerator nextObject])){
            id	tempState = [stateDict objectForKey:state];

            if(tempState){
                [tempArray addObject:tempState];
            }
        }

        //Generate the preview icon state, and add it to our preview state array
        tempIconState = [[[AIIconState alloc] initByCompositingStates:tempArray] autorelease];
        [previewStateArray addObject:tempIconState];
    }

    //Redisplay
    [tableView_icons display];
    [self animate:nil];
}

//Animate the preview icons
- (void)animate:(NSTimer *)timer
{
    NSEnumerator	*previewEnumerator;
    AIIconState		*state;
    NSEnumerator	*cellEnumerator;
    NSImageCell		*cell;

    if([matrix_iconPreview canDraw]){
        cycle++;

        //Process each preview
        previewEnumerator = [previewStateArray objectEnumerator];
        cellEnumerator = [[matrix_iconPreview cells] objectEnumerator];
        while((state = [previewEnumerator nextObject])){
            int	cycleSkip = ([state animationDelay] / 0.1);

            //Move to the next frame
            if([state animated] && !(cycle % cycleSkip)){
                [state nextFrame];
            }

            //Update the cell
            cell = [cellEnumerator nextObject];
            [cell setImage:[state image]];
        }

        //Redisplay
        [matrix_iconPreview setNeedsDisplay:YES];
        
    }
}

//User selected an icon in the table view
- (void)selectIcon:(id)sender
{
    int	clickedColumn, clickedRow, index;
    int	columns = [tableView_icons numberOfColumns];
    int	icons = [iconArray count];
    
    //Get the clicked cell
    clickedColumn = [tableView_icons clickedColumn];
    clickedRow = [tableView_icons clickedRow];
    index = (clickedRow * columns) + clickedColumn;
    
    if(index >= 0 && index < icons){
        NSDictionary	*iconDict = [iconArray objectAtIndex:index];
        NSString	*iconPath = [iconDict objectForKey:@"Path"];
        NSString	*iconName;
        
        //Set the new icon in preferences
        iconName = [[iconPath lastPathComponent] stringByDeletingPathExtension];
        [[owner preferenceController] setPreference:iconName forKey:KEY_ACTIVE_DOCK_ICON group:PREF_GROUP_GENERAL];
        
        //Set the selected icon
        [self configureForSelectedIcon:[iconArray objectAtIndex:index]];        
    }
}

//Build our array of icons
- (void)_buildIconArray
{
    NSDirectoryEnumerator	*fileEnumerator;
    NSString			*iconPath;
    NSString			*filePath;
    int					curPath;

    //Create a fresh icon array
    [iconArray release]; iconArray = [[NSMutableArray alloc] init];

    for (curPath = 0; curPath < 2; curPath ++)
    {
        //
        if (curPath == 0)
            iconPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:FOLDER_DOCK_ICONS];
        else
            iconPath = [[ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByExpandingTildeInPath] stringByAppendingPathComponent:FOLDER_DOCK_ICONS];
            
        fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:iconPath];
        
        //Find all the .AdiumIcon's
        while((filePath = [fileEnumerator nextObject])){
            if([[filePath pathExtension] caseInsensitiveCompare:@"AdiumIcon"] == 0){
                NSString		*fullPath;
                AIIconState		*previewState;
                
                //Get the icon pack's full path and preview state
                fullPath = [iconPath stringByAppendingPathComponent:filePath];
                previewState = [[[[owner dockController] iconPackAtPath:fullPath] objectForKey:@"State"] objectForKey:@"Preview"];
    
                //Add this icon to our icon array
                [iconArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:fullPath, @"Path", previewState, @"State", nil]];
    
            }
        }
    }

    selectedIcon = [iconArray objectAtIndex:2];
    
    //Update our view
    [tableView_icons reloadData];
}

//Find an icon in the icon array with the specified name
- (NSDictionary *)_iconInArrayNamed:(NSString *)name
{
    NSEnumerator	*enumerator;
    NSDictionary	*iconDict;

    enumerator = [iconArray objectEnumerator];
    while((iconDict = [enumerator nextObject])){
        if([name compare:[[[iconDict objectForKey:@"Path"] lastPathComponent] stringByDeletingPathExtension]] == 0){
            return(iconDict);
        }
    }

    return(nil);
}

//
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    int	icons = [iconArray count];
    int	columns = [tableView numberOfColumns];
    int	requiredRows = ([iconArray count] / [tableView numberOfColumns]);

    if(icons % columns) requiredRows++; //Add an extra row to handle the remainder

    return(requiredRows);
}

//
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    int	icons = [iconArray count];
    int	columns = [tableView numberOfColumns];
    int index;

    index = (row * columns) + [tableView indexOfTableColumn:tableColumn];

    if(index >= 0 && index < icons){
        return([[[iconArray objectAtIndex:index] objectForKey:@"State"] image]);
    }else{
        return([[[NSImage alloc] init] autorelease]); //new blank for now
    }
}

//
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    int	icons = [iconArray count];
    int	columns = [tableView numberOfColumns];
    int index;

    index = (row * columns) + [tableView indexOfTableColumn:tableColumn];

    if(index >= 0 && index < icons && ([iconArray objectAtIndex:index] == selectedIcon)){
        [cell setHighlighted:YES];
    }else{
        [cell setHighlighted:NO];
    }

}

//
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row
{
    return(NO);
}

@end

