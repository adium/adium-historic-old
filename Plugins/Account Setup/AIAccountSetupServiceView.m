//
//  AIServiceView.m
//  Adium
//
//  Created by Adam Iser on 12/9/04.
//  Copyright (c) 2004 The Adium Team. All rights reserved.
//

#import "AIAccountSetupServiceView.h"

#define SERVICE_ICON_NAME_PADDING	8

#define STATUS_ICON_NAME_PADDING 	3
#define STATUS_ICON_INDENT			2
#define STATUS_ICON_OFFSET			-2

#define ACCOUNT_NAME_SPACING		2
#define ACCOUNT_NAME_OFFSET			0

@interface AIAccountSetupServiceView (PRIVATE)
- (NSAttributedString *)attributedServiceName;
@end

@implementation AIAccountSetupServiceView

//
- (id)initWithService:(AIService *)inService
{
	[super init];
	
	//Cache a bunch of our drawing information
	service = [inService retain];
	serviceIcon = [[AIServiceIcons serviceIconForService:service type:AIServiceIconLarge direction:AIIconNormal] retain];
	serviceName = [[self attributedServiceName] retain];
	serviceNameSize = [serviceName size];
	accountNameHeight = [NSAttributedString stringHeightForAttributes:[self accountNameAttributes]];
	serviceIconSize = NSMakeSize(32, 32);
	
	return(self);
}

//
- (void)dealloc
{
	[service release];
	[serviceIcon release];
	
	[super dealloc];
}

//
- (void)resetCursorRects
{
	
}

- (void)addAccounts:(NSArray *)array
{
	accounts = [array retain];
	
	[self setFrameSize:NSMakeSize([self frame].size.width, 32 + accountNameHeight * [accounts count])];
}

//Service icon size
- (void)setServiceIconSize:(NSSize)inSize
{
	serviceIconSize = inSize;
}
- (NSSize)serviceIconSize{
	return(serviceIconSize);
}


- (NSDictionary *)accountNameAttributes
{
	return([NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:12] forKey:NSFontAttributeName]);
}


//
- (void)drawRect:(NSRect)drawRect
{
	NSAttributedString	*addAccountString = [self attributedAddAccountString];
	NSRect				frame = NSMakeRect(0, 0, [self frame].size.width, [self frame].size.height);
	NSRect				rect;

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
	
	
//	frame.size.height -= serviceIconSize.height;
	
	
	//Accounts
	if([accounts count]){
		NSEnumerator	*enumerator = [accounts objectEnumerator];
		AIAccount		*account;

		while(account = [enumerator nextObject]){
			NSImage *statusIcon = [AIStatusIcons statusIconForStatusID:@"available" type:AIStatusIconTab direction:AIIconNormal];
			NSSize	iconSize = [statusIcon size];
			
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

//
- (NSAttributedString *)attributedServiceName
{
	NSDictionary		*attributes = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont boldSystemFontOfSize:13], NSFontAttributeName,
		nil];
	
	return([[[NSAttributedString alloc] initWithString:[service longDescription]
												   attributes:attributes] autorelease]);
}

//
- (NSAttributedString *)attributedAddAccountString
{
	NSDictionary		*attributes = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont labelFontOfSize:11], NSFontAttributeName,
		[NSColor darkGrayColor], NSForegroundColorAttributeName,
		nil];
	
	return([[[NSAttributedString alloc] initWithString:@"Add Account..."
											attributes:attributes] autorelease]);
}


@end
