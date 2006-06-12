/*
 * AIXMLAppender.m
 *
 * Created by Colin Barrett on 12/23/05.
 *
 * This class is explicitly released under the BSD license with the following modification:
 * It may be used without reproduction of its copyright notice within The Adium Project.
 *
 * This class was created for use in the Adium project, which is released under the GPL.
 * The release of this specific class (AIXMLAppender) under BSD in no way changes the licensing of any other portion
 * of the Adium project.
 *
 ****
 Copyright (c) 2005, 2006 Colin Barrett
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer 
 in the documentation and/or other materials provided with the distribution.
 Neither the name of Adium nor the names of its contributors may be used to endorse or promote products
 derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
 INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/* TODO:
- Possible support for "healing" a damaged XML file?
- Possibly refactor the initializeDocument... and addElement... methods to return a BOOL and/or RBR an error code of some kind to indicate success or failure.
- Instead of just testing for ' ' in -rootElementNameForFileAtPath:, use NSCharacterSet and be more general.
*/


#import "AIXMLAppender.h"
#import <AIUtilities/AIFileManagerAdditions.h>
#import <sys/stat.h>

#define XML_APPENDER_BLOCK_SIZE 4096

#define XML_MARKER @"<?xml version=\"1.0\"?>"
enum { xmlMarkerLength = 21 };

@interface AIXMLAppender(PRIVATE)
- (NSString *)createElementWithName:(NSString *)name content:(NSString *)content attributeKeys:(NSArray *)keys attributeValues:(NSArray *)values;
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
		//We may need to create the directory structure, so call this just in case
		} else {
			NSFileManager *mgr = [NSFileManager defaultManager];

			//Save the current working directory, so we can change back to it.
			NSString *savedWorkingDirectory = [mgr currentDirectoryPath];
			//Change to the root.
			[mgr changeCurrentDirectoryPath:@"/"];

			/*Create each component of the path, then change into it.
			 *E.g. /foo/bar/baz:
			 *	cd /
			 *	mkdir foo
			 *	cd foo
			 *	mkdir bar
			 *	cd bar
			 *	mkdir baz
			 *	cd baz
			 *	cd $savedWorkingDirectory
			 */
			NSArray *pathComponents = [[filePath stringByDeletingLastPathComponent] pathComponents];
			NSEnumerator *pathComponentsEnum = [pathComponents objectEnumerator];
			NSString *component;
			while ((component = [pathComponentsEnum nextObject])) {
				[mgr createDirectoryAtPath:component attributes:nil];
				[mgr changeCurrentDirectoryPath:component];
			}

			[mgr changeCurrentDirectoryPath:savedWorkingDirectory];
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
 * @param attributeKeys An array of the attribute keys the element has.
 * @param attributeValues An array of the attribute values the element has.
 */
- (void)initializeDocumentWithRootElementName:(NSString *)name attributeKeys:(NSArray *)keys attributeValues:(NSArray *)values
{
	//Don't initialize twice
	if (!initialized) {
		//Keep track of this for later
		rootElementName = [name retain];

		//Create our strings
		int closingTagLength = [rootElementName length] + 4; //</rootElementName>
		NSString *rootElement = [self createElementWithName:rootElementName content:@"" attributeKeys:keys attributeValues:values];
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
 * @param attributeKeys An array of the attribute keys the element has.
 * @param attributeValues An array of the attribute values the element has.
 */

- (void)addElementWithName:(NSString *)name content:(NSString *)content attributeKeys:(NSArray *)keys attributeValues:(NSArray *)values
{
	[self addElementWithName:name
			  escapedContent:(content ? [(NSString *)CFXMLCreateStringByEscapingEntities(kCFAllocatorDefault, (CFStringRef)content, NULL) autorelease] : nil)
			   attributeKeys:keys
			 attributeValues:values];
}

/*!
 * @brief Adds a node to the document, performing no escaping on the content.
 *
 * @param name The name of the root element for this document.
 * @param content The stuff between the open and close tags. If nil, then the tag will be self closing. No escaping will be performed on the content.
 * @param attributeKeys An array of the attribute keys the element has.
 * @param attributeValues An array of the attribute values the element has.
 */

- (void)addElementWithName:(NSString *)name escapedContent:(NSString *)content attributeKeys:(NSArray *)keys attributeValues:(NSArray *)values
{
	//Don't add if not initialized
	if (initialized) {
		//Create our strings
		NSString *element = [self createElementWithName:name content:content attributeKeys:keys attributeValues:values];
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
 * @param content The stuff between the open and close tags. If nil, then the tag will be self closing. No escaping will be performed on the content.
 * @param attributeKeys An array of the attribute keys the element has.
 * @param attributeValues An array of the attribute values the element has.
 * @return An XML element, suitable for insertion into a document.
 *
 * The two attribute arrays must be of the same size, or the method will return nil.
 */

- (NSString *)createElementWithName:(NSString *)name content:(NSString *)content attributeKeys:(NSArray *)keys attributeValues:(NSArray *)values
{
	//Check our precondition
	if ([keys count] != [values count]) {
		NSLog(@"Attribute key and value arrays are of differing lengths, %u and %u, respectively", [keys count], [values count]);
		return nil;
	}
	
	//Collapse the attributes
	NSMutableString *attributeString = [NSMutableString string];
	NSEnumerator *attributeKeyEnumerator = [keys objectEnumerator];
	NSEnumerator *attributeValueEnumerator = [values objectEnumerator];
	NSString *key = nil, *value = nil;
	while ((key = [attributeKeyEnumerator nextObject]) && (value = [attributeValueEnumerator nextObject])) {
		[attributeString appendFormat:@" %@=\"%@\"", 
			[(NSString *)CFXMLCreateStringByEscapingEntities(kCFAllocatorDefault, (CFStringRef)key, NULL) autorelease],
			[(NSString *)CFXMLCreateStringByEscapingEntities(kCFAllocatorDefault, (CFStringRef)value, NULL) autorelease]];
	}
	
	//Format and return
	NSString *escapedName = [(NSString *)CFXMLCreateStringByEscapingEntities(kCFAllocatorDefault, (CFStringRef)name, NULL) autorelease];
	if (content)
		return [NSString stringWithFormat:@"<%@%@>%@</%@>", escapedName, attributeString, content, escapedName];
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
