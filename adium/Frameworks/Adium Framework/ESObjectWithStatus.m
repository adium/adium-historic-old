//
//  ESObjectWithStatus.m
//  Adium
//
//  Created by Evan Schoenberg on Sat Jul 31 2004.
//

#import "ESObjectWithStatus.h"

//ESObjectWithStatus is an abstract superclass for use by any subclass which needs a system of status objects

@implementation ESObjectWithStatus

DeclareString(Key);
DeclareString(Value);

- (id)init
{
	[super init];
	
	InitString(Key,@"Key");
	InitString(Value,@"Value");
	
    statusDictionary = [[NSMutableDictionary alloc] init];
    changedStatusKeys = [[NSMutableArray alloc] init];	
	displayDictionary = [[NSMutableDictionary alloc] init];
	delayedStatusTimers = nil;
	
	return self;
}

- (void)dealloc
{
	NSEnumerator	*enumerator;
	NSTimer			*timer;
	
	//Invalidate any outstanding delayed status changes
	enumerator = [delayedStatusTimers objectEnumerator];
	while(timer = [enumerator nextObject]){
		[timer invalidate];
	}
	[delayedStatusTimers release]; delayedStatusTimers = nil;
	
	[statusDictionary release];
	[changedStatusKeys release];
	[displayDictionary release];
	
	[super dealloc];
}

//Setting status objects -----------------------------------------------------------------------------------------------
#pragma mark Setting Status

//Quickly set a status key for this object
- (void)setStatusObject:(id)value forKey:(NSString *)key notify:(NotifyTiming)notify
{
	if(key){
		BOOL changedStatusDict = YES;
		
		if(value){
			[statusDictionary setObject:value forKey:key];
		}else{
			//If we are already nil and being told to set nil, we don't need to do anything at all
			if ([statusDictionary objectForKey:key]){
				[statusDictionary removeObjectForKey:key];
			}else{
				changedStatusDict = NO;
			}
		}
		
		if (changedStatusDict){
			[self object:self didSetStatusObject:value forKey:key notify:notify];
		}
	}
}

//Perform a status change after a delay
- (void)setStatusObject:(id)value forKey:(NSString *)key afterDelay:(NSTimeInterval)delay
{
	if(!delayedStatusTimers) delayedStatusTimers = [[NSMutableArray alloc] init];
	NSTimer		*timer = [NSTimer scheduledTimerWithTimeInterval:delay
														  target:self
														selector:@selector(_applyDelayedStatus:)
														userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
															key, Key,
															value, Value,
															nil]
														 repeats:NO];
	[delayedStatusTimers addObject:timer];
}

//Perform a delayed status change using a dictionary with Value, Key, and Delay keys
- (void)delayedStatusChange:(NSDictionary *)statusChangeDict
{
	[self setStatusObject:[statusChangeDict objectForKey:Value] 
				   forKey:[statusChangeDict objectForKey:Key]
			   afterDelay:[[statusChangeDict objectForKey:@"Delay"] intValue]];
}

- (void)_applyDelayedStatus:(NSTimer *)inTimer
{
	NSDictionary	*infoDict = [inTimer userInfo];
	id				object = [infoDict objectForKey:Value];
	NSString		*key = [infoDict objectForKey:Key];
	
	[self setStatusObject:object forKey:key notify:NotifyNow];
	
	[delayedStatusTimers removeObject:inTimer];
	if([delayedStatusTimers count] == 0){
		[delayedStatusTimers release]; delayedStatusTimers = nil;
	}
}

//Nofity of any queued status changes
- (void)notifyOfChangedStatusSilently:(BOOL)silent
{
    if([changedStatusKeys count]){
		//Clear changedStatusKeys in case this status change invokes another, and we re-enter this code
		NSArray	*keys = changedStatusKeys;
		changedStatusKeys = nil;
		
		[self didModifyStatusKeys:keys silent:silent];
		
		[self didNotifyOfChangedStatusSilently:silent];
		
		[keys release];
    }
}

//Getting status objects ----------------------------------------------------------------------------------------------
#pragma mark Getting Status
//Quickly retrieve a status key enumerator for this object
- (NSEnumerator	*)statusKeyEnumerator
{
	return([statusDictionary keyEnumerator]);
}
- (id)statusObjectForKey:(NSString *)key
{
    return([statusDictionary objectForKey:key]);
}
- (int)integerStatusObjectForKey:(NSString *)key
{
	NSNumber *number = [statusDictionary objectForKey:key];
    return(number ? [number intValue] : 0);
}
- (NSDate *)earliestDateStatusObjectForKey:(NSString *)key
{
	return([statusDictionary objectForKey:key]);
}
- (NSNumber *)numberStatusObjectForKey:(NSString *)key
{
    return([statusDictionary objectForKey:key]);
}
- (NSString *)stringFromAttributedStringStatusObjectForKey:(NSString *)key
{
	return([[statusDictionary objectForKey:key] string]);
}

//For Subclasses -------------------------------------------------------------------------------------------------------
#pragma mark For Subclasses

//Sublcasses should implement this method to take action when a status object changes
- (void)object:(id)inObject didSetStatusObject:(id)value forKey:(NSString *)key notify:(NotifyTiming)notify 
{
	//If the status object changed for the same object receiving this method, notification is called for.
	//Otherwise, it's just an informative message which shouldn't be triggering notification.
	if (inObject == self){
		switch (notify){
			case NotifyNow: {
				//Send out the notification now
				[self didModifyStatusKeys:[NSArray arrayWithObject:key]
								   silent:NO];
				break;
			}
			case NotifyLater: {
				//Add this key to changedStatusKeys for later notification 
				if(!changedStatusKeys) changedStatusKeys = [[NSMutableArray alloc] init];
				[changedStatusKeys addObject:key];
				break;
			}
			case NotifyNever: break; //Take no notification action
		}
	}
}

- (void)didModifyStatusKeys:(NSArray *)keys silent:(BOOL)silent {};
- (void)didNotifyOfChangedStatusSilently:(BOOL)silent {};

//Dynamic Display------------------------------------------------------------------------------------------------------
#pragma mark Dynamic Display
//Access to the display arrays for this object.  Will alloc and init an array if none exists.
- (AIMutableOwnerArray *)displayArrayForKey:(NSString *)inKey
{
    AIMutableOwnerArray	*array = [displayDictionary objectForKey:inKey];
	
    if(!array){
        array = [[AIMutableOwnerArray alloc] init];
		[array setDelegate:self];
        [displayDictionary setObject:array forKey:inKey];
        [array release];
    }
	
    return(array);
}

//With create:YES, this is identical to displayArrayForKey:
//With create:NO, just perform the lookup and return either a mutableOwnerArray or nil
- (AIMutableOwnerArray *)displayArrayForKey:(NSString *)inKey create:(BOOL)create
{
	AIMutableOwnerArray	*array;
	
	if (create){
		array = [self displayArrayForKey:inKey];
	}else{
		array = [displayDictionary objectForKey:inKey];
	}
	
	return array;
}

- (id)displayArrayObjectForKey:(NSString *)inKey
{
	return ([[displayDictionary objectForKey:inKey] objectValue]);
}


//Naming ---------------------------------------------------------------------------------------------------------------
#pragma mark Naming

//Subclasses should override this to provide a general display name
- (NSString *)displayName
{
	return @"";
}
@end
