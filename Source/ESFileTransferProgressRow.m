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

#import "ESFileTransferProgressRow.h"
#import "ESFileTransferProgressView.h"
#import "ESFileTransferProgressWindowController.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <Adium/AIListObject.h>
#import <Adium/AIUserIcons.h>
#import <Adium/ESFileTransfer.h>

#define	BYTES_RECEIVED		[NSString stringWithFormat:AILocalizedString(@"%@ received","(a bytes string) received"),bytesString]
#define	BYTES_SENT			[NSString stringWithFormat:AILocalizedString(@"%@ sent","(a bytes string) sent"),bytesString]

@interface ESFileTransferProgressRow (PRIVATE)
- (NSString *)stringForSize:(unsigned long long)size;
- (NSString *)stringForSize:(unsigned long long)inSize of:(unsigned long long)totalSize ofString:(NSString *)totalSizeString;
- (NSString *)readableTimeForSecs:(NSTimeInterval)secs inLongFormat:(BOOL)longFormat;
- (id)initForFileTransfer:(ESFileTransfer *)inFileTransfer withOwner:(id)owner;
- (void)updateIconImage;
- (void)updateSourceAndDestination;
@end

@implementation ESFileTransferProgressRow

+ (ESFileTransferProgressRow *)rowForFileTransfer:(ESFileTransfer *)inFileTransfer withOwner:(id)inOwner
{
	return([[[ESFileTransferProgressRow alloc] initForFileTransfer:inFileTransfer withOwner:inOwner] autorelease]);
}

- (id)initForFileTransfer:(ESFileTransfer *)inFileTransfer withOwner:(id)inOwner
{
	[super init];
	
	sizeString = nil;
	forceUpdate = NO;
	
	fileTransfer = [inFileTransfer retain];
	[fileTransfer setDelegate:self];

	owner = inOwner;
	
	[NSBundle loadNibNamed:@"ESFileTransferProgressView" owner:self];
	
	return(self);
}

- (void)dealloc
{
	owner = nil;
	[fileTransfer setDelegate:nil];
	[fileTransfer release];
	[view release]; view = nil;
	[super dealloc];
}

- (ESFileTransfer *)fileTransfer
{
	return(fileTransfer);
}

- (ESFileTransferProgressView *)view
{	
	return(view);
}

- (void)awakeFromNib
{	
	//If we already know something about this file transfer, update since we missed delegate calls
	[self updateSourceAndDestination];
	[self fileTransfer:fileTransfer didSetSize:[fileTransfer size]];
	[self fileTransfer:fileTransfer didSetLocalFilename:[fileTransfer localFilename]];
	[self fileTransfer:fileTransfer didSetType:[fileTransfer type]];

	//This always calls gotUpdate and display, so do it last
	[self fileTransfer:fileTransfer didSetStatus:[fileTransfer status]];

	[self performSelector:@selector(informOfAwakefromNib)
			   withObject:nil
			   afterDelay:0.000001];
}

- (void)informOfAwakefromNib
{
	//Once we've set up some basic information, tell our owner it can add the view
	[owner progressRowDidAwakeFromNib:self];
}


- (void)fileTransfer:(ESFileTransfer *)inFileTransfer didSetType:(FileTransferType)type
{
	[self updateSourceAndDestination];
	[self updateIconImage];
	
	[owner progressRowDidChangeType:self];
}

- (FileTransferType)type
{
	return([fileTransfer type]);
}

- (void)fileTransfer:(ESFileTransfer *)inFileTransfer didSetSize:(unsigned long long)inSize
{
	size = inSize;
	
	[sizeString release];
	sizeString = [[[adium fileTransferController] stringForSize:size] retain];
}

- (void)fileTransfer:(ESFileTransfer *)inFileTransfer didSetLocalFilename:(NSString *)inLocalFilename
{
	NSString	*filename = [inLocalFilename lastPathComponent];
	
	//If we don't have a local file name, try to use the remote file name.
	if(!filename) filename = [[inFileTransfer remoteFilename] lastPathComponent];
	
	[view setFileName:filename];

	[self updateIconImage];
}

- (void)fileTransfer:(ESFileTransfer *)inFileTransfer didSetStatus:(FileTransferStatus)inStatus
{
	forceUpdate = YES;
	[self gotUpdateForFileTransfer:inFileTransfer];
	
	[view setAllowsCancel:![inFileTransfer isStopped]];
	
	[[view window] display];
	forceUpdate = NO;
}

//Handle progress, bytes transferred/bytes total, rate, and time remaining
- (void)gotUpdateForFileTransfer:(ESFileTransfer *)inFileTransfer
{
	UInt32				updateTick = TickCount();
	FileTransferStatus	status = [inFileTransfer status];
	
	//Don't update continously; on a LAN transfer, for instance, we'll get almost constant updates
	if(lastUpdateTick && (((updateTick - lastUpdateTick) / 60.0) < 0.2) && (status == In_Progress_FileTransfer) && !forceUpdate){
		return;
	}

	unsigned long long	bytesSent = [inFileTransfer bytesSent];
	NSString			*transferBytesStatus = nil, *transferSpeedStatus = nil, *transferRemainingStatus = nil;
	FileTransferType	type = [inFileTransfer type];
	
	if(!size){
		size = [inFileTransfer size];
		
		[sizeString release];
		sizeString = [[[adium fileTransferController] stringForSize:size] retain];		
	}

	switch(status){
		case Unknown_Status_FileTransfer:
		case Not_Started_FileTransfer:
		case Accepted_FileTransfer:
			[view setProgressIndeterminate:YES];
			[view setProgressAnimation:YES];
			transferSpeedStatus = AILocalizedString(@"Waiting to start.","waiting to begin a file transfer status");
			
			break;
		case In_Progress_FileTransfer:
			[view setProgressIndeterminate:NO];
			[view setProgressDoubleValue:[inFileTransfer percentDone]];
			break;
		case Complete_FileTransfer:
			[view setProgressVisible:NO];
			transferSpeedStatus = AILocalizedString(@"Complete",nil);
			break;
		case Canceled_Local_FileTransfer:
		case Canceled_Remote_FileTransfer:
			[view setProgressVisible:NO];
			transferSpeedStatus = AILocalizedString(@"Stopped",nil);
			break;
	}

	if(type == Unknown_FileTransfer || status == Unknown_Status_FileTransfer || status == Not_Started_FileTransfer){
		transferBytesStatus = [NSString stringWithFormat:AILocalizedString(@"Initiating file transfer...",nil)];		
	}else{		
		switch(status){
			case Accepted_FileTransfer:
				transferBytesStatus = [NSString stringWithFormat:AILocalizedString(@"Accepted file transfer...",nil)];		
			break;
			case In_Progress_FileTransfer:
			{
				NSString			*bytesString = [[adium fileTransferController] stringForSize:bytesSent
																							  of:size
																						ofString:sizeString];

				switch(type){
					case Incoming_FileTransfer:
						transferBytesStatus = BYTES_RECEIVED;
						break;
					case Outgoing_FileTransfer:
						transferBytesStatus = BYTES_SENT;
						break;
					default:
						break;
				}
				
				break;
			}
			case Complete_FileTransfer:
			{
				NSString			*bytesString = [[adium fileTransferController] stringForSize:bytesSent];
				switch(type){
					case Incoming_FileTransfer:
						transferBytesStatus = BYTES_RECEIVED;
						break;
					case Outgoing_FileTransfer:
						transferBytesStatus = BYTES_SENT;
						break;
					default:
						break;
				}
				
				break;
			}
			case Canceled_Local_FileTransfer:
				transferBytesStatus = AILocalizedString(@"Canceled","File transfer canceled locally status description");
				break;
			case Canceled_Remote_FileTransfer:
				transferBytesStatus = AILocalizedString(@"Remote contact canceled","File transfer canceled remotely status description");
				break;
			default: 
				break;
		}
	}
	
	if((status == In_Progress_FileTransfer) && lastUpdateTick && lastBytesSent){
		if(updateTick != lastUpdateTick){
			unsigned long long	rate;
			
			rate = ((bytesSent - lastBytesSent) / ((updateTick - lastUpdateTick) / 60.0));
			transferSpeedStatus = [NSString stringWithFormat:AILocalizedString(@"%@ per sec.",nil),[[adium fileTransferController] stringForSize:rate]];
			
			if(rate > 0){
				unsigned long long secsRemaining = ((size - bytesSent) / rate);
				transferRemainingStatus = [NSString stringWithFormat:AILocalizedString(@"%@ remaining.",nil),[self readableTimeForSecs:secsRemaining inLongFormat:YES]];
				
			}else{
				transferRemainingStatus = AILocalizedString(@"Stalled","file transfer is stalled status message");
			}
		}
	}
	
	[view setTransferBytesStatus:transferBytesStatus
				 remainingStatus:transferRemainingStatus
					 speedStatus:transferSpeedStatus];
	[view setNeedsDisplay:YES];

	lastBytesSent = bytesSent;
	lastUpdateTick = updateTick;
}

- (void)updateIconImage
{
	NSImage	*iconImage;

	if(iconImage = [fileTransfer iconImage]){
		[view setIconImage:iconImage];		
	}
}

- (void)updateSourceAndDestination
{	
	AIListObject	*source = [fileTransfer source];
	AIListObject	*destination = [fileTransfer destination];
	
	[view setSourceName:[source formattedUID]];
	[view setSourceIcon:[AIUserIcons menuUserIconForObject:source]];
	
	[view setDestinationName:[destination formattedUID]];
	[view setDestinationIcon:[AIUserIcons menuUserIconForObject:destination]];
}

//Button actions
#pragma mark Button actions
- (IBAction)stopResumeAction:(id)sender
{
	[fileTransfer cancel];
}
- (IBAction)revealAction:(id)sender
{
	[fileTransfer reveal];	
}
- (IBAction)openFileAction:(id)sender
{
	if([fileTransfer status] == Complete_FileTransfer){
		[fileTransfer openFile];
	}
}
- (void)removeRowAction:(id)sender
{
	if([fileTransfer isStopped]){
		[owner _removeFileTransferRow:self];
	}
}

#pragma mark Contextual menu
- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	NSMenu		*contextualMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
	NSMenuItem  *menuItem;
	
	//Allow open and show in finder on complete incoming transfers and all outgoing transfers
	if(([fileTransfer status] == Complete_FileTransfer) ||
	   ([fileTransfer type] == Outgoing_FileTransfer)){
		menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Open",nil)
																		 target:self
																		 action:@selector(openFileAction:)
																  keyEquivalent:@""] autorelease];
		[contextualMenu addItem:menuItem];

		menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Show in Finder",nil)
																		 target:self
																		 action:@selector(revealAction:)
																  keyEquivalent:@""] autorelease];
		[contextualMenu addItem:menuItem];
		
	}	

	if([fileTransfer isStopped]){
		menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Remove from List",nil)
																		 target:self
																		 action:@selector(removeRowAction:)
																  keyEquivalent:@""] autorelease];
		[contextualMenu addItem:menuItem];	
	}else{
		menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Cancel",nil)
																		 target:self
																		 action:@selector(stopResumeAction:)
																  keyEquivalent:@""] autorelease];
		[contextualMenu addItem:menuItem];
	}	
	
	return([contextualMenu autorelease]);
}

//Pass height change information on to our owner
- (void)fileTransferProgressView:(ESFileTransferProgressView *)inView
			   heightChangedFrom:(float)oldHeight
							 to:(float)newHeight
{
	[owner fileTransferProgressRow:self
				 heightChangedFrom:oldHeight
								to:newHeight];
}

#pragma mark Localized readable values
//From Colloquy
- (NSString *)readableTimeForSecs:(NSTimeInterval)secs inLongFormat:(BOOL)longFormat
{
	unsigned int i = 0, stop = 0;
	NSDictionary *desc = [NSDictionary dictionaryWithObjectsAndKeys:AILocalizedString( @"second", "singular second" ), [NSNumber numberWithUnsignedInt:1], AILocalizedString( @"minute", "singular minute" ), [NSNumber numberWithUnsignedInt:60], AILocalizedString( @"hour", "singular hour" ), [NSNumber numberWithUnsignedInt:3600], AILocalizedString( @"day", "singular day" ), [NSNumber numberWithUnsignedInt:86400], AILocalizedString( @"week", "singular week" ), [NSNumber numberWithUnsignedInt:604800], AILocalizedString( @"month", "singular month" ), [NSNumber numberWithUnsignedInt:2628000], AILocalizedString( @"year", "singular year" ), [NSNumber numberWithUnsignedInt:31536000], nil];
	NSDictionary *plural = [NSDictionary dictionaryWithObjectsAndKeys:AILocalizedString( @"seconds", "plural seconds" ), [NSNumber numberWithUnsignedInt:1], AILocalizedString( @"minutes", "plural minutes" ), [NSNumber numberWithUnsignedInt:60], AILocalizedString( @"hours", "plural hours" ), [NSNumber numberWithUnsignedInt:3600], AILocalizedString( @"days", "plural days" ), [NSNumber numberWithUnsignedInt:86400], AILocalizedString( @"weeks", "plural weeks" ), [NSNumber numberWithUnsignedInt:604800], AILocalizedString( @"months", "plural months" ), [NSNumber numberWithUnsignedInt:2628000], AILocalizedString( @"years", "plural years" ), [NSNumber numberWithUnsignedInt:31536000], nil];
	NSDictionary *use = nil;
	NSMutableArray *breaks = nil;
	unsigned int val = 0.;
	NSString *retval = nil;
	
	if( secs < 0 ) secs *= -1;
	
	breaks = [[[desc allKeys] mutableCopy] autorelease];
	[breaks sortUsingSelector:@selector( compare: )];
	
	while( i < [breaks count] && secs >= (NSTimeInterval) [[breaks objectAtIndex:i] unsignedIntValue] ) i++;
	if( i > 0 ) i--;
	stop = [[breaks objectAtIndex:i] unsignedIntValue];
	
	val = (unsigned int) ( secs / stop );
	use = ( val > 1 ? plural : desc );
	retval = [NSString stringWithFormat:@"%d %@", val, [use objectForKey:[NSNumber numberWithUnsignedInt:stop]]];
	if( longFormat && i > 0 ) {
		unsigned int rest = (unsigned int) ( (unsigned int) secs % stop );
		stop = [[breaks objectAtIndex:--i] unsignedIntValue];
		rest = (unsigned int) ( rest / stop );
		if( rest > 0 ) {
			use = ( rest > 1 ? plural : desc );
			retval = [retval stringByAppendingFormat:@" %d %@", rest, [use objectForKey:[breaks objectAtIndex:i]]];
		}
	}
	
	return(retval);
}

@end
