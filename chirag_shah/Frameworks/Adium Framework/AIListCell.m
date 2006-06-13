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

#import "AIListCell.h"
#import "AIListGroup.h"
#import "AIListObject.h"
#import "AIListOutlineView.h"
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIMutableOwnerArray.h>
#import <AIUtilities/AIParagraphStyleAdditions.h>

//#define	ORDERING_DEBUG

@implementation AIListCell

static NSMutableParagraphStyle	*leftParagraphStyleWithTruncatingTail = nil;

//Init
- (id)init
{
    if ((self = [super init]))
	{
		   topSpacing = 
		bottomSpacing = 
		  leftSpacing = 
		 rightSpacing = 0;

		   topPadding = 
		bottomPadding = 
		  leftPadding = 
		 rightPadding = 0;
		
		font = [[NSFont systemFontOfSize:12] retain];
		textColor = [[NSColor blackColor] retain];
		invertedTextColor = [[NSColor whiteColor] retain];
		
		useAliasesAsRequested = YES;

		if (!leftParagraphStyleWithTruncatingTail) {
			leftParagraphStyleWithTruncatingTail = [[NSMutableParagraphStyle styleWithAlignment:NSLeftTextAlignment
																				  lineBreakMode:NSLineBreakByTruncatingTail] retain];
		}
	}
		
    return self;
}

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	AIListCell *newCell = [super copyWithZone:zone];

	newCell->listObject = nil;
	[newCell setListObject:listObject];

	[newCell->font retain];
	[newCell->textColor retain];
	[newCell->invertedTextColor retain];

	return newCell;
}

//Dealloc
- (void)dealloc
{
	[textColor release];
	[invertedTextColor release];
	
	[font release];
	
	[listObject release];

	[super dealloc];
}

//Set the list object being drawn
- (void)setListObject:(AIListObject *)inObject
{
	if (inObject != listObject) {
		[listObject release];
		listObject = [inObject retain];

		isGroup = [listObject isKindOfClass:[AIListGroup class]];
	}
}
- (BOOL)isGroup{
	return isGroup;
}

//Set our control view (Better than passing this around like crazy)
- (void)setControlView:(AIListOutlineView *)inControlView
{
	controlView = inControlView;
}


//Display options ------------------------------------------------------------------------------------------------------
#pragma mark Display options
//Font used to display label
- (void)setFont:(NSFont *)inFont
{
	if (inFont != font) {
		[font release];
		font = [inFont retain];
	}

	//Calculate and cache the height of this font
	labelFontHeight = [NSAttributedString stringHeightForAttributes:[NSDictionary dictionaryWithObject:[self font] forKey:NSFontAttributeName]]; 
}
- (NSFont *)font{
	return font;
}

//Alignment of label text
- (void)setTextAlignment:(NSTextAlignment)inAlignment
{
	textAlignment = inAlignment;
}
- (NSTextAlignment)textAlignment{
	return textAlignment;
}

//Text color
- (void)setTextColor:(NSColor *)inColor
{
	if (inColor != textColor) {
		[textColor release];
		textColor = [inColor retain];
	}
}
- (NSColor *)textColor{
	return textColor;
}

- (void)setInvertedTextColor:(NSColor *)inColor
{
	if (inColor != invertedTextColor) {
		[invertedTextColor release];
		invertedTextColor = [inColor retain];
	}
}
- (NSColor *)invertedTextColor{
	return invertedTextColor;
}


//Cell sizing and padding ----------------------------------------------------------------------------------------------
#pragma mark Cell sizing and padding
//Default cell size just contains our padding and spacing
- (NSSize)cellSize
{
	return NSMakeSize(0, [self topSpacing] + [self topPadding] + [self bottomPadding] + [self bottomSpacing]);
}

- (int)cellWidth
{
	return [self leftSpacing] + [self leftPadding] + [self rightPadding] + [self rightSpacing];
}

//User-defined spacing offsets.  A cell may adjust these values to to obtain a more desirable default. 
//These are offsets, they may be negative!  Spacing is the distance between cells (Spacing gaps are not filled).
- (void)setSplitVerticalSpacing:(int)inSpacing{
	topSpacing = inSpacing / 2;
	bottomSpacing = (inSpacing + 1) / 2;
}
- (void)setTopSpacing:(int)inSpacing{
	topSpacing = inSpacing;
}
- (int)topSpacing{
	return topSpacing;
}
- (void)setBottomSpacing:(int)inSpacing{
	bottomSpacing = inSpacing;
}
- (int)bottomSpacing{
	return bottomSpacing;
}
- (void)setLeftSpacing:(int)inSpacing{
	leftSpacing = inSpacing;
}
- (int)leftSpacing{
	return leftSpacing;
}
- (void)setRightSpacing:(int)inSpacing{
	rightSpacing = inSpacing;
}
- (int)rightSpacing{
	return rightSpacing;
}

//User-defined padding offsets.  A cell may adjust these values to to obtain a more desirable default.
//These are offsets, they may be negative!  Padding is the distance between cell edges and their content.
- (void)setSplitVerticalPadding:(int)inPadding{
	topPadding = inPadding / 2;
	bottomPadding = (inPadding + 1) / 2;
}
- (void)setTopPadding:(int)inPadding{
	topPadding = inPadding;
}
- (void)setBottomPadding:(int)inPadding{
	bottomPadding = inPadding;
}
- (int)topPadding{
	return topPadding;
}
- (int)bottomPadding{
	return bottomPadding;
}
- (void)setLeftPadding:(int)inPadding{
	leftPadding = inPadding;
}
- (int)leftPadding{
	return leftPadding;
}
- (void)setRightPadding:(int)inPadding{
	rightPadding = inPadding;
}
- (int)rightPadding{
	return rightPadding;
}


//Drawing --------------------------------------------------------------------------------------------------------------
#pragma mark Drawing
//
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)inControlView{
    [self drawInteriorWithFrame:cellFrame inView:inControlView];
}
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)inControlView
{	
	if (listObject) {
		//Cell spacing
		cellFrame.origin.y += [self topSpacing];
		cellFrame.size.height -= [self bottomSpacing] + [self topSpacing];
		cellFrame.origin.x += [self leftSpacing];
		cellFrame.size.width -= [self rightSpacing] + [self leftSpacing];
		
		[self drawBackgroundWithFrame:cellFrame];

		//Padding
		cellFrame.origin.y += [self topPadding];
		cellFrame.size.height -= [self bottomPadding] + [self topPadding];
		cellFrame.origin.x += [self leftPadding];
		cellFrame.size.width -= [self rightPadding] + [self leftPadding];

		[self drawContentWithFrame:cellFrame];
	}
}

//Custom highlighting (This is a private cell method we're overriding that handles selection drawing)
- (void)_drawHighlightWithFrame:(NSRect)cellFrame inView:(NSView *)inControlView
{
	//Cell spacing
	cellFrame.origin.y += [self topSpacing];
	cellFrame.size.height -= [self bottomSpacing] + [self topSpacing];
	cellFrame.origin.x += [self leftSpacing];
	cellFrame.size.width -= [self rightSpacing] + [self leftSpacing];
	
	[self drawSelectionWithFrame:cellFrame];
}

//Draw Selection
- (void)drawSelectionWithFrame:(NSRect)rect
{
	//
}
	
//Draw the background of our cell
- (void)drawBackgroundWithFrame:(NSRect)rect
{
	//
}

//Draw content of our cell
- (void)drawContentWithFrame:(NSRect)rect
{
	[self drawDisplayNameWithFrame:rect];
}

//Draw our display name
- (NSRect)drawDisplayNameWithFrame:(NSRect)inRect
{
	NSAttributedString	*displayName = [[NSAttributedString alloc] initWithString:[self labelString]
																	   attributes:[self labelAttributes]];
	NSSize				nameSize = [displayName size];
	NSRect				rect = inRect;
	
	if (nameSize.width > rect.size.width) nameSize.width = rect.size.width;
	if (nameSize.height > rect.size.height) nameSize.height = rect.size.height;

	//Alignment
	switch ([self textAlignment]) {
		case NSCenterTextAlignment:
			rect.origin.x += (rect.size.width - nameSize.width) / 2.0;
		break;
		case NSRightTextAlignment:
			rect.origin.x += (rect.size.width - nameSize.width);
		break;
		default:
		break;
	}

	//Draw (centered vertical)
	int half = ceil((rect.size.height - labelFontHeight) / 2.0);
	[displayName drawInRect:NSMakeRect(rect.origin.x,
									   rect.origin.y + half,
									   rect.size.width,
									   nameSize.height)];
	[displayName release];

	//Adjust the drawing rect
	switch ([self textAlignment]) {
		case NSRightTextAlignment:
			inRect.size.width -= nameSize.width;
		break;
		case NSLeftTextAlignment:
			inRect.origin.x += nameSize.width;
			inRect.size.width -= nameSize.width;
		break;
		default:
		break;
	}
	
	return inRect;
}

//Display string for our list object
- (NSString *)labelString
{
	NSString *leftText = [[listObject displayArrayForKey:@"Left Text"] objectValue];
	NSString *rightText = [[listObject displayArrayForKey:@"Right Text"] objectValue];

	//Ordering debug
#ifdef ORDERING_DEBUG
	rightText = (rightText ?
				 [rightText stringByAppendingFormat:@" %f",[listObject orderIndex]] :
				 [NSString stringWithFormat:@" %f",[listObject orderIndex]]); 
#endif

	if (!leftText && !rightText) {
		return (useAliasesAsRequested ? 
				[listObject longDisplayName] :
				([listObject formattedUID] ? [listObject formattedUID] : [listObject longDisplayName]));
	} else {
		//Combine left text, the object name, and right text
		return [NSString stringWithFormat:@"%@%@%@",
			(leftText ? leftText : @""),
			(useAliasesAsRequested ? [listObject longDisplayName] : ([listObject formattedUID] ?
																	 [listObject formattedUID] :
																	 [listObject longDisplayName])),
			(rightText ? rightText : @"")];
	}
}

- (void)setUseAliasesAsRequested:(BOOL)inFlag
{
	useAliasesAsRequested = inFlag;
}

//Attributes for displaying the label string
- (NSDictionary *)labelAttributes
{
	NSMutableDictionary	*labelAttributes;
	NSDictionary		*additionalAttributes = [self additionalLabelAttributes];
	NSColor				*currentTextColor = ([self cellIsSelected] ? [self invertedTextColor] : [self textColor]);

	[leftParagraphStyleWithTruncatingTail setMaximumLineHeight:(float)labelFontHeight];

	if (additionalAttributes) {
		labelAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			currentTextColor, NSForegroundColorAttributeName,
			leftParagraphStyleWithTruncatingTail, NSParagraphStyleAttributeName,
			[self font], NSFontAttributeName,
			nil];
		[labelAttributes addEntriesFromDictionary:additionalAttributes];

	} else {
		labelAttributes = (NSMutableDictionary *)[NSDictionary dictionaryWithObjectsAndKeys:
			currentTextColor, NSForegroundColorAttributeName,
			leftParagraphStyleWithTruncatingTail, NSParagraphStyleAttributeName,
			[self font], NSFontAttributeName,
			nil];
	}
	
	return labelAttributes;
}

//Additional attributes to apply to our label string (For Sub-Classes)
- (NSDictionary *)additionalLabelAttributes
{
	return nil;
}

//YES if our cell is currently selected
- (BOOL)cellIsSelected
{
	return ([self isHighlighted] &&
		   [[controlView window] isKeyWindow] &&
		   [[controlView window] firstResponder] == controlView);
}

//YES if a grid would be visible behind this cell (needs to be drawn)
- (BOOL)drawGridBehindCell
{
	return YES;
}

//The background color for this cell.  This will either be [controlView backgroundColor] or [controlView alternatingGridColor]
- (NSColor *)backgroundColor
{
	//We could just call backgroundColorForRow: but it's best to avoid doing a rowForItem lookup if there is no grid
	if ([controlView drawsAlternatingRows]) {
		return [controlView backgroundColorForRow:[controlView rowForItem:listObject]];
	} else {
		return [controlView backgroundColor];
	}
}

#pragma mark Accessibility

- (NSArray *)accessibilityAttributeNames
{
	NSMutableArray *names = [[super accessibilityAttributeNames] mutableCopy];
	[names addObject:NSAccessibilityValueAttribute];
	[names addObject:NSAccessibilityTitleAttribute];
	[names addObject:NSAccessibilityRoleAttribute];
	[names addObject:NSAccessibilityRoleDescriptionAttribute];
    [names addObject:NSAccessibilitySubroleAttribute];
    [names addObject:NSAccessibilityParentAttribute];
	[names addObject:NSAccessibilityWindowAttribute];
	[names addObject:NSAccessibilityDescriptionAttribute];
	[names addObject:@"ClassName"];
	[names autorelease];
	return names;
}
- (id)accessibilityAttributeValue:(NSString *)attribute
{
	id value;

#define IS_GROUP [listObject isKindOfClass:[AIListGroup class]]
#define IS_CONTACT (!IS_GROUP)

	if([attribute isEqualToString:NSAccessibilityRoleAttribute] || [attribute isEqualToString:NSAccessibilitySubroleAttribute])
		value = IS_CONTACT ? @"AIContactListItem": @"AIContactListGroup";
		
	else if([attribute isEqualToString:NSAccessibilityRoleDescriptionAttribute]){
		NSString *currentStatus = nil;
		
		if([listObject statusType] == AIAvailableStatusType)
			currentStatus = AILocalizedString(@"available contact", /*comment*/ nil);
		else if([listObject statusType] == AIAwayStatusType)
			currentStatus = AILocalizedString(@"away contact", /*comment*/ nil);
		else if([listObject statusType] == AIIdleStatus)
			currentStatus = AILocalizedString(@"idle contact", /*comment*/ nil);
		else if( ([listObject statusType] == AIIdleStatus) && ([listObject statusType]==AIAwayStatusType) )
			currentStatus = AILocalizedString(@"idle and away contact", /*comment*/ nil);
	
		value = IS_CONTACT ? AILocalizedString(currentStatus, /*comment*/ nil) : AILocalizedString(@"contact list group", /*comment*/ nil);
	
	}else if([attribute isEqualToString:NSAccessibilityValueAttribute])
		value = listObject;
	else if([attribute isEqualToString:NSAccessibilityTitleAttribute])
		value = [self labelString];
	else if([attribute isEqualToString:NSAccessibilityWindowAttribute])
		value = [controlView window];
	else if([attribute isEqualToString:@"ClassName"])
		value = NSStringFromClass([self class]);
	else
		value = [super accessibilityAttributeValue:attribute];

#undef IS_CONTACT
#undef IS_GROUP

	return value;
}

@end
