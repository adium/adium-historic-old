/*
 *  NDComponentInstance.m
 *  NDAppleScriptObjectProject
 *
 *  Created by Nathan Day on Tue May 20 2003.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */

#import "NDComponentInstance.h"
#import "NSAppleEventDescriptor+NDAppleScriptObject.h"

const OSType		kFinderCreatorCode = 'MACS';

const NSString		* NDAppleScriptOffendingObject = @"Error Offending Object",
						* NDAppleScriptPartialResult = @"Error Partial Result";

/*
 * category interface NDComponentInstance (Private)
 */
@interface NDComponentInstance (Private)
- (ComponentInstance)instanceRecord;
@end

/*
 * class implementation NDComponentInstance
 */
@implementation NDComponentInstance

static NDComponentInstance		* sharedComponentInstance = nil;

/*
 * +sharedComponentInstance
 */
+ (id)sharedComponentInstance
{
	if( sharedComponentInstance == nil )
		sharedComponentInstance = [[self alloc] init];
	NSAssert( sharedComponentInstance != nil, @"Could not create shared Component Instance" );
	return sharedComponentInstance;
}

/*
 * +closeSharedComponentInstance
 */
+ (void)closeSharedComponentInstance
{
	[sharedComponentInstance release];
	sharedComponentInstance = nil;
}

/*
 * findNextComponent
 */
+ (Component)findNextComponent
{
	ComponentDescription		theReturnCompDesc;
	static Component			theLastComponent = NULL;
	ComponentDescription		theComponentDesc;

	theComponentDesc.componentType = kOSAComponentType;
	theComponentDesc.componentSubType = kOSAGenericScriptingComponentSubtype;
	theComponentDesc.componentManufacturer = 0;
	theComponentDesc.componentFlags =  kOSASupportsCompiling | kOSASupportsGetSource | kOSASupportsAECoercion | kOSASupportsAESending | kOSASupportsConvenience | kOSASupportsDialects | kOSASupportsEventHandling;

	theComponentDesc.componentFlagsMask = theComponentDesc.componentFlags;

	do
	{
		theLastComponent = FindNextComponent( theLastComponent, &theComponentDesc );
 	}
	while( GetComponentInfo( theLastComponent, &theReturnCompDesc, NULL, NULL, NULL ) == noErr && theComponentDesc.componentSubType == kOSAGenericScriptingComponentSubtype );

	return theLastComponent;
}

/*
 * + componentInstance
 */
+ (id)componentInstance
{
	return [[[self alloc] init] autorelease];
}

/*
 * +componentInstanceWithComponent:
 */
+ (id)componentInstanceWithComponent:(Component)aComponent
{
	return [[[self alloc] initWithComponent:aComponent] autorelease];
}

/*
 * -init
 */
- (id)init
{
	return [self initWithComponent:NULL];
}

/*
 * -initWithComponent:
 */
- (id)initWithComponent:(Component)aComponent
{
	if( (self = [super init]) != nil )
	{
		if( aComponent == NULL )
		{
			// crashes here
			if( (instanceRecord = OpenDefaultComponent( kOSAComponentType, kAppleScriptSubtype )) == NULL )
			{
				[self release];
				self = nil;
				NSLog(@"Could not open connection with default AppleScript component");
			}
		}
		else if( (instanceRecord = OpenComponent( aComponent )) == NULL )
		{
			[self release];
			self = nil;
			NSLog(@"Could not open connection with component");
		}
	}
	return self;
}

/*
 * - dealloc
 */
-(void)dealloc
{
	[self setAppleEventSendTarget:nil];
	[self setActiveTarget:nil];
//	[self setAppleEventSpecialHandler:nil];
//	[self setAppleEventResumeHandler:nil];
		
	if( instanceRecord != NULL )
	{
		CloseComponent( instanceRecord );
	}
	[super dealloc];
}

/*
 * - setDefaultTarget:
 */
- (void)setDefaultTarget:(NSAppleEventDescriptor *)aDefaultTarget
{
	if( OSASetDefaultTarget( [self instanceRecord], [aDefaultTarget aeDesc] ) != noErr )
		NSLog( @"Could not set default target" );
}

/*
 * - setDefaultTargetAsCreator:
 */
- (void)setDefaultTargetAsCreator:(OSType)aCreator
{
	NSAppleEventDescriptor	* theAppleEventDescriptor;

	theAppleEventDescriptor = [NSAppleEventDescriptor descriptorWithDescriptorType:typeApplSignature data:[NSData dataWithBytes:&aCreator length:sizeof(aCreator)]];
	[self setDefaultTarget:theAppleEventDescriptor];
}

/*
 * - setFinderAsDefaultTarget
 */
- (void)setFinderAsDefaultTarget
{
	[self setDefaultTargetAsCreator:kFinderCreatorCode];
}

/*
 * setAppleEventSendTarget:
 */
- (void)setAppleEventSendTarget:(id<NDAppleScriptObjectSendEvent>)aTarget
{
	if( aTarget != sendAppleEventTarget )
	{
		OSErr		AppleEventSendProc( const AppleEvent *theAppleEvent, AppleEvent *reply, AESendMode sendMode, AESendPriority sendPriority, long timeOutInTicks, AEIdleUPP idleProc, AEFilterUPP filterProc, long refCon );

		NSParameterAssert( sizeof(long) == sizeof(id) );
		
		/*	need to save the default send proceedure as we will call it in our send proceedure	*/
		if( aTarget != nil )
		{
			if( defaultSendProcPtr == NULL )		// need to save this so we can restor it
			{
				ComponentInstance		theComponent = [self instanceRecord];

				NSAssert( OSAGetSendProc( theComponent, &defaultSendProcPtr, &defaultSendProcRefCon) == noErr, @"Could not get default AppleScript send procedure");
				NSAssert( OSASetSendProc( theComponent, AppleEventSendProc, (long)self ) == noErr, @"Could not set send procedure" );
			}

			[sendAppleEventTarget release];
			sendAppleEventTarget = [aTarget retain];
		}
		else
		{
			[sendAppleEventTarget release];
			sendAppleEventTarget = nil;

			NSAssert( OSASetSendProc( [self instanceRecord], defaultSendProcPtr, defaultSendProcRefCon ) == noErr, @"Could not restore default send procedure");

//			defaultSendProcPtr = NULL;
//			defaultSendProcRefCon = 0;
		}
	}
}

/*
 * appleEventSendTarget
 */
- (id<NDAppleScriptObjectSendEvent>)appleEventSendTarget
{
	return sendAppleEventTarget;
}

/*
 * setActiveTarget:
 */
- (void)setActiveTarget:(id<NDAppleScriptObjectActive>)aTarget
{
	static OSErr		AppleScriptActiveProc( long aRefCon );

	if( aTarget != activeTarget )
	{
		NSParameterAssert( sizeof(long) == sizeof(id) );

		if( aTarget != nil )
		{
			/*	need to save the default active proceedure as we will call it in our active proceedure	*/
			if( defaultActiveProcPtr == NULL )
			{
				ComponentInstance		theComponent = [self instanceRecord];

				NSAssert( OSAGetActiveProc(theComponent, &defaultActiveProcPtr, &defaultActiveProcRefCon ) == noErr, @"Could not get default AppleScript active procedure");
				NSAssert( OSASetActiveProc( theComponent, AppleScriptActiveProc , (long)self ) == noErr, @"Could not set AppleScript active procedure.");
			}

			[activeTarget release];
			activeTarget = [aTarget retain];
		}
		else if( defaultActiveProcPtr == NULL )
		{
			[activeTarget release];
			activeTarget = nil;
			NSAssert( OSASetActiveProc( [self instanceRecord], defaultActiveProcPtr, defaultActiveProcRefCon ) == noErr, @"Could not set default active procedure.");
			defaultActiveProcPtr = NULL;
			defaultActiveProcRefCon = 0;
		}
	}
}

/*
 * -activeTarget
 */
- (id<NDAppleScriptObjectActive>)activeTarget
{
	return activeTarget;
}

#if 0
- (void)setAppleEventSpecialHandler:(id<NDScriptDataAppleEventSpecialHandler>)aHandler
{
	if( aHandler != appleEventSpecialHandler )
	{
		[appleEventSpecialHandler release];
		appleEventSpecialHandler = [aHandler retain];
	}
}

- (id<NDScriptDataAppleEventSpecialHandler>)appleEventSpecialHandler
{
	return appleEventSpecialHandler;
}

- (void)setAppleEventResumeHandler:(id<NDScriptDataAppleEventResumeHandler>)aHandler
{
	if( aHandler != appleEventResumeHandler )
	{
		[appleEventResumeHandler release];
		appleEventResumeHandler = [aHandler retain];
	}
}

- (id<NDScriptDataAppleEventResumeHandler>)appleEventResumeHandler
{
	return appleEventResumeHandler;
}
#endif

/*
 * -sendAppleEvent:sendMode:sendPriority:timeOutInTicks:idleProc:filterProc:
 */
- (NSAppleEventDescriptor *)sendAppleEvent:(NSAppleEventDescriptor *)theAppleEventDescriptor sendMode:(AESendMode)aSendMode sendPriority:(AESendPriority)aSendPriority timeOutInTicks:(long)aTimeOutInTicks idleProc:(AEIdleUPP)anIdleProc filterProc:(AEFilterUPP)aFilterProc
{
	NSAppleEventDescriptor		* theReplyAppleEventDesc = nil;
	AppleEvent						theReplyAppleEvent;

	NSParameterAssert( defaultSendProcPtr != NULL );

	if( defaultSendProcPtr( [theAppleEventDescriptor aeDesc], &theReplyAppleEvent, aSendMode, aSendPriority, aTimeOutInTicks, anIdleProc, aFilterProc, defaultSendProcRefCon ) == noErr )
	{
		theReplyAppleEventDesc = [NSAppleEventDescriptor descriptorWithAEDescNoCopy:&theReplyAppleEvent];
	}
	
	return theReplyAppleEventDesc;
}

/*
 * appleScriptActive
 */
- (BOOL)appleScriptActive
{
	NSParameterAssert( defaultActiveProcPtr != NULL );
	return defaultActiveProcPtr( defaultActiveProcRefCon ) == noErr;
}

/*
 * -error
 */
- (NSDictionary *)error
{
	AEDesc					aDescriptor;
	unsigned int			theIndex;
	NSMutableDictionary	* theDictionary = [NSMutableDictionary dictionaryWithCapacity:7];

	struct { const NSString * key; const DescType desiredType; const OSType selector; }
			theResults[] = {
			{ NSAppleScriptErrorMessage, typeText, kOSAErrorMessage },
			{ NSAppleScriptErrorNumber, typeShortInteger, kOSAErrorNumber },
			{ NSAppleScriptErrorAppName, typeText, kOSAErrorApp },
			{ NSAppleScriptErrorBriefMessage, typeText, kOSAErrorBriefMessage },
			{ NSAppleScriptErrorRange, typeOSAErrorRange, kOSAErrorRange },
			{ NDAppleScriptOffendingObject, typeObjectSpecifier, kOSAErrorOffendingObject, },
			{ NDAppleScriptPartialResult, typeBest, kOSAErrorPartialResult },
			{ nil, 0, 0 }
			};
	for( theIndex = 0; theResults[theIndex].key != nil; theIndex++ )
	{
		if( OSAScriptError([self instanceRecord], theResults[theIndex].selector, theResults[theIndex].desiredType, &aDescriptor ) == noErr )
		{
			[theDictionary setObject:(id)[[NSAppleEventDescriptor descriptorWithAEDescNoCopy:&aDescriptor] objectValue] forKey:(id)theResults[theIndex].key];
		}
	}

	return theDictionary;
}

/*
 * -name
 */
- (NSString *)name
{
	AEDesc		theDesc = { typeNull, NULL };
	NSString		* theName = nil;
	if ( OSAScriptingComponentName( [self instanceRecord], &theDesc) == noErr )
		theName = [[NSAppleEventDescriptor descriptorWithAEDescNoCopy:&theDesc] stringValue];

	return theName;
}

/*
 * description
 */
- (NSString *)description
{
	NSString		* theName = [self name];
	return theName == nil
		? [@"NDComponentInstance name:" stringByAppendingString:theName]
		: @"NDComponentInstance name: not available";
}

/*
 * -isEqualToComponentInstance:
 */
- (BOOL)isEqualToComponentInstance:(NDComponentInstance *)aComponentInstance
{
	return aComponentInstance == self || [aComponentInstance instanceRecord] == [self instanceRecord];
}

/*
 * -isEqualTo:
 */
- (BOOL)isEqualTo:(id)anObject
{
	return anObject == self || ([anObject isKindOfClass:[self class]] && [self isEqualToComponentInstance:anObject]);
}

/*
 * -copyWithZone:
 */
- (id)copyWithZone:(NSZone *)aZone
{
	return [self retain];
}

/*
 * -hash
 */
- (unsigned int)hash
{
	return (unsigned int)instanceRecord;
}

/*
 * function AppleEventSendProc
 */
OSErr AppleEventSendProc( const AppleEvent *anAppleEvent, AppleEvent *aReply, AESendMode aSendMode, AESendPriority aSendPriority, long aTimeOutInTicks, AEIdleUPP anIdleProc, AEFilterUPP aFilterProc, long aRefCon )
{
	NDComponentInstance			* self = (id)aRefCon;
	OSErr								theError = errOSASystemError;
	id									theSendTarget = [self appleEventSendTarget];
	NSAppleEventDescriptor		* theAppleEventDescReply,
										* theAppleEventDescriptor = [NSAppleEventDescriptor descriptorWithAEDesc:anAppleEvent];

	NSCParameterAssert( self != nil );
	
	/*	if we have an instance, it has a target and we can create a NSAppleEventDescriptor	*/
	if( theSendTarget != nil && theAppleEventDescriptor != nil )
	{
		theAppleEventDescReply = [theSendTarget sendAppleEvent:theAppleEventDescriptor sendMode:aSendMode sendPriority:aSendPriority timeOutInTicks:aTimeOutInTicks idleProc:anIdleProc filterProc:aFilterProc];

		if( theAppleEventDescReply )
		{
			if( [theAppleEventDescReply getAEDesc:(AEDesc*)aReply] )
			{
				theError = noErr;			// NO ERROR
			}
		}
		else if( self->defaultSendProcPtr != NULL )
		{
			theError = (self->defaultSendProcPtr)( anAppleEvent, aReply, aSendMode, aSendPriority, aTimeOutInTicks, anIdleProc, aFilterProc, self->defaultSendProcRefCon );			
		}
	}
	else if( self->defaultSendProcPtr != NULL )
	{
		theError = (self->defaultSendProcPtr)( anAppleEvent, aReply, aSendMode, aSendPriority, aTimeOutInTicks, anIdleProc, aFilterProc, self->defaultSendProcRefCon );

	}

	return theError;
}

/*
 * function AppleScriptActiveProc
 */
static OSErr AppleScriptActiveProc( long aRefCon )
{
	NDComponentInstance	* self = (id)aRefCon;
	id							theActiveTarget = [self activeTarget];
	OSErr						theError = errOSASystemError;

	NSCParameterAssert( self != nil );
	
	if( theActiveTarget != nil )
		theError = [theActiveTarget appleScriptActive] ? noErr : errOSASystemError;
	else
		theError = (self->defaultActiveProcPtr)( self->defaultActiveProcRefCon );

	return theError;
}

#if 0

static OSErr AppleEventSpecialHandler(const AppleEvent * anAppleEvent, AppleEvent * aReply, long aRefCon )
{
	NDComponentInstance		* self = (id)aRefCon;
	OSErr							theError = errOSASystemError;
	id								theSpecialHandler = [self appleEventSpecialHandler];

	NSCParameterAssert( self != nil );

	if( theSpecialHandler )
	{
		theError = [theSpecialHandler handleSpecialAppleEvent:[NSAppleEventDescriptor descriptorWithAEDesc:anAppleEvent] ? noErr : errAEEventNotHandled;
	}
	else
	{
	}
	
	return theError;
}

static OSErr AppleEventResumeHandler(const AppleEvent * anAppleEvent, AppleEvent * aReply, long aRefCon )
{
	NDComponentInstance		* self = (id)aRefCon;
	OSErr							theError = errOSASystemError;
	id								theResumeHandler = [self appleEventResumeHandler];
	NSCParameterAssert( self != nil );

	if( theResumeHandler )
	{
		theError = [theResumeHandler handleResumeAppleEvent:[NSAppleEventDescriptor descriptorWithAEDesc:anAppleEvent] ? noErr : errAEEventNotHandled;
	}
	else
	{
	}
	
	return theError;
}

#endif

@end

/*
 * category implementation NDComponentInstance (Private)
 */
@implementation NDComponentInstance (Private)

/*
 * -instanceRecord
 */
- (ComponentInstance)instanceRecord
{
	return instanceRecord;
}

@end

