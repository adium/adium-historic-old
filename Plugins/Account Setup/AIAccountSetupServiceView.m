//
//  AIServiceView.m
//  Adium
//
//  Created by Adam Iser on 12/9/04.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "AIAccountSetupServiceView.h"

#define SERVICE_ICON_NAME_PADDING	8

#define STATUS_ICON_NAME_PADDING 	3
#define STATUS_ICON_INDENT			2
#define STATUS_ICON_OFFSET			-2

#define ACCOUNT_NAME_SPACING		2
#define ACCOUNT_NAME_OFFSET			0

@interface AIAccountSetupServiceView (PRIVATE)
- (NSDictionary *)accountNameAttributes;
- (NSAttributedString *)attributedServiceName;
- (NSAttributedString *)attributedAddAccountString;
- (void)startTrackingCursor;
- (void)stopTrackingCursor;
@end

@implementation AIAccountSetupServiceView

//Init
- (id)initWithService:(AIService *)inService delegate:(id)inDelegate
{
	[super init];

	[self setDelegate:inDelegate];
	
	//Cache a bunch of our drawing information
	service = [inService retain];
	serviceIcon = [[AIServiceIcons serviceIconForService:service type:AIServiceIconLarge direction:AIIconNormal] retain];
	serviceName = [[self attributedServiceName] retain];
	serviceNameSize = [serviceName size];
	accountNameHeight = [NSAttributedString stringHeightForAttributes:[self accountNameAttributes]];
	serviceIconSize = NSMakeSize(32, 32);
	
	return(self);
}

//Dealloc
- (void)dealloc
{
	[self stopTrackingCursor];
	[service release];
	[serviceIcon release];
	
	[super dealloc];
}


//Configure ------------------------------------------------------------------------------------------------------------
#pragma mark Drawing
//Set the accounts for this view to display
- (void)setAccounts:(NSArray *)array
{
	if(accounts != array){
		[accounts release];
		accounts = [array retain];
		[self setFrameSize:NSMakeSize([self frame].size.width, 32 + accountNameHeight * [accounts count])];
	}
}

//Service icon size
- (void)setServiceIconSize:(NSSize)inSize
{
	serviceIconSize = inSize;
}
- (NSSize)serviceIconSize{
	return(serviceIconSize);
}

//Delegate
- (void)setDelegate:(id)inDelegate
{
	NSParameterAssert([inDelegate respondsToSelector:@selector(newAccountOnService:)]);
	NSParameterAssert([inDelegate respondsToSelector:@selector(editExistingAccount:)]);
	delegate = inDelegate;
}
- (id)delegate{
	return(delegate);
}


//Drawing --------------------------------------------------------------------------------------------------------------
#pragma mark Drawing
//Draw
- (void)drawRect:(NSRect)drawRect
{
	NSAttributedString	*addAccountString = [self attributedAddAccountString];
	NSRect				frame = NSMakeRect(0, 0, [self frame].size.width, [self frame].size.height);
	NSRect				rect;
	
	if(mouseIn && !hoveredAccount){
		//[[NSColor controlHighlightColor] set];
		[[NSColor selectedControlColor] set];
		[NSBezierPath fillRect:drawRect];
	}
	
	//Service Icon
	rect = NSMakeRect(frame.origin.x,
					  frame.origin.y + frame.size.height - serviceIconSize.height,
					  serviceIconSize.width,
					  serviceIconSize.height);
	if(NSIntersectsRect(drawRect, rect)){
		[serviceIcon drawInRect:rect
					   fromRect:NSMakeRect(0, 0, [serviceIcon size].width, [serviceIcon size].height)
					  operation:NSCompositeSourceOver
					   fraction:1.0];
	}
	frame.origin.x += rect.size.width + SERVICE_ICON_NAME_PADDING;
	frame.size.width -= rect.size.width + SERVICE_ICON_NAME_PADDING;
	
	//Service Name
	rect = NSMakeRect(frame.origin.x,
					  frame.origin.y + frame.size.height - serviceNameSize.height,
					  frame.size.width,
					  serviceNameSize.height);
	
	if(NSIntersectsRect(drawRect, rect)){
		[serviceName drawInRect:rect];
	}
	frame.size.height -= rect.size.height;
	
	//Accounts
	if([accounts count]){
		NSEnumerator	*enumerator = [accounts objectEnumerator];
		AIAccount		*account;
		
		while(account = [enumerator nextObject]){
			NSImage *statusIcon = [AIStatusIcons statusIconForStatusID:@"available" type:AIStatusIconTab direction:AIIconNormal];
			NSSize	iconSize = [statusIcon size];
			
			if(mouseIn && hoveredAccount == account){
				[[NSColor selectedControlColor] set];
				[NSBezierPath fillRect:NSMakeRect(frame.origin.x,
												  frame.origin.y + frame.size.height - accountNameHeight + ACCOUNT_NAME_OFFSET,
												  frame.size.width,
												  accountNameHeight)];
			}
			
			//Status icon
			rect = NSMakeRect(frame.origin.x + STATUS_ICON_INDENT,
							  frame.origin.y + (frame.size.height - accountNameHeight) + STATUS_ICON_OFFSET,
							  iconSize.width,
							  iconSize.height);
			
			if(NSIntersectsRect(drawRect, rect)){
				[statusIcon drawInRect:rect
							  fromRect:NSMakeRect(0, 0, iconSize.width, iconSize.height)
							 operation:NSCompositeSourceOver
							  fraction:1.0];
			}
			
			//Account name
			rect = NSMakeRect(frame.origin.x + iconSize.width + STATUS_ICON_INDENT + STATUS_ICON_NAME_PADDING,
							  frame.origin.y + frame.size.height - accountNameHeight + ACCOUNT_NAME_OFFSET,
							  frame.size.width,
							  accountNameHeight);
			
			if(NSIntersectsRect(drawRect, rect)){
				NSAttributedString	*accountString = [[NSAttributedString alloc] initWithString:[account UID]
																					 attributes:[self accountNameAttributes]];
				[accountString drawInRect:rect];
			}
			
			frame.size.height -= rect.size.height + ACCOUNT_NAME_SPACING;
		}
	}
	
	//Add Accounts...
	if(![accounts count]){
		NSSize stringSize = [addAccountString size];
		rect = NSMakeRect(frame.origin.x,
						  frame.origin.y + frame.size.height - stringSize.height,
						  frame.size.width,
						  stringSize.height);
		
		if(NSIntersectsRect(drawRect, rect)){
			[addAccountString drawInRect:rect];
		}
		frame.size.height -= rect.size.height;
	}
}

//Text attributes for drawing the account names
- (NSDictionary *)accountNameAttributes
{
	return([NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:12] forKey:NSFontAttributeName]);
}

//String for drawing the service name text
- (NSAttributedString *)attributedServiceName
{
	NSDictionary		*attributes = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont boldSystemFontOfSize:13], NSFontAttributeName,
		nil];
	
	return([[[NSAttributedString alloc] initWithString:[service longDescription]
											attributes:attributes] autorelease]);
}

//String for drawing the add account text
- (NSAttributedString *)attributedAddAccountString
{
	NSDictionary		*attributes = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont labelFontOfSize:11], NSFontAttributeName,
		[NSColor darkGrayColor], NSForegroundColorAttributeName,
		nil];
	
	return([[[NSAttributedString alloc] initWithString:@"Add Account..."
											attributes:attributes] autorelease]);
}


//Cursor Tracking ------------------------------------------------------------------------------------------------------
#pragma mark Cursor Tracking
//Correctly stop tracking the cursor when our view is removed from its window.  We need to remove our tracking rects
//before we are removed from our window, or the remove method will be ignored and they will persist causing crashes.
- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
	if(!newWindow) [self stopTrackingCursor];
}

//Reset cursor tracking
- (void)resetCursorRects
{
	[self stopTrackingCursor];
	[self startTrackingCursor];
}

//Start tracking cursor
- (void)startTrackingCursor
{
	if([self window] && !trackingRects){
		NSTrackingRectTag	trackingTag;
		
		trackingRects = [[NSMutableArray alloc] init];
		
		if([accounts count]){
			NSEnumerator	*enumerator = [accounts objectEnumerator];
			AIAccount		*account;
			
			while(account = [enumerator nextObject]){
				
				NSRect	rect = NSMakeRect(serviceIconSize.width + SERVICE_ICON_NAME_PADDING,
										  [self frame].size.height - (serviceNameSize.height + (accountNameHeight + ACCOUNT_NAME_SPACING) * ([accounts indexOfObject:account]+1)),
										  [self frame].size.width - (serviceIconSize.width + SERVICE_ICON_NAME_PADDING),
										  accountNameHeight);
				
				
				trackingTag = [self addTrackingRect:rect
											  owner:self
										   userData:account
									   assumeInside:NO];
				[trackingRects addObject:[NSNumber numberWithInt:trackingTag]];
			}
			
			
		}else{
			trackingTag = [self addTrackingRect:NSMakeRect(0, 0, [self frame].size.width, [self frame].size.height)
										  owner:self
									   userData:nil
								   assumeInside:NO];
			[trackingRects addObject:[NSNumber numberWithInt:trackingTag]];
		}
	}
	
}

//Stop tracking cursor
- (void)stopTrackingCursor
{
	if([trackingRects count]){
		NSEnumerator	*enumerator = [trackingRects objectEnumerator];
		NSNumber		*trackingTag;
		
		while(trackingTag = [enumerator nextObject]){
			[self removeTrackingRect:(NSTrackingRectTag)[trackingTag intValue]];
		}
		
		[trackingRects release];
		trackingRects = nil;
	}
}

//Mouse Entered/Exited a tracking rect
- (void)mouseEntered:(NSEvent *)theEvent
{
	mouseIn = YES;
	hoveredAccount = [theEvent userData];
	[self setNeedsDisplay:YES];
}

- (void)mouseExited:(NSEvent *)theEvent
{
	mouseIn = NO;
	hoveredAccount = nil;
	[self setNeedsDisplay:YES];
}

//Mouse down
- (void)mouseDown:(NSEvent *)theEvent
{
	if(hoveredAccount){
		[delegate editExistingAccount:hoveredAccount];
	}else{
		[delegate newAccountOnService:service];
	}
}

@end
