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

#import <Adium/AIAbstractListController.h>
#import <Adium/AIListObject.h>
#import <Adium/AIObject.h>
#import <AIUtilities/AIFunctions.h>
#import "AIContactList.h"

typedef enum {
	EVERY = 0,
    FRONT,
    NONFRONT
} LISTS;

@interface AIMultiListWindowController : AIObject {
	NSMutableArray	*contactListArray;
	AIContactList	*mostRecentContactList;
}

+ (AIMultiListWindowController *)initialize:(LIST_WINDOW_STYLE)windowStyle;
- (AIMultiListWindowController *)createWindows:(LIST_WINDOW_STYLE)windowStyle;
- (BOOL)createNewSeparableContactListWithObject:(AIListObject<AIContainingObject> *)newListObject;
- (AIContactList *)mostRecentContactList;
- (void)showWindowInFront:(BOOL)inFront;
- (void)showNextWindowInFront;
- (BOOL)isVisible;
- (BOOL)isMainWindow;
- (BOOL)isNotSlidOffScreen;
- (NSWindow *)window;
- (void)performClose;
- (AIRectEdgeMask)windowSlidOffScreenEdgeMask;
- (void)destroyListController:(AIContactList *)doneController;
- (AIContactList *)nextContactList;
- (AIContactList *)contactListWithContact:(AIListObject *)object;
- (void)selector:(SEL)aSelector withArgument:(id)argument toItem:(CONTACT_LIST_ITEM)item on:(LISTS)lists;

@end
