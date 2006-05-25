#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h> 
#import "GetMetadataForHTMLLog.h"

/*
 Relevant keys from MDItem.h we use or may want to use:
 
 @constant kMDItemContentCreationDate
 This is the date that the contents of the file were created,
 has an application specific semantic.
 Type is a CFDate.

 @constant kMDItemTextContent
 Contains the text content of the document. Type is a CFString.
 
 @constant kMDItemDisplayName
 This is the localized version of the LaunchServices call
 LSCopyDisplayNameForURL()/LSCopyDisplayNameForRef().

 @const  kMDItemInstantMessageAddresses
 Instant message addresses for this item. Type is an Array of CFStrings.
 */
 
/* -----------------------------------------------------------------------------
Get metadata attributes from file

This function's job is to extract useful information your file format supports
and return it as a dictionary
----------------------------------------------------------------------------- */

Boolean GetMetadataForFile(void* thisInterface, 
						   CFMutableDictionaryRef attributes, 
						   CFStringRef contentTypeUTI,
						   CFStringRef pathToFile)
{
    /* Pull any available metadata from the file at the specified path */
    /* Return the attribute keys and attribute values in the dict */
    /* Return TRUE if successful, FALSE if there was no data provided */
    
	Boolean				success = FALSE;
	NSAutoreleasePool	*pool;
	pool = [[NSAutoreleasePool alloc] init];

	if (CFStringCompare(contentTypeUTI, (CFStringRef)@"com.adiumx.htmllog", kCFCompareBackwards) == kCFCompareEqualTo) {
		success = GetMetadataForHTMLLog((NSMutableDictionary *)attributes, (NSString *)pathToFile);
	} else {
		NSLog(@"We were passed %@, of type %@, which is an unknown type",pathToFile,contentTypeUTI);
	}

	[pool release];
	
    return success;
}

/*
 * @brief Copy the text content for a file
 *
 * This is the text which would be the kMDItemTextContent for the file in Spotlight.
 *
 * @param contentTypeUTI The UTI type. If NULL, the extension of pathToFile will be used
 * @param pathToFile The full path to the file
 *
 * @result The kMDItemTextContent. Follows the Copy rule.
 */
CFStringRef CopyTextContentForFile(CFStringRef contentTypeUTI,
								   CFStringRef pathToFile)
{
	NSAutoreleasePool	*pool;
	CFStringRef			textContent;
	pool = [[NSAutoreleasePool alloc] init];
	
	//Deteremine the UTI type if we weren't passed one
	if (contentTypeUTI == NULL) {
		if (CFStringCompare((CFStringRef)[(NSString *)pathToFile pathExtension],
							CFSTR("AdiumXMLLog"),
							(kCFCompareBackwards | kCFCompareCaseInsensitive)) == kCFCompareEqualTo) {
			contentTypeUTI = CFSTR("com.adiumx.log");
		} else {
			//Treat all other log extensions as HTML logs (plaintext will come out fine this way, too)
			contentTypeUTI = CFSTR("com.adiumx.htmllog");
		}
	}
		
	if (CFStringCompare(contentTypeUTI, CFSTR("com.adiumx.htmllog"), kCFCompareBackwards) == kCFCompareEqualTo) {
		textContent = (CFStringRef)GetTextContentForHTMLLog((NSString *)pathToFile);
	} else {
		textContent = nil;
		NSLog(@"We were passed %@, of type %@, which is an unknown type",pathToFile,contentTypeUTI);
	}

	if (textContent) CFRetain(textContent);
	[pool release];
	
	return textContent;
}
