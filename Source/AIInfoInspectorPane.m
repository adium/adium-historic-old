//
//  AIInfoInspectorPane.m
//  Adium
//
//  Created by Elliott Harris on 1/16/08.
//  Copyright 2008 Adium. All rights reserved.
//

#import "AIInfoInspectorPane.h"
#import <Adium/AIHTMLDecoder.h>

#define WIDTH_PROFILE_HEADER	 100.0f

@interface AIInfoInspectorPane (PRIVATE)
- (void)updateUserIcon:(AIListObject *)inObject;
- (void)updateAccountName:(AIListObject *)inObject;
- (void)updateServiceIcon:(AIListObject *)inObject;
- (void)updateStatusIcon:(AIListObject *)inObject;
- (void)updateAlias:(AIListObject *)inObject;
- (NSAttributedString *)attributedStringProfileForListObject:(AIListObject *)inObject;
- (void)gotFilteredProfile:(NSAttributedString *)infoString context:(AIListObject *)object;
- (void)gotFilteredStatus:(NSAttributedString *)infoString context:(AIListObject *)object;
- (void)setAttributedString:(NSAttributedString *)infoString intoTextView:(NSTextView *)textView;
@end

@implementation AIInfoInspectorPane

- (id) init
{
	self = [super init];
	if (self != nil) {
		//Load Bundle
		[NSBundle loadNibNamed:[self nibName] owner:self];
		//Register as AIListObjectObserver
		[[adium contactController] registerListObjectObserver:self];
		//Setup for userIcon
		[userIcon setAnimates:YES];
		[userIcon setMaxSize:NSMakeSize(256,256)];
		[userIcon setDelegate:self];
		
		[aliasLabel setLocalizedString:AILocalizedString(@"Alias:","Label beside the field for a contact's alias in the settings tab of the Get Infow indow")];
	}
	return self;
}

- (void) dealloc
{
	[lastAlias release]; lastAlias = nil;
	
	[inspectorContentView release];
	
	[[adium contactController] unregisterListObjectObserver:self];

	[super dealloc];
}


-(NSView *)inspectorContentView
{
	return inspectorContentView;
}

-(NSString *)nibName
{
	return @"AIInfoInspectorPane";
}

-(void)updateForListObject:(AIListObject *)inObject
{
	[contactAlias fireImmediately];
	
	displayedObject = inObject;
	
	[lastAlias release]; lastAlias = nil;
	
	if ([inObject isKindOfClass:[AIListContact class]]) {
		[[adium contactController] updateListContactStatus:(AIListContact *)inObject];
	}
	
	[self updateUserIcon:inObject];
	[self updateAccountName:inObject];
	[self updateServiceIcon:inObject];
	[self updateStatusIcon:inObject];
	[self gotFilteredProfile:[self attributedStringProfileForListObject:inObject]
					 context:inObject];
	[self updateAlias:inObject];
}

- (void)updateUserIcon:(AIListObject *)inObject
{
	NSImage		*currentIcon;
	NSSize		userIconSize, imagePickerSize;

	//User Icon
	if (!(currentIcon = [inObject userIcon])) {
		currentIcon = [NSImage imageNamed:@"DefaultIcon" forClass:[self class]];
	}
	
	/* NSScaleProportionally will lock an animated GIF into a single frame.  We therefore use NSScaleNone if
	 * we are already at the right size or smaller than the right size; otherwise we scale proportionally to
	 * fit the frame.
	 */
	userIconSize = [currentIcon size];
	imagePickerSize = [userIcon frame].size;
	
	[userIcon setImageScaling:(((userIconSize.width <= imagePickerSize.width) && (userIconSize.height <= imagePickerSize.height)) ?
										 NSScaleNone :
										 NSScaleProportionally)];
	[userIcon setImage:currentIcon];
	[userIcon setTitle:(inObject ?
								  [NSString stringWithFormat:AILocalizedString(@"%@'s Image",nil),[inObject displayName]] :
								  AILocalizedString(@"Image Picker",nil))];

	//Show the reset image button if a preference is set on this object, overriding its serverside icon
	[userIcon setShowResetImageButton:([inObject preferenceForKey:KEY_USER_ICON
															group:PREF_GROUP_USERICONS
											ignoreInheritedValues:YES] != nil)];
}

-(void)updateAccountName:(AIListObject *)inObject
{
	if(!inObject) {
		[accountName setStringValue:@""];
		return;
	}
	
	NSString *displayName = [inObject formattedUID];
	
	if (!displayName) {
		displayName = [inObject displayName];
	}
	
	[accountName setStringValue:displayName];
}

-(void)updateStatusIcon:(AIListObject *)inObject
{
	if([inObject isKindOfClass:[AIListGroup class]]) {
		[statusImage setHidden:YES];
	} else {
		[statusImage setHidden:NO];
		[statusImage setImage:[AIStatusIcons statusIconForListObject:inObject type:AIStatusIconList direction:AIIconNormal]];
	}
}

-(void)updateServiceIcon:(AIListObject *)inObject
{
	if([inObject isKindOfClass:[AIListGroup class]]) {
		[serviceImage setHidden:YES];
	} else {
		[serviceImage setHidden:NO];
		[serviceImage setImage:[AIServiceIcons serviceIconForObject:inObject type:AIServiceIconSmall direction:AIIconNormal]];
	}
}

#define KEY_KEY		@"Key"
#define KEY_VALUE	@"Value"
#define KEY_TYPE	@"Type"

- (void)addAttributedString:(NSAttributedString *)string
					toTable:(NSTextTable *)table
						row:(int)row
						col:(int)col
					colspan:(int)colspan
					  color:(NSColor *)color
				  alignment:(NSTextAlignment)alignment
		 toAttributedString:(NSMutableAttributedString *)text
{
	NSTextTableBlock		*block = [[NSTextTableBlock alloc] initWithTable:table
														   startingRow:row
															   rowSpan:1
														startingColumn:col
															columnSpan:colspan];
	NSMutableParagraphStyle	*style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	
	int textLength = [text length];

    [block setVerticalAlignment:NSTextBlockTopAlignment];
	
    [block setWidth:10.0f type:NSTextBlockAbsoluteValueType forLayer:NSTextBlockPadding edge:NSMinYEdge];
    [block setWidth:10.0f type:NSTextBlockAbsoluteValueType forLayer:NSTextBlockPadding edge:NSMaxYEdge];
    [block setWidth:5.0f type:NSTextBlockAbsoluteValueType forLayer:NSTextBlockPadding edge:NSMinXEdge];
    [block setWidth:5.0f type:NSTextBlockAbsoluteValueType forLayer:NSTextBlockPadding edge:NSMaxXEdge];
	
	
	if (col == 0) {
		[block setValue:WIDTH_PROFILE_HEADER
				   type:NSTextBlockAbsoluteValueType
		   forDimension:NSTextBlockWidth];
	}

    [style setTextBlocks:[NSArray arrayWithObject:block]];
    [style setAlignment:alignment];
	
	[text appendAttributedString:string];
	[text appendAttributedString:[NSAttributedString stringWithString:@"\n"]];

	[text addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(textLength, [text length] - textLength)];
    [text addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange(textLength, [text length] - textLength)];
	
    [style release];
    [block release];
	
}

- (NSAttributedString *)attributedStringProfileForListObject:(AIListObject *)inObject
{	
	// We don't know what to do for non-list contacts.
	if (![inObject isKindOfClass:[AIListContact class]]) {
		return [NSAttributedString stringWithString:@""];
	}
	
	// XXX Case out if we only have HTML (nothing currently does this)
	
	// Create the table
	NSTextTable		*table = [[[NSTextTable alloc] init] autorelease];
	
	[table setNumberOfColumns:2];
    [table setLayoutAlgorithm:NSTextTableAutomaticLayoutAlgorithm];
    [table setHidesEmptyCells:YES];

	NSMutableAttributedString		*result = [[[NSMutableAttributedString alloc] init] autorelease];
	NSEnumerator					*enumerator = [[(AIListContact *)inObject profileArray] objectEnumerator];
	NSDictionary					*lineDict;
	
	for (int row = 0; (lineDict = [enumerator nextObject]); row++) {
		NSAttributedString *value = nil, *key = nil;
		
		if ([lineDict objectForKey:KEY_VALUE]) {
			NSMutableString		*mutableValue = [[lineDict objectForKey:KEY_VALUE] mutableCopy];
			
			[mutableValue replaceOccurrencesOfString:@"</html>"
								   withString:@""
									  options:(NSCaseInsensitiveSearch | NSLiteralSearch)
										range:NSMakeRange(0, [mutableValue length])];
						
			value = [AIHTMLDecoder decodeHTML:mutableValue];
			
			[mutableValue release];
			
			value = [[adium contentController] filterAttributedString:value
												usingFilterType:AIFilterDisplay
													  direction:AIFilterIncoming
														context:inObject];
		}
		
		if ([lineDict objectForKey:KEY_KEY]) {
			// We don't need to filter the key.
			key = [NSAttributedString stringWithString:[[lineDict objectForKey:KEY_KEY] lowercaseString]];
		}
		
		if (key) {
			// This entry's name:
			[self addAttributedString:key
							  toTable:table
								  row:row
								  col:0
							  colspan:1
								color:[NSColor grayColor]
							alignment:NSRightTextAlignment
				   toAttributedString:result];
		}
		
		if (value) {
			// This entry's value:
			[self addAttributedString:value
							  toTable:table
								  row:row
								  col:1
							  colspan:(key ? 1 : 2) /* If there's no key, we need to fill both columns. */
								color:[NSColor controlTextColor]
							alignment:NSLeftTextAlignment
				   toAttributedString:result];
		}
	}
	
	return result;
}

- (void)updateAlias:(AIListObject *)inObject
{	
	if ([inObject isKindOfClass:[AIListContact class]]) {
		inObject = [(AIListContact *)inObject parentContact];
	}
	
	NSString *currentAlias = [inObject preferenceForKey:@"Alias"
												  group:PREF_GROUP_ALIASES
								  ignoreInheritedValues:YES];
	
	if (!currentAlias && ![[inObject displayName] isEqualToString:[inObject formattedUID]]) {
		[[contactAlias cell] setPlaceholderString:[inObject displayName]];
	} else {
		[[contactAlias cell] setPlaceholderString:nil];
	}
	
	//Fill in the current alias
	if (currentAlias) {
		[contactAlias setStringValue:currentAlias];
	} else {
		[contactAlias setStringValue:@""];
	}
	
	// Save a copy of this current alias so we don't spam updates of the same string.
	lastAlias = [[contactAlias stringValue] copy];
}

- (IBAction)setAlias:(id)sender
{
	if(!displayedObject || [[contactAlias stringValue] isEqualToString:lastAlias])
		return;
	
	AIListObject *contactToUpdate = displayedObject;
	
	if ([contactToUpdate isKindOfClass:[AIListContact class]]) {
		contactToUpdate = [(AIListContact *)contactToUpdate parentContact];
	}
	
	NSString *currentAlias = [contactAlias stringValue];
	[contactToUpdate setDisplayName:currentAlias];
	
	[self updateAccountName:displayedObject];
}

- (void)gotFilteredProfile:(NSAttributedString *)infoString context:(AIListObject *)object
{
	//Prevent duplicate profiles from being set again.
	if([[profileView string] isEqualToString:[infoString string]])
		return;
		
	//If we've been called with infoString == nil, we don't have the profile information yet.
	if(!infoString && ![displayedObject isKindOfClass:[AIListGroup class]]) {
		//This should only run if we get a nil string and if we aren't a group.
		[profileProgress startAnimation:self];
		/*	We deal with the progress indicator's visibility manually, because sometimes it will 
		corrupt text when set to hide/unhide automatically.	*/
		[profileProgress setHidden:NO];
		//We can freely start the progress indicator numerous times - it has no effect.
	} else {
		//Non-nil info string means we have some profile text and we will bet setting it.
		[profileProgress stopAnimation:self];
		[profileProgress setHidden:YES];
	}
	
	[self setAttributedString:infoString intoTextView:profileView];
}

- (void)setAttributedString:(NSAttributedString *)infoString intoTextView:(NSTextView *)textView
{
	NSColor		*backgroundColor = nil;

	if (infoString && [infoString length]) {
		[[textView textStorage] setAttributedString:infoString];	
		backgroundColor = [infoString attribute:AIBodyColorAttributeName
										atIndex:0 
						  longestEffectiveRange:nil 
										inRange:NSMakeRange(0,[infoString length])];
	} else {
		[[textView textStorage] setAttributedString:[NSAttributedString stringWithString:@""]];	
	}
	[textView setBackgroundColor:(backgroundColor ? backgroundColor : [NSColor whiteColor])];
    [[NSNotificationCenter defaultCenter] postNotificationName:NSTextDidChangeNotification object:textView];
}

- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	//This is a hold-over from the refactoring of the old Get Info Window.
	//The code for the Get Info Window only updated the status and profile, so we only do that here.
	//Update if our object or an object contained by our metacontact (if applicable) was updated
	if ([displayedObject isKindOfClass:[AIMetaContact class]] &&
		((inObject != displayedObject) && ![(AIMetaContact *)displayedObject containsObject:inObject]))
		return nil;
	else if (inObject != displayedObject)
		return nil;
	
	// If the properties changed for our observed contact, update based on them.
	[self updateForListObject:displayedObject];
	
	return nil;
}

#pragma mark AIImageViewWithImagePicker Delegate
// AIImageViewWithImagePicker Delegate ---------------------------------------------------------------------
- (void)imageViewWithImagePicker:(AIImageViewWithImagePicker *)sender didChangeToImageData:(NSData *)imageData
{
	if (displayedObject) {
		[displayedObject setUserIconData:imageData];
	}
	
	[self updateUserIcon:displayedObject];
}

- (void)deleteInImageViewWithImagePicker:(AIImageViewWithImagePicker *)sender
{
	if (displayedObject) {
		//Remove the preference
		[displayedObject setUserIconData:nil];

		[self updateUserIcon:displayedObject];
	}
}

/*
 If the userIcon was bigger than our image view's frame, it will have been clipped before being passed
 to the AIImageViewWithImagePicker.  This delegate method lets us pass the original, unmodified userIcon.
 */
- (NSImage *)imageForImageViewWithImagePicker:(AIImageViewWithImagePicker *)picker
{
	return ([displayedObject userIcon]);
}

- (NSImage *)emptyPictureImageForImageViewWithImagePicker:(AIImageViewWithImagePicker *)picker
{
	return [AIServiceIcons serviceIconForObject:displayedObject type:AIServiceIconLarge direction:AIIconNormal];
}

- (NSString *)fileNameForImageInImagePicker:(AIImageViewWithImagePicker *)picker
{
	NSString *fileName = [[displayedObject displayName] safeFilenameString];
	if ([fileName hasPrefix:@"."]) {
		fileName = [fileName substringFromIndex:1];
	}
	return fileName;
}


@end
