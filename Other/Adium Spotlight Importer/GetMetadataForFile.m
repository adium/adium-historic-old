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
