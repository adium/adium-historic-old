/*
 *  NDScriptData.m
 *  NDAppleScriptObjectProjectAlpha
 *
 *  Created by Nathan Day on Tue Apr 27 2004.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */

#import "NDScriptData.h"
#import "NDResourceFork.h"
#import "NDComponentInstance.h"
#import "NSAppleEventDescriptor+NDAppleScriptObject.h"
//#import "NSArray+NDUtilities.h"
#import "NDProgrammerUtilities.h"

//static NSString		* kScriptResourceName = @"script";

/*
 * class interface NDScriptData (Private)
 */
@interface NDScriptData (Private)
+ (id)newWithScriptID:(OSAID)aScriptID componentInstance:(NDComponentInstance *)component;
+ (id)scriptDataWithScriptID:(OSAID)aScriptID componentInstance:(NDComponentInstance *)component;
+ (Class)classForScriptID:(OSAID)scriptID componentInstance:(NDComponentInstance *)componentInstance;
- (id)initWithScriptID:(OSAID)aScriptID componentInstance:(NDComponentInstance *)component;
- (OSAID)scriptID;
- (ComponentInstance)instanceRecord;
- (BOOL)isCompiled;
@end

/*
 * class interface NDScriptContext (Private)
 */
@interface NDScriptContext (Private)
+ (OSAID)compileString:(NSString *)string modeFlags:(long)modeFlags scriptID:(OSAID)scriptID componentInstance:(NDComponentInstance *)aComponentInstance;
- (id)initWithScriptID:(OSAID)aScriptDataID parentScriptData:(NDScriptData *)aParentScriptData;
@end

@interface NDScriptHandler (Private)
+ (OSAID)compileString:(NSString *)aString scriptID:(OSAID)aScriptID componentInstance:(NDComponentInstance *)aComponentInstance;
+ (OSAID)compileString:(NSString *)aString modeFlags:(long)aModeFlags scriptID:(OSAID)aScriptID componentInstance:(NDComponentInstance *)aComponentInstance;
- (void)setResultScriptDataID:(OSAID)aScriptDataID;
@end

/*
 * category interface NDComponentInstance (Private)
 */
@interface NDComponentInstance (Private)
- (ComponentInstance)instanceRecord;
@end


static unsigned long int numberOfTimesModified( OSAID aScriptID, ComponentInstance aComponentInstance );
static BOOL isTypeCompiledScript( OSAID aScriptID, ComponentInstance aComponentInstance );
static BOOL isTypeScriptValue( OSAID aScriptID, ComponentInstance aComponentInstance );
static BOOL isTypeScriptContext( OSAID aScriptID, ComponentInstance aComponentInstance );
static DescType bestType( OSAID aScriptID, ComponentInstance aComponentInstance );
static BOOL canGetSource( OSAID aScriptID, ComponentInstance aComponentInstance );
static BOOL hasOpenHandler( OSAID aScriptID, ComponentInstance aComponentInstance );
static OSAID compileString(NSString * aString, long int aModeFlags, OSAID aScriptID, NDComponentInstance * aComp );
static OSAID loadScriptData( NSData * aData, long int aModeFlags, OSAID aScriptID, NDComponentInstance * aComp );

/*
 * class implementation NDScriptData
 */
@implementation NDScriptData

/*
 * +scriptDataWithAppleEventDescriptor:componentInstance:
 */
+ (id)scriptDataWithAppleEventDescriptor:(NSAppleEventDescriptor *)aDescriptor componentInstance:(NDComponentInstance *)aComponentInstance
{
	OSAID		theScriptID = kOSANullScript;
	id			theInstance = nil;
	
	if(aComponentInstance == nil)
		aComponentInstance = [NDComponentInstance sharedComponentInstance];
	
	if( NDLogOSStatus( OSACoerceFromDesc( [aComponentInstance instanceRecord], [aDescriptor aeDesc], kOSAModeNull, &theScriptID )) )
	{
		theInstance = [self newWithScriptID:theScriptID componentInstance:aComponentInstance];
	}
	
	return [theInstance autorelease];
}

/*
 * -init
 */
- (id)init
{
	if( NDLogFalse( self = [self initWithComponentInstance:[NDComponentInstance sharedComponentInstance]] ) )
	{
		scriptID = kOSANullScript;
	}

	return self;
}

/*
 * -initWithAppleEventDescriptor:componentInstance:
 */
- (id)initWithAppleEventDescriptor:(NSAppleEventDescriptor *)aDescriptor componentInstance:(NDComponentInstance *)aComponentInstance
{
	OSAID		theScriptID = kOSANullScript;
	if(aComponentInstance == nil)
		aComponentInstance = [NDComponentInstance sharedComponentInstance];

	if( NDLogOSStatus( OSACoerceFromDesc( [aComponentInstance instanceRecord], [aDescriptor aeDesc], kOSAModeNull, &theScriptID )) )
	{
		self = [self initWithScriptID:theScriptID componentInstance:aComponentInstance];
	}
	else
	{
		[self release];
		self = nil;
	}

	return self;
}

/*
 * -initWithData:componentInstance:
 */
- (id)initWithData:(NSData *)aData componentInstance:(NDComponentInstance *)aComponentInstance
{
	if(aComponentInstance == nil)
		aComponentInstance = [NDComponentInstance sharedComponentInstance];
	return [self initWithScriptID:loadScriptData( aData, kOSAModeNull, kOSANullScript, aComponentInstance ) componentInstance:aComponentInstance];
}

/*
 * -initWithCoder:
 */
- (id)initWithCoder:(NSCoder *)aDecoder
{
	return [self initWithData:[aDecoder decodeDataObject] componentInstance:[NDComponentInstance sharedComponentInstance]];

}

/*
 * -initWithContentsOfFile:componentInstance:
 */
- (id)initWithContentsOfFile:(NSString *)aPath componentInstance:(NDComponentInstance *)aComponentInstance
{
	OSAID		theScriptID = kOSANullScript;
	if( aComponentInstance == nil )
		aComponentInstance = [NDComponentInstance sharedComponentInstance];
	if( (theScriptID = loadScriptData( [NSData dataWithContentsOfFile:aPath], kOSAModeNull, kOSANullScript, aComponentInstance )) != kOSANullScript
		|| (theScriptID = loadScriptData( [NSData dataWithResourceForkContentsOfFile:aPath type:kOSAScriptResourceType Id:kScriptResourceID], kOSAModeNull, kOSANullScript, aComponentInstance )) != kOSANullScript
		|| (theScriptID = [[self class] compileString:[NSString stringWithContentsOfFile:aPath] scriptID:kOSANullScript componentInstance:aComponentInstance]) != kOSANullScript )
	{
		self = [self initWithScriptID:theScriptID componentInstance:aComponentInstance];
	}
	else
	{
		[self release];
		self = nil;
	}
		
	return self;
}

/*
 * -initWithContentsOfURL:componentInstance:
 */
- (id)initWithContentsOfURL:(NSURL *)anURL componentInstance:(NDComponentInstance *)aComponentInstance
{
	OSAID		theScriptID = kOSANullScript;
	if( aComponentInstance == nil )
		aComponentInstance = [NDComponentInstance sharedComponentInstance];
	if( (theScriptID = loadScriptData( [NSData dataWithContentsOfURL:anURL], kOSAModeNull, kOSANullScript, aComponentInstance )) != kOSANullScript
	  || (theScriptID = loadScriptData( [NSData dataWithResourceForkContentsOfURL:anURL type:kOSAScriptResourceType Id:kScriptResourceID], kOSAModeNull, kOSANullScript, aComponentInstance )) != kOSANullScript
	  || (theScriptID = [[self class] compileString:[NSString stringWithContentsOfURL:anURL] scriptID:kOSANullScript componentInstance:aComponentInstance]) != kOSANullScript )
	{
		self = [self initWithScriptID:theScriptID componentInstance:aComponentInstance];
	}
	else
	{
		[self release];
		self = nil;
	}
	return self;
}

/*
 * -initWithComponentInstance:
 */
- (id)initWithComponentInstance:(NDComponentInstance *)aComponentInstance
{
	if( NDLogFalse( self = [super init]) )
	{
		scriptID = kOSANullScript;
		componentInstance = aComponentInstance ? aComponentInstance : [NDComponentInstance sharedComponentInstance];
		[componentInstance retain];
	}
	return self;
}

/*
 * -dealloc
 */
- (void)dealloc
{
	if( scriptID != kOSANullScript )
	{
		NDLogOSStatus( OSADispose( [self instanceRecord], scriptID ));
	}
	[componentInstance release];
	[super dealloc];
}

/*
 * -encodeWithCoder:
 */
- (void)encodeWithCoder:(NSCoder *)anEncoder
{
	[anEncoder encodeDataObject:[self data]];
}

/*
 * -data
 */
- (NSData *)data
{
	AEDesc		theDesc;
	return NDLogOSStatus( OSAStore( [self instanceRecord], [self scriptID], typeOSAGenericStorage, kOSAModeDontStoreParent, &theDesc ))
				? [[NSAppleEventDescriptor descriptorWithAEDescNoCopy:&theDesc] data]
				: nil;
}

/*
 * -appleEventDescriptorValue
 */
- (NSAppleEventDescriptor *)appleEventDescriptorValue
{
	AEDesc		theDesc;
	return NDLogOSStatus( OSACoerceToDesc( [self instanceRecord], [self scriptID], typeWildCard, kOSAModeNull, &theDesc))
		? [NSAppleEventDescriptor descriptorWithAEDescNoCopy:&theDesc]
		: nil;
}

/*
 * -bestAppleEventDescriptorType
 */
- (DescType)bestAppleEventDescriptorType
{
	return bestType( [self scriptID], [self instanceRecord] );
}

/*
 * -stringValue
 */
- (NSString *)stringValue
{
	AEDesc		theDesc = {0};
	DescType		theBestType = bestType( [self scriptID], [self instanceRecord] );
	BOOL			theSuccess = NO;
	
	if( theBestType == kTXNUnicodeTextData || theBestType == kTXNTextData || theBestType == kTXNRichTextFormatData )
	{
		theSuccess = NDLogOSStatus( OSACoerceToDesc( [self instanceRecord], [self scriptID], theBestType, kOSAModeNull, &theDesc) );
	}
	else
	{
		theSuccess = NDLogOSStatus( OSADisplay( [self instanceRecord], [self scriptID], kTXNUnicodeTextData, kOSAModeNull, &theDesc) );
	}
	
	return theSuccess ? [[NSAppleEventDescriptor descriptorWithAEDescNoCopy:&theDesc] stringValue] : nil;
}


/*
 * -componentInstance
 */
- (NDComponentInstance *)componentInstance
{
	return componentInstance;
}

/*
 * -isValue
 */
- (BOOL)isValue
{
	long int		theResult;
	return NDLogOSStatus( OSAGetScriptInfo( [self instanceRecord], [self scriptID], kOSAScriptIsTypeScriptValue, &theResult)) && theResult != 0;
}

/*
 * -isCompiledScript
 */
- (BOOL)isCompiledScript
{
	long int		theResult;
	return NDLogOSStatus( OSAGetScriptInfo( [self instanceRecord], [self scriptID], kOSAScriptIsTypeCompiledScript, &theResult)) && theResult != 0;
}

/*
 * -hasScriptContext
 */
- (BOOL)hasScriptContext
{
	long int		theResult;
	return NDLogOSStatus( OSAGetScriptInfo( [self instanceRecord], [self scriptID], kOSAScriptIsTypeScriptContext, &theResult)) && theResult != 0;
}

/*
 * -hasOpenHandler
 */
- (BOOL)hasOpenHandler
{
	long int		theResult;
	return NDLogOSStatus( OSAGetScriptInfo( [self instanceRecord], [self scriptID], kASHasOpenHandler, &theResult)) && theResult != 0;
}

/*
 * -description
 */
- (NSString *)description
{
	AEDesc		theDesc;
	const char		* theTypeStr = [self hasScriptContext] ? "script context" : [self isCompiledScript] ? "script handler" : "script data";
	return NDLogOSStatus( OSADisplay( [self instanceRecord], [self scriptID], kTXNUnicodeTextData, kOSAModeDisplayForHumans, &theDesc ))
		? [NSString stringWithFormat:@"%s: %@", theTypeStr, [[NSAppleEventDescriptor descriptorWithAEDescNoCopy:&theDesc] stringValue]]
		: nil;
}

/*
 * -writeToFile:atomically:
 */
- (BOOL)writeToFile:(NSString *)aPath atomically:(BOOL)anAtomically
{
	return [[self data] writeToFile:aPath atomically:anAtomically];
}

/*
 * -writeToURL:atomically:
 */
- (BOOL)writeToURL:(NSURL* )anURL atomically:(BOOL)anAtomically
{
	return [[self data] writeToURL:anURL atomically:anAtomically];
}

/*
 * -copyWithComponentInstance:
 */
- (id)copyWithComponentInstance:(NDComponentInstance *)aComponentInstance
{
	return aComponentInstance == [self componentInstance] ? [self copyWithZone:nil]: [NDScriptData scriptDataWithScriptID:[self scriptID] componentInstance:aComponentInstance];
}

/*
 * -copyWithZone:
 */
- (id)copyWithZone:(NSZone *)aZone
{
	return [self retain];
}

/*
 * -isEqualToScriptData:
 */
- (BOOL)isEqualToScriptData:(NDScriptData *)aScriptData
{
	return aScriptData == self || ([aScriptData instanceRecord] == [self instanceRecord] && [aScriptData scriptID] == [self scriptID]);
}

/*
 * -isEqualTo:
 */
- (BOOL)isEqualTo:(id)anObject
{
	return anObject == self || ([anObject isKindOfClass:[NDScriptData class]] && [self isEqualToScriptData:anObject]);
}

/*
 * -hash
 */
- (unsigned int)hash
{
	return (unsigned int)[self instanceRecord] ^ (unsigned int)[self scriptID];
}

@end

@implementation NDScriptHandler

/*
 * -init
 */
- (id)init
{
	if( (self = [super init]) != nil )
	{
		resultScriptData = nil;
		resultScriptID = kOSANullScript;
	}

	return self;
}

/*
 * -initWithSource:modeFlags:componentInstance:
 */
- (id)initWithSource:(NSString *)aSource modeFlags:(long)aModeFlags componentInstance:(NDComponentInstance *)aComponentInstance
{
	if(aComponentInstance == nil)
		aComponentInstance = [NDComponentInstance sharedComponentInstance];
	return [self initWithScriptID:[[self class] compileString:aSource scriptID:kOSANullScript componentInstance:aComponentInstance] componentInstance:aComponentInstance];
}

/*
 * -source
 */
- (NSString *)source
{
	AEDesc		theDesc = {0};
	return canGetSource( [self scriptID], [self instanceRecord] ) && NDLogOSStatus( OSAGetSource( [self instanceRecord], [self scriptID], kTXNUnicodeTextData, &theDesc))
			? [[NSAppleEventDescriptor descriptorWithAEDescNoCopy:&theDesc] stringValue]
			: nil;
}

/*
 * -resultScriptData
 */
- (NDScriptData *)resultScriptData
{
	if( resultScriptData == nil && resultScriptID != kOSANullScript )
		resultScriptData = [NDScriptData newWithScriptID:resultScriptID componentInstance:[self componentInstance]];
		
	return resultScriptData;
}

- (void)dealloc
{
	[self setResultScriptDataID:kOSANullScript];	
	[super dealloc];
}

/*
 * -isCompiledScript
 */
- (BOOL)isCompiledScript
{
	return YES;
}

/*
 * -appleEventDescriptorValue
 */
- (NSAppleEventDescriptor *)appleEventDescriptorValue
{
	AEDesc		theDesc;
	return NDLogOSStatus( OSACoerceToDesc( [self instanceRecord], [self scriptID], typeAppleEvent, kOSAModeNull, &theDesc))
		? [NSAppleEventDescriptor descriptorWithAEDescNoCopy:&theDesc]
		: nil;
}

/*
 * -copyWithZone:
 */
- (id)copyWithZone:(NSZone *)aZone
{
	id				theInstance = nil;
	OSAID			theScriptID = kOSANullScript;
	if( NDLogOSStatus( OSACopyID( [self instanceRecord], [self scriptID], &theScriptID ) ) )
	{
		theInstance = [NDScriptData newWithScriptID:theScriptID componentInstance:[self componentInstance]];
	}
	
	return theInstance;
}

@end

/*
 * class implementation NDScriptContext
 */
@implementation NDScriptContext

/*
 * +compileExecuteSource:componentInstance:
 */
+ (NDScriptData *)compileExecuteSource:(NSString *)aSource componentInstance:(NDComponentInstance *)aComponentInstance
{
	OSAID		theScriptID = kOSANullScript,
				theResultScriptID = kOSANullScript;
	BOOL		theResult = NO;

	if( aComponentInstance == nil )
		aComponentInstance = [NDComponentInstance sharedComponentInstance];

	theScriptID = [self compileString:aSource modeFlags:kOSAModeCanInteract|kOSAModeAugmentContext|kOSAModeCompileIntoContext scriptID:kOSANullScript componentInstance:aComponentInstance];
	
	if( theScriptID != kOSANullScript )
	{
		theResult = NDLogOSStatus( OSAExecute( [aComponentInstance instanceRecord], theScriptID, kOSANullScript, kOSAModeNull, &theResultScriptID ));
		OSADispose( [aComponentInstance instanceRecord], theScriptID );
	}
	
	return theResult
		? [NDScriptData scriptDataWithScriptID:theResultScriptID componentInstance:aComponentInstance]
		: nil;
}

/*
 * -init
 */
- (id)init
{
	if( (self = [super init]) != nil )
	{
		parentScriptData = nil;
		executionModeFlags = kOSAModeNull;
	}
	return self;
}

/*
 * -initWithData:parentScriptData:
 */
- (id)initWithData:(NSData *)aData parentScriptData:(NDScriptData *)aParentData
{
	if( (self = [self initWithData:aData componentInstance:[aParentData componentInstance]]) != nil )
	{
		[self setParentScriptData:aParentData];
	}
	return self;
}

/*
 * -initWithParentScriptData:componentInstance:
 */
- (id)initWithParentScriptData:(NDScriptData *)aParentScriptData name:(NSString *)aName
{
	if( (self = [self initWithComponentInstance:[aParentScriptData componentInstance]]) != nil )
	{
		parentScriptData = [aParentScriptData retain];
		if( !NDLogOSStatus( OSAMakeContext( [self instanceRecord], aName ? [[NSAppleEventDescriptor descriptorWithString:aName] aeDesc] : NULL, parentScriptData ? [parentScriptData scriptID] : kOSANullScript, &scriptID )))
		{
			[self release];
			self = nil;
		}
	}

	return self;
}

/*
 * -initWithContentsOfFile:aPathparentScriptData:
 */
- (id)initWithContentsOfFile:aPath parentScriptData:(NDScriptData *)aParentData
{
	if( (self = [self initWithContentsOfFile:aPath componentInstance:[aParentData componentInstance]]) != nil )
	{
		[self setParentScriptData:aParentData];
	}
	return self;
}

/*
 * -initWithContentsOfURL:parentScriptData:
 */
- (id)initWithContentsOfURL:(NSURL *)aURL parentScriptData:(NDScriptData *)aParentData
{
	if( (self = [self initWithContentsOfURL:aURL componentInstance:[aParentData componentInstance]]) != nil )
	{
		[self setParentScriptData:aParentData];
	}
	return self;
}

/*
 * -dealloc
 */
- (void)dealloc
{
	[parentScriptData release];
	[super dealloc];
}

/*
 * -augmentWithSource:
 */
- (BOOL)augmentWithSource:(NSString *)aSource
{
	return NDLogOSStatus( OSACompile( [self instanceRecord], [[NSAppleEventDescriptor descriptorWithString:aSource] aeDesc], kOSAModeAugmentContext, &scriptID ));
}

/*
 * -parentScriptData
 */
- (NDScriptData *)parentScriptData
{
	if( parentScriptData == nil )
	{
		parentScriptData = [[self scriptDataForPropertyOfType:pASParent] retain];
	}
	return parentScriptData;
}

/*
 * -setParentScriptData:
 */
- (BOOL)setParentScriptData:(NDScriptData *)aParentData
{
	BOOL		theResult = YES;
	if( aParentData != parentScriptData )
	{
		theResult = [self setPropertyOfType:pASParent toScriptData:aParentData];
		[parentScriptData release];
		parentScriptData = [aParentData retain];
	}
	return theResult;
}

- (NSString *)name
{
	[[self scriptDataForPropertyOfType:pName] stringValue];
}

- (void)setName:(NSString *)aName
{
	NDLogFalse([self setPropertyOfType:pName toScriptData:[NDScriptData scriptDataWithObject:aName]]);
}

/*
 * -execute
 */
- (BOOL)execute
{
	OSAID		theResultScriptID = kOSANullScript;
	BOOL		theResult = NO;

	theResult = NDLogOSStatus( OSAExecute( [self instanceRecord], [self scriptID], kOSANullScript, [self executionModeFlags], &theResultScriptID ));

	[self setResultScriptDataID:theResult ? theResultScriptID : kOSANullScript];
	
	return theResult;
}

/*
 * -executeScriptHandler:
 */
- (BOOL)executeScriptHandler:(NDScriptHandler *)aScriptHandler
{
	OSAID		theResultScriptID = kOSANullScript;
	BOOL		theResult = NO;
	
	if( aScriptHandler )
	{
		BOOL		theNeedToRelease = NO;
		
		// if has a different component instance then we need to make a copy with selfs component instance.
		if( [aScriptHandler instanceRecord] != [self instanceRecord] )
		{
			aScriptHandler = [aScriptHandler copyWithComponentInstance:[self componentInstance]];
			theNeedToRelease = YES;
		}
		theResult = NDLogOSStatus( OSAExecute( [self instanceRecord], [aScriptHandler scriptID], [self scriptID], [self executionModeFlags], &theResultScriptID ));
		if( theNeedToRelease ) [aScriptHandler release];
	}
	else
		theResult = NDLogOSStatus( OSAExecute( [self instanceRecord], [self scriptID], kOSANullScript, [self executionModeFlags], &theResultScriptID ));

	[self setResultScriptDataID:theResult ? theResultScriptID : kOSANullScript];
	
	return theResult;
}

/*
 * -executeEvent:
 */
- (BOOL)executeEvent:(NSAppleEventDescriptor *)anEvent
{
	OSAID		theResultScriptID = kOSANullScript;
	BOOL		theResult = NO;

	theResult = NDLogOSStatus( OSAExecuteEvent([self instanceRecord], [anEvent aeDesc], [self scriptID], [self executionModeFlags], &theResultScriptID) );

	[self setResultScriptDataID:theResult ? theResultScriptID : kOSANullScript];

	return theResult;
}

/*
 * -executionModeFlags
 */
- (long int)executionModeFlags
{
	return executionModeFlags;
}

/*
 * -setExecutionModeFlags:mask:
 */
- (void)setExecutionModeFlags:(long int)aFlags mask:(long int)aMask
{
	executionModeFlags = (executionModeFlags & ~aMask) | (aFlags & aMask);
}

/*
 * -setExecutionModeFlags:
 */
- (void)setExecutionModeFlags:(long int)aFlags
{
	executionModeFlags = aFlags;
}

/*
 * appleEventTarget
 */
- (NSAppleEventDescriptor *)appleEventTarget
{
	unsigned int				theCurrentProcess = kCurrentProcess;

	return [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber data:[NSData dataWithBytes:&theCurrentProcess length:sizeof(theCurrentProcess)]];
}

/*
 * - arrayOfEventIdentifier
 */
- (NSArray *)arrayOfEventIdentifier
{
	AEDescList		theEventIdentifierList;
	NSArray			* theArray = nil;

	if( OSAGetHandlerNames ( [self instanceRecord], kOSAModeNull, [self scriptID], &theEventIdentifierList ) == noErr )
	{
		theArray = [[[[NSAppleEventDescriptor  alloc] initWithAEDescNoCopy:&theEventIdentifierList] autorelease] arrayValue];
	}
	return theArray;
}

/*
 * -arrayOfSubroutineNames
 */
- (NSArray *)arrayOfSubroutineNames
{
	return [[self arrayOfEventIdentifier] everyObjectOfKindOfClass:[NSString class]];
}

/*
 * - respondsToEventClass:eventID:
 */
- (BOOL)respondsToEventClass:(AEEventClass)anEventClass eventID:(AEEventID)anEventID
{
	OSAID		theResultScriptID = kOSANullScript;
	BOOL		theRespondsToSubroutine = NO;
	
	if( NDLogOSStatus(OSAGetHandler( [self instanceRecord], kOSAModeNull, [self scriptID], [[NSAppleEventDescriptor descriptorWithEventClass:anEventClass eventID:anEventID] aeDesc], &theResultScriptID ))
		 && theResultScriptID != kOSANullScript )
	{
		theRespondsToSubroutine = YES;
		NDLogOSStatus( OSADispose([self instanceRecord], theResultScriptID) );
	}
	return theRespondsToSubroutine;
}

/*
 * - respondsToSubroutineNamed:
 */
- (BOOL)respondsToSubroutineNamed:(NSString *)aName
{
	OSAID		theResultScriptID = kOSANullScript;
	BOOL		theRespondsToSubroutine = NO;

	if( NDLogOSStatus(OSAGetHandler( [self instanceRecord], kOSAModeNull, [self scriptID], [[NSAppleEventDescriptor descriptorWithString:aName] aeDesc], &theResultScriptID ))
		 && theResultScriptID != kOSANullScript )
	{
		theRespondsToSubroutine = YES;
		NDLogOSStatus( OSADispose([self instanceRecord], theResultScriptID) );
	}
	return theRespondsToSubroutine;
}

/*
 * -scriptHandlerForSubroutineNamed:
 */
- (NDScriptHandler *)scriptHandlerForSubroutineNamed:(NSString *)aName
{
	OSAID		theResultScriptID = kOSANullScript;
	return NDLogOSStatus( OSAGetHandler( [self instanceRecord], kOSAModeNull, [self scriptID], [[NSAppleEventDescriptor descriptorWithString:aName] aeDesc], &theResultScriptID ))
		? [[NDScriptData newWithScriptID:theResultScriptID componentInstance:[self componentInstance]] autorelease]
		: nil;
}

/*
 * -scriptHandlerForEventClass:eventID:
 */
- (NDScriptHandler *)scriptHandlerForEventClass:(AEEventClass)anEventClass eventID:(AEEventID)anEventID
{
	OSAID		theResultScriptID = kOSANullScript;
	return NDLogOSStatus( OSAGetHandler( [self instanceRecord], kOSAModeNull, [self scriptID], [[NSAppleEventDescriptor descriptorWithEventClass:anEventClass eventID:anEventID] aeDesc], &theResultScriptID ))
		? [[NDScriptData newWithScriptID:theResultScriptID componentInstance:[self componentInstance]] autorelease]
		: nil;
}

/*
 * -setSubroutineNamed:toScriptHandler:
 */
- (BOOL)setSubroutineNamed:(NSString *)aName toScriptHandler:(NDScriptHandler *)aScriptHandler
{
	BOOL			theResult = NO;
	if( aScriptHandler )
	{
		BOOL			theNeedToRelease = NO;
		
		// if has a different component instance then we need to make a copy with selfs component instance.
		if( [aScriptHandler instanceRecord] != [self instanceRecord] )
		{
			aScriptHandler = [aScriptHandler copyWithComponentInstance:[self componentInstance]];
			theNeedToRelease = YES;
		}
			
		theResult = NDLogOSStatus( OSASetHandler( [self instanceRecord], kOSAModeNull, [self scriptID], [[NSAppleEventDescriptor descriptorWithString:aName] aeDesc], [aScriptHandler scriptID] ));
		if( theNeedToRelease ) [aScriptHandler release];
	}
	
	return theResult;
}

/*
 * -setEventClass:eventID:toScriptHandler:
 */
- (BOOL)setEventClass:(AEEventClass)anEventClass eventID:(AEEventID)anEventID toScriptHandler:(NDScriptHandler *)aScriptHandler
{
	OSType		theString[3] = { anEventClass, anEventID, 0 };
	return [self setSubroutineNamed:[NSString stringWithCString:(char*)theString] toScriptHandler:aScriptHandler];
}

/*
 * -addSubroutineNamed:toScriptHandler:
 */
- (BOOL)addSubroutineNamed:(NSString *)aName withScriptHandler:(NDScriptHandler *)aScriptHandler
{
	BOOL			theResult = NO;
	if( aScriptHandler )
	{
		BOOL			theNeedToRelease = NO;
		
		// if has a different component instance then we need to make a copy with selfs component instance.
		if( [aScriptHandler instanceRecord] != [self instanceRecord] )
		{
			aScriptHandler = [aScriptHandler copyWithComponentInstance:[self componentInstance]];
			theNeedToRelease = YES;
		}
		
		theResult = NDLogOSStatus( OSASetHandler( [self instanceRecord], kOSAModeDontDefine, [self scriptID], [[NSAppleEventDescriptor descriptorWithString:aName] aeDesc], [aScriptHandler scriptID] ));
		if( theNeedToRelease ) [aScriptHandler release];
	}
	return theResult;
}

/*
 * -addEventClass:eventID:withScriptHandler:
 */
- (BOOL)addEventClass:(AEEventClass)anEventClass eventID:(AEEventID)anEventID withScriptHandler:(NDScriptHandler *)aScriptHandler
{
	OSType		theString[3] = { anEventClass, anEventID, 0 };
	return [self addSubroutineNamed:[NSString stringWithCString:(char*)theString] withScriptHandler:aScriptHandler];
}

/*
 * -arrayOfPropertyNames
 */
- (NSArray *)arrayOfPropertyNames
{
	AEDescList		thePropertyNamesList;
	NSArray			* theArray = nil;

	if( NDLogOSStatus( OSAGetPropertyNames ( [self instanceRecord], kOSAModeNull, [self scriptID], &thePropertyNamesList ) ) )
	{
		theArray = [[[[NSAppleEventDescriptor  alloc] initWithAEDescNoCopy:&thePropertyNamesList] autorelease] arrayValue];
	}
	return theArray;
}

/*
 * -hasPropertyName:
 */
- (BOOL)hasPropertyName:(NSString *)aName
{
	BOOL					theHasPropertyName = NO;
	OSAID					theResultID = kOSANullScript;
	if( OSAGetProperty( [self instanceRecord], kOSAModeNull, [self scriptID], [[NSAppleEventDescriptor descriptorWithString:aName] aeDesc], &theResultID )
		 && theResultID != kOSANullScript )
	{
		theHasPropertyName = YES;
		NDLogOSStatus( OSADispose([self instanceRecord], theResultID) );
	}
	return theHasPropertyName;
}

/*
 * -scriptDataForPropertyOfType:
 */
- (NDScriptData *)scriptDataForPropertyOfType:(DescType)aPropCode
{
	AEDesc		thePropDesc;
	NDScriptData	* theScriptData = nil;
	if( NDLogOSStatus( AECreateDesc( typeProperty, (void*)&aPropCode, sizeof(aPropCode), &thePropDesc) ) )
	{
		OSAID				theScriptID = kOSANullScript;
		if( NDLogOSStatus( OSAGetProperty([self instanceRecord], kOSAModeNull, [self scriptID], &thePropDesc, &theScriptID ) ) && theScriptID != kOSANullScript )
		{
			theScriptData = [NDScriptData scriptDataWithScriptID:theScriptID componentInstance:[self componentInstance]];
		}
		AEDisposeDesc( &thePropDesc );
	}
	return theScriptData;
}

/*
 * -scriptDataForPropertyNamed:
 */
- (NDScriptData *)scriptDataForPropertyNamed:(NSString *)aName
{
	OSAID					theResultID = kOSANullScript;
	return NDLogOSStatus( OSAGetProperty( [self instanceRecord], kOSAModeNull, [self scriptID], [[NSAppleEventDescriptor descriptorWithString:aName] aeDesc], &theResultID ))
		? [[NDScriptData newWithScriptID:theResultID componentInstance:[self componentInstance]] autorelease]
		: nil;
}

/*
 * -setPropertyOfType::toScriptData:
 */
- (BOOL)setPropertyOfType:(DescType)aPropCode toScriptData:(NDScriptData *)aScriptData
{
	AEDesc		thePropDesc = {0};
	BOOL			theResult = NO;
	BOOL			theNeedToRelease = NO;
	
	// if has a different component instance then we need to make a copy with selfs component instance.
	if( [aScriptData instanceRecord] != [self instanceRecord] )
	{
		aScriptData = [aScriptData copyWithComponentInstance:[self componentInstance]];
		theNeedToRelease = YES;
	}

	if( NDLogOSStatus( AECreateDesc( typeProperty, (void*)&aPropCode, sizeof(aPropCode), &thePropDesc) ) )
	{
		theResult = NDLogOSStatus( OSASetProperty([self instanceRecord], kOSAModeNull, [self scriptID], &thePropDesc, [aScriptData scriptID]) );
		AEDisposeDesc( &thePropDesc );
	}
	
	if( theNeedToRelease ) [aScriptData release];
	
	return theResult;
}

/*
 * -setPropertyNamed:toScriptData:
 */
- (BOOL)setPropertyNamed:(NSString *)aVariableName toScriptData:(NDScriptData *)aScriptData
{
	BOOL			theResult = NO;
	BOOL			theNeedToRelease = NO;
	
	// if has a different component instance then we need to make a copy with selfs component instance.
	if( [aScriptData instanceRecord] != [self instanceRecord] )
	{
		aScriptData = [aScriptData copyWithComponentInstance:[self componentInstance]];
		theNeedToRelease = YES;
	}
	
	theResult = NDLogOSStatus( OSASetProperty ( [self instanceRecord],  kOSAModeNull, [self scriptID], [[NSAppleEventDescriptor descriptorWithString:aVariableName] aeDesc], [aScriptData scriptID] ) );

	if( theNeedToRelease ) [aScriptData release];
	
	return theResult;
}

/*
 * -changePropertyNamed:toScriptData:
 */
- (BOOL)changePropertyNamed:(NSString *)aVariableName toScriptData:(NDScriptData *)aScriptData
{
	return NDLogOSStatus( OSASetProperty ( [self instanceRecord], kOSAModeDontDefine, [self scriptID], [[NSAppleEventDescriptor descriptorWithString:aVariableName] aeDesc], [aScriptData scriptID] ) );
	
}

/*
 * -copyWithComponentInstance:
 */
- (id)copyWithComponentInstance:(NDComponentInstance *)aComponentInstance
{
	id		theInstance = [super copyWithComponentInstance:aComponentInstance];
	[theInstance setExecutionModeFlags:[self executionModeFlags]];
	return theInstance;
}

/*
 * -copyWithZone:
 */
- (id)copyWithZone:(NSZone *)aZone
{
	id				theInstance = [self copyWithZone:aZone];
	[theInstance setExecutionModeFlags:[self executionModeFlags]];
	return theInstance;
}

@end

/*
 * class implementation NDScriptData (NDExtended)
 */
@implementation NDScriptData (NDExtended)

/*
 * +scriptDataWithAppleEventDescriptor:
 */
+ (id)scriptDataWithAppleEventDescriptor:(NSAppleEventDescriptor *)aDescriptor
{
	return [self scriptDataWithAppleEventDescriptor:aDescriptor componentInstance:nil];
}

/*
 * +scriptDataWithSource:
 */
+ (id)scriptDataWithSource:(NSString *)aString
{
	return [[[self alloc] initWithSource:aString] autorelease];
}

/*
 * +scriptDataWithSource:componentInstance:
 */
+ (id)scriptDataWithSource:(NSString *)aString componentInstance:(NDComponentInstance *)aComponentInstance
{
	return [[[self alloc] initWithSource:aString componentInstance:aComponentInstance] autorelease];
}

/*
 * +scriptDataWithData:
 */
+ (id)scriptDataWithData:(NSData *)aData
{
	return [[[self alloc] initWithData:aData] autorelease];
}

/*
 * +scriptDataWithData:componentInstance:
 */
+ (id)scriptDataWithData:(NSData *)aData componentInstance:(NDComponentInstance *)aComponentInstance
{
	return [[[self alloc] initWithData:aData componentInstance:aComponentInstance] autorelease];
}

/*
 * +scriptDataWithContentsOfFile:
 */
+ (id)scriptDataWithContentsOfFile:(NSString *)aPath
{
	return [self scriptDataWithContentsOfFile:(NSString *)aPath componentInstance:nil];
}

/*
 * +scriptDataWithContentsOfFile:componentInstance:
 */
+ (id)scriptDataWithContentsOfFile:(NSString *)aPath componentInstance:(NDComponentInstance *)aComponentInstance
{
	id		theInstance = nil;
	if( (theInstance = [self scriptDataWithData:[NSData dataWithContentsOfFile:aPath] componentInstance:aComponentInstance] ) == nil)
	{
		if( (theInstance = [NSData dataWithResourceForkContentsOfFile:aPath type:kOSAScriptResourceType Id:kScriptResourceID]) == nil )
			theInstance = [NSString stringWithContentsOfFile:aPath];
	}
	
	return theInstance;
}

/*
 * +scriptDataWithContentsOfURL:
 */
+ (id)scriptDataWithContentsOfURL:(NSURL *)anURL
{
	return [[[self alloc] initWithContentsOfURL:anURL] autorelease];
}

/*
 * +scriptDataWithContentsOfURL:componentInstance:
 */
+ (id)scriptDataWithContentsOfURL:(NSURL *)anURL componentInstance:(NDComponentInstance *)aComponentInstance
{
	id		theInstance = nil;
	if( (theInstance = [self scriptDataWithData:[NSData dataWithContentsOfURL:anURL] componentInstance:aComponentInstance] ) == nil)
	{
		if( (theInstance = [NSData dataWithResourceForkContentsOfURL:anURL type:kOSAScriptResourceType Id:kScriptResourceID]) == nil )
			theInstance = [NSString stringWithContentsOfURL:anURL];
	}

	return theInstance;
}

/*
 * +scriptDataWithObject:componentInstance:
 */
+ (id)scriptDataWithObject:(id)anObject componentInstance:(NDComponentInstance *)aComponentInstance
{
	return [[[self alloc] initWithObject:anObject componentInstance:aComponentInstance] autorelease];
}

/*
 * +scriptDataWithObject:
 */
+ (id)scriptDataWithObject:(id)anObject
{
	return [[[self alloc] initWithObject:anObject componentInstance:nil] autorelease];
}

/*
 * -initWithContentsOfFile:
 */
- (id)initWithContentsOfFile:(NSString *)aPath
{
	return [self initWithContentsOfFile:aPath componentInstance:nil];
}

/*
 * -initWithContentsOfURL:
 */
- (id)initWithContentsOfURL:(NSURL *)anURL
{
	return [self initWithContentsOfURL:anURL componentInstance:nil];
}

/*
 * -initWithAppleEventDescriptor:
 */
- (id)initWithAppleEventDescriptor:(NSAppleEventDescriptor *)anAppleEventDesc
{
	return [self initWithAppleEventDescriptor:anAppleEventDesc componentInstance:nil];
}

/*
 * -initWithData:
 */
- (id)initWithData:(NSData *)aData
{
	return [self initWithData:aData componentInstance:nil];
}

/*
 * -initWithObject:componentInstance:
 */
- (id)initWithObject:(id)anObject componentInstance:(NDComponentInstance *)aComponentInstance
{
	return [self initWithAppleEventDescriptor:[NSAppleEventDescriptor descriptorWithObject:anObject] componentInstance:aComponentInstance];
}

/*
 * -initDataWithObject:
 */
- (id)initDataWithObject:(id)anObject
{
	return [self initWithAppleEventDescriptor:[NSAppleEventDescriptor descriptorWithObject:anObject] componentInstance:nil];
}

/*
 * -objectValue
 */
- (id)objectValue
{
	return [[self appleEventDescriptorValue] objectValue];
}

/*
 * -writeToURL:
 */
- (BOOL)writeToURL:(NSURL *)anURL
{
	return [self writeToURL:anURL atomically:NO];
}

/*
 * -writeToFile:
 */
- (BOOL)writeToFile:(NSString *)aPath
{
	return [self writeToFile:aPath atomically:NO];
}

@end

@implementation NDScriptHandler (NDExtended)

/*
 * +scriptDataWithSource:
 */
+ (id)scriptDataWithSource:(NSString *)aString
{
	return [[[self alloc] initWithSource:aString componentInstance:nil] autorelease];
}

/*
 * +scriptDataWithSource:componentInstance:
 */
+ (id)scriptDataWithSource:(NSString *)aString componentInstance:(NDComponentInstance *)aComponentInstance
{
	return [[[self alloc] initWithSource:aString componentInstance:aComponentInstance] autorelease];
}

/*
 * -initWithSource:
 */
- (id)initWithSource:(NSString *)aSource
{
	return [self initWithSource:aSource componentInstance:nil];
}

/*
 * -initWithSource:componentInstance:
 */
- (id)initWithSource:(NSString *)aSource componentInstance:(NDComponentInstance *)aComponentInstance
{
	return [self initWithSource:aSource modeFlags:kOSAModeNull componentInstance:aComponentInstance];
}

/*
 * -resultAppleEventDescriptor
 */
- (NSAppleEventDescriptor *)resultAppleEventDescriptor
{
	return [[self resultScriptData] appleEventDescriptorValue];
}

/*
 * -resultObject
 */
- (id)resultObject
{
	return [[self resultScriptData] objectValue];
}

/*
 * -resultData
 */
- (NSData *)resultData
{
	return [[self resultAppleEventDescriptor] data];
}

/*
 * -resultAsString
 */
- (NSString *)resultAsString
{
	return [[self resultScriptData] stringValue];
}

/*
 * -objectValue
 */
- (id)objectValue
{
	return self;
}

@end

/*
 * @implementation NDScriptContext (NDExtended)
 */
@implementation NDScriptContext (NDExtended)

/*
 * +scriptData
 */
+ (id)scriptData
{
	return [[[self alloc] initWithParentScriptData:nil name:nil] autorelease];
}

/*
 * +scriptDataWithName:
 */
+ (id)scriptDataWithName:(NSString *)aName
{
	return [[[self alloc] initWithParentScriptData:nil name:aName] autorelease];
}

/*
 * +compileExecuteSource:
 */
+ (NDScriptData *)compileExecuteSource:(NSString *)aSource
{
	return [self compileExecuteSource:aSource componentInstance:nil];
}

/*
 * +scriptDataWithParentScriptData:name:
 */
+ (id)scriptDataWithParentScriptData:(NDScriptData *)aParentScriptData name:(NSString *)aName
{
	return [[[self alloc] initWithParentScriptData:aParentScriptData name:aName] autorelease];
}

/*
 * +scriptDataWithParentScriptData:
 */
+ (id)scriptDataWithParentScriptData:(NDScriptData *)aParentScriptData
{
	return [[[self alloc] initWithParentScriptData:aParentScriptData name:nil] autorelease];
}

/*
 * +scriptDataWithSource:parentScriptData:
 */
+ (id)scriptDataWithSource:(NSString *)aSource parentScriptData:(NDScriptData *)aParentData
{
	return [[[self alloc] initWithSource:aSource parentScriptData:aParentData] autorelease];
}

/*
 * -initWithParentScriptData:
 */
- (id)initWithParentScriptData:(NDScriptData *)aParentScriptData
{
	return [self initWithParentScriptData:aParentScriptData name:nil];
}

/*
 * -initWithSource:parentScriptData:
 */
- (id)initWithSource:(NSString *)aSource parentScriptData:(NDScriptData *)aParentData
{
	return [self initWithSource:aSource modeFlags:kOSAModeNull parentScriptData:aParentData];
}

/*
 * -initWithSource:modeFlags:parentScriptData:
 */
- (id)initWithSource:(NSString *)aSource modeFlags:(long)aModeFlags parentScriptData:(NDScriptData *)aParentData
{
	return [self initWithScriptID:[[self class] compileString:aSource scriptID:kOSANullScript componentInstance:[aParentData componentInstance]] parentScriptData:aParentData];
}

- (id)parentObject
{
	return [[self parentScriptData] objectValue];
}

- (BOOL)setParentObject:(id)anObject
{
	NDScriptData		* theScriptData = [NDScriptData scriptDataWithObject:anObject];
	return theScriptData ? [self setParentScriptData:theScriptData] : nil;
}

/*
 * - executeOpen:
 */
- (BOOL)executeOpen:(NSArray *)aParameters
{
	NSAppleEventDescriptor	* theEvent = nil;
	theEvent = [NSAppleEventDescriptor openEventDescriptorWithTargetDescriptor:[self appleEventTarget] array:aParameters];

	return (theEvent != nil) ? [self executeEvent:theEvent] : NO;
}

/*
 * -executeSubroutineNamed:withArgumentsArray:
 */
- (BOOL)executeSubroutineNamed:(NSString *)aName argumentsArray:(NSArray *)anArray
{
	return [self executeEvent:[NSAppleEventDescriptor descriptorWithSubroutineName:aName argumentsArray:anArray]];
}

/*
 * -executeSubroutineNamed:arguments:...
 */
- (BOOL)executeSubroutineNamed:(NSString *)aName arguments:(id)anObject, ...
{
	NSAppleEventDescriptor	* theDescriptor;
	va_list	theArgList;
	va_start( theArgList, anObject );
	theDescriptor = [NSAppleEventDescriptor listDescriptorWithObjects:anObject arguments:theArgList];
	va_end( theArgList );

	return [self executeEvent:[NSAppleEventDescriptor descriptorWithSubroutineName:aName argumentsListDescriptor:theDescriptor]];
}

/*
 * -executeSubroutineNamed:labelsAndArguments:...
 */
- (BOOL)executeSubroutineNamed:(NSString *)aName labelsAndArguments:(AEKeyword)aKeyWord, ...
{
	NSAppleEventDescriptor	* theDescriptor;
	va_list	theArgList;
	va_start( theArgList, aKeyWord );
	theDescriptor = [[[NSAppleEventDescriptor alloc] initWithSubroutineName:aName labelsAndArguments:aKeyWord arguments:theArgList] autorelease];
	va_end( theArgList );

	return [self executeEvent:theDescriptor];
}

/*
 * -descriptorForPropertyNamed:
 */
- (NSAppleEventDescriptor *)descriptorForPropertyNamed:(NSString *)aVariableName
{
	return [[self scriptDataForPropertyNamed:aVariableName] appleEventDescriptorValue];
}

/*
 * -objectForPropertyNamed:
 */
- (id)objectForPropertyNamed:(NSString *)aVariableName
{
	return [[[self scriptDataForPropertyNamed:aVariableName] appleEventDescriptorValue] objectValue];
}

/*
 * -setPropertyNamed:toDescriptor:
 */
- (BOOL)setPropertyNamed:(NSString *)aVariableName toDescriptor:(NSAppleEventDescriptor *)aDescriptor
{
	return [self setPropertyNamed:aVariableName toScriptData:[NDScriptData scriptDataWithAppleEventDescriptor:aDescriptor]];
}

/*
 * -changePropertyNamed:toDescriptor:
 */
- (BOOL)changePropertyNamed:(NSString *)aVariableName toDescriptor:(NSAppleEventDescriptor *)aDescriptor
{
	return [self changePropertyNamed:aVariableName toScriptData:[NDScriptData scriptDataWithAppleEventDescriptor:aDescriptor]];
}

/*
 * -setPropertyNamed:toObject:
 */
- (BOOL)setPropertyNamed:(NSString *)aVariableName toObject:(id)anObject
{
	return [self setPropertyNamed:aVariableName toScriptData:[NDScriptData scriptDataWithAppleEventDescriptor:[NSAppleEventDescriptor descriptorWithObject:anObject]]];
}

/*
 * -changePropertyNamed:toObject:
 */
- (BOOL)changePropertyNamed:(NSString *)aVariableName toObject:(id)anObject
{
	return [self changePropertyNamed:(NSString *)aVariableName toScriptData:[NDScriptData scriptDataWithAppleEventDescriptor:[NSAppleEventDescriptor descriptorWithObject:anObject]]];
}


/*
 * -setExecutionModeNeverInteract:
 *	flag kOSAModeNeverInteract
 */
- (void)setExecutionModeNeverInteract:(BOOL)aFlag
{
	[self setExecutionModeFlags:aFlag?kOSAModeNeverInteract:0 mask:kOSAModeNeverInteract];
}

/*
 * -executionModeNeverInteract
 *	flag kOSAModeNeverInteract
 */
- (BOOL)executionModeNeverInteract
{
	return ([self executionModeFlags] & kOSAModeNeverInteract) != 0;
}
/*
 * -setExecutionModeCanInteract:
 *	flag kOSAModeCanInteract
 */
- (void)setExecutionModeCanInteract:(BOOL)aFlag
{
	[self setExecutionModeFlags:aFlag?kOSAModeCanInteract:0 mask:kOSAModeCanInteract];
}

/*
 * -executionModeCanInteract
 *	flag kOSAModeCanInteract
 */
- (BOOL)executionModeCanInteract
{
	return ([self executionModeFlags] & kOSAModeCanInteract) != 0;
}
/*
 * -setExecutionModeAlwaysInteract:
 *	flag kOSAModeAlwaysInteract
 */
- (void)setExecutionModeAlwaysInteract:(BOOL)aFlag
{
	[self setExecutionModeFlags:aFlag?kOSAModeAlwaysInteract:0 mask:kOSAModeAlwaysInteract];
}

/*
 * -executionModeAlwaysInteract
 *	flag kOSAModeAlwaysInteract
 */
- (BOOL)executionModeAlwaysInteract
{
	return ([self executionModeFlags] & kOSAModeAlwaysInteract) != 0;
}

/*
 * -setExecutionModeCanSwitchLayer:
 *	flag kOSAModeCantSwitchLayer
 */
- (void)setExecutionModeCanSwitchLayer:(BOOL)aFlag
{
	[self setExecutionModeFlags:aFlag?0:kOSAModeCantSwitchLayer mask:kOSAModeCantSwitchLayer];
}

/*
 * -executionModeCanSwitchLayer
 *	flag kOSAModeCantSwitchLayer
 */
- (BOOL)executionModeCanSwitchLayer
{
	return ([self executionModeFlags] & kOSAModeCantSwitchLayer) == 0;
}
/*
 * -setExecutionModeReconnect:
 *	flag kOSAModeDontReconnect
 */
- (void)setExecutionModeReconnect:(BOOL)aFlag
{
	[self setExecutionModeFlags:aFlag?0:kOSAModeDontReconnect mask:kOSAModeDontReconnect];
}

/*
 * -executionModeReconnect
 *	flag kOSAModeDontReconnect
 */
- (BOOL)executionModeReconnect
{
	return ([self executionModeFlags] & kOSAModeDontReconnect) == 0;
}
/*
 * -setExecutionRecord:
 *	flag kOSAModeDoRecord
 */
- (void)setExecutionModeRecord:(BOOL)aFlag
{
	[self setExecutionModeFlags:aFlag?kOSAModeDoRecord:0 mask:kOSAModeDoRecord];
}

/*
 * -executionModeRecord
 *	flag kOSAModeDoRecord
 */
- (BOOL)executionModeRecord
{
	return ([self executionModeFlags] & kOSAModeDoRecord) != 0;
}

@end

/*
 * category implementation NSAppleEventDescriptor (NDScriptDataValueExtension)
 */
@implementation NSAppleEventDescriptor (NDScriptDataValueExtension)

/*
 * -scriptDataValue
 */
- (NDScriptData *)scriptDataValue
{
	return [NDScriptData scriptDataWithAppleEventDescriptor:self];
}

/*
 * +descriptorWithScriptData:
 */
+ (NSAppleEventDescriptor *)descriptorWithScriptData:(NDScriptData *)aScriptData
{
	return [aScriptData appleEventDescriptorValue];
}

@end


/*
 * class implementation NDScriptData (Private)
 */
@implementation NDScriptData (Private)

/*
 * +classForScriptID:componentInstance:
 */
+ (Class)classForScriptID:(OSAID)aScriptID componentInstance:(NDComponentInstance *)aComponentInstance
{
	return isTypeScriptContext(aScriptID, [aComponentInstance instanceRecord] )
		? [NDScriptContext class]
		: isTypeCompiledScript( aScriptID, [aComponentInstance instanceRecord] )
			? [NDScriptHandler class]
			: [NDScriptData class];
}

/*
 * +newWithScriptID:componentInstance:
 */
+ (id)newWithScriptID:(OSAID)aScriptID componentInstance:(NDComponentInstance *)aComponentInstance
{
	return ( aScriptID != kOSANullScript )
		? [[[self classForScriptID:aScriptID componentInstance:aComponentInstance] alloc] initWithScriptID:aScriptID componentInstance:aComponentInstance]
		: nil ;
}

/*
 * +scriptDataWithScriptID:componentInstance:
 */
+ (id)scriptDataWithScriptID:(OSAID)aScriptID componentInstance:(NDComponentInstance *)aComponentInstance
{
	return [[self newWithScriptID:aScriptID componentInstance:aComponentInstance] autorelease];
}

/*
 * -initWithScriptID:componentInstance:
 */
- (id)initWithScriptID:(OSAID)aScriptID componentInstance:(NDComponentInstance *)aComponentInstance
{
	if(NDLogFalse([[NDScriptData classForScriptID:aScriptID componentInstance:aComponentInstance] isSubclassOfClass:[self class]])
		 && NDLogFalse(self = [self initWithComponentInstance:aComponentInstance]))
	{
		scriptID = aScriptID;
	}
	else
	{
		[self release];
		self = nil;
	}
	
	return self;
}

/*
 * -scriptID
 */
- (OSAID)scriptID
{
	return scriptID;
}

/*
 * -instanceRecord
 */
- (ComponentInstance)instanceRecord
{
	return componentInstance ? [componentInstance instanceRecord] : (ComponentInstance)0;
}

/*
 * -isCompiled
 *		Overridden by NDAppleScriptObject since it can be not compilied
 */
- (BOOL)isCompiled
{
	return YES;
}

@end

@implementation NDScriptHandler (Private)

/*
 * -setResultScriptDataID:
 */
- (void)setResultScriptDataID:(OSAID)aScriptDataID
{
	/*
	 * if resultScriptID is wrapped in a NDScriptData then we need to release the object and it will dispose of the resultScriptID,
	 * otherwise we have to dispose of the resultScriptID ourselves
	 */
	if( resultScriptData != nil )
	{
		[resultScriptData release];
		resultScriptData = nil;
	}
	else if( resultScriptID != kOSANullScript )
	{
		NDLogOSStatus( OSADispose( [self instanceRecord], resultScriptID ));
	}
	
	resultScriptID = aScriptDataID;
}

/*
 * + compileString:
 */
+ (OSAID)compileString:(NSString *)aString scriptID:(OSAID)aScriptID componentInstance:(NDComponentInstance *)aComponentInstance
{
	return [self compileString:aString modeFlags:kOSAModeCanInteract scriptID:aScriptID componentInstance:aComponentInstance];
}

/*
 * - compileString:
 */
+ (OSAID)compileString:(NSString *)aString modeFlags:(long)aModeFlags scriptID:(OSAID)aScriptID componentInstance:(NDComponentInstance *)aComponentInstance
{
	return compileString( aString, aModeFlags & ~(kOSAModeAugmentContext|kOSAModeCompileIntoContext), aScriptID, aComponentInstance );
}

@end

/*
 * class implementation NDScriptContext (Private)
 */
@implementation NDScriptContext (Private)

/*
 * -initWithScriptID:parentScriptData:
 */
- (id)initWithScriptID:(OSAID)aScriptDataID parentScriptData:(NDScriptData *)aParentScriptData
{
	if( (self = [self initWithScriptID:aScriptDataID componentInstance:[aParentScriptData componentInstance]]) != nil )
	{
		if( aParentScriptData )
			[self setParentScriptData:aParentScriptData];
	}
	return self;
}

/*
 * +compileString:modeFlags:scriptID:
 */
+ (OSAID)compileString:(NSString *)aString modeFlags:(long)aModeFlags scriptID:(OSAID)aScriptID componentInstance:(NDComponentInstance *)aComponentInstance
{
	return compileString( aString, aModeFlags | kOSAModeCompileIntoContext, aScriptID, aComponentInstance );
}

@end


/*
 * kOSAScriptIsModified
 */
static unsigned long int numberOfTimesModified( OSAID aScriptID, ComponentInstance aComponentInstance )
{
	long int		theResult;
	return NDLogOSStatus( OSAGetScriptInfo( aComponentInstance, aScriptID, kOSAScriptIsModified, &theResult)) ? theResult : 0;
}

/*
 * kOSAScriptIsTypeCompiledScript
 */
static BOOL isTypeCompiledScript( OSAID aScriptID, ComponentInstance aComponentInstance )
{
	long int		theResult;
	return NDLogOSStatus( OSAGetScriptInfo( aComponentInstance, aScriptID, kOSAScriptIsTypeCompiledScript, &theResult)) && theResult != 0;
}

/*
 * kOSAScriptIsTypeScriptValue
 */
static BOOL isTypeScriptValue( OSAID aScriptID, ComponentInstance aComponentInstance )
{
	long int		theResult;
	return NDLogOSStatus( OSAGetScriptInfo( aComponentInstance, aScriptID, kOSAScriptIsTypeScriptValue, &theResult)) && theResult != 0;
}

/*
 * kOSAScriptIsTypeScriptContext
 */
static BOOL isTypeScriptContext( OSAID aScriptID, ComponentInstance aComponentInstance )
{
	long int		theResult;
	return NDLogOSStatus( OSAGetScriptInfo( aComponentInstance, aScriptID, kOSAScriptIsTypeScriptContext, &theResult)) && theResult != 0;
}

/*
 * kOSAScriptBestType
 */
static DescType bestType( OSAID aScriptID, ComponentInstance aComponentInstance )
{
	long int		theResult;
	return NDLogOSStatus( OSAGetScriptInfo( aComponentInstance, aScriptID, kOSAScriptBestType, &theResult))
		? theResult
			: typeWildCard;
}

/*
 * kOSACanGetSource
 */
static BOOL canGetSource( OSAID aScriptID, ComponentInstance aComponentInstance )
{
	long int		theResult;
	return NDLogOSStatus( OSAGetScriptInfo( aComponentInstance, aScriptID, kOSACanGetSource, &theResult)) && theResult != 0;
}

/*
 * kASHasOpenHandler
 */
static BOOL hasOpenHandler( OSAID aScriptID, ComponentInstance aComponentInstance )
{
	long int		theResult;
	return NDLogOSStatus( OSAGetScriptInfo( aComponentInstance, aScriptID, kASHasOpenHandler, &theResult)) && theResult != 0;
}

/*
 *	compileString()
 */
static OSAID compileString(NSString * aString, long int aModeFlags, OSAID aScriptID, NDComponentInstance * aComp )
{
	NSAppleEventDescriptor		* theStringDesc;

	if( (theStringDesc = [NSAppleEventDescriptor descriptorWithString:aString]) != nil )
	{
		NDLogOSStatus( OSACompile([aComp instanceRecord], [theStringDesc aeDesc], aModeFlags, &aScriptID) );
	}

	return aScriptID;
}

/*
 *	loadScriptData()
 */
static OSAID loadScriptData( NSData * aData, long int aModeFlags, OSAID aScriptID, NDComponentInstance * aComp )
{
	NSAppleEventDescriptor		* theDataDesc;

	if( (theDataDesc = [NSAppleEventDescriptor descriptorWithDescriptorType:typeOSAGenericStorage data:aData]) != nil )
	{
		NDLogOSStatus( OSALoad([aComp instanceRecord], [theDataDesc aeDesc], kOSAModeCompileIntoContext, &aScriptID) );
	}

	return aScriptID;
}

