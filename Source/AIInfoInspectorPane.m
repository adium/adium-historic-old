//
//  AIInfoInspectorPane.m
//  Adium
//
//  Created by Elliott Harris on 1/16/08.
//  Copyright 2008 Adium. All rights reserved.
//

#import "AIInfoInspectorPane.h"


@interface AIInfoInspectorPane (PRIVATE)
- (void)updateUserIcon:(AIListObject *)inObject;
- (void)updateAccountName:(AIListObject *)inObject;
- (void)updateServiceIcon:(AIListObject *)inObject;
- (void)updateStatusIcon:(AIListObject *)inObject;
- (void)updateProfileView:(AIListObject *)inObject;
- (void)updateAlias:(AIListObject *)inObject;
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
	[self updateProfileView:inObject];
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

-(void)updateProfileView:(AIListObject *)inObject
{	
	[[adium contentController] filterAttributedString:([inObject isKindOfClass:[AIListContact class]] ?
													   [(AIListContact *)inObject profile] :
													   nil)
									  usingFilterType:AIFilterDisplay
											direction:AIFilterIncoming
										filterContext:inObject
									  notifyingTarget:self
											 selector:@selector(gotFilteredProfile:context:)
											  context:inObject];
}

- (void)updateAlias:(AIListObject *)inObject
{	
	if ([inObject isKindOfClass:[AIListContact class]]) {
		inObject = [(AIListContact *)inObject parentContact];
	}
	
	NSString *currentAlias = [inObject preferenceForKey:@"Alias"
												  group:PREF_GROUP_ALIASES
								  ignoreInheritedValues:YES];
	
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
