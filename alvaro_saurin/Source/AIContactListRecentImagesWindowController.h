//
//  AIContactListRecentImagesWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on 12/19/05.
//

#import <Adium/AIWindowController.h>

@class AIImageGridView, AIColoredBoxView, AIMenuItemView, AIContactListImagePicker;

@interface AIContactListRecentImagesWindowController : AIWindowController {
	IBOutlet	AIImageGridView	 *imageGridView;
	IBOutlet	AIColoredBoxView *coloredBox;
	IBOutlet	AIMenuItemView	 *menuItemView;

	AIContactListImagePicker *picker;
	SEL						 recentPictureSelector;

	int currentHoveredIndex;
}

+ (void)showWindowFromPoint:(NSPoint)inPoint
				imagePicker:(AIContactListImagePicker *)inPicker
	  recentPictureSelector:(SEL)inRecentPictureSelector;

- (void)positionFromPoint:(NSPoint)inPoint;

@end
