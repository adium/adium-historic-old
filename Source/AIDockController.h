/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import <Adium/AIObject.h>

#define Dock_IconWillChange			@"Dock_IconWillChange"
#define Dock_IconDidChange			@"Dock_IconDidChange"

#define PREF_GROUP_APPEARANCE		@"Appearance"

#define KEY_ACTIVE_DOCK_ICON		@"Dock Icon"
#define FOLDER_DOCK_ICONS			@"Dock Icons"

#define KEY_ANIMATE_DOCK_ICON	@"Animate Dock Icon on Unread Messages"
#define KEY_BADGE_DOCK_ICON		@"Badge Dock Icon on Unread Messages"

@class AIIconState;

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

@protocol AIController, AIFlashObserver;

@interface AIDockController: AIObject <AIController, AIFlashObserver> {
    NSTimer 				*animationTimer;
    NSTimer					*bounceTimer;
    
    NSMutableDictionary		*availableIconStateDict;
    NSMutableDictionary		*availableDynamicIconStateDict;
    NSMutableArray			*activeIconStateArray;
    AIIconState				*currentIconState;
    
    int						currentAttentionRequest;
	
    BOOL					observingFlash;
    BOOL					needsDisplay;
	
	NSTimeInterval			currentBounceInterval;
	}

//Icon animation & states
- (void)setIconStateNamed:(NSString *)inName;
- (void)removeIconStateNamed:(NSString *)inName;
- (void)setIconState:(AIIconState *)iconState named:(NSString *)inName;
- (float)dockIconScale;
- (NSImage *)baseApplicationIconImage;

//Special access to icon pack loading
- (NSArray *)availableDockIconPacks;
- (BOOL)currentIconSupportsIconStateNamed:(NSString *)inName;;
- (NSMutableDictionary *)iconPackAtPath:(NSString *)folderPath;
- (void)getName:(NSString **)outName previewState:(AIIconState **)outIconState forIconPackAtPath:(NSString *)folderPath;
- (AIIconState *)previewStateForIconPackAtPath:(NSString *)folderPath;

//Bouncing & behavior
- (void)performBehavior:(DOCK_BEHAVIOR)behavior;
- (NSString *)descriptionForBehavior:(DOCK_BEHAVIOR)behavior;

@end
