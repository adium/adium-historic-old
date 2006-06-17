//
//  SmackListContact.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-06-05.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "SmackListContact.h"


@implementation SmackListContact

- (id)initWithUID:(NSString *)inUID service:(AIService *)inService {
    if((self = [super initWithUID:inUID service:inService])) {
        containedObjects = [[NSMutableArray alloc] init];
        
        largestOrder = 1.0;
        smallestOrder = 1.0;
        expanded = YES;
    }
    return self;
}

- (void)dealloc {
    [containedObjects release];
    
    [super dealloc];
}

- (BOOL)canContainOtherContacts {
    return YES;
}

- (AIListContact *)preferredContact {
    NSArray *contacts = [self containedObjects];
    
    NSLog(@"contacts = %@",[contacts description]);
    
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
    NSLog(@"best contact = %@",[bestcontact internalUniqueObjectID]);
    
    return bestcontact;
}

#pragma mark Status
- (NSString *)statusName
{
    NSLog(@"statusName = %@",[[self preferredContact] statusObjectForKey:@"StatusName"]);
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
	
    NSLog(@"statusType = %d",statusType);
	return statusType;
}

/*!
* @brief Determine the status message to be displayed in the contact list
 *
 * @result <tt>NSAttributedString</tt> which will be the message for this contact in the contact list, after modifications
 */
- (NSAttributedString *)contactListStatusMessage
{
/*	NSEnumerator		*enumerator;
	NSAttributedString	*contactListStatusMessage = nil;
	AIListContact		*listContact;
	
	//Try to use an actual status message first
	enumerator = [[self containedObjects] objectEnumerator];
	while (!contactListStatusMessage && (listContact = [enumerator nextObject])) {
		contactListStatusMessage = [listContact statusMessage];
	}
    
	if (!contactListStatusMessage) {
		//Next go for any contact list status message, which may include a display name or the name of a status such as "BRB"
		enumerator = [[self containedObjects] objectEnumerator];
		while (!contactListStatusMessage && (listContact = [enumerator nextObject])) {
			contactListStatusMessage = [listContact contactListStatusMessage];
		}		
	}
    
	if (!contactListStatusMessage) {
		return [self statusMessage];
	}
    
	return contactListStatusMessage;*/
    
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] init];
    
    NSEnumerator *e = [[self containedObjects] objectEnumerator];
    AIListContact *contact;
    
    while((contact = [e nextObject])) {
        NSAttributedString *temp = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: ",[contact internalUniqueObjectID]] attributes:[NSDictionary dictionaryWithObject:[NSFont boldSystemFontOfSize:[NSFont labelFontSize]] forKey:NSFontAttributeName]];
        [result appendAttributedString:temp];
        [temp release];
        
        [result appendAttributedString:[contact contactListStatusMessage]];

        temp = [[NSAttributedString alloc] initWithString:@"\n" attributes:nil];
        [result appendAttributedString:temp];
        [temp release];
    }
    
    NSLog(@"contactListStatusMessage = %@",[result string]);
    
    return [result autorelease];
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
    return [containedObjects count];
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
    [containedObjects removeAllObjects];
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
		[containedObjects addObject:inObject];
    
		[inObject setContainingObject:self];

		return YES;
	}
	NSLog(@"tried to contain myself!");
	return NO;
}

- (void)removeObject:(AIListObject*)inObject {
    [containedObjects removeObject:inObject];

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
