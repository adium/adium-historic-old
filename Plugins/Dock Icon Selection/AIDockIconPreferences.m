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
#define DEFAULT_DOCK_ICON_NAME		@"Adiumy Green"

@interface AIDockIconPreferences (PRIVATE)
- (void)_buildIconArray;
- (void)selectIconWithName:(NSString *)selectName;
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
	//Init
	animatedIndex = -1;
	iconArray = nil;
    [self _buildIconArray];

	//Setup our image grid
	[imageGridView_icons setImageSize:NSMakeSize(64,64)];

    //Observe xtras changes
	[[adium notificationCenter] addObserver:self
								   selector:@selector(xtrasChanged:)
									   name:Adium_Xtras_Changed
									 object:nil];
}

//Preference view is closing
- (void)viewWillClose
{
    [[adium notificationCenter] removeObserver:self];
    [self setAnimatedDockIconAtIndex:-1];

	[iconArray release]; iconArray = nil;
}

//When the xtras are changed, update our icons
- (void)xtrasChanged:(NSNotification *)notification
{
	if([[notification object] caseInsensitiveCompare:@"AdiumIcon"] == 0){
		[self _buildIconArray];
	}
}

//Build an array of available icon packs
- (void)_buildIconArray
{
    NSDirectoryEnumerator	*fileEnumerator;
    NSString				*iconPath;
    NSString				*filePath;
	NSEnumerator			*enumerator;

    //Create a fresh icon array
    [iconArray release]; iconArray = [[NSMutableArray alloc] init];
	enumerator = [[adium resourcePathsForName:FOLDER_DOCK_ICONS] objectEnumerator];
	
    while(iconPath = [enumerator nextObject]) {            
        fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:iconPath];
        
        //Find all the .AdiumIcon's
        while((filePath = [fileEnumerator nextObject])){
            if([[filePath pathExtension] caseInsensitiveCompare:@"AdiumIcon"] == NSOrderedSame){
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
    
    //Update our view and re-select the correct icon
	[imageGridView_icons reloadData];
	[self selectIconWithName:[[adium preferenceController] preferenceForKey:KEY_ACTIVE_DOCK_ICON group:PREF_GROUP_GENERAL]];
}

//Set the selected icon by name
- (void)selectIconWithName:(NSString *)selectName
{
	NSEnumerator	*enumerator = [iconArray objectEnumerator];
	NSDictionary	*iconDict;
	int				index = 0;
	
	while(iconDict = [enumerator nextObject]){
		NSString	*iconName = [[[iconDict objectForKey:@"Path"] lastPathComponent] stringByDeletingPathExtension]		;
		if([iconName isEqualToString:selectName]){
			[imageGridView_icons selectIndex:index];
			break; //we can exit early
		}
		index++;
	}
}


//Animation ------------------------------------------------------------------------------------------------------------
#pragma mark Animation
//Start animating an icon in our grid by index (pass -1 to stop animation)
- (void)setAnimatedDockIconAtIndex:(int)index
{
	//Schedule the old and new animating images for redraw
	[imageGridView_icons setNeedsDisplayOfImageAtIndex:animatedIndex];
	[imageGridView_icons setNeedsDisplayOfImageAtIndex:index];
	
	//Stop the current animation
    if(animationTimer){
        [animationTimer invalidate];
        [animationTimer release];
        animationTimer = nil;
	}
	[animatedIconState release]; animatedIconState = nil;
	animatedIndex = -1;

	//Start the new animation
	if(index != -1){
		NSString	*path = [[iconArray objectAtIndex:index] objectForKey:@"Path"];

		animatedIconState = [[self animatedStateForDockIconAtPath:path] retain];
		animatedIndex = index;
		animationTimer = [[NSTimer scheduledTimerWithTimeInterval:[animatedIconState animationDelay]
														   target:self
														 selector:@selector(animate:)
														 userInfo:nil
														  repeats:YES] retain];
    }
}

//Returns an animated AIIconState for the dock icon pack at the specified path
- (AIIconState *)animatedStateForDockIconAtPath:(NSString *)path
{
	NSDictionary 	*iconPackDict = [[adium dockController] iconPackAtPath:path];
	NSDictionary	*stateDict = [iconPackDict objectForKey:@"State"];
	
	return([[[AIIconState alloc] initByCompositingStates:[NSArray arrayWithObjects:
		[stateDict objectForKey:@"Base"],
		[stateDict objectForKey:@"Online"],
		[stateDict objectForKey:@"Alert"], nil]] autorelease]);
}

//Animate the hovered icon
- (void)animate:(NSTimer *)timer
{
	[animatedIconState nextFrame];
	[imageGridView_icons setNeedsDisplayOfImageAtIndex:animatedIndex];
}

//ImageGridView Delegate -----------------------------------------------------------------------------------------------
#pragma mark ImageGridView Delegate
- (int)numberOfImagesInImageGridView:(AIImageGridView *)imageGridView
{
	return([iconArray count]);
}

- (NSImage *)imageGridView:(AIImageGridView *)imageGridView imageAtIndex:(int)index
{
	if(index == animatedIndex){
		return([animatedIconState image]);
	}else{
		return([[[iconArray objectAtIndex:index] objectForKey:@"State"] image]);
	}
}

- (void)imageGridViewSelectionDidChange:(NSNotification *)notification
{	
	NSDictionary	*iconDict = [iconArray objectAtIndex:[imageGridView_icons selectedIndex]];
	NSString		*iconName = [[[iconDict objectForKey:@"Path"] lastPathComponent] stringByDeletingPathExtension];
	
	[[adium preferenceController] setPreference:iconName forKey:KEY_ACTIVE_DOCK_ICON group:PREF_GROUP_GENERAL];
}

- (void)imageGridView:(AIImageGridView *)imageGridView cursorIsHoveringImageAtIndex:(int)index
{
	[self setAnimatedDockIconAtIndex:index];
}


//Deleting dock xtras --------------------------------------------------------------------------------------------------
#pragma mark Deleting dock xtras
//Delete the selected dock icon
- (void)imageGridViewDeleteSelectedImage:(AIImageGridView *)imageGridView
{            
	NSString	*selectedIconPath = [[iconArray objectAtIndex:[imageGridView selectedIndex]] valueForKey:@"Path"];
	NSString	*name = [[selectedIconPath lastPathComponent] stringByDeletingPathExtension];
	
	//We need atleast one icon installed, so prevent the user from deleting the default icon
	if(![name isEqualToString:DEFAULT_DOCK_ICON_NAME]){
		NSBeginAlertSheet(AILocalizedString(@"Delete Dock Icon",nil),
						  AILocalizedString(@"Delete",nil),
						  AILocalizedString(@"Cancel",nil),
						  @"",
						  [[self view] window], 
						  self, 
						  @selector(trashConfirmSheetDidEnd:returnCode:contextInfo:),
						  nil,
						  selectedIconPath,
						  AILocalizedString(@"Are you sure you want to delete the %@ Dock Icon? It will be moved to the Trash.",nil), name);
	}
}
- (void)trashConfirmSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(NSString *)selectedIconPath
{
    if(returnCode == NSOKButton){
		int deletedIndex = [imageGridView_icons selectedIndex];
		
		//Deselect and stop animating
		[self setAnimatedDockIconAtIndex:-1];
		[imageGridView_icons selectIndex:-1];
		
		//Trash the file & Rebuild our icons
		[[NSFileManager defaultManager] trashFileAtPath:selectedIconPath];
		[self _buildIconArray];

		//Select the next available icon
		[imageGridView_icons selectIndex:deletedIndex];
    }
}

@end

