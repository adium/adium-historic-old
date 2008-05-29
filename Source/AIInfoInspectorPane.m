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
- (void)updateProfile:(NSAttributedString *)infoString context:(AIListObject *)object;
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
	
	[self updateProfile:nil
				context:inObject];
	
	[profileProgress startAnimation:self];
	[profileProgress setHidden:NO];
	
	[self updateUserIcon:inObject];
	[self updateAccountName:inObject];
	[self updateServiceIcon:inObject];
	[self updateStatusIcon:inObject];
	[self updateAlias:inObject];
	
	[self updateProfile:[self attributedStringProfileForListObject:inObject]
				context:inObject];
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
					 header:(BOOL)header
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
	
    [block setWidth:5.0f type:NSTextBlockAbsoluteValueType forLayer:NSTextBlockPadding edge:NSMinYEdge];
    [block setWidth:5.0f type:NSTextBlockAbsoluteValueType forLayer:NSTextBlockPadding edge:NSMaxYEdge];
    [block setWidth:1.0f type:NSTextBlockAbsoluteValueType forLayer:NSTextBlockPadding edge:NSMinXEdge];
    [block setWidth:5.0f type:NSTextBlockAbsoluteValueType forLayer:NSTextBlockPadding edge:NSMaxXEdge];

	if (col == 0 && !header && colspan == 1) {
		[block setValue:WIDTH_PROFILE_HEADER
				   type:NSTextBlockAbsoluteValueType
		   forDimension:NSTextBlockWidth];
	}
	
    [style setTextBlocks:[NSArray arrayWithObject:block]];
	
	[style setAlignment:alignment];
	
	[text appendAttributedString:string];
	[text appendAttributedString:[NSAttributedString stringWithString:@"\n"]];
	
	if (header) {
		[text addAttribute:NSFontAttributeName value:[NSFont boldSystemFontOfSize:13] range:NSMakeRange(textLength, [text length] - textLength)];
		[block setWidth:1.0f type:NSTextBlockAbsoluteValueType forLayer:NSTextBlockBorder edge:NSMaxYEdge];
		[block setBorderColor:[NSColor darkGrayColor]];
	} 
	
	[text addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(textLength, [text length] - textLength)];
    [text addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange(textLength, [text length] - textLength)];
	
    [style release];
    [block release];
	
}


- (NSArray *)metaContactProfileArrayForContact:(AIMetaContact *)metaContact
{
	NSMutableArray		*array = [NSMutableArray array];
	NSMutableDictionary	*addedKeysDict = [NSMutableDictionary dictionary];
	NSMutableDictionary *ownershipDict = [NSMutableDictionary dictionary];

	NSEnumerator *enumerator = [([metaContact online] ?
								 [metaContact listContacts] :
								 [metaContact listContactsIncludingOfflineAccounts]) objectEnumerator];
	AIListContact *listContact;
	BOOL metaContactIsOnline = [metaContact online];
	
	while ((listContact = [enumerator nextObject])) {
		//If one or more contacts are online, skip offline ones
		if (metaContactIsOnline && ![listContact online]) continue;
		
		NSEnumerator *profileEnumerator = [[listContact profileArray] objectEnumerator];
		NSDictionary *lineDict;
		while ((lineDict = [profileEnumerator nextObject])) {
			NSString *key = [lineDict objectForKey:KEY_KEY];
			AIUserInfoEntryType entryType = [[lineDict objectForKey:KEY_TYPE] intValue];
			int insertionIndex = -1;
	
			switch (entryType) {
				case AIUserInfoSectionBreak:
					/* Skip double section breaks */
					if ([[[array lastObject] objectForKey:KEY_TYPE] intValue] == AIUserInfoSectionBreak)
						continue;
					break;
				case AIUserInfoSectionHeader:
					/* Use the most recent header if we have multiple headers in a row */
					if ([[[array lastObject] objectForKey:KEY_TYPE] intValue] == AIUserInfoSectionHeader)
						[array removeLastObject];
					break;
				case AIUserInfoLabelValuePair:
						/* No action needed */
					break;
			}
			
			if (key) {
				NSMutableSet *previousDictValuesOnThisKey = [addedKeysDict objectForKey:key];
				if (previousDictValuesOnThisKey) {
					/* If any previously added dictionary has the same key and value as the this new one, skip this new one entirely */
					NSSet *existingValues = [previousDictValuesOnThisKey valueForKeyPath:[@"nonretainedObjectValue." stringByAppendingString:KEY_VALUE]];
					if ([existingValues containsObject:[lineDict valueForKey:KEY_VALUE]])
						continue;
					
					NSEnumerator *prevDictValueEnumerator = [[[previousDictValuesOnThisKey copy] autorelease] objectEnumerator];
					NSValue *prevDictValue;
					while ((prevDictValue = [prevDictValueEnumerator nextObject])) {
						NSDictionary		*prevDict = [prevDictValue nonretainedObjectValue];
						NSMutableDictionary *newDict = [prevDict mutableCopy];
						AIListContact *ownerOfPrevDict = [[ownershipDict objectForKey:prevDictValue] nonretainedObjectValue];
						[newDict setObject:[NSString stringWithFormat:AILocalizedString(@"%@'s %@", nil),
											[ownerOfPrevDict formattedUID],
											key]
									forKey:KEY_KEY];
						
						//Array of dicts which will be returned
						insertionIndex = [array indexOfObjectIdenticalTo:prevDict];
						[array replaceObjectAtIndex:insertionIndex
										 withObject:newDict];
						
						//Known dictionaries on this key
						[previousDictValuesOnThisKey removeObject:prevDictValue];
						[previousDictValuesOnThisKey addObject:[NSValue valueWithNonretainedObject:newDict]];

						//Ownership of new dictionary
						[ownershipDict removeObjectForKey:prevDictValue];
						[ownershipDict setObject:[NSValue valueWithNonretainedObject:newDict]
										  forKey:[NSValue valueWithNonretainedObject:ownerOfPrevDict]];
						[newDict release];
					}
					
					NSMutableDictionary *newDict = [lineDict mutableCopy];
					[newDict setObject:[NSString stringWithFormat:AILocalizedString(@"%@'s %@", nil),
										[listContact formattedUID],
										key]
								forKey:KEY_KEY];					
					lineDict = [newDict autorelease];
					
					[previousDictValuesOnThisKey addObject:[NSValue valueWithNonretainedObject:lineDict]];

				} else {
					[addedKeysDict setObject:[NSMutableSet setWithObject:[NSValue valueWithNonretainedObject:lineDict]]
									  forKey:key];
				}
			}
			
			if (lineDict) {
				if (insertionIndex != -1) {
					//Group items with the same key together
					[array insertObject:lineDict atIndex:insertionIndex];					
				} else {
					[array addObject:lineDict];
				}
				
				[ownershipDict setObject:[NSValue valueWithNonretainedObject:listContact]
								  forKey:[NSValue valueWithNonretainedObject:lineDict]];
			}
		}
	}

	return array;
}

- (NSAttributedString *)attributedStringProfileForListObject:(AIListObject *)inObject
{	
	NSArray *profileArray;

	// We don't know what to do for non-list contacts.
	if (![inObject isKindOfClass:[AIListContact class]]) {
		return [NSAttributedString stringWithString:@""];
	}
	
	// XXX Case out if we only have HTML (nothing currently does this)
	
	if ([inObject isKindOfClass:[AIMetaContact class]]) {
		profileArray = [self metaContactProfileArrayForContact:(AIMetaContact *)inObject];
	} else {
		profileArray = [(AIListContact *)inObject profileArray];
	}

	// Don't do anything if we have nothing to display.
	if ([profileArray count] == 0) {
		AILogWithSignature(@"No profile array items found for %@", inObject);
		return nil;
	}
	
	// Create the table
	NSTextTable		*table = [[[NSTextTable alloc] init] autorelease];
	
	[table setNumberOfColumns:2];
    [table setLayoutAlgorithm:NSTextTableAutomaticLayoutAlgorithm];
    [table setHidesEmptyCells:YES];

	NSMutableAttributedString		*result = [[[NSMutableAttributedString alloc] init] autorelease];
	NSEnumerator					*enumerator = [profileArray objectEnumerator];
	NSDictionary					*lineDict;
	
	BOOL							shownAnyContent = NO;
	
	for (int row = 0; (lineDict = [enumerator nextObject]); row++) {
		if ([[lineDict objectForKey:KEY_TYPE] intValue] == AIUserInfoSectionBreak && shownAnyContent == NO) {
			continue;
		}
		
		NSAttributedString *value = nil, *key = nil;
		
		if ([lineDict objectForKey:KEY_VALUE]) {
			value = [AIHTMLDecoder decodeHTML:[lineDict objectForKey:KEY_VALUE]];
			
			value = [[adium contentController] filterAttributedString:value
												usingFilterType:AIFilterDisplay
													  direction:AIFilterIncoming
														context:inObject];
		}
		
		if ([lineDict objectForKey:KEY_KEY]) {
			// We don't need to filter the key.
			key = [NSAttributedString stringWithString:[[lineDict objectForKey:KEY_KEY] lowercaseString]];
		}
		
		switch ([[lineDict objectForKey:KEY_TYPE] intValue]) {
			case AIUserInfoLabelValuePair:
				if (key) {
					[self addAttributedString:key
									  toTable:table
										  row:row
										  col:0
									  colspan:1
									   header:NO
										color:[NSColor grayColor]
									alignment:NSRightTextAlignment
						   toAttributedString:result];
				}
				
				if (value) {
					[self addAttributedString:value
									  toTable:table
										  row:row
										  col:(key ? 1 : 0)
									  colspan:(key ? 1 : 2) /* If there's no key, we need to fill both columns. */
									   header:NO
										color:[NSColor controlTextColor]
									alignment:NSLeftTextAlignment
						   toAttributedString:result];
				}
				break;
				
			case AIUserInfoSectionHeader:
				[self addAttributedString:key
								  toTable:table
									  row:row
									  col:0
								  colspan:2
								   header:YES
									color:[NSColor darkGrayColor]
								alignment:NSLeftTextAlignment
					   toAttributedString:result];
				break;
				
				
			case AIUserInfoSectionBreak:
				[self addAttributedString:[NSAttributedString stringWithString:@" "]
								  toTable:table
									  row:row
									  col:0
								  colspan:2
								   header:NO
									color:[NSColor controlTextColor]
								alignment:NSLeftTextAlignment
					   toAttributedString:result];
				break;
		}
		
		shownAnyContent = YES;
	}
	
	return result;
}

- (void)updateAlias:(AIListObject *)inObject
{
	NSString *currentAlias = nil;
	
	
	if ([inObject isKindOfClass:[AIListContact class]]) {
		currentAlias = [[(AIListContact *)inObject parentContact] preferenceForKey:@"Alias"
																			 group:PREF_GROUP_ALIASES
															 ignoreInheritedValues:YES];
	} else {
		currentAlias = [inObject preferenceForKey:@"Alias"
											group:PREF_GROUP_ALIASES
							ignoreInheritedValues:YES];		
	}
	
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

- (void)updateProfile:(NSAttributedString *)infoString context:(AIListObject *)object
{
	if (infoString) {
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
	//Update if our object or an object contained by our metacontact (if applicable) was updated
	if ([displayedObject isKindOfClass:[AIMetaContact class]] &&
		((inObject != displayedObject) && ![(AIMetaContact *)displayedObject containsObject:inObject]))
		return nil;
	else if (inObject != displayedObject)
		return nil;
	
	// Update the status icon if it changes.
	if (inModifiedKeys == nil ||
		[inModifiedKeys containsObject:@"Online"] ||
		[inModifiedKeys containsObject:@"IdleSince"] ||
		[inModifiedKeys containsObject:@"Signed Off"] ||
		[inModifiedKeys containsObject:@"IsMobile"] ||
		[inModifiedKeys containsObject:@"IsBlocked"] ||
		[inModifiedKeys containsObject:@"StatusType"]) {
		[self updateStatusIcon:displayedObject];
	}
	
	// Update the profile if it changes.	
	if (inModifiedKeys == nil ||
		[inModifiedKeys containsObject:@"ProfileArray"]) {
		[self updateProfile:[self attributedStringProfileForListObject:displayedObject]
					context:displayedObject];
	}
	
	// Cause everything to update if everything's probably changed.
	if ([inModifiedKeys containsObject:@"NotAStranger"] ||
		[inModifiedKeys containsObject:@"Server Display Name"]) {
		[self updateForListObject:displayedObject];
	}
	
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
