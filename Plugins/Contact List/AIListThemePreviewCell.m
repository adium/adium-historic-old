//
//  AIListThemePreviewCell.m
//  Adium
//
//  Created by Adam Iser on 8/11/04.
//

#import "AIListThemePreviewCell.h"
#import "AIListThemeWindowController.h"

@implementation AIListThemePreviewCell

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	AIListThemePreviewCell *newCell = [super copyWithZone:zone];
	
	newCell->themeDict = nil;
	[newCell setThemeDict:themeDict];
	
	newCell->colorKeyArray = [colorKeyArray retain];
	
	return(newCell);
}

- (id)init
{
	[super init];
	
	themeDict = nil;
	colorKeyArray = [[NSArray arrayWithObjects:
		KEY_LABEL_AWAY_COLOR,
		KEY_LABEL_IDLE_COLOR,
		KEY_LABEL_TYPING_COLOR,
		KEY_LABEL_SIGNED_OFF_COLOR,
		KEY_LABEL_SIGNED_ON_COLOR,
		KEY_LABEL_UNVIEWED_COLOR,
		KEY_LABEL_ONLINE_COLOR,
		KEY_LABEL_IDLE_AWAY_COLOR,
		KEY_LABEL_OFFLINE_COLOR,
		
		KEY_AWAY_COLOR,
		KEY_IDLE_COLOR,
		KEY_TYPING_COLOR,
		KEY_SIGNED_OFF_COLOR,
		KEY_SIGNED_ON_COLOR,
		KEY_UNVIEWED_COLOR,
		KEY_ONLINE_COLOR,
		KEY_IDLE_AWAY_COLOR,
		KEY_OFFLINE_COLOR,
		
		KEY_LIST_THEME_BACKGROUND_COLOR,
		KEY_LIST_THEME_GRID_COLOR,
		
		KEY_LIST_THEME_GROUP_BACKGROUND,
		KEY_LIST_THEME_GROUP_BACKGROUND_GRADIENT,
		nil] retain];
	
	return(self);
}

- (void)dealloc
{
	[themeDict release];
	[colorKeyArray release];
	[super dealloc];
}

- (void)setThemeDict:(NSDictionary *)inDict
{
	if(inDict != themeDict){
		[themeDict release];
		themeDict = [inDict retain];
	}
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	cellFrame.origin.y += 2;
	cellFrame.size.height -= 4;
	
	NSEnumerator	*enumerator = [colorKeyArray objectEnumerator];
	NSString		*key;
	NSRect			segmentRect = NSMakeRect(cellFrame.origin.x, cellFrame.origin.y,
											 (cellFrame.size.width / [colorKeyArray count]), cellFrame.size.height);
	
	[[NSColor whiteColor] set];
	[NSBezierPath fillRect:cellFrame];
	
	while(key = [enumerator nextObject]){
		NSLog(@"%@ %@",[themeDict objectForKey:key],[[themeDict objectForKey:key] representedColor]);
		[[[themeDict objectForKey:key] representedColor] set];
		[NSBezierPath fillRect:segmentRect];
		segmentRect.origin.x += segmentRect.size.width;
	}

	[[NSColor blackColor] set];
	[NSBezierPath strokeRect:NSOffsetRect(cellFrame, .5, .5)];
	
}

@end
