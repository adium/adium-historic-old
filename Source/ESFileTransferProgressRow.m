//
//  ESFileTransferProgressRow.m
//  Adium
//
//  Created by Evan Schoenberg on 11/11/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import "ESFileTransferProgressRow.h"
#import "ESFileTransferProgressWindowController.h"

@interface ESFileTransferProgressRow (PRIVATE)
- (NSString *)stringForSize:(unsigned long long)size;
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
		
	[super dealloc];
}

- (ESFileTransferProgressView *)view
{	
	return(view);
}

- (void)awakeFromNib
{
	[self performSelector:@selector(informOfAwakefromNib)
			   withObject:nil
			   afterDelay:0.000001];
}

- (void)informOfAwakefromNib
{
	[owner progressRowDidAwakeFromNib:self];

	//If we already know something about this file transfer, update since we missed delegate calls
	[self updateSourceAndDestination];
	[self fileTransfer:fileTransfer didSetSize:[fileTransfer size]];
	[self fileTransfer:fileTransfer didSetLocalFilename:[fileTransfer localFilename]];
	[self gotUpdateForFileTransfer:fileTransfer];
	
	//This always calls displayIfNeeded, so do it last
	[self fileTransfer:fileTransfer didSetType:[fileTransfer type]];
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
	sizeString = [[self stringForSize:size] retain];
}

- (void)fileTransfer:(ESFileTransfer *)inFileTransfer didSetLocalFilename:(NSString *)inLocalFilename
{
	[view setFileName:[inLocalFilename lastPathComponent]];
	[self updateIconImage];
}

- (void)fileTransfer:(ESFileTransfer *)inFileTransfer didSetStatus:(FileTransferStatus)inStatus
{
	forceUpdate = YES;
	[self gotUpdateForFileTransfer:inFileTransfer];
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
	NSString			*bytesString = [self stringForSize:bytesSent];
	FileTransferType	type = [inFileTransfer type];
	
	if(!size){
		size = [inFileTransfer size];
		
		[sizeString release];
		sizeString = [[self stringForSize:size] retain];		
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
			[view setProgressIndeterminate:YES];
			[view setProgressAnimation:NO];
			transferSpeedStatus = AILocalizedString(@"Complete",nil);
			break;
		case Canceled_Local_FileTransfer:
		case Canceled_Remote_FileTransfer:
			[view setProgressIndeterminate:YES];
			[view setProgressAnimation:NO];
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
				switch(type){
					case Incoming_FileTransfer:
						transferBytesStatus = [NSString stringWithFormat:AILocalizedString(@"%@ of %@ received","bytes of bytes total received"),bytesString,sizeString];
						break;
					case Outgoing_FileTransfer:
						transferBytesStatus = [NSString stringWithFormat:AILocalizedString(@"%@ of %@ sent","bytes of bytes total received"),bytesString,sizeString];
						break;
					default:
						break;
				}
				
				break;
			}
			case Complete_FileTransfer:
			{
				switch(type){
					case Incoming_FileTransfer:
						transferBytesStatus = [NSString stringWithFormat:AILocalizedString(@"File receiption complete: %@ received","File reception complete: (total bytes) received"),bytesString];
						break;
					case Outgoing_FileTransfer:
						transferBytesStatus = [NSString stringWithFormat:AILocalizedString(@"File send complete: %@ sent","File send complete: (total bytes) received"),bytesString];
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
			transferSpeedStatus = [NSString stringWithFormat:AILocalizedString(@"%@ per sec.",nil),[self stringForSize:rate]];
			
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
	NSString	*extension;
	if((extension = [[fileTransfer localFilename] pathExtension]) &&
	   ([extension length])){
		
		NSImage		*iconImage = nil;
		
		if(iconImage = [[NSWorkspace sharedWorkspace] iconForFileType:extension]){
#warning Test for file transfer type, overlay a light up arrow or down arrow?
			[view setIconImage:iconImage];
		}
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
- (IBAction)stopResumeAction:(id)sender
{
	[fileTransfer cancel];
}
- (IBAction)revealAction:(id)sender
{
	[fileTransfer reveal];	
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
- (NSString *)stringForSize:(unsigned long long)inSize
{
	NSString *ret = nil;

	if( inSize == 0. ) ret = AILocalizedString( @"Zero bytes", "no file size" );
	else if( inSize > 0. && inSize < 1024. ) ret = [NSString stringWithFormat:AILocalizedString( @"%lu bytes", "file size measured in bytes" ), inSize];
	else if( inSize >= 1024. && inSize < pow( 1024., 2. ) ) ret = [NSString stringWithFormat:AILocalizedString( @"%.1f KB", "file size measured in kilobytes" ), ( inSize / 1024. )];
	else if( inSize >= pow( 1024., 2. ) && inSize < pow( 1024., 3. ) ) ret = [NSString stringWithFormat:AILocalizedString( @"%.2f MB", "file size measured in megabytes" ), ( inSize / pow( 1024., 2. ) )];
	else if( inSize >= pow( 1024., 3. ) && inSize < pow( 1024., 4. ) ) ret = [NSString stringWithFormat:AILocalizedString( @"%.3f GB", "file size measured in gigabytes" ), ( inSize / pow( 1024., 3. ) )];
	else if( inSize >= pow( 1024., 4. ) ) ret = [NSString stringWithFormat:AILocalizedString( @"%.4f TB", "file size measured in terabytes" ), ( inSize / pow( 1024., 4. ) )];

	return(ret);
}

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
