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

#import <Adium/AIObject.h>

@interface GBFireLogImporter : AIObject {
	IBOutlet	NSTextField			*textField_quote;
	IBOutlet	NSProgressIndicator	*progressIndicator;
	IBOutlet	NSWindow			*window;
}

+ (void)importLogs;

@end

typedef enum{
	XML_STATE_NONE,
	XML_STATE_ENVELOPE,
	XML_STATE_SENDER,
	XML_STATE_MESSAGE,
	XML_STATE_EVENT,
	XML_STATE_EVENT_MESSAGE,
	XML_STATE_EVENT_NICKNAME
} xmlState;

@interface GBFireXMLLogImporter : NSObject {
	CFXMLParserRef	parser;
	NSFileHandle	*inputFileHandle;
	NSFileHandle	*outputFileHandle;
	
	xmlState		state;
	NSString		*sender;
	NSString		*mySN;
	NSCalendarDate	*date;
	int				messageStart;
	
	NSString		*eventName;
}

- (NSString *)readFile:(NSString *)inFile toFile:(NSString *)outFile;

- (void)startedElement:(NSString *)name info:(const CFXMLElementInfo *)info;
- (void)endedElement:(NSString *)name;
- (void)text:(NSString *)text;

@end
