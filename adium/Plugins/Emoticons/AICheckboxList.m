//
//  AICheckboxList.m
//  Adium
//
//  Created by Ian Krieg on Sat Jul 05 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AICheckboxList.h"

#define	LIST_CHECKBOX_HEIGHT	18.0

@interface AICheckboxList (PRIVATE)

- (unsigned int)findNameIndex:(NSString*) name;	// Returns the size of the array if the name is not present
- (void)doLayout;
@end

@implementation AICheckboxList

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		NSRect	rect;
		rect.origin.x = rect.origin.y = 0.0;
		rect.size.width = [self contentSize].width;
		rect.size.height = 2;
	
        checkboxes = [[NSMutableArray alloc] initWithCapacity:5];
		nextOffset = 0.0;
		content = [[NSView alloc] initWithFrame:rect];
		[self setDocumentView:content];
    }
    return self;
}

- (void)dealloc {
	[checkboxes release];
}

//- (void)drawRect:(NSRect)rect {
    // Drawing code here.
//}

- (BOOL)addItemName:(NSString*)name state:(int)state
{
	unsigned int ind = [self findNameIndex:name];
	
	if (ind != [checkboxes count])
		return FALSE;
	else
	{
		// Make & Configure checkbox
		NSRect	listBnd = [content bounds];
		NSButton*	btn = [[NSButton alloc] initWithFrame:NSMakeRect(0, nextOffset, listBnd.size.width, LIST_CHECKBOX_HEIGHT)];
		nextOffset += LIST_CHECKBOX_HEIGHT;
		
		[btn setAllowsMixedState:TRUE];
		[btn setState:state];
		[btn setButtonType:NSSwitchButton];
		[btn setTitle:name];
		
		listBnd.size.height = MAX (listBnd.size.height, ([checkboxes count] + 1) * LIST_CHECKBOX_HEIGHT);
		
		// Add Checkbox to List and View
		[checkboxes addObject:btn];
		[content setBounds:listBnd];
		[content addSubview:btn];
		
		return TRUE;
	}
}

- (int)itemState:(NSString*)name
{
	unsigned int ind = [self findNameIndex:name];
	NSButton*	btn = [checkboxes objectAtIndex:ind];
	
	return [btn state];
}

- (void)setItemState:(NSString*)name	state:(int)state
{
	unsigned int ind = [self findNameIndex:name];
	NSButton*	btn = [checkboxes objectAtIndex:ind];
	
	[btn setState:state];
}

- (void)removeItemName:(NSString*)name
{
	unsigned int ind = [self findNameIndex:name];
	NSButton*	btn = [checkboxes objectAtIndex:ind];
	
	nextOffset -= LIST_CHECKBOX_HEIGHT;
	
	[btn removeFromSuperview];
	[checkboxes removeObjectAtIndex:ind];
	
	[self doLayout];
}

- (unsigned int)findNameIndex:(NSString*) name
{
	NSEnumerator	*numer = [checkboxes objectEnumerator];
	NSButton		*btn;
	unsigned int	i = 0;
	
	while (btn = [numer nextObject])
	{
		if ([[btn title] compare:name] == 0)
		{
			return i;
		}
		i++;
	}
	
	return i;
}

- (void)doLayout
{
	float	curLoc = 0.0;
	NSRect	boundsRect = [content bounds],
			rect;
	NSEnumerator	*numer = [checkboxes objectEnumerator];
	NSButton		*btn;
	
	boundsRect.size.height = LIST_CHECKBOX_HEIGHT * [checkboxes count];
	
	while (btn = [numer nextObject])
	{
		rect = [btn frame];
		rect.origin.y = curLoc;
		rect.origin.x = 0.0;
		curLoc += LIST_CHECKBOX_HEIGHT;
		
		[btn setFrame:rect];
	}
	
	[content setBounds:boundsRect];
}
@end
