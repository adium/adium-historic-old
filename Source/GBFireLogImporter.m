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

#import "GBFireLogImporter.h"
#import <AIUtilities/NSCalendarDate+ISO8601Unparsing.h>

#define XML_MARKER @"<?xml version=\"1.0\"?>"

@implementation GBFireLogImporter

+ (void)test
{
	GBFireXMLLogImporter *xmlLog = [[GBFireXMLLogImporter alloc] init];
	[xmlLog readFile:@"/Users/gbooker/Desktop/fireTestLog.xhtml" toFile:@"/Users/gbooker/Desktop/fireTestLog.chatlog"];
	[xmlLog release];
}

@end

static void *createStructure(CFXMLParserRef parser, CFXMLNodeRef node, void *context);
static void addChild(CFXMLParserRef parser, void *parent, void *child, void *context);
static void endStructure(CFXMLParserRef parser, void *xmlType, void *context);

@implementation GBFireXMLLogImporter

- (id)init
{
	self = [super init];
	if(self == nil)
		return nil;
	
	state = XML_STATE_NONE;
	
	inputFileHandle = nil;
	outputFileHandle = nil;
	sender = nil;
	mySN = nil;
	date = nil;
	parser = NULL;
	
	return self;
}

- (void)readFile:(NSString *)inFile toFile:(NSString *)outFile;
{
	inputFileHandle = [[NSFileHandle fileHandleForReadingAtPath:inFile] retain];
	int outfd = open([outFile fileSystemRepresentation], O_CREAT | O_WRONLY, 0644);
	outputFileHandle = [[NSFileHandle alloc] initWithFileDescriptor:outfd closeOnDealloc:YES];
	NSURL *url = [[NSURL alloc] initFileURLWithPath:inFile];
	
	CFXMLParserCallBacks callbacks = {
		0,
		createStructure,
		addChild,
		endStructure,
		NULL,
		NULL
	};
	CFXMLParserContext context = {
		0,
		self,
		CFRetain,
		CFRelease,
		NULL
	};
	parser = CFXMLParserCreateWithDataFromURL(NULL, (CFURLRef)url, kCFXMLParserSkipMetaData | kCFXMLParserSkipWhitespace, kCFXMLNodeCurrentVersion, &callbacks, &context);
	if (!CFXMLParserParse(parser)) {
		printf("parse failed\n");
	}
	CFRelease(parser);
	parser = nil;
	[url release];
	[inputFileHandle closeFile];
	[outputFileHandle closeFile];
}

- (void)dealloc
{
	[inputFileHandle release];
	[outputFileHandle release];
	[sender release];
	[mySN release];
	[date release];
	[super dealloc];
}

- (void)startedElement:(NSString *)name info:(const CFXMLElementInfo *)info
{
	NSDictionary *attributes = (NSDictionary *)info->attributes;
	
	switch(state){
		case XML_STATE_NONE:
			if([name isEqualToString:@"envelope"])
				state = XML_STATE_ENVELOPE;
			else if([name isEqualToString:@"event"])
			{
				[date release];
				
				NSString *dateStr = [attributes objectForKey:@"occurred"];
				if(dateStr != nil)
					date = [[NSCalendarDate dateWithString:dateStr] retain];
				else
					date = nil;
				
				[eventName release];
				NSString *eventStr = [attributes objectForKey:@"name"];
				if(eventStr != nil)
					eventName = [[NSString alloc] initWithString:eventStr];
				else
					eventName = nil;
				state = XML_STATE_EVENT;
			}
			else if([name isEqualToString:@"log"])
			{
				NSString *service = [attributes objectForKey:@"service"];
				NSString *account = [attributes objectForKey:@"accountName"];
				if(account != nil)
				{
					NSRange range = [account rangeOfString:@"-"];
					if(range.location != NSNotFound)
						mySN = [[account substringFromIndex:range.location + 1] retain];
				}
				NSMutableString *chatTag = [NSMutableString stringWithFormat:@"%@\n<chat", XML_MARKER];
				if(mySN != nil)
					[chatTag appendFormat:@" account=\"%@\"", mySN];
				if(service != nil)
					[chatTag appendFormat:@" service=\"%@\"", service];
				[chatTag appendString:@">\n"];
				[outputFileHandle writeData:[chatTag dataUsingEncoding:NSUTF8StringEncoding]];
			}
			break;
		case XML_STATE_ENVELOPE:
			if ([name isEqualToString:@"message"])
			{
				[date release];
				
				NSString *dateStr = [attributes objectForKey:@"received"];
				if(dateStr != nil)
					date = [[NSCalendarDate dateWithString:dateStr] retain];
				else
					date = nil;
				
				//Mark the location of the message...  We can copy it directly.  Anyone know why it is off by 2?
				messageStart = CFXMLParserGetLocation(parser) + 2;
				state = XML_STATE_MESSAGE;
			}
			else if([name isEqualToString:@"sender"])
			{
				[sender release];
				
				NSString *nickname = [attributes objectForKey:@"nickname"];
				NSString *selfSender = [attributes objectForKey:@"self"];
				if(nickname != nil)
					sender = [nickname retain];
				else if ([selfSender isEqualToString:@"yes"])
					sender = [mySN retain];
				else
					sender = nil;
				state = XML_STATE_SENDER;
			}
			break;
		case XML_STATE_SENDER:
		case XML_STATE_MESSAGE:
		case XML_STATE_EVENT:
			if([name isEqualToString:@"message"])
			{
				//Mark the location of the message...  same as above
				messageStart = CFXMLParserGetLocation(parser) + 2;
				state = XML_STATE_EVENT_MESSAGE;
			}
		case XML_STATE_EVENT_MESSAGE:
			break;
	}
}

- (void)endedElement:(NSString *)name
{
	switch(state)
	{
		case XML_STATE_ENVELOPE:
			if([name isEqualToString:@"envelope"])
			{
				[outputFileHandle writeData:[[NSString stringWithString:@"</chat>"] dataUsingEncoding:NSUTF8StringEncoding]];
				state = XML_STATE_NONE;
			}
			break;
		case XML_STATE_SENDER:
			if([name isEqualToString:@"sender"])
				state = XML_STATE_ENVELOPE;
			break;
		case XML_STATE_MESSAGE:
			if([name isEqualToString:@"message"])
			{
				CFIndex end = CFXMLParserGetLocation(parser);
				[inputFileHandle seekToFileOffset:messageStart];
				NSData *data = [inputFileHandle readDataOfLength:end-messageStart-8];  //10 chars for </message> and -2 for index being off
				
				NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
				//Common logging format
				NSString *outMessage = [NSString stringWithFormat:@"<message sender=\"%@\" time=\"%@\">%@</message>\n",
					sender,
					[date ISO8601DateString],
					message];
				[outputFileHandle writeData:[outMessage dataUsingEncoding:NSUTF8StringEncoding]];
				[message release];
				state = XML_STATE_ENVELOPE;
			}
			break;
		case XML_STATE_EVENT:
			if([name isEqualToString:@"event"])
				state = XML_STATE_NONE;
			break;
		case XML_STATE_EVENT_MESSAGE:
			if([name isEqualToString:@"message"])
			{
				CFIndex end = CFXMLParserGetLocation(parser);
				[inputFileHandle seekToFileOffset:messageStart];
				NSData *data = [inputFileHandle readDataOfLength:end-messageStart-8];  //10 chars for </message> and -2 for index being off
				
				NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
				//Need to translate these
				NSLog(@"Got an Event %@ at %@: %@",
					  eventName,
					  date,
					  message);
				[message release];
				state = XML_STATE_EVENT;
			}
			break;
		case XML_STATE_NONE:
			break;
	}
}

- (void)text:(NSString *)text
{
	switch(state)
	{
		case XML_STATE_SENDER:
			if(sender == nil)
				sender = [text retain];
		case XML_STATE_NONE:
		case XML_STATE_ENVELOPE:
		case XML_STATE_MESSAGE:
		case XML_STATE_EVENT:
		case XML_STATE_EVENT_MESSAGE:
			break;
	}
}

@end

void *createStructure(CFXMLParserRef parser, CFXMLNodeRef node, void *context)
{
	NSString *ret = nil;
	
    // Use the dataTypeID to determine what to print.
    switch (CFXMLNodeGetTypeCode(node)) {
        case kCFXMLNodeTypeDocument:
            break;
        case kCFXMLNodeTypeElement:
		{
			NSString *name = [NSString stringWithString:(NSString *)CFXMLNodeGetString(node)];
			const CFXMLElementInfo *info = CFXMLNodeGetInfoPtr(node);
			[(GBFireXMLLogImporter *)context startedElement:name info:info];
			ret = [name retain];
			break;
		}
        case kCFXMLNodeTypeProcessingInstruction:
        case kCFXMLNodeTypeComment:
			break;
        case kCFXMLNodeTypeText:
			[(GBFireXMLLogImporter *)context text:[NSString stringWithString:(NSString *)CFXMLNodeGetString(node)]];
            break;
        case kCFXMLNodeTypeCDATASection:
        case kCFXMLNodeTypeEntityReference:
        case kCFXMLNodeTypeDocumentType:
        case kCFXMLNodeTypeWhitespace:
        default:
			break;
	}
	
    // Return the data string for use by the addChild and 
    // endStructure callbacks.
    return (void *) ret;
}

void addChild(CFXMLParserRef parser, void *parent, void *child, void *context)
{
}

void endStructure(CFXMLParserRef parser, void *xmlType, void *context)
{
	NSString *name = [NSString stringWithString:(NSString *)xmlType];
	[(GBFireXMLLogImporter *)context endedElement:name];
	[(NSString *)xmlType release];
}
