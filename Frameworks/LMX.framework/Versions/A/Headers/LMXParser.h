//
//  LMXParser.h
//  LMX
//
//  Created by Mac-arena the Bored Zo on 2005-10-14.
//  Copyright 2005 Mac-arena the Bored Zo. All rights reserved.
//

#include <sys/types.h>

@class NSString;

enum LMXParseResult {
	LMXParsedCompletely = 0, //element stack reached zero depth, and there was no more XML to parse
	LMXParsedIncomplete = -1, //element stack is not empty; more data is wanted
	LMXParsedCompletelyWithExtraData = -2, //element stack reached zero depth, but there's still XML to parse
};

extern NSString *LMXStringFromParseResult(enum LMXParseResult result);
extern enum LMXParseResult LMXParseResultFromString(NSString *result);

@interface LMXParser : NSObject {
	NSMutableData *dataToParse;
	off_t currentIndex;

	NSMutableArray *elementStack;

	id delegate;
	void *contextInfo;

	//parser state
	NSMutableString *characters;
	NSMutableString *currentToken;
	NSMutableString *entityName;
	NSMutableString *comment;
	NSString *systemID;
	NSMutableDictionary *overrideDict; //stores any entities that we're using our own values instead of the DTD's values for
	NSMutableDictionary *cacheDict; //caches entity values
	NSMutableDictionary *attributes;
	NSString *attributeValue;
	off_t charactersRunStartIndex, tokenRunStartIndex, entityNameRunStartIndex, commentRunStartIndex;
	off_t greaterThanIndex;
	unsigned reserved:       22;
	unsigned inComment:       1;
	//start of a comment: <!--
	//  end of a comment:   -->
	unsigned hasBang:         1; //with has{First,Second}Hyphen, indicates a comment may be about to start (if a < is encountered)
	unsigned hasSecondHyphen: 1; //with hasGreaterThan and hasFirstHyphen, part of the start of a comment
	unsigned hasFirstHyphen:  1; //with hasGreaterThan, 1/3 of the end of a comment; else, 1/3 of the start of a comment
	unsigned hasEqualSign:    1; //an attribute value has been recorded, and a = encountered
	unsigned couldBeEndTag:   1; //a / has been encountered
	unsigned isEmptyTag:      1; //a / was encountered immediately after a >
	unsigned inEntity:        1; //in between & and ;
	unsigned hasHashMark:     1; //a # was just encountered (if this is 1 when the & is encountered, it's a numeric entity; otherwise, the entity ends)
	unsigned noNonWhitespaceSinceTagEnd: 1; //used by / to check for a <blah/> tag
	unsigned inTag:           1; //in between < and >
	unsigned parsing:         1; //set to 0 by -pause
	char attributeQuoteChar; //one of '"', '\'', or '\0'
}

//how to get autoreleased parser in only one message instead of three:
+ parser;

- initWithData:(NSData *)data;

#pragma mark -

- (NSString *)systemID;
- (void)setSystemID:(NSString *)sysID;
- (void)overrideEntityNamed:(NSString *)name withValue:(NSData *)val;
- (void)setOverriddenEntities:(NSDictionary *)entityDict;
- (NSData *)dataForEntityNamed:(NSString *)name;

#pragma mark -

- (enum LMXParseResult)parseChunk:(NSData *)data;

- (void)addData:(NSData *)data; //add more data (in front of the existing data) without parsing
- (enum LMXParseResult)parse; //begin/resume parsing without adding more data

#pragma mark -

//either or both of these can be called by the delegate.
- (void)pause;
- (enum LMXParseResult)resume; //synonym for -parse

//calling -reset leaves the parser in the same state it was in (more or less) after it was inited.
//*don't* call this from the delegate.
- (void)reset;

#pragma mark -

- delegate;
- setDelegate:newDelegate; //returns old delegate.

- (void *)contextInfo;
- (void)setContextInfo:(void *)newContextInfo;

@end

@interface LMXParser (LMXCompatibilityWithNSXMLParser)

- initWithData:(NSData *)data; //same as -init, -addData:

- (void)abortParsing; //compatibility synonym for -pause

@end

@interface NSObject (LMXParserDelegate)

- (void)parserDidStartDocument:(LMXParser *)parser;

- (void)parser:(LMXParser *)parser elementEnded:(NSString *)elementName;
//returns one or two UTF-16 code units, or nil.
- (NSData *)parser:(LMXParser *)parser resolveExternalEntityName:(NSString *)entityName systemID:(NSString *)systemID;
- (void)parser:(LMXParser *)parser foundCharacters:(NSString *)string;
- (void)parser:(LMXParser *)parser elementStarted:(NSString *)elementName attributes:(NSDictionary *)attributes;

- (void)parserDidEndDocument:(LMXParser *)parser;
- (void)parser:(LMXParser *)parser finishedParsingChunk:(NSData *)chunkData withResult:(enum LMXParseResult)result;

@end
