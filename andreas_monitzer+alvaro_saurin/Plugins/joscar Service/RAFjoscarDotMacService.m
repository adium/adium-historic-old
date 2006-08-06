//
//  RAFjoscarDotMacService.m
//  Adium
//
//  Created by Augie Fackler on 1/10/06.
//

#import "RAFjoscarDotMacService.h"
#import "RAFjoscarDotMacAccount.h"
#import <Adium/AIAccountViewController.h>
#import "RAFjoscarAccountViewController.h"
#import <AIUtilities/AIStringUtilities.h>

@implementation RAFjoscarDotMacService

//Account Creation
- (Class)accountClass{
	return [RAFjoscarDotMacAccount class];
}

//
- (AIAccountViewController *)accountViewController{
    return [RAFjoscarAccountViewController	accountViewController];
}

//Service Description
- (NSString *)serviceCodeUniqueID{
	return @"joscar-OSCAR-dotMac";
}
#ifdef JOSCAR_SUPERCEDE_LIBGAIM
- (NSString *)serviceID{
	return @"Mac";
}
- (NSString *)shortDescription{
	return @".Mac";
}
- (NSString *)longDescription{
	return @".Mac";
}
#else
- (NSString *)serviceID{
	return @"Mac-joscar";
}
- (NSString *)shortDescription{
	return @".Mac-joscar";
}
- (NSString *)longDescription{
	return @".Mac-joscar";
}
#endif
- (NSCharacterSet *)ignoredCharacters{
	return [NSCharacterSet characterSetWithCharactersInString:@" "];
}
- (BOOL)caseSensitive{
	return NO;
}
- (AIServiceImportance)serviceImportance{
	return AIServiceSecondary;
}
- (NSString *)userNameLabel{
    return AILocalizedString(@"Member Name",nil); //.Mac Member Name
}

/*!
* @brief Filter a UID
 *
 * Add @mac.com to the end of a dotMac contact if it's not already present but should be.  super's implementation will make the UID
 * lowercase, since [self caseSensitive] returns NO, so we can use -[NSString hasSuffix:] to check for the string.
 */
- (NSString *)filterUID:(NSString *)inUID removeIgnoredCharacters:(BOOL)removeIgnored
{
	NSString	*filteredUID = [super filterUID:inUID removeIgnoredCharacters:removeIgnored];
	
#warning Right now, this code would mean that the New Message prompt for a .Mac account can only message .Mac users
	//XXX ToDo: Rewrite the New Message prompt to be service-oriented rather than account-oriented such that this isn't a problem
#if 0
	char		firstCharacter;
	
	if ([filteredUID length]) {
		/* Add @mac.com to the end if:
		*		1. It is not yet present AND
		*		2. The first character is neither a number nor a '+' (which would indicate a mobile contact)
		*/
		if ((![filteredUID hasSuffix:@"@mac.com"]) &&
			!((firstCharacter = [filteredUID characterAtIndex:0]) && 
			  ((firstCharacter >= '0' && firstCharacter <= '9') || (firstCharacter == '+'))))
		{
			AILog(@"ESDotMacService: Filtered %@ to %@@mac.com",filteredUID,filteredUID);
			filteredUID = [filteredUID stringByAppendingString:@"@mac.com"];
		}
	}
#endif
	
	return filteredUID;
}

@end
