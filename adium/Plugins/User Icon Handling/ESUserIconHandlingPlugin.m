//
//  ESUserIconHandlingPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on Fri Feb 20 2004.
//

#import "ESUserIconHandlingPlugin.h"

#define USER_ICON_CACHE_PATH		[@"~/Library/Caches/Adium" stringByExpandingTildeInPath]

@interface ESUserIconHandlingPlugin (PRIVATE)
- (BOOL)cacheAndSetUserIconFromPreferenceForListObject:(AIListObject *)inObject;
- (BOOL)_cacheUserIconData:(NSData *)inData forObject:(AIListObject *)inObject;
- (NSString *)_cachedImagePathForObject:(AIListObject *)inObject;
- (BOOL)destroyCacheForListObject:(AIListObject *)inObject;
@end

@implementation ESUserIconHandlingPlugin

- (void)installPlugin
{
	//Ensure our user icon cache path exists
	[[NSFileManager defaultManager] createDirectoriesForPath:USER_ICON_CACHE_PATH];
	
	//Register our observers
    [[adium contactController] registerListObjectObserver:self];
	
	[[adium notificationCenter] addObserver:self selector:@selector(listObjectAttributesChanged:) 
									   name:ListObject_AttributesChanged
									 object:nil];
	
	[[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) 
									   name:Preference_GroupChanged 
									 object:nil];	
}

- (void)uninstallPlugin
{
    [[adium contactController] unregisterListObjectObserver:self];
}

//Handle object creation and changes to the userIcon status object, which should be set by account code
//when a user icon is retrieved for the object
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{    
    if(inModifiedKeys == nil){
		//At object creation, load the user icon.
		
		//Only load the cached image file if we do not load from a preference
		if (![self cacheAndSetUserIconFromPreferenceForListObject:inObject]){

			//Load the cached image file by reference into the display array;
			//It will only be loaded into memory if needed
			NSString			*cachedImagePath = [self _cachedImagePathForObject:inObject];
			if ([[NSFileManager defaultManager] fileExistsAtPath:cachedImagePath]){
				NSImage				*cachedImage = [[[NSImage alloc] initByReferencingFile:cachedImagePath] autorelease];
				
				if (cachedImage) {
					//A cache image is used at lowest priority, since it is outdated data
					[[inObject displayArrayForKey:KEY_USER_ICON] setObject:cachedImage
																 withOwner:self
															 priorityLevel:Lowest_Priority];
					[inObject setStatusObject:cachedImagePath
									   forKey:@"UserIconPath"
									   notify:YES];
				}
			}
		}
		
	}else if([inModifiedKeys containsObject:KEY_USER_ICON]){
		//The status UserIcon object is set by account code; apply this to the display array and cache it if necesssary
		AIMutableOwnerArray *userIconDisplayArray = [inObject displayArrayForKey:KEY_USER_ICON];
		NSImage				*statusUserIcon = [inObject statusObjectForKey:KEY_USER_ICON];
		
		//Apply the image at medium priority
		[userIconDisplayArray setObject:statusUserIcon 
							  withOwner:self
						  priorityLevel:Medium_Priority];
		
		//If the new objectValue is what we just set, notify and cache
		NSImage				*userIcon = [userIconDisplayArray objectValue];

		if (userIcon == statusUserIcon){
			//Cache using the raw data if possible, otherwise create a TIFF representation to cache
			//Note: TIFF supports transparency but not animation
			NSData  *userIconData = [inObject statusObjectForKey:@"UserIconData"];
			
			[self _cacheUserIconData:(userIconData ? userIconData : [userIcon TIFFRepresentation]) forObject:inObject];
			
			[[adium contactController] listObjectAttributesChanged:inObject
													  modifiedKeys:[NSArray arrayWithObject:KEY_USER_ICON]];
		}
	}
	
	return(nil);
}

//A plugin, or this plugin, modified the display array for the object; ensure our cache is up to date
- (void)listObjectAttributesChanged:(NSNotification *)notification
{
    AIListObject	*inObject = [notification object];
    NSArray			*keys = [[notification userInfo] objectForKey:@"Keys"];
	
	if([keys containsObject:KEY_USER_ICON]){
		AIMutableOwnerArray *userIconDisplayArray = [inObject displayArrayForKey:KEY_USER_ICON];
		NSImage *userIcon = [userIconDisplayArray objectValue];
		NSImage *ownedUserIcon = [userIconDisplayArray objectWithOwner:self];
		
		//If the new user icon is not the same as the one we set in updateListObject: 
		//(either cached or not), update the cache
		if (userIcon != ownedUserIcon){
			[self _cacheUserIconData:[userIcon TIFFRepresentation] forObject:inObject];
		}
	}
}

//The user icon preference was changed
- (void)preferencesChanged:(NSNotification *)notification
{
	if([(NSString *)[[notification userInfo] objectForKey:@"Group"] isEqualToString:PREF_GROUP_USERICONS]){
		AIListObject	*listObject = [notification object];
		if (listObject){
			if (![self cacheAndSetUserIconFromPreferenceForListObject:listObject]){
				[self destroyCacheForListObject:listObject];
			}
		}
	}
}

- (BOOL)cacheAndSetUserIconFromPreferenceForListObject:(AIListObject *)inObject
{
	NSData  *imageData = [inObject preferenceForKey:KEY_USER_ICON 
											  group:PREF_GROUP_USERICONS
							  ignoreInheritedValues:YES];
	if (imageData){
		//Cache the image to disk for use elsewhere
		[self _cacheUserIconData:imageData forObject:inObject];
		
		//A preference is used at highest priority
		[[inObject displayArrayForKey:KEY_USER_ICON] setObject:[[[NSImage alloc] initWithData:imageData] autorelease]
													 withOwner:self
												 priorityLevel:Highest_Priority];
	}else{
		//A preference is used at highest priority
		AIMutableOwnerArray *userIconDisplayArray = [inObject displayArrayForKey:KEY_USER_ICON create:NO];
		if (userIconDisplayArray){
			[userIconDisplayArray setObject:nil
								  withOwner:self];
			
			//This will trigger a call to - (void)listObjectAttributesChanged:(NSNotification *)notification
			//leading to an update of our icon cache
			[[adium contactController] listObjectAttributesChanged:inObject
													  modifiedKeys:[NSArray arrayWithObject:KEY_USER_ICON]];
		}
	}
	
	return (imageData != nil);
}

/*
- (BOOL)_cacheUserIcon:(NSImage *)inImage forObject:(AIListObject *)inObject
{
	BOOL		success = NO;
	NSString	*cachedImagePath = [self _cachedImagePathForObject:inObject];
	
	
	NSBitmapImageRep* imageRep = [[inImage representations] objectAtIndex:0];
	NSLog(@"ImageRep %@",imageRep);
		unsigned char *imageBytes = [imageRep bitmapData];
		NSData  *imageData = [NSData dataWithBytes:imageBytes 
											length:[imageRep bytesPerRow] * [imageRep pixelsHigh]];
		success = ([imageData writeToFile:cachedImagePath
							   atomically:YES]);
		if (success){
			NSLog(@"Success!");
			[inObject setStatusObject:cachedImagePath 
							   forKey:@"UserIconPath"
						   notify:YES];
		}

	return success;
}
*/


- (BOOL)_cacheUserIconData:(NSData *)inData forObject:(AIListObject *)inObject
{
	BOOL		success;
	NSString	*cachedImagePath = [self _cachedImagePathForObject:inObject];

	success = ([inData writeToFile:cachedImagePath
						atomically:YES]);
	if (success){
		[inObject setStatusObject:cachedImagePath 
						   forKey:@"UserIconPath"
						   notify:YES];
	}
	
	return success;
}
- (BOOL)destroyCacheForListObject:(AIListObject *)inObject
{
	NSString	*cachedImagePath = [self _cachedImagePathForObject:inObject];
	BOOL		success;
	
	if(success = [[NSFileManager defaultManager] trashFileAtPath:cachedImagePath]){
		[inObject setStatusObject:nil 
						   forKey:@"UserIconPath"
						   notify:YES];
	}
	
	return (success);
}

- (NSString *)_cachedImagePathForObject:(AIListObject *)inObject
{
	return ([USER_ICON_CACHE_PATH stringByAppendingPathComponent:[inObject uniqueObjectID]]);
}

@end
