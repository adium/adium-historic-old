//
//  AIMessageWindow.m
//  Adium
//
//  Created by Evan Schoenberg on 12/26/05.
//

#import "AIMessageWindow.h"
#import "AIClickThroughThemeDocumentButton.h"

/*
 * @class AIMessageWindow
 * @brief This AIDockingWindow subclass serves message windows.
 *
 * It overrides the standardWindowButton:forStyleMask: class method to provide
 * AIClickThroughThemeDocumentButton objects for NSWindowDocumentIconButton requests.
 */
@implementation AIMessageWindow

/*
 * @brief Return the standard window button for a mask
 *
 * We return AIClickThroughThemeDocumentButton instead of NSThemeDocumentButton to provide
 * click-through dragging behavior.
 */
+ (NSButton *)standardWindowButton:(NSWindowButton)button forStyleMask:(unsigned int)styleMask
{
	NSButton *standardWindowButton = [super standardWindowButton:button forStyleMask:styleMask];

	if (button == NSWindowDocumentIconButton) {
		[NSKeyedArchiver setClassName:@"AIClickThroughThemeDocumentButton" forClass:[NSThemeDocumentButton class]];
		standardWindowButton = [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:standardWindowButton]];
	}
	
	return standardWindowButton;
}

@end
