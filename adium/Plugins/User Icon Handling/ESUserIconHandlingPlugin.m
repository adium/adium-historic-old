//
//  ESUserIconHandlingPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on Fri Feb 20 2004.
//

#import "ESUserIconHandlingPlugin.h"

#define USER_ICON_CACHE_PATH		[@"~/Library/Caches/Adium" stringByExpandingTildeInPath]

@interface ESUserIconHandlingPlugin (PRIVATE)
- (BOOL)_cacheUserIcon:(NSImage *)inImage forObject:(AIListObject *)inObject;
- (NSString *)_cachedImagePathForObject:(AIListObject *)inObject;
@end

@implementation ESUserIconHandlingPlugin

- (void)installPlugin
{
	//ensure our user icon cache path exists
    [AIFileUtilities createDirectory:USER_ICON_CACHE_PATH];

    [[adium contactController] registerListObjectObserver:self];
	
	[[adium notificationCenter] addObserver:self selector:@selector(listObjectAttributesChanged:) 
									   name:ListObject_AttributesChanged
									 object:nil];
}

- (void)uninstallPlugin
{
    [[adium contactController] unregisterListObjectObserver:self];
}

- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{    
    if(inModifiedKeys == nil){
		//At object creation, load the cached image file by reference into the display array;
		//it will only be loaded into memory if needed
		NSString			*cachedImagePath = [self _cachedImagePathForObject:inObject];
		if ([[NSFileManager defaultManager] fileExistsAtPath:cachedImagePath]){
			NSImage				*cachedImage = [[[NSImage alloc] initByReferencingFile:cachedImagePath] autorelease];
			
			if (cachedImage) {
				[[inObject displayArrayForKey:@"UserIcon"] setObject:cachedImage
														   withOwner:self
													   priorityLevel:Lowest_Priority];
				[inObject setStatusObject:cachedImagePath
								   forKey:@"UserIconPath"
								   notify:YES];
			}
		}
		
	}else if([inModifiedKeys containsObject:@"UserIcon"]){
		//The status UserIcon object is set by account code; apply this to the display array and cache it if necesssary
		AIMutableOwnerArray *userIconDisplayArray = [inObject displayArrayForKey:@"UserIcon"];
		NSImage				*statusUserIcon = [inObject statusObjectForKey:@"UserIcon"];
		
		//Apply the image at medium priority
		[userIconDisplayArray setObject:statusUserIcon 
							  withOwner:self
						  priorityLevel:Medium_Priority];
		
		//If the new objectValue is what we just set, notify and cache
		NSImage				*userIcon = [userIconDisplayArray objectValue];

		if (userIcon == statusUserIcon){
			[[adium contactController] listObjectAttributesChanged:inObject
													  modifiedKeys:[NSArray arrayWithObject:@"UserIcon"]];
			[self _cacheUserIcon:userIcon forObject:inObject];
		}
	}
	
	return(nil);
}

- (void)listObjectAttributesChanged:(NSNotification *)notification
{
    AIListObject	*inObject = [notification object];
    NSArray			*keys = [[notification userInfo] objectForKey:@"Keys"];
	
	if([keys containsObject:@"UserIcon"]){
		AIMutableOwnerArray *userIconDisplayArray = [inObject displayArrayForKey:@"UserIcon"];
		NSImage *userIcon = [userIconDisplayArray objectValue];
		NSImage *ownedUserIcon = [userIconDisplayArray objectWithOwner:self];
		
		//If the new user icon is not the same as the one we set in updateListObject: (either cached or not), update the cache
		if (userIcon != ownedUserIcon)
			[self _cacheUserIcon:userIcon forObject:inObject];
	}
}

- (BOOL)_cacheUserIcon:(NSImage *)inImage forObject:(AIListObject *)inObject
{
	BOOL		success;
	NSString	*cachedImagePath = [self _cachedImagePathForObject:inObject];
	
	//Evan: Note that animatation is going to be stripped in the caching process... not sure how to handle this, since
	//the NSImage GIF handling is horrible.
	success = ([[inImage TIFFRepresentation] writeToFile:cachedImagePath
											  atomically:YES]);
	if (success)
		[inObject setStatusObject:cachedImagePath 
						   forKey:@"UserIconPath"
						   notify:YES];
	
	return success;
}

- (NSString *)_cachedImagePathForObject:(AIListObject *)inObject
{
	//Appending .tiff is probably unnecessary; may want to change this later
	return ([USER_ICON_CACHE_PATH stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.tiff",[inObject uniqueObjectID]]]);
}

@end
