/*
 *  NDComponentInstance.m
 *  NDAppleScriptObjectProject
 *
 *  Created by Nathan Day on Tue May 20 2003.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */

#import "NDComponentInstance.h"
#import "NSAppleEventDescriptor+NDAppleScriptObject.h"
#include "NDProgrammerUtilities.h"

const OSType		kFinderCreatorCode = 'MACS';

const NSString		* NDAppleScriptOffendingObject = @"Error Offending Object",
						* NDAppleScriptPartialResult = @"Error Partial Result";

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

static OSErr AppleEventResumeHandler(const AppleEvent * anAppleEvent, AppleEvent * aReply, long aRefCon )
{
	NDComponentInstance			* self = (id)aRefCon;
	OSErr								theError = errAEEventNotHandled;
	id									theResumeHandler = [self appleEventResumeHandler];
	NSAppleEventDescriptor		* theResult = nil;	

	NSCParameterAssert( self != nil );

	if( theResumeHandler == nil )
		theResumeHandler = self;

	theResult = [theResumeHandler handleResumeAppleEvent:[NSAppleEventDescriptor descriptorWithAEDesc:anAppleEvent]];
	
	if( theResult )
	{
		NSCParameterAssert( [theResult getAEDesc:aReply] );
		theError = noErr;
	}
	else
		theError = errOSASystemError;
	
	return theError;
}

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
	[self setAppleEventResumeHandler:nil];
		
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

- (void)setAppleEventSendTarget:(id<NDScriptDataSendEvent>)aTarget
{
	[self setAppleEventSendTarget:aTarget currentProcessOnly:NO];
}

/*
 * setAppleEventSendTarget:
 */
- (void)setAppleEventSendTarget:(id<NDScriptDataSendEvent>)aTarget currentProcessOnly:(BOOL)aFlag;
{
	sendAppleEvent.currentProcessOnly = aFlag;
	if( aTarget != sendAppleEvent.target )
	{
		OSErr		AppleEventSendProc( const AppleEvent *theAppleEvent, AppleEvent *reply, AESendMode sendMode, AESendPriority sendPriority, long timeOutInTicks, AEIdleUPP idleProc, AEFilterUPP filterProc, long refCon );

		NSParameterAssert( sizeof(long) == sizeof(id) );
		
		/*	need to save the default send proceedure as we will call it in our send proceedure	*/
		if( aTarget != nil )
		{
			if( defaultSendProcPtr == NULL )		// need to save this so we can restor it
			{
				OSASendUPP						theDefaultSendProcPtr;
				long int							theDefaultSendProcRefCon;
				ComponentInstance		theComponent = [self instanceRecord];

				NSAssert( OSAGetSendProc( theComponent, &theDefaultSendProcPtr, &theDefaultSendProcRefCon) == noErr, @"Could not get default AppleScript send procedure");
				
				/*
				 * make sure we haven't already set the send procedure for this component instance.
				 */
				if( theDefaultSendProcPtr != AppleEventSendProc )
				{
					defaultSendProcPtr = theDefaultSendProcPtr;
					defaultSendProcRefCon = theDefaultSendProcRefCon;
				}
				else	// get the original component instance
				{
					NSLog( @"The send procedure for this component instance is already set." );
					defaultSendProcPtr = ((NDComponentInstance*)theDefaultSendProcRefCon)->defaultSendProcPtr;
					defaultSendProcRefCon = ((NDComponentInstance*)theDefaultSendProcRefCon)->defaultSendProcRefCon;
				}
				NSAssert( OSASetSendProc( theComponent, AppleEventSendProc, (long)self ) == noErr, @"Could not set send procedure" );
			}

			[sendAppleEvent.target release];
			sendAppleEvent.target = [aTarget retain];
		}
		else
		{
			[sendAppleEvent.target release];
			sendAppleEvent.target = nil;

			NSAssert( OSASetSendProc( [self instanceRecord], defaultSendProcPtr, defaultSendProcRefCon ) == noErr, @"Could not restore default send procedure");

			defaultSendProcPtr = NULL;
			defaultSendProcRefCon = 0;
		}
	}
}

/*
 * appleEventSendTarget
 */
- (id<NDScriptDataSendEvent>)appleEventSendTarget
{
	return sendAppleEvent.target;
}

- (BOOL)appleEventSendCurrentProcessOnly
{
	return sendAppleEvent.currentProcessOnly;
}

/*
 * setActiveTarget:
 */
- (void)setActiveTarget:(id<NDScriptDataActive>)aTarget
{
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
- (id<NDScriptDataActive>)activeTarget
{
	return activeTarget;
}

#if 0
/*
 * -setAppleEventSpecialHandler:
 */
- (void)setAppleEventSpecialHandler:(id<NDScriptDataAppleEventSpecialHandler>)aHandler
{
	if( aHandler != appleEventSpecialHandler )
	{
		[appleEventSpecialHandler release];
		appleEventSpecialHandler = [aHandler retain];
	}
}

/*
 * -appleEventSpecialHandler
 */
- (id<NDScriptDataAppleEventSpecialHandler>)appleEventSpecialHandler
{
	return appleEventSpecialHandler;
}
#endif

/*
 * -setAppleEventResumeHandler:
 */
- (void)setAppleEventResumeHandler:(id<NDScriptDataAppleEventResumeHandler>)aHandler
{
	if( aHandler != appleEventResumeHandler )
	{
		if( defaultResumeProcPtr == NULL )
			NDLogOSStatus( OSAGetResumeDispatchProc ( [self instanceRecord], &defaultResumeProcPtr, &defaultResumeProcRefCon ) );

		NDLogOSStatus( OSASetResumeDispatchProc( [self instanceRecord], AppleEventResumeHandler, (long int)self ) );
		[(NSObject *)appleEventResumeHandler release];
		appleEventResumeHandler = [(NSObject *)aHandler retain];
	}
}

/*
 * -appleEventResumeHandler
 */
- (id<NDScriptDataAppleEventResumeHandler>)appleEventResumeHandler
{
	return appleEventResumeHandler;
}

/*
 * -sendAppleEvent:sendMode:sendPriority:timeOutInTicks:idleProc:filterProc:
 */
- (NSAppleEventDescriptor *)sendAppleEvent:(NSAppleEventDescriptor *)anAppleEventDescriptor sendMode:(AESendMode)aSendMode sendPriority:(AESendPriority)aSendPriority timeOutInTicks:(long)aTimeOutInTicks idleProc:(AEIdleUPP)anIdleProc filterProc:(AEFilterUPP)aFilterProc
{
	NSAppleEventDescriptor		* theReplyAppleEventDescriptor = nil;
	AEDesc							theReplyDesc = { typeNull, NULL };

	NSParameterAssert( defaultSendProcPtr != NULL );
	
//	if( NDLogOSStatus( defaultSendProcPtr( [anAppleEventDescriptor aeDesc], &theReplyDesc, aSendMode, aSendPriority, aTimeOutInTicks, anIdleProc, aFilterProc, defaultSendProcRefCon ) ) )
	NDLogOSStatus( defaultSendProcPtr( [anAppleEventDescriptor aeDesc], &theReplyDesc, aSendMode, aSendPriority, aTimeOutInTicks, anIdleProc, aFilterProc, defaultSendProcRefCon ) );
	{
		theReplyAppleEventDescriptor = [NSAppleEventDescriptor descriptorWithAEDescNoCopy:&theReplyDesc];
	}
	
	return theReplyAppleEventDescriptor;
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
 * -handleResumeAppleEvent:
 */
- (NSAppleEventDescriptor *)handleResumeAppleEvent:(NSAppleEventDescriptor *)aDescriptor
{
	AEDesc		theReplyDesc = { typeNull, NULL };
	return defaultResumeProcPtr([aDescriptor aeDesc], &theReplyDesc, defaultResumeProcRefCon ) == noErr ? [NSAppleEventDescriptor descriptorWithAEDescNoCopy:&theReplyDesc] : nil;
}


/*
 * -error
 */
- (NSDictionary *)error
{
	AEDesc					theDescriptor = { typeNull, NULL };
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
		if( OSAScriptError([self instanceRecord], theResults[theIndex].selector, theResults[theIndex].desiredType, &theDescriptor ) == noErr )
		{
			[theDictionary setObject:(id)[[NSAppleEventDescriptor descriptorWithAEDescNoCopy:&theDescriptor] objectValue] forKey:(id)theResults[theIndex].key];
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
	BOOL								theCurrentProcessOnly = [self appleEventSendCurrentProcessOnly];
	NSAppleEventDescriptor		* theAppleEventDescReply,
										* theAppleEventDescriptor = [[NSAppleEventDescriptor alloc] initWithAEDesc:anAppleEvent];

	NSCParameterAssert( self != nil );

	/*	if we have an instance, it has a target and we can create a NSAppleEventDescriptor	*/
	if( theSendTarget != nil && theAppleEventDescriptor != nil && (theCurrentProcessOnly == NO || [theAppleEventDescriptor isTargetCurrentProcess]) )
	{	
		theAppleEventDescReply = [theSendTarget sendAppleEvent:theAppleEventDescriptor sendMode:aSendMode sendPriority:aSendPriority timeOutInTicks:aTimeOutInTicks idleProc:anIdleProc filterProc:aFilterProc];

		if( [theAppleEventDescReply getAEDesc:(AEDesc*)aReply] )
		{
			theError = noErr;			// NO ERROR
		}
	}
	else if( self->defaultSendProcPtr != NULL )
	{
		NDLogOSStatus(theError = (self->defaultSendProcPtr)( anAppleEvent, aReply, aSendMode, aSendPriority, aTimeOutInTicks, anIdleProc, aFilterProc, self->defaultSendProcRefCon ));
	}
	else
		NSLog( @"Failed to send" );
	
	[theAppleEventDescriptor release];

	return theError;
}

#if 0
static OSErr AppleEventSpecialHandler(const AppleEvent * anAppleEvent, AppleEvent * aReply, long aRefCon )
{
	NDComponentInstance			* self = (id)aRefCon;
	OSErr								theError = errAEEventNotHandled;
	id									theSpecialHandler = [self appleEventSpecialHandler];
	NSAppleEventDescriptor		* theResult = nil;
	
	NSCParameterAssert( self != nil );

	if( theSpecialHandler == nil )
		theSpecialHandler = self;
	
	theResult = [theSpecialHandler handleSpecialAppleEvent:[NSAppleEventDescriptor descriptorWithAEDesc:anAppleEvent]];
	if( theResult )
	{
		NSCParameterAssert( [theResult getAEDesc:aReply] );
		theError = noErr;
	}
	else
		theError = errOSASystemError;
	
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

