/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import "AIServiceType.h"

// The reason for this class is that there may be multiple instances of AIService that are compatable... 
// so only the service types need to match.  More than one AIService can return the same service type if
// they are compatable.

// menuImage is an optional argument; if it is nil but an image is passed, menuImage will be created by
// scaling image to 16x16, the size a menu item image should be.  Accordingly, if menuImage -is- passed,
// it should be a 16x16 image.  Failure to do so will make a big mess of the menu (assuming you want the
// menu items to look normal.
// If it is nil and no image is passed, default images will be used to keep menus looking consistent.

// AIServiceType also provides online, connecting, and offline menu images, 
// which are 100%, 75%, and 50% opaque versions of menuImage.

@interface AIServiceType (PRIVATE)
- (id)initWithIdentifier:(NSString *)inIdentifier description:(NSString *)inDescription image:(NSImage *)inImage
			   menuImage:(NSImage *)inMenuImage
		   caseSensitive:(BOOL)inCaseSensitive allowedCharacters:(NSCharacterSet *)inAllowedCharacters
	   ignoredCharacters:(NSCharacterSet *)inIgnoredCharacters allowedLength:(int)inAllowedLength;

- (void)buildImagesFromImage:(NSImage *)inImage menuImage:(NSImage *)inMenuImage;
@end

@implementation AIServiceType

static NSImage *genericOnlineMenuImage = nil;
static NSImage *genericConnectingMenuImage = nil;
static NSImage *genericOfflineMenuImage = nil;

//Create a new service type
+ (id)serviceTypeWithIdentifier:(NSString *)inIdentifier description:(NSString *)inDescription image:(NSImage *)inImage
					  menuImage:(NSImage *)inMenuImage
				  caseSensitive:(BOOL)inCaseSensitive allowedCharacters:(NSCharacterSet *)inAllowedCharacters
			  ignoredCharacters:(NSCharacterSet *)inIgnoredCharacters allowedLength:(int)inAllowedLength
{
    return([[[self alloc] initWithIdentifier:inIdentifier
								 description:inDescription
									   image:inImage
								   menuImage:inMenuImage
							   caseSensitive:inCaseSensitive
						   allowedCharacters:inAllowedCharacters
						   ignoredCharacters:inIgnoredCharacters
							   allowedLength:inAllowedLength] autorelease]);
}

- (NSString *)identifier{
    return(identifier);
}

- (NSString *)description{
    return(description);
}

- (NSImage *)image{
    return(image);
}

- (NSImage *)menuImage{
	return(menuImage);
}

- (NSImage *)onlineMenuImage{
	return(onlineMenuImage);
}

- (NSImage *)connectingMenuImage{
	return(connectingMenuImage);
}

- (NSImage *)offlineMenuImage{
	return(offlineMenuImage);
}

- (NSCharacterSet *)allowedCharacters
{
    return(allowedCharacters);
}

- (NSCharacterSet *)ignoredCharacters
{
    return(ignoredCharacters);
}

- (int)allowedLength
{
    return(allowedLength);
}

- (BOOL)caseSensitive
{
    return(caseSensitive);
}


//UID's are ONLY filtered when creating handles, and when renaming handles.
//When changing ownership of a handle, a filter is not necessary, since all the accounts should have the same service types and requirements.
//When account code retrieves handles from the contact list, filtering is NOT done.  It is up to the account to ensure it passes UID's in the proper format for it's service type.
//Filter UID's only when the user has entered or mucked with them in some way... UID's TO and FROM account code SHOULD ALWAYS BE VALID.
//Filters a UID.  All invalid characters and ignored characters are removed.
- (NSString *)filterUID:(NSString *)inUID removeIgnoredCharacters:(BOOL)removeIgnored
{
	NSString	*workingString = (caseSensitive ? inUID : [inUID lowercaseString]);
	
	//Prepare a little buffer for our filtered UID
	int		destLength = 0;
	unichar *dest = malloc([workingString length] * sizeof(unichar));
	
	//Filter the UID
	int pos;
	for(pos = 0; pos < [workingString length]; pos++){
		unichar c = [workingString characterAtIndex:pos];
		
        if([allowedCharacters characterIsMember:c] && (!removeIgnored || ![ignoredCharacters characterIsMember:c])){
            dest[destLength] = (removeIgnored ? [workingString characterAtIndex:pos] : [inUID characterAtIndex:pos]);
			destLength++;
		}
	}

	//Turn it back into a string and return
    NSString *filteredString = [NSString stringWithCharacters:dest length:destLength];
	free(dest);
	return(filteredString);
}


//Private ---------------------------------------------------------------------------
- (id)initWithIdentifier:(NSString *)inIdentifier description:(NSString *)inDescription image:(NSImage *)inImage
			   menuImage:(NSImage *)inMenuImage
		   caseSensitive:(BOOL)inCaseSensitive allowedCharacters:(NSCharacterSet *)inAllowedCharacters
		   ignoredCharacters:(NSCharacterSet *)inIgnoredCharacters allowedLength:(int)inAllowedLength
{
    [super init];

    identifier = [inIdentifier retain];
    description = [inDescription retain];
	
	[self buildImagesFromImage:inImage menuImage:inMenuImage];

    caseSensitive = inCaseSensitive;
    allowedCharacters = [inAllowedCharacters retain];
    ignoredCharacters = [inIgnoredCharacters retain];
	allowedLength = inAllowedLength;

    return(self);
}

- (void)buildImagesFromImage:(NSImage *)inImage menuImage:(NSImage *)inMenuImage
{
    image = [inImage retain];

	onlineMenuImage = nil;
	connectingMenuImage = nil;
	offlineMenuImage = nil;
	
	//Use the menu image if we are passed one
	if (inMenuImage){
		menuImage = [inMenuImage retain];
	}else{
		//If we aren't, but we are passed an image, create a menu image from the image
		if (inImage){
			menuImage = [[image imageByScalingToSize:NSMakeSize(16,16)] retain];
		}else{
			if (!genericOnlineMenuImage){
				genericOnlineMenuImage = [[NSImage imageNamed:@"Account_Online" forClass:[self class]] retain];
				genericConnectingMenuImage = [[NSImage imageNamed:@"Account_Connecting" forClass:[self class]] retain];
				genericOfflineMenuImage = [[NSImage imageNamed:@"Account_Offline" forClass:[self class]] retain];
			}
			
			//No menuImage called for.  Use the generic images.
			menuImage = [genericOnlineMenuImage retain];
			onlineMenuImage = [genericOnlineMenuImage retain];
			connectingMenuImage = [genericConnectingMenuImage retain];
			offlineMenuImage = [genericOfflineMenuImage retain];
		}
	}
	
	//If we didn't use the generic menu images, we won't have an online menu image yet.
	if (!onlineMenuImage){
		//Online is the same as the menuImage
		onlineMenuImage = [menuImage retain];
		connectingMenuImage = [[menuImage imageByFadingToFraction:CONNECTING_MENU_IMAGE_FRACTION] retain];
		offlineMenuImage = [[menuImage imageByFadingToFraction:OFFLINE_MENU_IMAGE_FRACTION] retain];
	}
}


- (void)dealloc
{
    [identifier release];
    [description release];
    
	[image release];
	[menuImage release];
	[onlineMenuImage release];
	[connectingMenuImage release];
	[offlineMenuImage release];
	
    [allowedCharacters release];
    [ignoredCharacters release];

    [super dealloc];
}

- (BOOL)isEqual:(id)anObject
{
	return ([anObject isKindOfClass:[self class]] && 
			[[self identifier] isEqualToString:[anObject identifier]]);
}

@end
