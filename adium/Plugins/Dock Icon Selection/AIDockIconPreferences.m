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

#import "AIDockIconPreferences.h"
#import "AIDockIconSelectionPlugin.h"

#define PREF_GROUP_DOCK_ICON		@"Dock Icon"

@interface AIDockIconPreferences (PRIVATE)
- (void)configureForSelectedIcon:(NSDictionary *)iconDict;
- (void)_buildIconArray;
- (NSDictionary *)_iconInArrayNamed:(NSString *)name;
- (void)setupPreferenceView;
- (void)animate:(NSTimer *)timer;
- (void)stateChange:(NSTimer *)timer;
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
    return(AILocalizedString(@"Dock Icon", nil))
}
- (NSString *)nibName{
    return(@"IconSelectionPrefs");
}

//Setup our preference view
- (void)viewDidLoad
{
    NSEnumerator	*enumerator;
    NSTableColumn	*column;

	cycle = -1;
    animationTimer = nil;
	stateChangeTimer = nil;
	selectedIconIndex = -1;
	selectedIcon = nil;
	
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
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];
    
    //Start animating
    [self _startAnimating];
}

//Preference view is closing
- (void)viewWillClose
{
    [iconArray release]; iconArray = nil;
    [previewStateArray release]; previewStateArray = nil;
    [selectedIcon release]; selectedIcon = nil;
	
    //Stop animating
    [self _stopAnimating];
    
    //
    [[adium notificationCenter] removeObserver:self];
}

//Preferences have changed
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_GENERAL] == 0){
        NSDictionary 	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_GENERAL];
        NSDictionary	*iconDict;
        NSString	*iconName;

        //Set the selected icon
        iconName = [preferenceDict objectForKey:KEY_ACTIVE_DOCK_ICON];
        iconDict = [self _iconInArrayNamed:iconName];
		

        [self configureForSelectedIcon:iconDict];
		selectedIconIndex = [iconArray indexOfObject:iconDict];        
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
    
	if (selectedIconIndex != -1) {
		int oldIndex = selectedIconIndex;
		
		//Set selectedIconIndex to -1 and stop animating so the state doesn't change after we've restored it
		selectedIconIndex = -1;
		[self _stopAnimating];
		
		[[iconArray objectAtIndex:oldIndex] setObject:[selectedIcon objectForKey:@"Original State"]
													  forKey:@"State"];
		[[matrix_iconPreview selectedCell] setImage:[[selectedIcon objectForKey:@"Original State"] image]];
	}
	
	
    //Remember this as selected
	//LEAKING?
    [selectedIcon release]; selectedIcon = [[iconDict copy] retain];

    //
    iconPackDict = [[adium dockController] iconPackAtPath:[iconDict objectForKey:@"Path"]];

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
        AIIconState		*tempIconState;

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

//Start animating
- (void)_startAnimating
{
    if(!stateChangeTimer){
		stateToAnimate = nil;
		previewToAnimateEnumerator = nil;
		
		stateChangeTimer = [[NSTimer scheduledTimerWithTimeInterval:2 
															 target:self 
														   selector:@selector(stateChange:)
														   userInfo:nil
															repeats:YES] retain];
		[self stateChange:nil];
    }
}

- (void)_stopAnimating
{
    if(animationTimer){
        [animationTimer invalidate];
        [animationTimer release];
        animationTimer = nil;
	}
	
	if(stateChangeTimer){
		[stateChangeTimer invalidate];
		[stateChangeTimer release];
		stateChangeTimer = nil;
	}
	
	[stateToAnimate release]; stateToAnimate = nil;
	[previewToAnimateEnumerator release]; previewToAnimateEnumerator = nil;
}

//Animate the preview icons
- (void)animate:(NSTimer *)timer
{
	[stateToAnimate nextFrame];
	[[matrix_iconPreview selectedCell] setImage:[stateToAnimate image]];
	
	//Redisplay now.
	[tableView_icons display];
}

- (void)stateChange:(NSTimer *)timer
{
	if (!previewToAnimateEnumerator)
		previewToAnimateEnumerator = [[previewStateArray objectEnumerator] retain];

	AIIconState *newStateToAnimate = [previewToAnimateEnumerator nextObject];
	
	//If we reached the end, make a new enumerator and start again
	if (!newStateToAnimate) {
		[previewToAnimateEnumerator release];
		previewToAnimateEnumerator = [[previewStateArray objectEnumerator] retain];
		
		newStateToAnimate = [previewToAnimateEnumerator nextObject];
	}
	
	[stateToAnimate release]; stateToAnimate = [newStateToAnimate retain];

	if (selectedIconIndex != -1) {
		[[iconArray objectAtIndex:selectedIconIndex] setObject:stateToAnimate
														forKey:@"State"];
	}
	
	NSLog(@"flipped? %i animated=%i",[[stateToAnimate image] isFlipped],[stateToAnimate animated]);
	//Set the image to the new state
	[[matrix_iconPreview selectedCell] setImage:[stateToAnimate image]];
	
	//Update our view
	[tableView_icons setNeedsDisplay:YES];
	
	if (animationTimer) {
		[animationTimer invalidate];
        [animationTimer release];
        animationTimer = nil;
	}
	if ([stateToAnimate animated]) {
		//Start the flash timer
		animationTimer = [[NSTimer scheduledTimerWithTimeInterval:[stateToAnimate animationDelay]
														   target:self
														 selector:@selector(animate:)
														 userInfo:nil
														  repeats:YES] retain];
		
		//Move to the first frame of animation
		//			[self animateIcon:animationTimer]; //Set the icon and move to the next frame
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
        [[adium preferenceController] setPreference:iconName forKey:KEY_ACTIVE_DOCK_ICON group:PREF_GROUP_GENERAL];
        
        //Set the selected icon
        [self configureForSelectedIcon:[iconArray objectAtIndex:index]];
        
		selectedIconIndex = index;
    }
	[self _startAnimating];
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
                previewState = [[[[adium dockController] iconPackAtPath:fullPath] objectForKey:@"State"] objectForKey:@"Preview"];
    
                //Add this icon to our icon array
                [iconArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:fullPath, @"Path", previewState, @"State", previewState, @"Original State", nil]];
    
            }
        }
    }

	[selectedIcon release];
    selectedIcon = [[iconArray objectAtIndex:2] copy];
    
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
		return [[[iconArray objectAtIndex:index] objectForKey:@"State"] image];
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

    if(index >= 0 && index < icons && (index == selectedIconIndex)){
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

