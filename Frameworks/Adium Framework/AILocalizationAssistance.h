typedef enum {
	AILOCALIZATION_MOVE_SELF = 0,
	AILOCALIZATION_MOVE_ANCHOR
} AILocalizationAnchorMovementType;

@interface NSObject (PRIVATE_AILocalizationControls)
- (void)_resizeWindow:(NSWindow *)inWindow leftBy:(float)difference;
- (void)_resizeWindow:(NSWindow *)inWindow rightBy:(float)difference;
- (void)setRightAnchorMovementType:(AILocalizationAnchorMovementType)inType;
- (void)_handleSizingWithOldFrame:(NSRect)oldFrame stringValue:(NSString *)inStringValue;
- (NSControl *)viewForSizing;
@end

#import "AILocalizationTextField.h"
#import "AILocalizationButton.h"
#import "AILocalizationButtonCell.h"