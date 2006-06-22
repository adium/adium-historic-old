/* AIXMLElement.m
 *
 * Created by Peter Hosey on 2006-06-07.
 *
 * This class is explicitly released under the BSD license with the following modification:
 * It may be used without reproduction of its copyright notice within The Adium Project.
 *
 * This class was created for use in the Adium project, which is released under the GPL.
 * The release of this specific class (AIXMLElement) under BSD in no way changes the licensing of any other portion
 * of the Adium project.
 *
 ****
 Copyright © 2006 Peter Hosey
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 Neither the name of Peter Hosey nor the names of his contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "AIXMLElement.h"

@implementation AIXMLElement

+ (id) elementWithNamespaceName:(NSString *)namespace elementName:(NSString *)newName
{
	if (namespace)
		newName = [NSString stringWithFormat:@"%@:%@", namespace, newName];
	return [self elementWithName:newName];
}
- (id) initWithNamespaceName:(NSString *)namespace elementName:(NSString *)newName
{
	if (namespace)
		newName = [NSString stringWithFormat:@"%@:%@", namespace, newName];
	return [self initWithName:newName];
}
+ (id) elementWithName:(NSString *)newName
{
	return [[[self alloc] initWithName:newName] autorelease];
}
- (id) initWithName:(NSString *)newName
{
	NSParameterAssert(newName != nil);

	if ((self = [super init])) {
		name = [newName copy];
		attributes = [[NSMutableDictionary alloc] init];
		contents = [[NSMutableArray alloc] init];
	}
	return self;
}
- (id) init
{
	NSException *exc = [NSException exceptionWithName:@"Can't init AIXMLElement" reason:AILocalizedString(@"AIXMLElement does not support the -init method; use -initWithName: instead.", /*comment*/ nil) userInfo:nil];
	[exc raise];
	return nil;
}
- (void) dealloc
{
	[name release];
	[attributes release];
	[contents release];

	[super dealloc];
}

#pragma mark -

- (NSString *) name
{
	return name;
}

- (NSDictionary *) attributes
{
	return attributes;
}
- (void) setAttributes:(NSDictionary *)newAttrs
{
	[attributes setDictionary:newAttrs];
}

- (BOOL) selfCloses
{
	return selfCloses;
}
- (void) setSelfCloses:(BOOL)flag
{
	selfCloses = flag;
}

#pragma mark -

//NSString: Unescaped string data (will be escaped for XMLification).
//AIXMLElement: Sub-element (e.g. span in a p).
- (void) addObject:(id)obj
{
	BOOL isString = [obj isKindOfClass:[NSString class]];
	NSParameterAssert(isString || [obj isKindOfClass:[AIXMLElement class]]);

	if(isString) {
		obj = [(NSString *)CFXMLCreateStringByEscapingEntities(kCFAllocatorDefault, (CFStringRef)obj, /*entitiesDictionary*/ NULL) autorelease];
	}

	[contents addObject:obj];
}
- (void) addObjectsFromArray:(NSArray *)array
{
	//We do it this way for the assertion.
	NSEnumerator *arrayEnum = [array objectEnumerator];
	id obj;
	while ((obj = [arrayEnum nextObject])) {
		[self addObject:obj];
	}
}

- (NSArray *)contents
{
	return contents;
}
- (void)setContents:(NSArray *)newContents
{
	[contents setArray:newContents];
}

#pragma mark -

- (NSString *) quotedXMLAttributeValueStringForString:(NSString *)str
{
	return [NSString stringWithFormat:@"\"%@\"", [(NSString *)CFXMLCreateStringByEscapingEntities(kCFAllocatorDefault, (CFStringRef)str, /*entitiesDictionary*/ NULL) autorelease]];
}

- (void) appendXMLStringtoString:(NSMutableString *)string
{
	[string appendFormat:@"<%@", name];
	if ([attributes count]) {
		NSEnumerator *keysEnum = [[[attributes allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] objectEnumerator];
		NSString *key;
		while ((key = [keysEnum nextObject])) {
			NSString *value = [attributes objectForKey:key];
			if ([value respondsToSelector:@selector(stringValue)]) {
				value = [(NSNumber *)value stringValue];
			} else if ([value respondsToSelector:@selector(absoluteString)]) {
				value = [(NSURL *)value absoluteString];
			}
			[string appendFormat:@" %@=%@", key, [self quotedXMLAttributeValueStringForString:value]];
		}
	}
	if ((![contents count]) && (selfCloses)) {
		[string appendString:@" /"];
	}
	[string appendString:@">"];

	NSEnumerator *contentsEnum = [contents objectEnumerator];
	id obj;
	while ((obj = [contentsEnum nextObject])) {
		if ([obj isKindOfClass:[NSString class]]) {
			[string appendString:(NSString *)obj];
		} else if([obj isKindOfClass:[AIXMLElement class]]) {
			[(AIXMLElement *)obj appendXMLStringtoString:string];
		}
	}

	if ([contents count] || !selfCloses) {
		[string appendFormat:@"</%@>", name];
	}
}
- (NSString *) XMLString
{
	NSMutableString *string = [NSMutableString string];
	[self appendXMLStringtoString:string];
	return [NSString stringWithString:string];
}

- (void) appendUTF8XMLBytesToData:(NSMutableData *)data
{
	NSMutableString *startTag = [NSMutableString stringWithFormat:@"<%@", name];
	if ([attributes count]) {
		NSEnumerator *keysEnum = [[[attributes allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] objectEnumerator];
		NSString *key;
		while ((key = [keysEnum nextObject])) {
			NSString *value = [attributes objectForKey:key];
			if ([value respondsToSelector:@selector(stringValue)]) {
				value = [(NSNumber *)value stringValue];
			} else if ([value respondsToSelector:@selector(absoluteString)]) {
				value = [(NSURL *)value absoluteString];
			}
			[startTag appendFormat:@" %@=%@", key, [self quotedXMLAttributeValueStringForString:value]];
		}
	}
	if ((![contents count]) && (selfCloses)) {
		[startTag appendString:@" /"];
	}
	[startTag appendString:@">"];
	[data appendData:[startTag dataUsingEncoding:NSUTF8StringEncoding]];

	NSEnumerator *contentsEnum = [contents objectEnumerator];
	id obj;
	while ((obj = [contentsEnum nextObject])) {
		if ([obj isKindOfClass:[NSString class]]) {
			[data appendData:[(NSString *)obj dataUsingEncoding:NSUTF8StringEncoding]];
		} else if([obj isKindOfClass:[AIXMLElement class]]) {
			[(AIXMLElement *)obj appendUTF8XMLBytesToData:data];
		}
	}

	if ([contents count] || !selfCloses) {
		[data appendData:[[NSString stringWithFormat:@"</%@>", name] dataUsingEncoding:NSUTF8StringEncoding]];
	}
}
- (NSData *)UTF8XMLData
{
	NSMutableData *data = [NSMutableData data];
	[self appendUTF8XMLBytesToData:data];
	return [NSData dataWithData:data];
}

- (NSString *)description
{
	NSMutableString *string = [NSMutableString stringWithFormat:@"<%@ AIXMLElement:id=\"%p\"", name, self];
	if ([attributes count]) {
		NSEnumerator *keysEnum = [[[attributes allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] objectEnumerator];
		NSString *key;
		while ((key = [keysEnum nextObject])) {
			NSString *value = [attributes objectForKey:key];
			if ([value respondsToSelector:@selector(stringValue)]) {
				value = [(NSNumber *)value stringValue];
			} else if ([value respondsToSelector:@selector(absoluteString)]) {
				value = [(NSURL *)value absoluteString];
			}
			[string appendFormat:@" %@=%@", key, [self quotedXMLAttributeValueStringForString:value]];
		}
	}
	[string appendString:@" />"];

	return [NSString stringWithString:string];
}

#pragma mark KVC

- (id) valueForKey:(NSString *)key {
	id obj = [attributes objectForKey:key];
	if(!obj) obj = [super valueForKey:key];
	return obj;
}
- (void) setValue:(id)obj forKey:(NSString *)key {
	[attributes setValue:obj forKey:key];
}

@end
