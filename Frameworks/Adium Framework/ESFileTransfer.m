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

#import "AIAccount.h"
#import "AIListContact.h"
#import "ESFileTransfer.h"


#define UPLOAD_ARROW		[NSString stringWithFormat:@"%C", 0x2B06]
#define DOWNLOAD_ARROW		[NSString stringWithFormat:@"%C", 0x2B07]


@implementation ESFileTransfer
//Init
+ (id)fileTransferWithContact:(AIListContact *)inContact forAccount:(AIAccount *)inAccount
{
    return [[[self alloc] initWithContact:inContact forAccount:inAccount] autorelease];    
}

- (id)initWithContact:(AIListContact *)inContact forAccount:(AIAccount *)inAccount;
{
    if ((self = [super init]))
	{
		//Retain our information
		contact = [inContact retain];
		account = [inAccount retain];
		type = Unknown_FileTransfer;
		status = Unknown_Status_FileTransfer;
		delegate = nil;
	}
	
    return self;
}

- (void)dealloc
{
    [contact release];
    [account release];
    [remoteFilename release];
    [localFilename release];
    [accountData release];
    
    [super dealloc];
}

- (AIListContact *)contact
{
    return contact;   
}

- (AIAccount<AIAccount_Files> *)account
{
    return account;   
}

- (void)setRemoteFilename:(NSString *)inRemoteFilename
{
    if (remoteFilename != inRemoteFilename) {
        [remoteFilename release];
        remoteFilename = [inRemoteFilename retain];
    }
}
- (NSString *)remoteFilename
{
    return remoteFilename;
}

- (void)setLocalFilename:(NSString *)inLocalFilename
{
    if (localFilename != inLocalFilename) {
        [localFilename release];
        localFilename = [inLocalFilename retain];
	}
	
	if (delegate)
		[delegate fileTransfer:self didSetLocalFilename:localFilename];
}
- (NSString *)localFilename
{
    return localFilename;
}

- (NSString *)displayFilename
{
	NSString	*displayFilename = [localFilename lastPathComponent];
	
	//If we don't have a local file name, try to use the remote file name.
	if (!displayFilename) displayFilename = [remoteFilename lastPathComponent];
	
	return displayFilename;
}

- (void)setSize:(unsigned long long)inSize
{
    size = inSize;
	
	if (delegate)
		[delegate fileTransfer:self didSetSize:size];
}
- (unsigned long long)size
{
    return size;
}

- (void)setType:(FileTransferType)inType
{
    type = inType;
	
	if (delegate)
		[delegate fileTransfer:self didSetType:type];
}
- (FileTransferType)type
{
    return type;   
}

- (void)setStatus:(FileTransferStatus)inStatus
{
	if (status != inStatus) {
		status = inStatus;
		
		[[adium fileTransferController] fileTransfer:self didSetStatus:status];
		
		if (delegate)
			[delegate fileTransfer:self didSetStatus:status];
	}
}
- (FileTransferStatus)status
{
	return status;
}

/*
 * @brief Report a progress update on the file transfer
 *
 * @param inPercent The percentage complete.  If 0, inBytesSent will be used to calculate the percent complete if possible.
 * @param inBytesSent The number of bytes sent. If 0, inPercent will be used to calculate bytes sent if possible.
 */
- (void)setPercentDone:(float)inPercent bytesSent:(unsigned long long)inBytesSent
{
	float oldPercentDone = percentDone;
	unsigned long long oldBytesSent = bytesSent;

    if (inPercent == 0) {		
        if (inBytesSent != 0 && size != 0) {
            percentDone = ((float)inBytesSent / (float)size);
		} else {
			percentDone = inPercent;
		}

    } else {
        percentDone = inPercent;
    }

    if (inBytesSent == 0) {
        if (inPercent != 0 && size != 0) {
            bytesSent = inPercent * size;
		} else {
			bytesSent = inBytesSent;			
		}

    } else {

        bytesSent = inBytesSent;
	}
	
	if ((percentDone != oldPercentDone) || (bytesSent != oldBytesSent)) {
		if (delegate) {
			[delegate gotUpdateForFileTransfer:self];
		}
		
		if (percentDone >= 1.0) {
			[self setStatus:Complete_FileTransfer];
		} else if ((percentDone != 0) && (status != In_Progress_FileTransfer)) {
			[self setStatus:In_Progress_FileTransfer];
		}
	}
}
- (float)percentDone
{
    return percentDone;
}
- (unsigned long long)bytesSent
{
    return bytesSent;
}

- (void)setAccountData:(id)inAccountData
{
    if (accountData != inAccountData) {
        [accountData release];
        accountData = [inAccountData retain];
    }
}
- (id)accountData
{
    return accountData;   
}

- (void)setDelegate:(id <FileTransferDelegate>)inDelegate
{
	delegate = inDelegate;
}
- (id <FileTransferDelegate>)delegate;
{
	return delegate;
}

- (AIListObject *)source
{
	AIListObject	*source;
	switch (type) {
		case Incoming_FileTransfer:
			source = contact;
			break;
		case Outgoing_FileTransfer:
			source = account;
			break;
		default:
			source = nil;
			break;
	}
	
	return source;
}
- (AIListObject *)destination
{
	AIListObject	*destination;
	switch (type) {
		case Incoming_FileTransfer:
			destination = account;
			break;
		case Outgoing_FileTransfer:
			destination = contact;
			break;
		default:
			destination = nil;
			break;
	}
	
	return destination;	
}

- (void)cancel
{
	[[self account] cancelFileTransfer:self];
}

- (void)reveal
{
	[[NSWorkspace sharedWorkspace] selectFile:localFilename
					 inFileViewerRootedAtPath:[localFilename stringByDeletingLastPathComponent]];
}

- (void)openFile
{
	[[NSWorkspace sharedWorkspace] openFile:localFilename];
}

- (NSImage *)iconImage
{
	NSImage		*iconImage = nil;
	NSString	*extension;
	
	extension = [[self localFilename] pathExtension];
	
	//Fall back on the remote filename if necessary
	if (!extension) extension = [[self remoteFilename] pathExtension]; 
	
	if (extension && [extension length]) {		
		NSImage		*systemIcon = [[NSWorkspace sharedWorkspace] iconForFileType:extension];
		NSString	*badgeArrow = nil; 
		NSFont		*appleGothicFont = [NSFont fontWithName:@"AppleGothic" size:24];

		switch (type) {
			case Incoming_FileTransfer:
				badgeArrow = DOWNLOAD_ARROW;
				break;
			case Outgoing_FileTransfer:
				badgeArrow = UPLOAD_ARROW;			
				break;
			case Unknown_FileTransfer:
			default:
				break;
		}
		
		if (!badgeArrow || !appleGothicFont)
			return systemIcon;
		
		// If type is Incoming (*down*load) or Outgoing (*up*load), overlay an arrow in a circle.
		iconImage = [[NSImage alloc] initWithSize:[systemIcon size]];
		
		NSRect	rect = { NSZeroPoint, [iconImage size] };
		NSRect	bottomRight = NSMakeRect(NSMidX(rect), ([iconImage isFlipped] ? NSMidY(rect) : NSMinY(rect)), (NSWidth(rect)/2.0), (NSHeight(rect)/2.0));		

		NSMutableDictionary *atts = [(NSMutableDictionary *)[[NSDictionary dictionaryWithObjectsAndKeys:
			[NSColor alternateSelectedControlColor], NSForegroundColorAttributeName,
			appleGothicFont, NSFontAttributeName, // AppleGothic has our arrow glyphs
			nil] mutableCopy] autorelease];
		
		NSSize arrowSize = [badgeArrow sizeWithAttributes:atts];
		while (arrowSize.height > NSHeight(bottomRight)*0.9) { // shrink arrow to fit
			NSFont *tempFont = (NSFont *)[atts objectForKey:NSFontAttributeName];
			[atts setObject:[NSFont fontWithName:[tempFont fontName] size:[tempFont pointSize]*0.99] forKey:NSFontAttributeName];
			arrowSize = [badgeArrow sizeWithAttributes:atts];
		}
		
		[iconImage lockFocus];
		
		[systemIcon compositeToPoint:NSMakePoint(0.0,0.0) operation:NSCompositeSourceOver];
		
		float line = ((NSWidth(bottomRight) / 15) + ((NSHeight(bottomRight) / 15) / 2));
		NSRect	circleRect = NSMakeRect(NSMinX(bottomRight),
										NSMinY(bottomRight) + (line),
										NSWidth(bottomRight) - (line),
										NSHeight(bottomRight) - (line));

		NSBezierPath *circle = [NSBezierPath bezierPathWithOvalInRect:circleRect];
		[circle setLineWidth:line];
		[[[NSColor alternateSelectedControlColor] colorWithAlphaComponent:0.75] setStroke];
		[[[NSColor alternateSelectedControlTextColor] colorWithAlphaComponent:0.75] setFill];
		[circle fill];
		[circle stroke];
		
		NSMutableParagraphStyle *mps = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		[mps setAlignment:NSCenterTextAlignment];
		float lineheight = NSHeight(circleRect) * 0.99;
		[mps setMaximumLineHeight:lineheight];
		[mps setMinimumLineHeight:lineheight];
		[mps setLineHeightMultiple:lineheight];
		[atts setObject:mps forKey:NSParagraphStyleAttributeName];
		[mps release];

		[badgeArrow drawInRect:circleRect withAttributes:atts];
		
		[iconImage unlockFocus];
		[iconImage autorelease];
	}

	return iconImage;
}	

- (BOOL)isStopped
{
	return (status == Complete_FileTransfer ||
		   (status == Canceled_Local_FileTransfer) ||
		   (status == Canceled_Remote_FileTransfer));
}

@end
