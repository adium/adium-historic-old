//
//  AIListContactCell.h
//  Adium
//
//  Created by Adam Iser on Tue Jul 27 2004.
//

#import "AIListCell.h"
#import "AIListLayoutWindowController.h"

@interface AIListContactCell : AIListCell {
	BOOL				userIconVisible;
	BOOL				extendedStatusVisible;
	BOOL				statusIconsVisible;
	BOOL				serviceIconsVisible;
	NSSize				userIconSize;
	int					statusFontHeight;
	int					labelFontHeight;
			
	BOOL				backgroundColorIsStatus;

	LIST_POSITION		userIconPosition;
	LIST_POSITION		statusIconPosition;
	LIST_POSITION		serviceIconPosition;
	BOOL				extendedStatusIsBelowName;
	
	float				backgroundOpacity;

	NSFont				*statusFont;
	NSColor				*statusColor;

	NSDictionary		*_statusAttributes;
	NSMutableDictionary	*_statusAttributesInverted;
}

//Status Text
- (void)setStatusFont:(NSFont *)inFont;
- (NSFont *)statusFont;
- (NSDictionary *)statusAttributes;
- (NSDictionary *)statusAttributesInverted;
- (void)setTextAlignment:(NSTextAlignment)inAlignment;
- (void)setStatusColor:(NSColor *)inColor;
- (NSColor *)statusColor;

//Display options
- (void)setUserIconVisible:(BOOL)inShowIcon;
- (BOOL)userIconVisible;
- (void)setUserIconSize:(int)inSize;
- (int)userIconSize;
- (void)setExtendedStatusVisible:(BOOL)inShowStatus;
- (BOOL)extendedStatusVisible;
- (void)setStatusIconsVisible:(BOOL)inShowStatus;
- (BOOL)statusIconsVisible;
- (void)setServiceIconsVisible:(BOOL)inShowService;
- (BOOL)serviceIconsVisible;
- (void)setExtendedStatusIsBelowName:(BOOL)inBelowName;
- (void)setUserIconPosition:(LIST_POSITION)inPosition;
- (void)setStatusIconPosition:(LIST_POSITION)inPosition;
- (void)setServiceIconPosition:(LIST_POSITION)inPosition;
- (void)setBackgroundOpacity:(float)inOpacity;
- (float)backgroundOpacity;
- (void)setFont:(NSFont *)inFont;
- (void)setBackgroundColorIsStatus:(BOOL)isStatus;

//Drawing
- (void)drawContentWithFrame:(NSRect)rect;
- (void)drawBackgroundWithFrame:(NSRect)rect;
- (NSRect)drawUserIconInRect:(NSRect)inRect position:(IMAGE_POSITION)position;
- (NSRect)drawStatusIconInRect:(NSRect)rect position:(IMAGE_POSITION)position;
- (NSRect)drawServiceIconInRect:(NSRect)rect position:(IMAGE_POSITION)position;
- (NSRect)drawUserExtendedStatusInRect:(NSRect)rect drawUnder:(BOOL)drawUnder;
- (NSColor *)labelColor;
- (NSColor *)textColor;
- (NSImage *)userIconImage;
- (NSImage *)statusImage;
- (NSImage *)serviceImage;
//- (BOOL)drawStatusBelowLabelInRect:(NSRect)rect;
- (BOOL)drawGridBehindCell;
- (float)imageOpacityForDrawing;

@end
