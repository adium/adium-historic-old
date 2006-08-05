//
//  SmackListContact.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-06-05.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "SmackListContact.h"
#import "SmackXMPPAccount.h"
#import "AIAdium.h"
#import "AIContactController.h"

#import <AIUtilities/AIImageAdditions.h>

@implementation SmackListContact

- (id)initWithUID:(NSString *)inUID service:(AIService *)inService {
    if((self = [super initWithUID:inUID service:inService])) {
		bogusContact = [[adium contactController] contactWithService:inService account:[self account] UID:inUID class:[AIListContact class]];
		[bogusContact setContainingObject:self];
		[bogusContact setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Online" notify:NO];
		[bogusContact setStatusObject:[NSNumber numberWithInt:-256] forKey:@"XMPPPriority" notify:NO];

		[bogusContact retain];
		
        containedObjects = [[NSMutableArray alloc] initWithObjects:bogusContact,nil];
        largestOrder = 1.0;
        smallestOrder = 1.0;
        expanded = YES;
    }
    return self;
}

- (void)dealloc {
    [containedObjects release];
    [bogusContact release];

    [super dealloc];
}

- (BOOL)canContainOtherContacts {
    return YES;
}

- (AIListContact *)preferredContact {
    NSArray *contacts = [self containedObjects];
    
//    NSLog(@"contacts = %@",[contacts description]);
    
    AIListContact *bestcontact = nil;
    int priority = -129;
    
    NSEnumerator *e = [contacts objectEnumerator];
    AIListContact *contact;
    while((contact = [e nextObject])) {
        int c_prio = [[contact statusObjectForKey:@"XMPPPriority"] intValue];
        if(priority < c_prio) {
            bestcontact = contact;
            priority = c_prio;
        }
    }
    
    return bestcontact;
}

#pragma mark Status
- (void)object:(id)inObject didSetStatusObject:(id)value forKey:(NSString *)key notify:(NotifyTiming)notify
{
	if (inObject != bogusContact) {
		BOOL	shouldNotify = NO;

		if ([key isEqualToString:@"Online"]) {
			shouldNotify = YES;
		}
		
		if ([key isEqualToString:@"StatusType"] ||
			[key isEqualToString:@"IdleSince"] ||
			[key isEqualToString:@"IsIdle"] ||
			[key isEqualToString:@"IsMobile"] ||
			[key isEqualToString:@"StatusMessage"] ||
			[key isEqualToString:@"Signed On"] ||
			[key isEqualToString:@"Signed Off"]) {
			shouldNotify = YES;
		}

		if (shouldNotify) {
			[super object:self didSetStatusObject:value forKey:key notify:notify];
		}
	}
}

- (id)statusObjectForKey:(NSString *)key
{
	id					returnValue;
	
	if (!(returnValue = [super statusObjectForKey:key])) {
		returnValue = [[self preferredContact] statusObjectForKey:key];
	}
	
	return returnValue;
}

- (int)integerStatusObjectForKey:(NSString *)key
{
	return [[self statusObjectForKey:key] intValue];
}

- (NSString *)statusName
{
//    NSLog(@"statusName = %@",[[self preferredContact] statusObjectForKey:@"StatusName"]);
	return [[self preferredContact] statusObjectForKey:@"StatusName"];
}

- (AIStatusType)statusType
{
	NSNumber		*statusTypeNumber = [[self preferredContact] statusObjectForKey:@"StatusType"];
	/* DON'T ASK why AIAvailableStatusType is right, but that fixed things
	 * That's the same as is set in AIMetaContact. This is clearly Deep Magic.
	 * There be dragons.
	 */
	AIStatusType	statusType = (statusTypeNumber ?
								  [statusTypeNumber intValue] :
								  AIAvailableStatusType);
//	NSLog(@"statusType for %@ = %d (Avail = %d, Offline = %d)",self,statusType, AIAvailableStatusType, AIOfflineStatusType);
	return statusType;
}

- (BOOL)containsMultipleContacts
{
//    return [containedObjects count] > 1;
    return YES;
}

#define META_TOOLTIP_ICON_SIZE NSMakeSize(11,11)

- (NSAttributedString *)resourceInfo
{
    NSMutableString	*entryString;
    BOOL			shouldAppendString = NO;
    
    NSMutableAttributedString *entry = [[NSMutableAttributedString alloc] init];
    entryString = [entry mutableString];
    
    NSEnumerator *e = [[self containedObjects] objectEnumerator];
    AIListContact *contact;
    
    while((contact = [e nextObject])) {
		if (contact != bogusContact) {
/*			NSAttributedString *temp = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: ",[[contact UID] jidResource]] attributes:[NSDictionary dictionaryWithObject:[NSFont boldSystemFontOfSize:[NSFont labelFontSize]] forKey:NSFontAttributeName]];
			[result appendAttributedString:temp];
			[temp release];
			
			if([contact contactListStatusMessage])
				[result appendAttributedString:[contact contactListStatusMessage]];

			temp = [[NSAttributedString alloc] initWithString:@"\n" attributes:nil];
			[result appendAttributedString:temp];
			[temp release];*/
			
            NSImage	*statusIcon;
            
            if (shouldAppendString) {
                [entryString appendString:@"\r"];
            } else {
                shouldAppendString = YES;
            }
            
            statusIcon = [[contact displayArrayObjectForKey:@"Tab Status Icon"] imageByScalingToSize:META_TOOLTIP_ICON_SIZE];
            
            if (statusIcon) {
                NSTextAttachment		*attachment;
                NSTextAttachmentCell	*cell;
                
                cell = [[NSTextAttachmentCell alloc] init];
                [cell setImage:statusIcon];
                
                attachment = [[NSTextAttachment alloc] init];
                [attachment setAttachmentCell:cell];
                [cell release];
                
                [entry appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
                [attachment release];
            }
            
            NSAttributedString *statusString = [contact contactListStatusMessage];
            
            [entryString appendString:[[contact UID] jidResource]];
            
            if(statusString && [statusString length] > 0)
            {
                [entryString appendString:@": "];
                [entry appendAttributedString:statusString];
            }
		}
    }
    
//    NSLog(@"contactListStatusMessage = %@",[result string]);
    
    return [entry autorelease];
}

- (NSAttributedString *)statusMessage
{
    return [[self preferredContact] statusMessage];
}

- (NSAttributedString *)contactListStatusMessage
{
    return [[self preferredContact] contactListStatusMessage];
}

- (NSString*)statusMessageString
{
//    NSLog(@"statusMessageString = %@", [[[self preferredContact] contactListStatusMessage] string]);
    return [[self statusMessage] string];
}

/*
 * @brief Are sounds for this contact muted?
 */
- (BOOL)soundsAreMuted
{
	return [[[[self preferredContact] account] statusState] mutesSound];
}

#pragma mark contained objects

- (NSArray*)containedObjects {
    return containedObjects;
}

- (unsigned)containedObjectsCount {
	//never return less than 1 because we always "contain" the bogusContact
    return [containedObjects count] > 0 ? [containedObjects count] : 1;
}

//Test for the presence of an object in our group
- (BOOL)containsObject:(AIListObject *)inObject
{
	return [containedObjects containsObject:inObject];
}

//Retrieve an object by index
- (id)objectAtIndex:(unsigned)index
{
    return [containedObjects objectAtIndex:index];
}

//Retrieve the index of an object
- (int)indexOfObject:(AIListObject *)inObject
{
    return [containedObjects indexOfObject:inObject];
}

- (void)removeAllObjects
{
	NSLog(@"remove everyone!");
    [containedObjects removeAllObjects];
	[containedObjects addObject:bogusContact];
}

- (AIListObject *)objectWithService:(AIService *)inService UID:(NSString *)inUID {
	NSEnumerator	*enumerator = [[self containedObjects] objectEnumerator];
	AIListObject	*object;
	
	while ((object = [enumerator nextObject])) {
		if ([inUID isEqualToString:[object UID]] && [object service] == inService) break;
	}
	
	return object;
}

- (NSArray *)listContacts {
    return containedObjects;
}

- (BOOL)addObject:(AIListObject *)inObject {
    
	if (inObject != self) {
//		NSLog(@"containing %@",inObject);
		[containedObjects addObject:inObject];
    
		[inObject setContainingObject:self];
		[self notifyOfChangedStatusSilently:NO];
		[containedObjects removeObject:bogusContact];
		return YES;
	}
	NSLog(@"tried to contain myself!");
	return NO;
}

- (void)removeObject:(AIListObject*)inObject {
    [containedObjects removeObject:inObject];
	if ([containedObjects count] == 0)
		[containedObjects addObject:bogusContact];

    [self notifyOfChangedStatusSilently:NO];
}

- (void)setExpanded:(BOOL)inExpanded {
    expanded = inExpanded;
}

- (BOOL)isExpanded {
    return expanded;
}

- (float)smallestOrder
{
	return smallestOrder;
}

- (float)largestOrder
{
	return largestOrder;
}

- (void)listObject:(AIListObject *)listObject didSetOrderIndex:(float)inOrderIndex {
    if (inOrderIndex > largestOrder) {
		largestOrder = inOrderIndex;
	} else if (inOrderIndex < smallestOrder) {
		smallestOrder = inOrderIndex;
	}
}

- (unsigned)visibleCount {
    return [containedObjects count];
}

@end
