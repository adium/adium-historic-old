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
 
#define Dock_IconWillChange			@"Dock_IconWillChange"
#define Dock_IconDidChange			@"Dock_IconDidChange"

#define KEY_ACTIVE_DOCK_ICON		@"Dock Icon"
#define KEY_LAST_VERSION_LAUNCHED	@"Last Version Launched"
#define FOLDER_DOCK_ICONS			@"Dock Icons"

typedef enum {
    BOUNCE_NONE = 0,
    BOUNCE_ONCE,
    BOUNCE_REPEAT,
    BOUNCE_DELAY5,
    BOUNCE_DELAY10,
    BOUNCE_DELAY15,
    BOUNCE_DELAY30,
    BOUNCE_DELAY60
} DOCK_BEHAVIOR;

@protocol AIFlashObserver;

@interface AIDockController: NSObject <AIFlashObserver> {
    IBOutlet	AIAdium 	*owner;
	
    NSTimer 				*animationTimer;
    NSTimer					*bounceTimer;
    
    NSMutableDictionary		*availableIconStateDict;
    NSMutableDictionary		*availableDynamicIconStateDict;
    NSMutableArray			*activeIconStateArray;
    AIIconState				*currentIconState;
    
    int						currentAttentionRequest;
	
    BOOL					observingFlash;
    BOOL					needsDisplay;
}

//Icon animation & states
- (void)setIconStateNamed:(NSString *)inName;
- (void)removeIconStateNamed:(NSString *)inName;
- (void)setIconState:(AIIconState *)iconState named:(NSString *)inName;
- (float)dockIconScale;

//Special access to icon pack loading
- (NSMutableDictionary *)iconPackAtPath:(NSString *)folderPath;

//Bouncing & behavior
- (void)performBehavior:(DOCK_BEHAVIOR)behavior;
- (NSString *)descriptionForBehavior:(DOCK_BEHAVIOR)behavior;

//Private
- (void)initController;
- (void)closeController;

@end
