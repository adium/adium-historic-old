/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#define ANIMATION_SPEED_CHANGE			0.50
#define ANIMATION_STATE_SWITCH_DELAY	1.00

#define DEFAULT_DOCK_ICON_NAME		@"Adiumy Green"

@interface AIDockIconPreferences (PRIVATE)
- (void)configureForSelectedIcon:(NSDictionary *)iconDict;
- (void)_buildIconArray;
- (NSDictionary *)_iconInArrayNamed:(NSString *)name;
- (void)setupPreferenceView;
- (void)animate:(NSTimer *)timer;
- (void)stateChange:(NSTimer *)timer;
- (void)_startAnimating;
- (void)_stopAnimating;
- (void)_createActiveFrameImageFromState:(AIIconState *)iconState;
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation AIDockIconPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Dock);
}
- (NSString *)label{
    return(AILocalizedString(@"Dock Icon", nil));
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
	activeFrameImage = nil;
	
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
	NSDictionary *userInfo = [notification userInfo];
	
    if(notification == nil || 
	   (([(NSString *)[userInfo objectForKey:@"Group"] isEqualToString:PREF_GROUP_GENERAL]) && 
		([[userInfo objectForKey:@"Key"] isEqualToString:KEY_ACTIVE_DOCK_ICON]))){

        NSDictionary	*iconDict;
        NSString		*iconName;

        //Set the selected icon
        iconName = [[adium preferenceController] preferenceForKey:KEY_ACTIVE_DOCK_ICON
															group:PREF_GROUP_GENERAL];
        iconDict = [self _iconInArrayNamed:iconName];
			
        [self configureForSelectedIcon:iconDict];
    }
}

//Configures our view for the passed icon being selected
- (void)configureForSelectedIcon:(NSDictionary *)iconDict
{
    NSDictionary	*iconPackDict;
    NSDictionary	*stateDict;
    NSEnumerator	*previewEnumerator, *stateEnumerator;
    NSArray			*stateArray;
    NSString		*state;
    NSArray			*previewArray;
    		
	if (selectedIconIndex >= 0 && selectedIconIndex < [iconArray count]) {
		int oldIndex = selectedIconIndex;
		
		//Set selectedIconIndex to -1 and stop animating so the state doesn't change after we've restored it
		selectedIconIndex = -1;
		[self _stopAnimating];
		
		AIIconState *theState = [selectedIcon objectForKey:@"Original State"];
		if (theState){
			[[iconArray objectAtIndex:oldIndex] setObject:theState
												   forKey:@"State"];
			[[matrix_iconPreview selectedCell] setImage:[theState image]];
		}
	}
	
	
    //Remember this as selected
    [selectedIcon release]; selectedIcon = [iconDict retain];

	selectedIconIndex = [iconArray indexOfObject:iconDict];
	[tableView_icons display];
			
    //
    iconPackDict = [[adium dockController] iconPackAtPath:[iconDict objectForKey:@"Path"]];

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
    [tableView_icons setNeedsDisplay:YES];
    //[self animate:nil];
}

//Start animating
- (void)_startAnimating
{
    if(!stateChangeTimer){
		stateToAnimate = nil;
		previewToAnimateEnumerator = nil;
		
		stateChangeTimer = [[NSTimer scheduledTimerWithTimeInterval:ANIMATION_STATE_SWITCH_DELAY
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
	[activeFrameImage release]; activeFrameImage = nil;
}

//Animate the preview icons
- (void)animate:(NSTimer *)timer
{
	[stateToAnimate nextFrame];
	
	[self _createActiveFrameImageFromState:stateToAnimate];
	
	//Update our view
	[tableView_icons setNeedsDisplay:YES];
}

- (void)stateChange:(NSTimer *)timer
{
	if (selectedIconIndex >= 0 && selectedIconIndex < [iconArray count]) {
		
		//Create an objectEnumerator if needed
		if (!previewToAnimateEnumerator)
			previewToAnimateEnumerator = [[previewStateArray objectEnumerator] retain];
		
		//Get the next state from the enumerator
		AIIconState *newStateToAnimate = [previewToAnimateEnumerator nextObject];
		
		//If we reached the end, make a new enumerator and start again
		if (!newStateToAnimate) {
			[previewToAnimateEnumerator release];
			previewToAnimateEnumerator = [[previewStateArray objectEnumerator] retain];
			
			newStateToAnimate = [previewToAnimateEnumerator nextObject];
		}
		
		//Set stateToAnimate to the new state
		[stateToAnimate release]; stateToAnimate = [newStateToAnimate retain];
		
		//Update the icon array
		[[iconArray objectAtIndex:selectedIconIndex] setObject:stateToAnimate
														forKey:@"State"];
		
		[self _createActiveFrameImageFromState:stateToAnimate];
		
		//Update our view
		[tableView_icons setNeedsDisplay:YES];
		
		//Destroy any current animation timer
		if (animationTimer) {
			[animationTimer invalidate];
			[animationTimer release];
			animationTimer = nil;
		}
		//Start an animation timer for this frame if needed
		if ([stateToAnimate animated]) {
			animationTimer = [[NSTimer scheduledTimerWithTimeInterval:[stateToAnimate animationDelay] * ANIMATION_SPEED_CHANGE
															   target:self
															 selector:@selector(animate:)
															 userInfo:nil
															  repeats:YES] retain];
		}
	}
}

- (void)_createActiveFrameImageFromState:(AIIconState *)iconState
{
	NSImage *image = [iconState image];
	if(image){
		NSSize  size = [image size];
		if(size.width != 0 && size.height != 0){
			[activeFrameImage release]; activeFrameImage = nil;
			
			activeFrameImage = [[NSImage alloc] initWithSize:size];
			
			[activeFrameImage setFlipped:YES];
			[activeFrameImage lockFocus];
			[image drawAtPoint:NSMakePoint(0,0)
					  fromRect:NSMakeRect(0,0,size.width,size.height)
					 operation:NSCompositeSourceOver
					  fraction:1.0];
			[activeFrameImage unlockFocus];
		}
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
	NSEnumerator		*enumerator;

    //Create a fresh icon array
    [iconArray release]; iconArray = [[NSMutableArray alloc] init];
	
	enumerator = [[adium resourcePathsForName:FOLDER_DOCK_ICONS] objectEnumerator];
	
    while(iconPath = [enumerator nextObject]) {            
        fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:iconPath];
        
        //Find all the .AdiumIcon's
        while((filePath = [fileEnumerator nextObject])){
            if([[filePath pathExtension] caseInsensitiveCompare:@"AdiumIcon"] == 0){
                NSString		*fullPath;
                AIIconState		*previewState;
                
                //Get the icon pack's full path and preview state
                fullPath = [iconPath stringByAppendingPathComponent:filePath];
				previewState = [[adium dockController] previewStateForIconPackAtPath:fullPath];
    
                //Add this icon to our icon array
                [iconArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:fullPath, @"Path", previewState, @"State", previewState, @"Original State", nil]];    
            }
        }
    }

	[selectedIcon release];
    selectedIcon = nil;
    
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
        if([name isEqualToString:[[[iconDict objectForKey:@"Path"] lastPathComponent] stringByDeletingPathExtension]]){
            return(iconDict);
        }
    }

    return(nil);
}

// delete support, via table delegate and nifty dialog + move to trash
- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView
{            
	NSString	*selectedIconPath = [[iconArray objectAtIndex:selectedIconIndex] valueForKey:@"Path"];
	NSString	*name = [[selectedIconPath lastPathComponent] stringByDeletingPathExtension];
	
	//Deleting the default would be messy.  Just don't let it happen.
	if (![name isEqualToString:DEFAULT_DOCK_ICON_NAME]){
		NSBeginAlertSheet(AILocalizedString(@"Delete Dock Icon",nil),
						  AILocalizedString(@"Delete",nil),
						  AILocalizedString(@"Cancel",nil),
						  @"",
						  [[self view] window], 
						  self, 
						  @selector(trashConfirmSheetDidEnd:returnCode:contextInfo:), /* Did end selector */
						  nil,  /* Did dismiss selector */
						  selectedIconPath, /* Context Info */
						  AILocalizedString(@"Are you sure you want to delete the %@ Dock Icon? It will be moved to the Trash.",nil), name);
	}
}

- (void)trashConfirmSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(NSString *)selectedIconPath
{
    if(returnCode == NSOKButton)
    {
		//We are deleting the currently selected icon, so reset to the default
		[[adium preferenceController] setPreference:DEFAULT_DOCK_ICON_NAME
											 forKey:KEY_ACTIVE_DOCK_ICON 
											  group:PREF_GROUP_GENERAL];		
		
		//We don't want to try loading a new image after we trash the dock icon folder
		[self _stopAnimating];
		
		//Trash the file
		[[NSFileManager defaultManager] trashFileAtPath:selectedIconPath];

		//Rebuild the icon array
		[self _buildIconArray];
    }
}
// ----- end trashiness -------

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
		AIIconState *iconState = [[iconArray objectAtIndex:index] objectForKey:@"State"];
		if (iconState == stateToAnimate) {
			return activeFrameImage;
		} else {
			return [iconState image];
		}
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

