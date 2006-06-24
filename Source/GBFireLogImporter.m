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
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/NSCalendarDate+ISO8601Unparsing.h>
#import <Adium/AIAccount.h>
#import "AIAccountController.h"
#import "AIAdium.h"
#import "AIInterfaceController.h"
#import "AILoginController.h"
#import "AILoggerPlugin.h"
#import "ESTextAndButtonsWindowController.h"

#define XML_MARKER @"<?xml version=\"1.0\"?>"

@interface GBFireLogImporter (private)
- (void)askBeforeImport;
- (void)importFireLogs;
@end

@implementation GBFireLogImporter

+ (void)importLogs
{
	GBFireLogImporter *importer = [[GBFireLogImporter alloc] init];
	[importer askBeforeImport];
	[importer release];
}

- (id)init
{
	self = [super init];
	if(self == nil)
		return nil;
	
	[NSBundle loadNibNamed:@"FireLogImporter" owner:self];
	
	return self;
}

- (void)askBeforeImport
{
	[[adium interfaceController] displayQuestion:AILocalizedString(@"Import Fire Logs?",nil)
								 withDescription:AILocalizedString(@"For some older log formats, the importer cannot properly determine which account was used for conversation.  In such cases, the importer will guess which account to use based upon the order of the accounts.  Before importing Fire's logs, arrange your account order within the Preferences.",nil)
								 withWindowTitle:nil
								   defaultButton:AILocalizedString(@"Import", nil)
								 alternateButton:AILocalizedString(@"Cancel", nil)
									 otherButton:nil
										  target:self
										selector:@selector(importQuestionResponse:userInfo:)
										userInfo:nil];
}

- (void)importQuestionResponse:(NSNumber *)response userInfo:(id)info
{
	if([response intValue] == AITextAndButtonsDefaultReturn)
		[NSThread detachNewThreadSelector:@selector(importFireLogs) toTarget:self withObject:nil];
}

NSString *quotes[] = {
	@"(I have gotten into the habit of recording important mettings)",
	@"(One never knows when an inconvenient truth will fall between the cracks and vanish)",
	@"(I have the feeling he and his associates are carving a great, dark hole in the middle of the universe)",
	@"(and when they go down, anyone nearby will go down with them)",
	@"(- Londo Mollari)"
};

- (void)importFireLogs
{
	NSAutoreleasePool *outerPool = [[NSAutoreleasePool alloc] init];
	[window orderFront:self];
	[progressIndicator startAnimation:nil];
	[textField_quote setStringValue:quotes[0]];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *inputLogDir = [[[fm userApplicationSupportFolder] stringByAppendingPathComponent:@"Fire"] stringByAppendingPathComponent:@"Sessions"];
	BOOL isDir = NO;
	
	if(![fm fileExistsAtPath:inputLogDir isDirectory:&isDir] || !isDir)
		//Nothing to read
		return;
	
	NSArray *subPaths = [fm subpathsAtPath:inputLogDir];
	NSString *outputBasePath = [[[[adium loginController] userDirectory] stringByAppendingPathComponent:PATH_LOGS] stringByExpandingTildeInPath];
	
	NSArray *accounts = [[adium accountController] accounts];
	int current;
	NSMutableDictionary *defaultScreenname = [NSMutableDictionary dictionary];
	for(current = [accounts count] - 1; current >= 0; current--)
	{
		AIAccount *acct = [accounts objectAtIndex:current];
		[defaultScreenname setObject:[acct UID] forKey:[acct serviceID]];
	}
	
	[progressIndicator setDoubleValue:0.0];
	[progressIndicator setIndeterminate:NO];
	int total = [subPaths count], currentQuote = 0;
	for(current = 0; current < total; current++)
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];  //A lot of temporary memory is used here
		[progressIndicator setDoubleValue:(double)current/(double)total];
		int nextQuote = current*sizeof(quotes)/sizeof(NSString *)/total;
		if(nextQuote != currentQuote)
		{
			currentQuote = nextQuote;
			[textField_quote setStringValue:quotes[currentQuote]];
		}
		NSString *logPath = [subPaths objectAtIndex:current];
		NSString *fullInputPath = [inputLogDir stringByAppendingPathComponent:logPath];
		if(![fm fileExistsAtPath:fullInputPath isDirectory:&isDir] || isDir)
		{
			//ignore directories
			[pool release];
			continue;
		}
		NSString *extension = [logPath pathExtension];
		NSArray *pathComponents = [logPath pathComponents];
		if([pathComponents count] != 2)
		{
			//Incorrect directory structure, likely a .DS_Store or something like that
			[pool release];
			continue;
		}
		
		NSString *userAndService = [pathComponents objectAtIndex:[pathComponents count] - 2];
		NSRange range = [userAndService rangeOfString:@"-" options:NSBackwardsSearch];
		NSString *user = [userAndService substringToIndex:range.location];
		NSString *service = [userAndService substringFromIndex:range.location + 1];
		NSDate *date = [NSDate dateWithNaturalLanguageString:[[pathComponents lastObject] stringByDeletingPathExtension]];
				
		if([extension isEqualToString:@"session"])
		{
			NSString *account = [defaultScreenname objectForKey:service];
			if(account == nil)
				account = @"Fire";
			NSString *outputFileDir = [[outputBasePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", service, account]] stringByAppendingPathComponent:user];
			NSString *outputFile = [outputFileDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ (%@).adiumLog", user, [date descriptionWithCalendarFormat:@"%Y-%m-%dT%H.%M.%S%z" timeZone:nil locale:nil]]];
			[fm createDirectoriesForPath:outputFileDir];
			[fm copyPath:fullInputPath toPath:outputFile handler:self];
		}
		else if([extension isEqualToString:@"session2"])
		{
			NSString *account = [defaultScreenname objectForKey:service];
			if(account == nil)
				account = @"Fire";
			NSString *outputFileDir = [[outputBasePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", service, account]] stringByAppendingPathComponent:user];
			NSString *outputFile = [outputFileDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ (%@).AdiumHTMLLog", user, [date descriptionWithCalendarFormat:@"%Y-%m-%dT%H.%M.%S%z" timeZone:nil locale:nil]]];
			[fm createDirectoriesForPath:outputFileDir];
			[fm copyPath:fullInputPath toPath:outputFile handler:self];
		}
		else if([extension isEqualToString:@"xhtml"])
		{
			NSString *outputFile = [outputBasePath stringByAppendingPathComponent:@"tempLogImport"];
			[fm createDirectoriesForPath:outputBasePath];
			GBFireXMLLogImporter *xmlLog = [[GBFireXMLLogImporter alloc] init];
			NSString *account = [xmlLog readFile:fullInputPath toFile:outputFile];
			if(account == nil)
				account = [defaultScreenname objectForKey:service];
			if(account == nil)
				account = @"Fire";
			[xmlLog release];
			NSString *realOutputFileDir = [[outputBasePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", service, account]] stringByAppendingPathComponent:user];
			NSString *realOutputFile = [realOutputFileDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ (%@).chatlog", user, [date descriptionWithCalendarFormat:@"%Y-%m-%dT%H.%M.%S%z" timeZone:nil locale:nil]]];
			[fm createDirectoriesForPath:realOutputFileDir];
			[fm movePath:outputFile toPath:realOutputFile handler:self];
		}
		[pool release];
	}
	[window close];
	[outerPool release];
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

- (NSString *)readFile:(NSString *)inFile toFile:(NSString *)outFile;
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
	
	return [[mySN retain] autorelease];
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
			{
				[sender release];
				sender = nil;
				state = XML_STATE_ENVELOPE;
			}
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
				[sender release];
				sender = nil;
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
					{
						mySN = [[account substringFromIndex:range.location + 1] retain];
						range = [mySN rangeOfString:@"@"];
						NSRange revRange = [mySN rangeOfString:@"@" options:NSBackwardsSearch];
						if(revRange.location != range.location)
						{
							NSString *oldMySN = mySN;
							mySN = [[mySN substringToIndex:revRange.location] retain];
							[oldMySN release];
						}
					}
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
			if([name isEqualToString:@"nickname"])
			{
				state = XML_STATE_EVENT_NICKNAME;
			}
		case XML_STATE_EVENT_MESSAGE:
		case XML_STATE_EVENT_NICKNAME:
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
				NSMutableString *outMessage = [NSMutableString stringWithString:@"<message"];
				if(sender != nil)
					[outMessage appendFormat:@"sender=\"%@\"", sender];
				if(date != nil)
					[outMessage appendFormat:@"time=\"%@\"", [date ISO8601DateString]];
				if([message length])
					[outMessage appendFormat:@">%@</message>\n", message];
				else
					[outMessage appendString:@"/>\n"];
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
				if([eventName isEqualToString:@"loggedOff"] || [eventName isEqualToString:@"memberParted"])
				{
					NSMutableString *outMessage = [NSMutableString stringWithString:@"<status type=\"offline\""];
					if(sender != nil)
						[outMessage appendFormat:@" sender=\"%@\"", sender];
					if(date != nil)
						[outMessage appendFormat:@" time=\"%@\"", [date ISO8601DateString]];
					[outMessage appendString:@"/>"];
					[outputFileHandle writeData:[outMessage dataUsingEncoding:NSUTF8StringEncoding]];
				}
				else if([eventName isEqualToString:@"loggedOn"] || [eventName isEqualToString:@"memberJoined"])
				{
					NSMutableString *outMessage = [NSMutableString stringWithString:@"<status type=\"online\""];
					if(sender != nil)
						[outMessage appendFormat:@" sender=\"%@\"", sender];
					if(date != nil)
						[outMessage appendFormat:@" time=\"%@\"", [date ISO8601DateString]];
					[outMessage appendString:@"/>"];
					[outputFileHandle writeData:[outMessage dataUsingEncoding:NSUTF8StringEncoding]];
				}
				else if([eventName isEqualToString:@"StatusChanged"])
				{
					//now we have to parse all these
					NSString *type = nil;
					if(message != nil)
					{
						if([message rangeOfString:@"changed status to Idle"].location != NSNotFound)
							type = @"idle";
						else if([message rangeOfString:@"status to Available"].location != NSNotFound)
							type = @"available";
						else if([message rangeOfString:@"status to Away"].location != NSNotFound)
							type = @"away";
						else if([message rangeOfString:@"status to Busy"].location != NSNotFound)
							type = @"busy";
						else if([message rangeOfString:@"status to Not at Home"].location != NSNotFound)
							type = @"notAtHome";
						else if([message rangeOfString:@"status to On the Phone"].location != NSNotFound)
							type = @"onThePhone";
						else if([message rangeOfString:@"status to On Vacation"].location != NSNotFound)
							type = @"onVacation";
						else if([message rangeOfString:@"status to Do Not Disturb"].location != NSNotFound)
							type = @"doNotDisturb";
						else if([message rangeOfString:@"status to Extended Away"].location != NSNotFound)
							type = @"extendedAway";
						else if([message rangeOfString:@"status to Be Right Back"].location != NSNotFound)
							type = @"beRightBack";
						else if([message rangeOfString:@"status to Be NA"].location != NSNotFound)
							type = @"notAvailable";
						else if([message rangeOfString:@"status to Be Not at Home"].location != NSNotFound)
							type = @"notAtHome";
						else if([message rangeOfString:@"status to Not at my Desk"].location != NSNotFound)
							type = @"notAtMyDesk";
						else if([message rangeOfString:@"status to Not in the Office"].location != NSNotFound)
							type = @"notInTheOffice";
						else if([message rangeOfString:@"status to Stepped Out"].location != NSNotFound)
							type = @"steppedOut";
						else
							NSLog(@"Unknown type %@", message);
					}
					//if the type is unknown, we can't do anything, drop it!
					if(type != nil)
					{
						int colonIndex = [message rangeOfString:@":"].location;
						
						NSMutableString *outMessage = [NSMutableString stringWithFormat:@"<status type=\"%@\"", type];
						if(sender != nil)
							[outMessage appendFormat:@" sender=\"%@\"", sender];
						if(date != nil)
							[outMessage appendFormat:@" time=\"%@\"", [date ISO8601DateString]];

						NSString *subStr = nil;
						if(colonIndex != NSNotFound && [message length] > colonIndex + 2)
							subStr = [message substringFromIndex:colonIndex + 2];
						if([subStr length])
							[outMessage appendFormat:@">%@</status>\n", subStr];
						else
							[outMessage appendString:@"/>\n"];
					}
				}
				else if([eventName isEqualToString:@"topicChanged"] ||
						[eventName isEqualToString:@"memberPromoted"] ||
						[eventName isEqualToString:@"memberDemoted"] ||
						[eventName isEqualToString:@"memberVoiced"] ||
						[eventName isEqualToString:@"memberDevoiced"] ||
						[eventName isEqualToString:@"memberKicked"] ||
						[eventName isEqualToString:@"newNickname"])
				{
					NSMutableString *outMessage = [NSMutableString stringWithFormat:@"<status type=\"%@\"", eventName];
					if(sender != nil)
						[outMessage appendFormat:@" sender=\"%@\"", sender];
					if(date != nil)
						[outMessage appendFormat:@" time=\"%@\"", [date ISO8601DateString]];
					
					[outMessage appendFormat:@">%@</status>\n", message];
				}
				else if(eventName == nil)
				{
					//Generic message
					NSMutableString *outMessage = [NSMutableString stringWithFormat:@"<event type=\"service\"", eventName];
					if(sender != nil)
						[outMessage appendFormat:@" sender=\"%@\"", sender];
					if(date != nil)
						[outMessage appendFormat:@" time=\"%@\"", [date ISO8601DateString]];
					
					[outMessage appendFormat:@">%@</status>\n", message];
				}
				else
				{
					//Need to translate these
					NSLog(@"Got an Event %@ at %@: %@",
						  eventName,
						  date,
						  message);
				}
				[message release];
				state = XML_STATE_EVENT;
			}
			break;
		case XML_STATE_EVENT_NICKNAME:
			state = XML_STATE_EVENT;
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
		case XML_STATE_EVENT_NICKNAME:
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
