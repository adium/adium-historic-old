/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIXMLAppender.h"
#import <sys/stat.h>

#define XML_APPENDER_BLOCK_SIZE 4096

#define XML_MARKER @"<?xml version=\"1.0\"?>"
enum { xmlMarkerLength = 21 };

@interface AIXMLAppender(PRIVATE)
- (NSString *)createElementWithName:(NSString *)name content:(NSString *)content attributes:(NSDictionary *)attributes;
- (NSString *)rootElementNameForFileAtPath:(NSString *)path;
@end

/*!
 * @class AIXMLAppender
 * @brief Provides multiple-write access to an XML document while maintaining wellformedness.
 *
 * Just a couple of general comments here;
 * - Despite the hackish nature of seeking backwards and overwriting, sometimes you need to cheat a little or things
 *   get a bit insane. That's what was happening, so a Grand Compromise was reached, and this is what we're doing.
 */
 
@implementation AIXMLAppender

/*!
 * @brief Create a new, autoreleased document.
 *
 * @param path Path to the file where XML document will be stored
 */
+ (id)documentWithPath:(NSString *)path 
{
	return [[[self alloc] initWithPath:path] autorelease];
}

/*!
 * @brief Create a new document at the path \a path
 *
 * @param path 
 */
- (id)initWithPath:(NSString *)path
{
	if ((self = [super init])) {
		//Set up our instance variables
		initialized = NO;
		rootElementName = nil;
		filePath = [path copy];
		
		//Check if the file already exists
		if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
			//Get the root element name and set initialized
			rootElementName = [[self rootElementNameForFileAtPath:filePath] retain];
			initialized = (rootElementName != nil);				
		}
		
		//Open our file handle and seek if necessary
		const char *pathCString = [filePath fileSystemRepresentation];
		int fd = open(pathCString, O_CREAT | O_WRONLY, 0644);
		file = [[NSFileHandle alloc] initWithFileDescriptor:fd closeOnDealloc:YES];
		if (initialized) {
			struct stat sb;
			fstat(fd, &sb);
			int closingTagLength = [rootElementName length] + 4; //</rootElementName>
			[file seekToFileOffset:sb.st_size - closingTagLength];
		}
	}

	return self;
}

/*!
 * @brief Clean up.
 */
- (void)dealloc
{
	[filePath release];
	[file release]; //This will also close the fd, since we set the closeOnDealloc flag to YES
	[rootElementName release];
	[super dealloc];
}


/*!
 * @brief If the document is initialized.
 *
 * @return YES if the document is initialized. NO otherwise.
 *
 * This should be called before adding any elements to the document. If the document is uninitialized, any element
 * adding methods will fail. If the document is initialized, any initializing methods will fail.
 */
- (BOOL)isInitialized
{
	return initialized;
}

/*!
 * @brief The path to the file.
 *
 * @return The path to the file the XML document is being written to.
 */
- (NSString *)path
{
	return filePath;
}

/*!
 * @brief Name of the root element of this document
 *
 * @return The name of the root element of this document, nil if not initialized.
 */
- (NSString *)rootElement
{
	return rootElementName;
}

/*!
 * @brief Sets up the document.
 *
 * @param name The name of the root element for this document.
 * @param attributes A dictionary of the element's attributes.
 */
- (void)initializeDocumentWithRootElementName:(NSString *)name attributes:(NSDictionary *)attributes
{
	//Don't initialize twice
	if (!initialized) {
		//Keep track of this for later
		rootElementName = [name retain];

		//Create our strings
		int closingTagLength = [rootElementName length] + 4; //</rootElementName>
		NSString *rootElement = [self createElementWithName:rootElementName content:@"" attributes:attributes];
		NSString *initialDocument = [NSString stringWithFormat:@"%@\n%@\n", XML_MARKER, rootElement];
		
		//Write the data, and then seek backwards
		[file writeData:[initialDocument dataUsingEncoding:NSUTF8StringEncoding]];
		[file synchronizeFile];
		[file seekToFileOffset:([file offsetInFile] - closingTagLength)];
		
		initialized = YES;
	}
}

/*!
 * @brief Adds a node to the document.
 *
 * @param name The name of the root element for this document.
 * @param content The stuff between the open and close tags. If nil, then the tag will be self closing.
 * @param attributes A dictionary of the element's attributes.
 */

- (void)addElementWithName:(NSString *)name content:(NSString *)content attributes:(NSDictionary *)attributes
{
	//Don't add if not initialized
	if (initialized) {
		//Create our strings
		NSString *element = [self createElementWithName:name content:content attributes:attributes];
		NSString *closingTag = [NSString stringWithFormat:@"</%@>\n", rootElementName];
		
		//Write the data, and then seek backwards
		[file writeData:[[element stringByAppendingString:closingTag] dataUsingEncoding:NSUTF8StringEncoding]];
		[file synchronizeFile];
		[file seekToFileOffset:([file offsetInFile] - [closingTag length])];
	}
}

#pragma mark Private Methods

/*!
 * @brief Creates an element node.
 *
 * @param name The name of the element.
 * @param content The stuff between the open and close tags. If nil, then the tag will be self closing.
 * @param attributes A dictionary of the element's attributes.
 * @return An XML element, suitable for insertion into a document.
 *
 * Currently, attributes doesn't respsect the order specified by -arrayWithObjectsAndKeys:. That's because dictionaries
 * are not ordered.
 */

- (NSString *)createElementWithName:(NSString *)name content:(NSString *)content attributes:(NSDictionary *)attributes
{
	//Collapse the attributes
	NSMutableString *attributeString = [NSMutableString string];
	NSEnumerator *attributeKeyEnumerator = [attributes keyEnumerator];
	NSString *key = nil;
	while ((key = [attributeKeyEnumerator nextObject])) {
		[attributeString appendFormat:@" %@=\"%@\"", 
			[(NSString *)CFXMLCreateStringByEscapingEntities(kCFAllocatorDefault, (CFStringRef)key, NULL) autorelease],
			[(NSString *)CFXMLCreateStringByEscapingEntities(kCFAllocatorDefault, (CFStringRef)[attributes objectForKey:key], NULL) autorelease]];
	}
	
	//Format and return
	NSString *escapedName = [(NSString *)CFXMLCreateStringByEscapingEntities(kCFAllocatorDefault, (CFStringRef)name, NULL) autorelease];
	if (content)
		return [NSString stringWithFormat:@"<%@%@>%@</%@>", escapedName, attributeString, 
			[(NSString *)CFXMLCreateStringByEscapingEntities(kCFAllocatorDefault, (CFStringRef)content, NULL) autorelease], escapedName];
	else
		return [NSString stringWithFormat:@"<%@%@/>", escapedName, attributeString];
}

/*!
 * @brief Get the root element name for file
 * 
 * @return The root element name, or nil if there isn't one (possibly because the file is not valid XML)
 */
- (NSString *)rootElementNameForFileAtPath:(NSString *)path
{
	//Create a temporary file handle for validation, and read the marker
	NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:path];
	NSString *markerString = [[[NSString alloc] initWithData:[handle readDataOfLength:xmlMarkerLength]
													encoding:NSUTF8StringEncoding] autorelease];

	if (![markerString isEqualToString:XML_MARKER]) {
		[handle closeFile];
		return nil;
	}
	
	NSScanner *scanner = nil;
	do {
		//Read a block of arbitrary size
		NSString *block = [[[NSString alloc] initWithData:[handle readDataOfLength:XML_APPENDER_BLOCK_SIZE]
												 encoding:NSUTF8StringEncoding] autorelease];
		//If we read 0 characters, then we have reached the end of the file, so return
		if ([block length] == 0) {
			[handle closeFile];
			return nil;
		}

		scanner = [NSScanner scannerWithString:block];
		[scanner scanUpToString:@"<" intoString:nil];
	} while([scanner isAtEnd]); //If the scanner is at the end, not found in this block

	//Scn past the '<' we know is there
	[scanner scanString:@"<" intoString:nil];
	
	NSString *accumulated = [NSString string];
	NSMutableString *accumulator = [NSMutableString string];
	BOOL found = NO;
	do {
		[scanner scanUpToString:@" " intoString:&accumulated]; //very naive
		[accumulator appendString:accumulated];
		
		//If the scanner is at the end, not found in this block
		found = ![scanner isAtEnd];
		
		//If we've found the end of the element name, break
		if (found)
			break;
			
		NSString *block = [[[NSString alloc] initWithData:[handle readDataOfLength:XML_APPENDER_BLOCK_SIZE]
												 encoding:NSUTF8StringEncoding] autorelease];
		//Again, if we've reached the end of the file, we aren't initialized, so return nil
		if ([block length] == 0) {
			[handle closeFile];
			return nil;
		}

		scanner = [NSScanner scannerWithString:block];
	} while (!found);
	
	[handle closeFile];
	
	//We've obviously found the root element name, so return a nonmutble copy.
	return [NSString stringWithString:accumulator];
}

@end
