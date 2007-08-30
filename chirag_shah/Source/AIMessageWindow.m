//
//  AIMessageWindow.m
//  Adium
//
//  Created by Evan Schoenberg on 12/26/05.
//

#import "AIMessageWindow.h"
#import "AIClickThroughThemeDocumentButton.h"
#import <AIUtilities/AIApplicationAdditions.h>

/*!
 * @class AIMessageWindow
 * @brief This AIDockingWindow subclass serves message windows.
 *
 * It overrides the standardWindowButton:forStyleMask: class method to provide
 * AIClickThroughThemeDocumentButton objects for NSWindowDocumentIconButton requests on 10.4 and earlier.
 * Delegate methods in 10.5+ handle what we need.
 */
@implementation AIMessageWindow

/*!
 * @brief Return the standard window button for a mask
 *
 * We return AIClickThroughThemeDocumentButton instead of NSThemeDocumentButton to provide
 * click-through dragging behavior on 10.4 and earlier.
 */
+ (NSButton *)standardWindowButton:(NSWindowButton)button forStyleMask:(unsigned int)styleMask
{
	NSButton *standardWindowButton = [super standardWindowButton:button forStyleMask:styleMask];

	if (![NSApp isOnLeopardOrBetter]) {
		if (button == NSWindowDocumentIconButton) {
			[NSKeyedArchiver setClassName:@"AIClickThroughThemeDocumentButton" forClass:[NSThemeDocumentButton class]];
			standardWindowButton = [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:standardWindowButton]];
			
			[[standardWindowButton retain] autorelease];
		}
	}
	
	return standardWindowButton;
}

@end
