#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h> 
#import "GetMetadataForHTMLLog.h"
#import "NSCalendarDate+ISO8601Parsing.h"

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

Boolean GetMetadataForXMLLog(NSMutableDictionary *attributes, NSString *pathToFile);
NSString *GetTextContentForXMLLog(NSString *pathToFile);

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
	} else if (CFStringCompare(contentTypeUTI, (CFStringRef)@"com.adiumx.xmllog", kCFCompareBackwards) == kCFCompareEqualTo) {
		success = GetMetadataForXMLLog((NSMutableDictionary *)attributes, (NSString *)pathToFile);
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
							CFSTR("chatLog"),
							(kCFCompareBackwards | kCFCompareCaseInsensitive)) == kCFCompareEqualTo) {
			contentTypeUTI = CFSTR("com.adiumx.xmllog");
		} else if (CFStringCompare((CFStringRef)[(NSString *)pathToFile pathExtension],
							CFSTR("AdiumXMLLog"),
							(kCFCompareBackwards | kCFCompareCaseInsensitive)) == kCFCompareEqualTo) {
			contentTypeUTI = CFSTR("com.adiumx.xmllog");
		} else {
			//Treat all other log extensions as HTML logs (plaintext will come out fine this way, too)
			contentTypeUTI = CFSTR("com.adiumx.htmllog");
		}
	}
		
	if (CFStringCompare(contentTypeUTI, CFSTR("com.adiumx.htmllog"), kCFCompareBackwards) == kCFCompareEqualTo) {
		textContent = (CFStringRef)GetTextContentForHTMLLog((NSString *)pathToFile);
	} else if (CFStringCompare(contentTypeUTI, (CFStringRef)@"com.adiumx.xmllog", kCFCompareBackwards) == kCFCompareEqualTo) {
		textContent = (CFStringRef)GetTextContentForXMLLog((NSString *)pathToFile);
		
	} else {
		textContent = nil;
		NSLog(@"We were passed %@, of type %@, which is an unknown type",pathToFile,contentTypeUTI);
	}

	if (textContent) CFRetain(textContent);
	[pool release];
	
	return textContent;
}

/*
 * @brief get metadata for an XML file
 *
 * This function gets the metadata contained within a universal chat log format file
 * @param attributes The dictionary in which to store the metadata
 * @param pathToFile The path to the file to index
 *
 * @result true if successful, false if not
 */
Boolean GetMetadataForXMLLog(NSMutableDictionary *attributes, NSString *pathToFile)
{
	Boolean ret = YES;
	NSXMLDocument *xmlDoc;
	NSError *err=nil;
	NSURL *furl = [NSURL fileURLWithPath:(NSString *)pathToFile];
	xmlDoc = [[NSXMLDocument alloc] initWithContentsOfURL:furl
												  options:NSXMLNodePreserveCDATA
													error:&err];    
	
	if (xmlDoc)
	{        
		NSArray *authorsArray = [xmlDoc nodesForXPath:@"//message/@sender"
												error:&err];
		NSSet *duplicatesRemover = [NSSet setWithArray: authorsArray];
		authorsArray = [duplicatesRemover allObjects];
		
		[(NSMutableDictionary *)attributes setObject:authorsArray
											  forKey:(NSString *)kMDItemAuthors];
		
		NSArray *contentArray = [xmlDoc nodesForXPath:@"//message/*/text()"
												error:&err];
		NSString *contentString = [contentArray componentsJoinedByString:@" "];
		
		[attributes setObject:contentString
					   forKey:(NSString *)kMDItemTextContent];

		NSString *serviceString = [[[xmlDoc rootElement] attributeForName:@"service"] objectValue];
		if(serviceString != nil)
			[attributes setObject:serviceString
						   forKey:@"com_adiumX_service"];
		
		NSArray *children = [[xmlDoc rootElement] children];
		NSString *dateStr = [[(NSXMLElement *)[children objectAtIndex:0] attributeForName:@"time"] objectValue];
		NSCalendarDate *startDate = [NSCalendarDate calendarDateWithString:dateStr];
		if(startDate != nil)
			[(NSMutableDictionary *)attributes setObject:startDate
												  forKey:(NSString *)kMDItemContentCreationDate];

		dateStr = [[(NSXMLElement *)[children objectAtIndex:0] attributeForName:@"time"] objectValue];
		NSCalendarDate *endDate = [NSCalendarDate calendarDateWithString:dateStr];
		if(endDate != nil)
			[(NSMutableDictionary *)attributes setObject:[NSNumber numberWithInt:[endDate timeIntervalSinceDate:startDate]]
												  forKey:(NSString *)kMDItemDurationSeconds];
		
		NSString *accountString = [[[xmlDoc rootElement] attributeForName:@"account"] objectValue];
		if(accountString != nil)
		{
			[attributes setObject:accountString
						   forKey:@"com_adiumX_chatSource"];
			NSMutableArray *otherAuthors = [authorsArray mutableCopy];
			[otherAuthors removeObject:accountString];
			//pick the first author for this.  likely a bad idea
			NSString *toUID = [otherAuthors objectAtIndex:0];
			[attributes setObject:[NSString stringWithFormat:@"%@ on %@",toUID,[startDate descriptionWithCalendarFormat:@"%y-%m-%d"
																											   timeZone:nil
																												 locale:nil]]
						   forKey:(NSString *)kMDItemDisplayName];
			[otherAuthors release];
			
		}
		[attributes setObject:@"Chat log"
					   forKey:(NSString *)kMDItemKind];
		
		[xmlDoc release];
	}
	else
		ret = NO;
	
	return ret;
}

NSString *GetTextContentForXMLLog(NSString *pathToFile)
{
	NSXMLDocument *xmlDoc;
	NSError *err=nil;
	NSURL *furl = [NSURL fileURLWithPath:(NSString *)pathToFile];
	xmlDoc = [[NSXMLDocument alloc] initWithContentsOfURL:furl
												  options:NSXMLNodePreserveCDATA
													error:&err];    

	NSArray *contentArray = [xmlDoc nodesForXPath:@"//message/*/text()"
											error:&err];
	NSString *contentString = [contentArray componentsJoinedByString:@" "];

	return contentString;
}
