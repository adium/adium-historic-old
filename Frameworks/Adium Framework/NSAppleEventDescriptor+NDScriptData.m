/*
 *  NSAppleEventDescriptor+NDScriptData.m
 *  AppleScriptObjectProject
 *
 *  Created by Nathan Day on Fri Dec 14 2001.
 *  Copyright (c) 2001 Nathan Day. All rights reserved.
 */

#import "NSAppleEventDescriptor+NDScriptData.h"
#import "NSURL+NDCarbonUtilities.h"
#import "NSValue+NDFourCharCode.h"
#import "NDProgrammerUtilities.h"

NSString		* NDAppleEventDescriptorCoercionError = @"AppleEventDescriptorCoercionError",
				* NDAppleEventDescriptorCoercionObject = @"object";

static BOOL aeDescForObjectSpecifier( AEDesc * aDesc, NSScriptObjectSpecifier * specifier );
static NSScriptObjectSpecifier * objectSpecifierForAppleEventDescriptor( NSAppleEventDescriptor * descriptor );

@class		NDFourCharCodeValue;

/*
 * class implementation NSAppleEventDescriptor (NDScriptData)
 */
@implementation NSAppleEventDescriptor (NDScriptData)

/*
 * +descriptorWithAEDescNoCopy:
 */
+ (id)descriptorWithAEDescNoCopy:(const AEDesc *)aDesc
{
	return [[[self alloc] initWithAEDescNoCopy:aDesc] autorelease];
}

/*
 * +descriptorWithAEDesc:
 */
+ (id)descriptorWithAEDesc:(const AEDesc *)anAEDesc
{
	return [[[self alloc] initWithAEDesc:anAEDesc] autorelease];
}

/*
 * -initWithAEDesc:
 */
- (id)initWithAEDesc:(const AEDesc *)anAEDesc
{
	AEDesc	theAEDesc;
	return AEDuplicateDesc( anAEDesc, &theAEDesc ) == noErr ? [self initWithAEDescNoCopy:&theAEDesc] : nil;
}

/*
 * isTargetCurrentProcess
 */
- (BOOL)isTargetCurrentProcess
{
	ProcessSerialNumber		theProcessSerialNumber;

	theProcessSerialNumber = [self targetProcessSerialNumber];

	return theProcessSerialNumber.highLongOfPSN == 0 && theProcessSerialNumber.lowLongOfPSN == kCurrentProcess;
}

/*
 * -getAEDesc:
 */
- (BOOL)getAEDesc:(AEDesc *)aDescPtr
{
	NSData		* theData;

	theData = [self data];
	return AECreateDesc( [self descriptorType], [theData bytes], [theData length], aDescPtr ) == noErr;
}

@end

@implementation NSAppleEventDescriptor (NDConversion)

/*
 * targetProcessSerialNumber
 */
- (ProcessSerialNumber)targetProcessSerialNumber
{
	NSAppleEventDescriptor	* theTarget;
	ProcessSerialNumber		theProcessSerialNumber = { 0, 0 };

	theTarget = [self attributeDescriptorForKeyword:keyAddressAttr];

	if( theTarget )
	{
		if( [theTarget descriptorType] != typeProcessSerialNumber )
			theTarget = [theTarget coerceToDescriptorType:typeProcessSerialNumber];

		[[theTarget data] getBytes:&theProcessSerialNumber length:sizeof(ProcessSerialNumber)];
	}
	return theProcessSerialNumber;
}

/*
 * targetCreator
 */
- (OSType)targetCreator
{
	NSAppleEventDescriptor	* theTarget;
	OSType						theCreator = 0;

	theTarget = [self attributeDescriptorForKeyword:keyAddressAttr];

	if( theTarget )
	{
		if( [theTarget descriptorType] != typeApplSignature )
			theTarget = [theTarget coerceToDescriptorType:typeApplSignature];

		[[theTarget data] getBytes:&theCreator length:sizeof(OSType)];
	}
	return theCreator;
}

/*
 * currentProcessDescriptor
 */
+ (NSAppleEventDescriptor *)currentProcessDescriptor
{
	ProcessSerialNumber	theCurrentProcess = { 0, kCurrentProcess };
	return [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber bytes:(void*)&theCurrentProcess length:sizeof(theCurrentProcess)];
}

/*
 * + aliasListDescriptorWithArray:
 */
+ (NSAppleEventDescriptor *)aliasListDescriptorWithArray:(NSArray *)anArray
{
	NSAppleEventDescriptor	* theEventList = nil;
	unsigned int				theIndex,
									theNumOfParam;

	theNumOfParam = [anArray count];

	if( theNumOfParam > 0)
	{
		theEventList = [self listDescriptor];
	
		for( theIndex = 0; theIndex < theNumOfParam; theIndex++ )
		{
			NSAppleEventDescriptor	* theAliasDesc;
			theAliasDesc = [self aliasDescriptorWithFile:[anArray objectAtIndex:theIndex]];
			
			NSAssert1( theAliasDesc != nil, @"Could not get an alias NSAppleEventDescriptor for %@", [anArray objectAtIndex:theIndex] );

			[theEventList insertDescriptor:theAliasDesc atIndex:theIndex+1];
		}
	}

	return theEventList;
}

/*
 * + descriptorWithURL:
 */
+ (id)descriptorWithURL:(NSURL *)aURL
{
	return [self descriptorWithDescriptorType:typeFileURL data:[NSData dataWithBytes:(void *)aURL length:sizeof(NSURL)]];
}

/*
 * + aliasDescriptorWithURL:
 */
+ (NSAppleEventDescriptor *)aliasDescriptorWithURL:(NSURL *)aURL
{
	return [self aliasDescriptorWithFile:aURL];
}

+ (NSAppleEventDescriptor *)aliasDescriptorWithString:(NSString *)aPath
{
	return [self aliasDescriptorWithFile:aPath];
}

+ (NSAppleEventDescriptor *)aliasDescriptorWithFile:(id)aFile
{
	AliasHandle						theAliasHandle;
	FSRef								theReference;
	NSAppleEventDescriptor		* theAppleEventDescriptor = nil;

	if( [aFile getFSRef:&theReference] == YES && FSNewAliasMinimal( &theReference, &theAliasHandle ) == noErr )
	{
		HLock((Handle)theAliasHandle);
		theAppleEventDescriptor = [self descriptorWithDescriptorType:typeAlias data:[NSData dataWithBytes:*theAliasHandle length:GetHandleSize((Handle) theAliasHandle)]];
		HUnlock((Handle)theAliasHandle);
		DisposeHandle((Handle)theAliasHandle);
	}

	return theAppleEventDescriptor;
}

// typeTrue
/*
 * +descriptorWithTrueBoolean
 */
+ (id)descriptorWithTrueBoolean
{						// doesn't need any data
	return [self descriptorWithDescriptorType:typeTrue data:[NSData data]];
}
// typeFalse
/*
 * +descriptorWithFalseBoolean
 */
+ (id)descriptorWithFalseBoolean
{						// doesn't need any data
	return [self descriptorWithDescriptorType:typeFalse data:[NSData data]];
}
// typeShortInteger
/*
 * +descriptorWithShort:
 */
+ (id)descriptorWithShort:(short int)aValue
{
	return [self descriptorWithDescriptorType:typeShortInteger data:[NSData dataWithBytes:&aValue length: sizeof(aValue)]];
}
// typeLongInteger
/*
 * +descriptorWithLong:
 */
+ (id)descriptorWithLong:(long int)aValue
{
	return [self descriptorWithDescriptorType:typeLongInteger data:[NSData dataWithBytes:&aValue length: sizeof(aValue)]];
}
// typeInteger
/*
 * +descriptorWithInt:
 */
+ (id)descriptorWithInt:(int)aValue
{
	return [self descriptorWithDescriptorType:typeInteger data:[NSData dataWithBytes:&aValue length: sizeof(aValue)]];
}
// typeShortFloat
/*
 * +descriptorWithFloat:
 */
+ (id)descriptorWithFloat:(float)aValue
{
	return [self descriptorWithDescriptorType:typeShortFloat data:[NSData dataWithBytes:&aValue length: sizeof(aValue)]];
}
// typeLongFloat
/*
 * +descriptorWithDouble:
 */
+ (id)descriptorWithDouble:(double)aValue
{
	return [self descriptorWithDescriptorType:typeLongFloat data:[NSData dataWithBytes:&aValue length: sizeof(aValue)]];
}
// typeMagnitude
/*
 * +descriptorWithUnsignedInt:
 */
+ (id)descriptorWithUnsignedInt:(unsigned int)aValue
{
	return [self descriptorWithDescriptorType:typeMagnitude data:[NSData dataWithBytes:&aValue length: sizeof(aValue)]];
}

/*
 * +descriptorWithCString:
 */
+ (id)descriptorWithCString:(const char *)aString
{
	return [self descriptorWithDescriptorType:typeText bytes:aString length:strlen(aString)];
}

/*
 * +descriptorWithUnsignedInt:
 */
+ (id)descriptorWithNumber:(NSNumber *)aNumber
{
	const char					* theType = [aNumber objCType];
	NSAppleEventDescriptor	* theDescriptor = nil;
	unsigned int				theIndex;
	struct
	{
		char				* objCType;
		DescType			descType;
		unsigned short	size;
	}		theTypes[] = {
		{ @encode(float), typeIEEE32BitFloatingPoint, sizeof(float) },
		{ @encode(double), typeIEEE64BitFloatingPoint, sizeof(double) },
		{ @encode(long double), type128BitFloatingPoint, sizeof(long double) },
		{ @encode(unsigned char), typeUInt32, sizeof(unsigned char) },
		{ @encode(char), typeSInt16, sizeof(char) },
		{ @encode(unsigned short int), typeUInt32, sizeof(unsigned short int) },
		{ @encode(short int), typeSInt16, sizeof(short int) },
		{ @encode(unsigned int), typeUInt32, sizeof(unsigned int) },
		{ @encode(int), typeSInt32, sizeof(int) },
		{ @encode(unsigned long int), typeUInt32, sizeof(unsigned long int) },
		{ @encode(long int), typeSInt32, sizeof(long int) },
		{ @encode(unsigned long long), typeSInt64, sizeof(unsigned long long) },			// no unsigned 64
		{ @encode(long long), typeSInt64, sizeof(long long) },
		{ @encode(FourCharCode), typeType, sizeof(FourCharCode) },
		{ @encode(BOOL), typeBoolean, sizeof(BOOL) },			// most likely picked up by char
		{ NULL, 0, 0 }
	};

	for( theIndex = 0; theDescriptor == nil && theTypes[theIndex].objCType != NULL; theIndex++ )
	{
		if( strcmp( theTypes[theIndex].objCType, theType ) == 0 )
		{
			char		* theBuffer[64];
			[aNumber getValue:theBuffer];
			theDescriptor = [self descriptorWithDescriptorType:theTypes[theIndex].descType bytes:theBuffer length:theTypes[theIndex].size];
		}
	}

	return theDescriptor;
}

+ (id)descriptorWithValue:(NSValue *)aValue
{
	NSAppleEventDescriptor		* theDescriptor = nil;
	const char						* theObjCType = [aValue objCType];

	if( strcmp( theObjCType, @encode( FourCharCode ) ) == 0 )
	{
		theDescriptor = [NSAppleEventDescriptor descriptorWithTypeCode:[aValue fourCharCode]];
	}
	else if( strcmp( theObjCType, @encode( NSPoint ) ) )
	{
		NSPoint		thePoint = [aValue pointValue];
		theDescriptor = [NSAppleEventDescriptor listDescriptorWithObjects:[NSNumber numberWithFloat:thePoint.x], [NSNumber numberWithFloat:thePoint.y], nil];
	}
	else if( strcmp( theObjCType, @encode( NSSize ) ) )
	{
		NSSize		theSize = [aValue sizeValue];
		theDescriptor = [NSAppleEventDescriptor listDescriptorWithObjects:[NSNumber numberWithFloat:theSize.width], [NSNumber numberWithFloat:theSize.height], nil];
	}
	else if( strcmp( theObjCType, @encode( NSRect ) ) )
	{
		NSRect		theRect = [aValue rectValue];
		theDescriptor = [NSAppleEventDescriptor listDescriptorWithObjects:[NSNumber numberWithFloat:theRect.origin.x], [NSNumber numberWithFloat:theRect.origin.y], [NSNumber numberWithFloat:theRect.size.width], [NSNumber numberWithFloat:theRect.size.height], nil];
	}
	else if( strcmp( theObjCType, @encode( NSRange ) ) )
	{
		NSRange		theRange = [aValue rangeValue];
		theDescriptor = [NSAppleEventDescriptor listDescriptorWithObjects:[NSNumber numberWithUnsignedInt:theRange.location], [NSNumber numberWithUnsignedInt:theRange.location + theRange.length], nil];
	}
#if 0
	else if( strcmp( theObjCType, @encode( NSRange ) ) == 0 )
	{
		AEDesc		theDesc,
						theValues[2];
		NSRange		theRange;
		
		[aValue getValue:(void*)&theRange];
		theRange.length += theRange.location;
		
		if( AECreateDesc( keyAERangeStart, (void*)&theRange.location, sizeof(unsigned int), &theValues[0] ) == noErr )
		{
			if( AECreateDesc( keyAERangeStop, (void*)&theRange.length, sizeof(unsigned int), &theValues[1] ) == noErr )
			{
				
				if( AECreateDesc( typeRangeDescriptor, (void*)&theRange, sizeof(NSRange), &theDesc ) == noErr )
				{
					theDescriptor = [NSAppleEventDescriptor descriptorWithAEDescNoCopy:&theDesc];
				}
				else
					AEDisposeDesc( &theDesc );
				
				AEDisposeDesc( &theValues[1] );
			}
			AEDisposeDesc( &theValues[0] );
		}
	}
#endif
	return theDescriptor;
}

/*
 * +descriptorWithObject:
 */
+ (id)descriptorWithObject:(id)anObject
{
	NSAppleEventDescriptor		* theDescriptor = nil;

	if( anObject == nil || [anObject isKindOfClass:[NSNull class]] )
	{
		theDescriptor = [NSAppleEventDescriptor nullDescriptor];
	}
	else if( [anObject isKindOfClass:[NSNumber class]] )
	{
		theDescriptor = [self descriptorWithNumber:anObject];
	}
	else if( [anObject isKindOfClass:[NSValue class]] )
	{
		theDescriptor = [self descriptorWithValue:anObject];
	}
	else if( [anObject isKindOfClass:[NSString class]] )
	{
		theDescriptor = [self descriptorWithString:anObject];
	}
	else if( [anObject isKindOfClass:[NSData class]] )
	{
		theDescriptor = [self descriptorWithData:anObject];
	}
	else if( [anObject isKindOfClass:[NSArray class]] )
	{
		theDescriptor = [self descriptorWithArray:anObject];
	}
	else if( [anObject isKindOfClass:[NSDictionary class]] )
	{
		theDescriptor = [self descriptorWithDictionary:anObject];
	}
	else if( [anObject isKindOfClass:[NSURL class]] )
	{
		theDescriptor = [self aliasDescriptorWithURL:anObject];
	}
	else if( [anObject isKindOfClass:[NSAppleEventDescriptor class]] )
	{
		theDescriptor = anObject;
	}
	else if( [anObject isKindOfClass:[NSScriptObjectSpecifier class]] )
	{
		theDescriptor = [self descriptorWithScriptObjectSpecifier:anObject];
	}
	else if( [anObject isKindOfClass:NSClassFromString(@"NDScriptData")] )
	{
		theDescriptor = [self performSelector:NSSelectorFromString(@"descriptorWithScriptData:") withObject:anObject];
	}
	else if( [anObject respondsToSelector:@selector(objectSpecifier)] )
	{
		theDescriptor = [self descriptorWithScriptObjectSpecifier:[anObject objectSpecifier]];
	}
	else
	{
		[[NSException exceptionWithName:NDAppleEventDescriptorCoercionError reason:[NSString stringWithFormat:@"Objects of class %@ cant be coerced into NSAppleEventDescriptors", [anObject class]] userInfo:[NSDictionary dictionaryWithObjectsAndKeys:anObject, NDAppleEventDescriptorCoercionObject, nil]] raise];
	}
	
	NSAssert1( theDescriptor != nil, @"Error occured whilst trying to coerce '%@' into an NSAppleEventDescriptor", anObject );

	return theDescriptor;
}

+ (id)descriptorWithData:(NSData *)aData
{
	return [self descriptorWithDescriptorType:typeOSAGenericStorage data:aData];
}

/*
 * +descriptorWithArray:
 */
+ (id)descriptorWithArray:(NSArray *)anArray
{
	NSAppleEventDescriptor	* theEventList = nil;
	unsigned int				theIndex,
									theNumOfParam;

	theNumOfParam = [anArray count];

	if( theNumOfParam > 0)
	{
		theEventList = [self listDescriptor];

		for( theIndex = 0; theIndex < theNumOfParam; theIndex++ )
			[theEventList insertDescriptor:[self descriptorWithObject:[anArray objectAtIndex:theIndex]] atIndex:theIndex+1];
	}

	return theEventList;
}

+ (id)descriptorWithEventClass:(AEEventClass)anEventClass eventID:(AEEventID)anEventID
{
	unsigned int		theValues[] = {anEventClass,anEventID};
	return [self descriptorWithDescriptorType:cEventIdentifier bytes:theValues length:sizeof(theValues)];
}
/*
 * +listDescriptorWithObjects:...
 */
+ (id)listDescriptorWithObjects:(id)anObject, ...
{
	NSAppleEventDescriptor	* theDescriptor = nil;
	va_list	theArgList;
	va_start( theArgList, anObject );
	theDescriptor = [self listDescriptorWithObjects:anObject arguments:theArgList];
	va_end( theArgList );

	return theDescriptor;
}

/*
 * +listDescriptorWithObjects:arguments:
 */
+ (id)listDescriptorWithObjects:(id)anObject arguments:(va_list)anArgList
{
	unsigned int					theIndex;
	NSAppleEventDescriptor		* theEventList = [self listDescriptor];

	for( theIndex = 1; anObject != nil; anObject = va_arg( anArgList, id ) )
	{
		[theEventList insertDescriptor:[self descriptorWithObject:anObject] atIndex:theIndex++];
	}

	return theEventList;
}

/*
 * +recordDescriptorWithObjects:keywords:count:
 */
+ (NSAppleEventDescriptor *)recordDescriptorWithObjects:(id *)anObjects keywords:(AEKeyword *)aKeywords count:(unsigned int)aCount
{
	NSAppleEventDescriptor	* theDescriptor = nil;
	if( (theDescriptor = [self recordDescriptor]) != nil )
	{
		unsigned int		theIndex;
		for( theIndex = 0; theIndex < aCount; theIndex++ )
		{
			[theDescriptor setDescriptor:[NSAppleEventDescriptor descriptorWithObject:anObjects[theIndex]] forKeyword:aKeywords[theIndex]];
		}
	}
	return theDescriptor;
}

/*
 * +descriptorWithDictionary:
 */
+ (id)descriptorWithDictionary:(NSDictionary *)aDictionary
{
	NSAppleEventDescriptor		* theRecordDescriptor = [self recordDescriptor],
										* theUserRecordDesc = nil;
	NSArray							* theKeyArray = [aDictionary allKeys];
	unsigned int					theIndex = 0,
										theUserRecordCount = 1,
										theCount = [theKeyArray count];
	Class								theValueClass = [NSValue class];
	for( theIndex = 0; theIndex < theCount; theIndex++ )
	{
		id		theKey = [theKeyArray objectAtIndex:theIndex];
		if( [theKey isKindOfClass:theValueClass] )
		{
			[theRecordDescriptor setDescriptor:[NSAppleEventDescriptor descriptorWithObject:[aDictionary objectForKey:theKey]] forKeyword:[theKey fourCharCode]];
		}
		else		// non unsigned long keys need to be added with there value into an array with the key keyASUserRecordFields
		{
			if( theUserRecordDesc == nil )
			{
				theUserRecordDesc = [self listDescriptor];
			}
			[theUserRecordDesc insertDescriptor:[NSAppleEventDescriptor descriptorWithString:[theKey description]] atIndex:theUserRecordCount++];
			[theUserRecordDesc insertDescriptor:[NSAppleEventDescriptor descriptorWithObject:[aDictionary objectForKey:theKey]] atIndex:theUserRecordCount++];		
		}
	}
	
	if( theUserRecordDesc != nil )
		[theRecordDescriptor setDescriptor:theUserRecordDesc forKeyword:keyASUserRecordFields];
	
	return theRecordDescriptor;
}

/*
 * +descriptorWithScriptObjectSpecifier:
 */
+ (id)descriptorWithScriptObjectSpecifier:(NSScriptObjectSpecifier *)anObjectSpecifier
{
	NSAppleEventDescriptor		* theDescriptor = nil;
	AEDesc							theDesc = {0};
	if( aeDescForObjectSpecifier( &theDesc, anObjectSpecifier ) )
	{
		theDescriptor = [NSAppleEventDescriptor descriptorWithAEDescNoCopy:&theDesc];
		
		if( theDescriptor == nil )
			AEDisposeDesc( &theDesc );
	}
	return theDescriptor;
}

/*
 * +descriptorWithObjectsAndKeys:...
 */
+ (id)descriptorWithObjectAndKeys:(id)anObject, ...
{
	NSAppleEventDescriptor	* theDescriptor = nil,
									* theRecordDescriptor = nil;
	va_list	theArgList;
	va_start( theArgList, anObject );
	theDescriptor = [self userRecordDescriptorWithObjectAndKeys:anObject arguments:theArgList];
	va_end( theArgList );

	theRecordDescriptor = theDescriptor ? [self recordDescriptor] : nil;
	[theRecordDescriptor setDescriptor:theDescriptor forKeyword:keyASUserRecordFields];
	return theRecordDescriptor;
}

+ (id)descriptorWithObjectAndKeys:(id)anObject arguments:(va_list)anArgList
{
	NSAppleEventDescriptor		* theRecordDescriptor = [self recordDescriptor];
	[theRecordDescriptor setDescriptor:[NSAppleEventDescriptor userRecordDescriptorWithObjectAndKeys:anObject arguments:anArgList] forKeyword:keyASUserRecordFields];
	return theRecordDescriptor;
}

/*
 * +userRecordDescriptorWithObjectAndKeys:...
 */
+ (id)userRecordDescriptorWithObjectAndKeys:(id)anObject, ...
{
	NSAppleEventDescriptor	* theDescriptor = nil;
	va_list	theArgList;
	va_start( theArgList, anObject );
	theDescriptor = [self userRecordDescriptorWithObjectAndKeys:anObject arguments:theArgList];
	va_end( theArgList );

	return theDescriptor;
}

/*
 * +userRecordDescriptorWithObjectAndKeys:arguments:
 */
+ (NSAppleEventDescriptor *)userRecordDescriptorWithObjectAndKeys:(id)anObject arguments:(va_list)anArgList
{
	NSAppleEventDescriptor		* theUserRecord = [self listDescriptor];
	if( theUserRecord )
	{
		unsigned int		theIndex = 1;
		for( ; anObject != nil; anObject = va_arg( anArgList, id ) )
		{
			NSString		* theKey = va_arg( anArgList, id );
			NSParameterAssert( theKey != nil );
			[theUserRecord insertDescriptor:[NSAppleEventDescriptor descriptorWithString:[theKey description]] atIndex:theIndex++];
			[theUserRecord insertDescriptor:[NSAppleEventDescriptor descriptorWithObject:anObject] atIndex:theIndex++];
		}
	}

	return theUserRecord;
}

/*
 * +userRecordDescriptorWithObjects:keys:count:
 */
+ (NSAppleEventDescriptor *)userRecordDescriptorWithObjects:(id *)anObject keys:(NSString **)aKeys count:(unsigned int)aCount
{
	NSAppleEventDescriptor		* theUserRecord = [self listDescriptor];
	if( theUserRecord )
	{
		unsigned int		theIndex;
		for( theIndex = 0; theIndex < aCount; theIndex++ )
		{
			NSParameterAssert( aKeys[theIndex] != nil );
			[theUserRecord insertDescriptor:[NSAppleEventDescriptor descriptorWithString:aKeys[theIndex]] atIndex:theIndex+1];
			[theUserRecord insertDescriptor:[NSAppleEventDescriptor descriptorWithObject:anObject[theIndex]] atIndex:theIndex+2];
		}
	}

	return theUserRecord;
}

/*
 * +userRecordDescriptorWithDictionary:
 */
+ (NSAppleEventDescriptor *)userRecordDescriptorWithDictionary:(NSDictionary *)aDictionary
{
	NSAppleEventDescriptor	* theUserRecord;

	if( [aDictionary count] > 0 && (theUserRecord = [self listDescriptor]) != nil )
	{
		NSEnumerator	* theEnumerator = [aDictionary keyEnumerator];
		id					theKey;
		unsigned int	theIndex = 1;

		while ((theKey = [theEnumerator nextObject]) != nil )
		{
			[theUserRecord insertDescriptor:[NSAppleEventDescriptor descriptorWithString:[theKey description]] atIndex:theIndex++];
			[theUserRecord insertDescriptor:[NSAppleEventDescriptor descriptorWithObject:[aDictionary objectForKey:theKey]] atIndex:theIndex++];		
		}
	}

	return theUserRecord;
}

/*
 * - arrayValue:
 */
- (NSArray *)arrayValue
{
	SInt32						theNumOfItems,
									theIndex;
	NSAppleEventDescriptor	* theDescriptor;
	NSMutableArray				* theArray;

	theNumOfItems = [self numberOfItems];
	theArray = [NSMutableArray arrayWithCapacity:theNumOfItems];

	for( theIndex = 1; theIndex <= theNumOfItems; theIndex++)
	{
		if( (theDescriptor = [self descriptorAtIndex:theIndex]) != nil )
		{
			[theArray addObject:[theDescriptor objectValue]];
		}
	}

	return theArray;
}

/*
 * - dictionaryValue
 */
-(NSDictionary *)dictionaryValue
{
	unsigned int				theIndex,
									theNumOfItems = [self numberOfItems];
	NSMutableDictionary		*theDictionary = [NSMutableDictionary dictionaryWithCapacity:theNumOfItems];

	NSParameterAssert( sizeof( AEKeyword ) == sizeof( unsigned long ) );
	for( theIndex = 1; theIndex <= theNumOfItems; theIndex++ )
	{
		AEKeyword					theKeyword = [self keywordForDescriptorAtIndex:theIndex];
		NSAppleEventDescriptor	* theDesc = [self descriptorForKeyword:theKeyword];
		
		if( theKeyword == keyASUserRecordFields )
		{
			[theDictionary addEntriesFromDictionary:[theDesc dictionaryValueFromUserRecordDescriptor]];
		}
		else
		{
			[theDictionary setObject:[theDesc objectValue] forKey:[NSValue valueWithAEKeyword:theKeyword]];
		}
	}

	return theDictionary;
}

- (NSDictionary *)dictionaryValueFromUserRecordDescriptor
{
	unsigned int				theIndex,
									theNumOfItems = [self numberOfItems];
	NSMutableDictionary		* theDictionary = theNumOfItems
		? [NSMutableDictionary dictionaryWithCapacity:theNumOfItems/2]
		: nil;
	
	for( theIndex = 1; theIndex+1 <= theNumOfItems; theIndex+=2)
	{
		id		theKey = [[self descriptorAtIndex:theIndex] objectValue],
		theValue = [self descriptorAtIndex:theIndex+1];
		
		if( [theKey isKindOfClass:[NDFourCharCodeValue class]] && [theKey fourCharCode] == keyASUserRecordFields )
		{
			[theDictionary addEntriesFromDictionary:[theValue dictionaryValue]];
		}
		else if( [theKey isKindOfClass:[NSNumber class]] && [theKey unsignedLongValue] == keyASUserRecordFields )
		{
			[theDictionary addEntriesFromDictionary:[theValue dictionaryValue]];
		}
		else
		{
			[theDictionary setObject:[theValue objectValue] forKey:theKey];
		}
	}
	
	return theDictionary;
}

/*
 * - urlValue:
 */
- (NSURL *)urlValue
{
	id					theURL = nil;
	OSAError			theError;

	switch([self descriptorType])
	{
		case typeAlias:							//	alias record
		{
			unsigned int	theSize;
			Handle			theAliasHandle;
			FSRef				theTarget;
			Boolean			theWasChanged;

			theSize = (unsigned int)AEGetDescDataSize([self aeDesc]);
			theAliasHandle = NewHandle( theSize );
			HLock(theAliasHandle);
			theError = AEGetDescData([self aeDesc], *theAliasHandle, theSize);
			HUnlock(theAliasHandle);
			if( theError == noErr  && FSResolveAlias( NULL, (AliasHandle)theAliasHandle, &theTarget, &theWasChanged ) == noErr )
			{
				theURL = [NSURL URLWithFSRef:&theTarget];
			}

			DisposeHandle(theAliasHandle);
			break;
		}
		case typeFileURL:					// ???		NOT IMPLEMENTED YET
			NSLog(@"NOT IMPLEMENTED YET: Attempt to create a NSURL from 'typeFileURL' AEDesc" );
			break;
	}

	return theURL;
}

/*
 * -intValue
 */
- (int)intValue
{
	int		theInt = 0;
	if( AEGetDescData([self aeDesc], &theInt, sizeof(int)) != noErr )
		NSLog(@"Failed to get int value from NSAppleEventDescriptor");
	
	return theInt;
}

/*
 * -unsignedIntValue
 */
- (unsigned int)unsignedIntValue
{
	unsigned int		theUnsignedInt = 0;
	if( AEGetDescData([self aeDesc], &theUnsignedInt, sizeof(unsigned int)) != noErr )
		NSLog(@"Failed to get unsigned int value from NSAppleEventDescriptor");

	return theUnsignedInt;
}

/*
 * -longValue
 */
- (long)longValue
{
	long		theLong = 0;
	if( AEGetDescData([self aeDesc], &theLong, sizeof(long)) != noErr )
		NSLog(@"Failed to get long value from NSAppleEventDescriptor");
	
	return theLong;
}

/*
 * -unsignedLongValue
 */
- (unsigned long)unsignedLongValue
{
	unsigned long		theUnsignedLong = 0;
	if( AEGetDescData([self aeDesc], &theUnsignedLong, sizeof(unsigned long)) != noErr )
		NSLog(@"Failed to get unsigned long value from NSAppleEventDescriptor");
	
	return theUnsignedLong;
}

/*
 * -fourCharCodeValue
 */
- (FourCharCode)fourCharCodeValue
{
	FourCharCode		theResult = 0;
	if( AEGetDescData([self aeDesc], &theResult, sizeof(FourCharCode)) != noErr )
		NSLog(@"Failed to get FourCharCode value from NSAppleEventDescriptor");
	
	return theResult;
}

/*
 * -floatValue
 */
- (float)floatValue
{
	float		theFloat = 0.0;
	if( AEGetDescData([self aeDesc], &theFloat, sizeof(float)) != noErr )
		NSLog(@"Failed to get float value from NSAppleEventDescriptor");
	
	return theFloat;
}

/*
 * -doubleValue
 */
- (double)doubleValue
{
	double		theDouble = 0.0;
	if( AEGetDescData([self aeDesc], &theDouble, sizeof(double)) != noErr )
		NSLog(@"Failed to get double value from NSAppleEventDescriptor");

	return theDouble;
}

/*
 * -value
 */
- (NSValue *)value
{
	NSValue		* theValue = nil;

	switch([self descriptorType])
	{
		case typeBoolean:						//	Boolean value
		case typeShortInteger:				//	16-bit integer
		case typeLongInteger:				//	32-bit integer
		case typeShortFloat:					//	SANE single
		case typeFloat:						//	SANE double
		case typeMagnitude:					//	unsigned 32-bit integer
		case typeTrue:							//	TRUE Boolean value
		case typeFalse:						//	FALSE Boolean value
			theValue = [self numberValue];
			break;
		case typeOSAErrorRange:
		{
			DescType		theTypeCode;
			Size			theActualSize;
			short int	theStart,
							theEnd;
			if( AEGetParamPtr([self aeDesc], keyOSASourceStart, typeShortInteger, &theTypeCode, (void*)&theStart, sizeof(short int), &theActualSize ) == noErr && AEGetParamPtr([self aeDesc], keyOSASourceEnd, typeShortInteger, &theTypeCode, (void*)&theEnd, sizeof(short int), &theActualSize ) == noErr )
			{
				theValue = [NSValue valueWithRange:NSMakeRange( theStart, theEnd - theStart )];
			}
			break;
		}
		case typeRangeDescriptor:
		{
			DescType		theTypeCode;
			Size			theActualSize;
			short int	theStart,
							theEnd;
			if( AEGetParamPtr ([self aeDesc], keyAERangeStart, typeShortInteger, &theTypeCode, (void*)&theStart, sizeof(short int), &theActualSize ) == noErr && AEGetParamPtr ([self aeDesc], keyAERangeStop, typeShortInteger, &theTypeCode, (void*)&theEnd, sizeof(short int), &theActualSize ) == noErr )
			{
				theValue = [NSValue valueWithRange:NSMakeRange( theStart, theEnd - theStart )];
			}
			break;
		}
		case typeType:
			theValue = [NSValue valueWithFourCharCode:[self typeCodeValue]];
			break;
		default:
			theValue = nil;
			break;
	}

	return theValue;
}

/*
 * -numberValue
 */
- (NSNumber *)numberValue
{
	NSNumber		* theNumber;

	switch([self descriptorType])
	{
		case typeBoolean:						//	Boolean value
			theNumber = [NSNumber numberWithBool:[self booleanValue]];
			break;
		case typeShortInteger:				//	16-bit integer
			theNumber = [NSNumber numberWithShort: [self int32Value]];
			break;
		case typeLongInteger:				//	32-bit integer
//		case typeInteger:							//	32-bit integer
		{
			int		theInteger;
			if( AEGetDescData([self aeDesc], &theInteger, sizeof(int)) == noErr )
				theNumber = [NSNumber numberWithInt: theInteger];
			break;
		}
		case typeShortFloat:					//	SANE single
//		case typeSMFloat:							//	SANE single
			theNumber = [NSNumber numberWithFloat:[self floatValue]];
			break;
		case typeFloat:						//	SANE double
//		case typeLongFloat:						//	SANE double
			theNumber = [NSNumber numberWithDouble:[self doubleValue]];
			break;
//		case typeExtended:						//	SANE extended
//			break;
//		case typeComp:							//	SANE comp
//			break;
		case typeMagnitude:					//	unsigned 32-bit integer
		case typeProperty:
			theNumber = [NSNumber numberWithUnsignedLong:[self unsignedIntValue]];
			break;
		case typeTrue:							//	TRUE Boolean value
			theNumber = [NSNumber numberWithBool:YES];
			break;
		case typeFalse:						//	FALSE Boolean value
			theNumber = [NSNumber numberWithBool:NO];
			break;
		case typeType:
			theNumber = [NSNumber numberWithUnsignedLong:[self typeCodeValue]];
			break;
		default:
			theNumber = nil;
			break;
	}

	return theNumber;
}

- (NSScriptObjectSpecifier *)scriptObjectSpecifierValue
{
	return objectSpecifierForAppleEventDescriptor( self );
}

/*
 * -objectValue
 */
- (id)objectValue
{
	id			theResult;
	DescType	theDescType = [self descriptorType];

#if 1
	printf("descriptor type = %s\n", [NSFileTypeForHFSTypeCode(theDescType) lossyCString] );
#endif
	
	switch(theDescType)
	{
		case typeBoolean:						//	1-byte Boolean value
		case typeShortInteger:				//	16-bit integer
//		case typeSMInt:							//	16-bit integer
		case typeLongInteger:				//	32-bit integer
//		case typeInteger:							//	32-bit integer
		case typeShortFloat:					//	SANE single
//		case typeSMFloat:							//	SANE single
		case typeFloat:						//	SANE double
 //		case typeLongFloat:						//	SANE double
//		case typeExtended:						//	SANE extended
//		case typeComp:							//	SANE comp
		case typeMagnitude:					//	unsigned 32-bit integer
		case typeTrue:							//	TRUE Boolean value
		case typeFalse:						//	FALSE Boolean value
		case typeProperty:
			theResult = [self numberValue];
			break;
		case typeOSAErrorRange:
			theResult = [self value];
			break;
//		case typeChar:								//	unterminated string, equal to typeText
		case typeText:							//	plain text
		case kTXNUnicodeTextData:			//	unicode string
			theResult = [self stringValue];
			break;
		case typeAEList:						//	list of descriptor records
			theResult = [self arrayValue];
			break;
		case typeAERecord:					//	list of keyword-specified
			theResult = [self dictionaryValue];
			break;
		case typeAlias:						//	alias record
		case typeFileURL:
			theResult = [self urlValue];
			break;
//		case typeEnumerated:					//	enumerated data
//			break;
//		case cScript:							// script data
		case typeOSAGenericStorage:		// raw script data
		{
			SEL		theSelector;

			theSelector = NSSelectorFromString(@"scriptDataValue");
			theResult = [self respondsToSelector:theSelector] ? [self performSelector:theSelector] : self;
			break;
		}
		case cObjectSpecifier:
//			theResult = [self scriptObjectSpecifierValue];
			theResult = [[self scriptObjectSpecifierValue] objectsByEvaluatingSpecifier];
			break;
		case cEventIdentifier:
		{
			unsigned int		*theValues;
			theValues = (unsigned int*)[[self data] bytes];
			theResult = [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithFourCharCode:theValues[0]], @"EventClass", [NSValue valueWithFourCharCode:theValues[1]], @"EventID", nil];
			break;
		}
		case typeNull:
			theResult = [NSNull null];
			break;
		default:
			theResult = self;
			break;
	}

	return theResult;
}

@end

/*
 * class implementation NSAppleEventDescriptor (NDCompleteEvents)
 */
@implementation NSAppleEventDescriptor (NDCompleteEvents)

/*
 * -openEventDescriptorWithTargetDescriptor:
 */
+ (NSAppleEventDescriptor *)openEventDescriptorWithTargetDescriptor:(NSAppleEventDescriptor *)aTargetDescriptor
{
	return aTargetDescriptor ? [self appleEventWithEventClass:kCoreEventClass eventID:kAEOpenApplication targetDescriptor:aTargetDescriptor returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID] : nil;
}

/*
 * -openEventDescriptorWithTargetDescriptor:array:
 */
+ (NSAppleEventDescriptor *)openEventDescriptorWithTargetDescriptor:(NSAppleEventDescriptor *)aTargetDescriptor array:(NSArray *)anArray 
{
	NSAppleEventDescriptor	* theEvent = nil,
									* theEventList = nil;

	if( aTargetDescriptor != nil)
	{
		theEventList = [NSAppleEventDescriptor aliasListDescriptorWithArray:anArray];

		if( theEventList )
		{
			theEvent = [self appleEventWithEventClass:kCoreEventClass eventID:kAEOpenDocuments targetDescriptor:aTargetDescriptor returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
			[theEvent setParamDescriptor:theEventList forKeyword:keyDirectObject];
		}
	}

	return theEvent;
}

/*
 * -quitEventDescriptorWithTargetDescriptor:
 */
+ (NSAppleEventDescriptor *)quitEventDescriptorWithTargetDescriptor:(NSAppleEventDescriptor *)aTargetDescriptor
{
	return aTargetDescriptor ? [self appleEventWithEventClass:kCoreEventClass eventID:kAEQuitApplication targetDescriptor:aTargetDescriptor returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID] : nil;
}

/*
 * +descriptorWithSubroutineName:argumentsListDescriptor:
 */
+ (id)descriptorWithSubroutineName:(NSString *)aRoutineName argumentsListDescriptor:(NSAppleEventDescriptor *)aParam
{
	return [[[NSAppleEventDescriptor alloc] initWithSubroutineName:aRoutineName argumentsListDescriptor:aParam] autorelease];
}

/*
 * +descriptorWithPositionalSubroutineName:argumentsArray:
 */
+ (id)descriptorWithSubroutineName:(NSString *)aRoutineName argumentsArray:(NSArray *)aParamArray
{
	return [[[NSAppleEventDescriptor alloc] initWithSubroutineName:aRoutineName argumentsListDescriptor:aParamArray ? [NSAppleEventDescriptor descriptorWithArray:aParamArray] : nil] autorelease];
}

/*
 * +descriptorWithSubroutineName:prepositionalArgumentObjects:forKeyword:count:
 */
+ (id)descriptorWithSubroutineName:(NSString *)aRoutineName labels:(AEKeyword*)aLabels argumentObjects:(id *)anObjects count:(unsigned int)aCount
{
	return [[[self alloc] initWithSubroutineName:aRoutineName labels:aLabels arguments:anObjects count:aCount] autorelease];
}

/*
 * +descriptorWithSubroutineName:labels:argumentDescriptors:count:
 */
+ (id)descriptorWithSubroutineName:(NSString *)aRoutineName labels:(AEKeyword*)aLabels argumentDescriptors:(NSAppleEventDescriptor **)aParam count:(unsigned int)aCount
{
	return [[[self alloc] initWithSubroutineName:aRoutineName labels:aLabels argumentDescriptors:aParam  count:aCount] autorelease];
}

/*
 * +descriptorWithSubroutineName:labelsAndArguments:
 */
+ (id)descriptorWithSubroutineName:(NSString *)aRoutineName labelsAndArguments:(AEKeyword)aKeyWord, ...
{
	NSAppleEventDescriptor	* theDescriptor;
	va_list	theArgList;
	va_start( theArgList, aKeyWord );
	theDescriptor = [[[self alloc] initWithSubroutineName:aRoutineName labelsAndArguments:aKeyWord arguments:theArgList] autorelease];
	va_end( theArgList );
	return theDescriptor;
}

/*
 * -initWithSubroutineName:argumentsArray:
 */
- (id)initWithSubroutineName:(NSString *)aRoutineName argumentsArray:(NSArray *)aParamArray
{
	return [self initWithSubroutineName:aRoutineName argumentsListDescriptor:aParamArray ? [NSAppleEventDescriptor descriptorWithArray:aParamArray] : nil];
}

/*
 * -initWithSubroutineName:argumentsListDescriptor:
 */
- (id)initWithSubroutineName:(NSString *)aRoutineName argumentsListDescriptor:(NSAppleEventDescriptor *)aParam
{
	if( (self = [self initWithEventClass:kASAppleScriptSuite eventID:kASSubroutineEvent
									 targetDescriptor:[NSAppleEventDescriptor currentProcessDescriptor] returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID]) != nil )
	{
		[self setParamDescriptor:[NSAppleEventDescriptor descriptorWithCString:[[aRoutineName lowercaseString] lossyCString]] forKeyword:keyASSubroutineName];
		[self setParamDescriptor:aParam ? aParam : [NSAppleEventDescriptor listDescriptor] forKeyword:keyDirectObject];
	}

	return self;
}

/*
 * -initWithSubroutineName:labels:arguments:count:
 */
- (id)initWithSubroutineName:(NSString *)aRoutineName labels:(AEKeyword*)aLabels arguments:(id *)anObjects count:(unsigned int)aCount
{
	if( (self = [self initWithEventClass:kASAppleScriptSuite eventID:kASPrepositionalSubroutine
														 targetDescriptor:[NSAppleEventDescriptor currentProcessDescriptor] returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID]) != nil )
	{
		unsigned int		theIndex;
		[self setParamDescriptor:[NSAppleEventDescriptor descriptorWithCString:[[aRoutineName lowercaseString] lossyCString]] forKeyword:keyASSubroutineName];
		for( theIndex = 0; theIndex < aCount; theIndex++ )
		{
			if( aLabels[theIndex] == keyASPrepositionGiven
					&& [anObjects[theIndex] isKindOfClass:[NSDictionary class]] )
			{
				[self setParamDescriptor:[NSAppleEventDescriptor userRecordDescriptorWithDictionary:anObjects[theIndex]] forKeyword:keyASUserRecordFields];
			}
			else if( aLabels[theIndex] == keyASPrepositionGiven
					&& [anObjects[theIndex] isKindOfClass:[NSAppleEventDescriptor class]] )
			{
				[self setParamDescriptor:anObjects[theIndex] forKeyword:keyASUserRecordFields];
			}
			else
			{
				[self setParamDescriptor:[NSAppleEventDescriptor descriptorWithObject:anObjects[theIndex]] forKeyword:aLabels[theIndex]];
			}
		}
	}

	return self;
}

/*
 * -initWithSubroutineName:prepositionalArgumentDescriptors:forKeywords:count:
 */
- (id)initWithSubroutineName:(NSString *)aRoutineName labels:(AEKeyword*)aLabels argumentDescriptors:(NSAppleEventDescriptor **)aParam count:(unsigned int)aCount
{
	if( (self = [self initWithEventClass:kASAppleScriptSuite eventID:kASPrepositionalSubroutine
												  targetDescriptor:[NSAppleEventDescriptor currentProcessDescriptor] returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID]) != nil )
	{
		unsigned int		theIndex;
		[self setParamDescriptor:[NSAppleEventDescriptor descriptorWithCString:[[aRoutineName lowercaseString] lossyCString]] forKeyword:keyASSubroutineName];
		for( theIndex = 0; theIndex < aCount; theIndex++ )
			[self setParamDescriptor:aParam[theIndex] forKeyword:aLabels[theIndex]];
	}

	return self;
}

/*
 * -initWithSubroutineName:labelsAndArguments:arguments:
 */
- (id)initWithSubroutineName:(NSString *)aRoutineName labelsAndArguments:(AEKeyword)aKeyWord arguments:(va_list)anArgList
{
	if( (self = [self initWithEventClass:kASAppleScriptSuite eventID:kASPrepositionalSubroutine targetDescriptor:[NSAppleEventDescriptor currentProcessDescriptor] returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID]) != nil )
	{
		[self setParamDescriptor:[NSAppleEventDescriptor descriptorWithCString:[[aRoutineName lowercaseString] lossyCString]] forKeyword:keyASSubroutineName];
		for( ; aKeyWord != nil; aKeyWord = va_arg( anArgList, AEKeyword ) )
		{
			id		theObject = va_arg( anArgList, id );

			if( aKeyWord == keyASPrepositionGiven )
			{
				[self setParamDescriptor:[NSAppleEventDescriptor descriptorWithObject:[NSAppleEventDescriptor userRecordDescriptorWithObjectAndKeys:theObject arguments:anArgList]] forKeyword:keyASUserRecordFields];
				break;				// all the arguments have been got
			}
			else
				[self setParamDescriptor:[NSAppleEventDescriptor descriptorWithObject:theObject] forKeyword:aKeyWord];
		}
	}

	return self;
}

@end

/*
 * aeDescForObjectSpecifier()
 */
	static BOOL aeDescForIndexSpecifier(AEDesc*,NSIndexSpecifier*);
	static BOOL aeDescForMiddleSpecifier(AEDesc*,NSMiddleSpecifier*);
	static BOOL aeDescForNameSpecifier(AEDesc*,NSNameSpecifier*);
	static BOOL aeDescForPositionalSpecifier(AEDesc*,NSPositionalSpecifier*);
	static BOOL aeDescForPropertySpecifier(AEDesc*,NSPropertySpecifier*);
	static BOOL aeDescForRandomSpecifier(AEDesc*,NSRandomSpecifier*);
	static BOOL aeDescForRangeSpecifier(AEDesc*,NSRangeSpecifier*);
	static BOOL aeDescForRelativeSpecifier(AEDesc*,NSRelativeSpecifier*);
	static BOOL aeDescForUniqueIDSpecifier(AEDesc*,NSUniqueIDSpecifier*);
	static BOOL aeDescForWhoseSpecifier(AEDesc*,NSWhoseSpecifier*);
static BOOL aeDescForObjectSpecifier( AEDesc * aDesc, NSScriptObjectSpecifier * aSpecifier )
{
	BOOL		theResult = NO;
	if( aSpecifier )
	{
		if( [aSpecifier isKindOfClass:[NSIndexSpecifier class]] )
			theResult = aeDescForIndexSpecifier( aDesc, (NSIndexSpecifier*)aSpecifier );
		else if( [aSpecifier isKindOfClass:[NSMiddleSpecifier class]] )
			theResult = aeDescForMiddleSpecifier( aDesc, (NSMiddleSpecifier*)aSpecifier );
		else if( [aSpecifier isKindOfClass:[NSNameSpecifier class]] )
			theResult = aeDescForNameSpecifier( aDesc, (NSNameSpecifier*)aSpecifier );
		else if( [aSpecifier isKindOfClass:[NSPositionalSpecifier class]] )
			theResult = aeDescForPositionalSpecifier( aDesc, (NSPositionalSpecifier*)aSpecifier );
		else if( [aSpecifier isKindOfClass:[NSPropertySpecifier class]] )
			theResult = aeDescForPropertySpecifier( aDesc, (NSPropertySpecifier*)aSpecifier );
		else if( [aSpecifier isKindOfClass:[NSRandomSpecifier class]] )
			theResult = aeDescForRandomSpecifier( aDesc, (NSRandomSpecifier*)aSpecifier );
		else if( [aSpecifier isKindOfClass:[NSRangeSpecifier class]] )
			theResult = aeDescForRangeSpecifier( aDesc, (NSRangeSpecifier*)aSpecifier );
		else if( [aSpecifier isKindOfClass:[NSRelativeSpecifier class]] )
			theResult = aeDescForRelativeSpecifier( aDesc, (NSRelativeSpecifier*)aSpecifier );
		else if( [aSpecifier isKindOfClass:[NSUniqueIDSpecifier class]] )
			theResult = aeDescForUniqueIDSpecifier( aDesc, (NSUniqueIDSpecifier*)aSpecifier );
		else if( [aSpecifier isKindOfClass:[NSWhoseSpecifier class]] )
			theResult = aeDescForWhoseSpecifier( aDesc, (NSWhoseSpecifier*)aSpecifier );
		else 
			NSLog(@"Script Object Specifier %@ of unhandled type %@", aSpecifier, [aSpecifier class]);
	}
	else	// if a nil specifier then return a typeNull descriptor
		theResult = NDLogOSStatus(AECreateDesc( typeNull, NULL, 0, aDesc ));

	return theResult;
}
	/* aeDescForIndexSpecifier() */
	static BOOL aeDescForIndexSpecifier( AEDesc * aDesc, NSIndexSpecifier * aSpecifier )
	{
		BOOL								theResult = NO;
		AEDesc							theContainerDesc,
											theKeyData;
		NSScriptClassDescription	* theContainerClassDesc = [aSpecifier containerClassDescription];
		NSScriptObjectSpecifier		* theContainerSpecifier = [aSpecifier containerSpecifier];
		
		AEInitializeDesc(&theContainerDesc);	// need to initialize it to typeNull in case it is not set
		
		NSCAssert( theContainerClassDesc != nil, @"Coercsion of NSScriptObjectSpecifiers to NSAppleEventDescriptor can only occur with NSScriptObjectSpecifiers that have there container class specifiers set.");
		
		/* nil container specifier means the container is the application and the container desc should be typeNull */
		if( theContainerSpecifier == nil || NDLogFalse(aeDescForObjectSpecifier( &theContainerDesc, theContainerSpecifier  ) ) )
		{
			long int		theIndex = [aSpecifier index]+1;
			if( NDLogOSStatus( AECreateDesc( typeLongInteger, &theIndex, sizeof( theIndex ), &theKeyData ) ) )
			{
				DescType		theKeyDesc = [theContainerClassDesc appleEventCodeForKey:[aSpecifier key]];
				theResult = NDLogOSStatus( CreateObjSpecifier( theKeyDesc, &theContainerDesc, formAbsolutePosition, &theKeyData, NO, aDesc) );
				AEDisposeDesc(&theKeyData);
			}
			AEDisposeDesc(&theContainerDesc);
		}

		return theResult;
	}
	/* aeDescForMiddleSpecifier() */
	static BOOL aeDescForMiddleSpecifier( AEDesc * aDesc, NSMiddleSpecifier * aSpecifier )
	{
		return NO;
	}
	/* aeDescForNameSpecifier() */
	static BOOL aeDescForNameSpecifier( AEDesc * aDesc, NSNameSpecifier * aSpecifier )
	{
		BOOL								theResult = NO;
		AEDesc							theContainerDesc,
											theKeyData;
		NSScriptClassDescription	* theContainerClassDesc = [aSpecifier containerClassDescription];
		NSScriptObjectSpecifier		* theContainerSpecifier = [aSpecifier containerSpecifier];

		AEInitializeDesc(&theContainerDesc);	// need to initialize it to typeNull in case it is not set

		NSCAssert( theContainerClassDesc != nil, @"Coercsion of NSScriptObjectSpecifiers to NSAppleEventDescriptor can only occur with NSScriptObjectSpecifiers that have there container class specifiers set.");

		if( theContainerSpecifier == nil || NDLogFalse(aeDescForObjectSpecifier( &theContainerDesc, theContainerSpecifier  ) ) )
		{
			NSString			* theName = [aSpecifier name];
			unsigned int		theLength = [theName length];
			unichar				* theCharacters = malloc( theLength * sizeof(unichar) );
			[theName getCharacters:theCharacters];
			if( NDLogOSStatus( AECreateDesc( typeUnicodeText, theCharacters, theLength, &theKeyData ) ) )
			{
				DescType		theKeyDesc = [theContainerClassDesc appleEventCodeForKey:[aSpecifier key]];
				theResult = NDLogOSStatus( CreateObjSpecifier( theKeyDesc, &theContainerDesc, formName, &theKeyData, NO, aDesc) );
				AEDisposeDesc(&theKeyData);
			}
			AEDisposeDesc(&theContainerDesc);
		}
		
		return theResult;
	}
	/* aeDescForPositionalSpecifier() */
	static BOOL aeDescForPositionalSpecifier( AEDesc * aDesc, NSPositionalSpecifier * aSpecifier )
	{
		return NO;
	}
	/* aeDescForPropertySpecifier() */
	static BOOL aeDescForPropertySpecifier( AEDesc * aDesc, NSPropertySpecifier * aSpecifier )
	{
		BOOL								theResult = NO;
		AEDesc							theContainerDesc,
											theKeyData;
		NSScriptClassDescription	* theContainerClassDesc = [aSpecifier containerClassDescription];
		NSScriptObjectSpecifier		* theContainerSpecifier = [aSpecifier containerSpecifier];
		
		AEInitializeDesc(&theContainerDesc);	// need to initialize it to typeNull in case it is not set
		
		NSCAssert( theContainerClassDesc != nil, @"Coercsion of NSScriptObjectSpecifiers to NSAppleEventDescriptor can only occur with NSScriptObjectSpecifiers that have there container class specifiers set.");
		
		/* nil container specifier means the container is the application and the container desc should be typeNull */
		if( theContainerSpecifier == nil || NDLogFalse(aeDescForObjectSpecifier( &theContainerDesc, theContainerSpecifier  ) ) )
		{
			DescType		theKeyDesc = [theContainerClassDesc appleEventCodeForKey:[aSpecifier key]];
			if( NDLogOSStatus( AECreateDesc( typeType, &theKeyDesc, sizeof(theKeyDesc), &theKeyData ) ) )
			{
				theResult = NDLogOSStatus( CreateObjSpecifier( formPropertyID, &theContainerDesc, formPropertyID, &theKeyData, NO, aDesc) );
				AEDisposeDesc(&theKeyData);
			}
			AEDisposeDesc(&theContainerDesc);
		}
		return theResult;
	}
	/* aeDescForRandomSpecifier() */
	static BOOL aeDescForRandomSpecifier( AEDesc * aDesc, NSRandomSpecifier * aSpecifier )
	{
		return NO;
	}
	/* aeDescForRangeSpecifier() */
	static BOOL aeDescForRangeSpecifier( AEDesc * aDesc, NSRangeSpecifier * aSpecifier )
	{
		BOOL			theResult = NO;
		AEDesc		theStartDesc,
						theEndDesc;
		
		if( aeDescForObjectSpecifier( &theStartDesc, [aSpecifier startSpecifier] ) )
		{
			if( aeDescForObjectSpecifier( &theEndDesc, [aSpecifier endSpecifier] ) )
			{
				theResult = NDLogOSStatus( CreateRangeDescriptor( &theStartDesc, &theEndDesc, NO, aDesc) );
				AEDisposeDesc(&theEndDesc);
			}
			else
				NSLog( @"Failed to create end descriptor" );
			AEDisposeDesc(&theStartDesc);
		}
		else
			NSLog( @"Failed to create start descriptor" );
		
		return theResult;
	}
	/* aeDescForRelativeSpecifier() */
	static BOOL aeDescForRelativeSpecifier( AEDesc * aDesc, NSRelativeSpecifier * aSpecifier )
	{
		return NO;
	}

	/* aeDescForUniqueIDSpecifier() */
	static BOOL aeDescForUniqueIDSpecifier( AEDesc * aDesc, NSUniqueIDSpecifier * aSpecifier )
	{
			BOOL								theResult = NO;
			AEDesc							theContainerDesc,
												theKeyData;
			NSScriptObjectSpecifier		* theContainerSpecifier = [aSpecifier containerSpecifier];
			
			AEInitializeDesc(&theContainerDesc);	// need to initialize it to typeNull in case it is not set
						
			/* nil container specifier means the container is the application and the container desc should be typeNull */
			if( theContainerSpecifier == nil || NDLogFalse(aeDescForObjectSpecifier( &theContainerDesc, theContainerSpecifier  ) ) )
			{
				id		theIdentifier = [aSpecifier uniqueID];
				if( [theIdentifier isKindOfClass:[NSString class]] )
				{
					unsigned int		theLength = [(NSString*)theIdentifier length];
					unichar				* theCharacters = malloc( theLength * sizeof(unichar) );
					[theIdentifier getCharacters:theCharacters];
					if( NDLogOSStatus( AECreateDesc( typeUnicodeText, theCharacters, theLength, &theKeyData ) ) )
					{
						theResult = NDLogOSStatus( CreateObjSpecifier( [[aSpecifier keyClassDescription] appleEventCode], &theContainerDesc, formAbsolutePosition, &theKeyData, NO, aDesc) );
						AEDisposeDesc(&theKeyData);
					}
				}
				else if( [theIdentifier isKindOfClass:[NSNumber class]] )
				{
					long int	theIndex = [(NSNumber*)theIdentifier unsignedIntValue];
					if( NDLogOSStatus( AECreateDesc( typeLongInteger, &theIndex, sizeof( theIndex ), &theKeyData ) ) )
					{
						theResult = NDLogOSStatus( CreateObjSpecifier( [[aSpecifier keyClassDescription] appleEventCode], &theContainerDesc, formAbsolutePosition, &theKeyData, NO, aDesc) );
						AEDisposeDesc(&theKeyData);
					}
					AEDisposeDesc(&theContainerDesc);
				}
				
				AEDisposeDesc(&theContainerDesc);
			}
			
			return theResult;
	}
	/* aeDescForWhoseSpecifier() */
	static BOOL aeDescForWhoseSpecifier( AEDesc * aDesc, NSWhoseSpecifier * aSpecifier )
	{
		return NO;
	}
/*
 * objectSpecifierForAEDesc()
 */
	static NSIndexSpecifier * objectSpecifierForAbsolutePositionAppleEventDescriptor( NSAppleEventDescriptor * );
	static NSPropertySpecifier * objectSpecifierForPropertyAppleEventDescriptor( NSAppleEventDescriptor * );
	static NSNameSpecifier * objectSpecifierForNameAppleEventDescriptor( NSAppleEventDescriptor * );
	static NSRelativeSpecifier * objectSpecifierForRelativePositionAppleEventDescriptor( NSAppleEventDescriptor * );
//	static NSRangeSpecifier * objectSpecifierForRangeAppleEventDescriptor( NSAppleEventDescriptor * );
static NSScriptObjectSpecifier * objectSpecifierForAppleEventDescriptor( NSAppleEventDescriptor * aDescriptor )
{
	NSScriptObjectSpecifier		* theResultSpecifier = nil;
	
	if( aDescriptor )
	{
		DescType							theFormType = [[aDescriptor descriptorForKeyword:keyAEKeyForm] fourCharCodeValue];
		
		switch( theFormType )
		{
			case formAbsolutePosition:
				theResultSpecifier = objectSpecifierForAbsolutePositionAppleEventDescriptor( aDescriptor );
				break;
			case formPropertyID:
				theResultSpecifier = objectSpecifierForPropertyAppleEventDescriptor( aDescriptor );
				break;
			case formName:
				theResultSpecifier = objectSpecifierForNameAppleEventDescriptor( aDescriptor );
				break;
			case formRelativePosition:
				theResultSpecifier = objectSpecifierForRelativePositionAppleEventDescriptor( aDescriptor );
				break;
			case formTest:
			case formRange:
				NSLog( @"Unsupported form %@", NSFileTypeForHFSTypeCode(theFormType) );
				break;
			default:
				NSLog( @"Unknown form %@", NSFileTypeForHFSTypeCode(theFormType) );
				break;
		}
	}
	return theResultSpecifier;
}
	/* objectSpecifierForAbsolutePositionAppleEventDescriptor */
	static NSIndexSpecifier * objectSpecifierForAbsolutePositionAppleEventDescriptor( NSAppleEventDescriptor * aDescriptor )
	{
		NSIndexSpecifier				* theResultSpecifier = nil;
		NSScriptObjectSpecifier		* theContainerSpec = objectSpecifierForAppleEventDescriptor( [aDescriptor descriptorForKeyword:keyAEContainer] );
		DescType		theTypeDesc = [[aDescriptor descriptorForKeyword:keyAEDesiredClass] fourCharCodeValue];
		
		NSScriptClassDescription	* theClassDesc = theContainerSpec ? [theContainerSpec keyClassDescription] : [[NSScriptSuiteRegistry sharedScriptSuiteRegistry] classDescriptionWithAppleEventCode:cApplication];
		long int		theIndex = [[aDescriptor descriptorForKeyword:keyAEKeyData] longValue]-1;
		theResultSpecifier = [[[NSIndexSpecifier allocWithZone:[theContainerSpec zone]] initWithContainerClassDescription:theClassDesc containerSpecifier:theContainerSpec key:[theClassDesc keyWithAppleEventCode:theTypeDesc] index:theIndex] autorelease];

			return theResultSpecifier;
	}
	/* objectSpecifierForPropertyAppleEventDescriptor */
	static NSPropertySpecifier * objectSpecifierForPropertyAppleEventDescriptor( NSAppleEventDescriptor * aDescriptor )
	{
		NSPropertySpecifier			* theResultSpecifier = nil;
		NSScriptObjectSpecifier		* theContainerSpec = objectSpecifierForAppleEventDescriptor( [aDescriptor descriptorForKeyword:keyAEContainer] );
		
		NSScriptClassDescription	* theClassDesc = theContainerSpec ? [theContainerSpec containerClassDescription] : [[NSScriptSuiteRegistry sharedScriptSuiteRegistry] classDescriptionWithAppleEventCode:cApplication];
		DescType		theKeyDesc = [[aDescriptor descriptorForKeyword:keyAEKeyData] fourCharCodeValue];
		theResultSpecifier = [[[NSPropertySpecifier allocWithZone:[theContainerSpec zone]] initWithContainerClassDescription:theClassDesc containerSpecifier:theContainerSpec key:[theClassDesc keyWithAppleEventCode:theKeyDesc]] autorelease];
		return theResultSpecifier;
	}
	/* objectSpecifierForNameAppleEventDescriptor */
	static NSNameSpecifier * objectSpecifierForNameAppleEventDescriptor( NSAppleEventDescriptor * aDescriptor )
	{
		NSNameSpecifier				* theResultSpecifier = nil;
		NSScriptObjectSpecifier		* theContainerSpec = objectSpecifierForAppleEventDescriptor( [aDescriptor descriptorForKeyword:keyAEContainer] );	
		DescType		theTypeDesc = [[aDescriptor descriptorForKeyword:keyAEDesiredClass] fourCharCodeValue];
		NSScriptClassDescription	* theClassDesc = [[NSScriptSuiteRegistry sharedScriptSuiteRegistry] classDescriptionWithAppleEventCode:theTypeDesc];
		NSString							* theName = [[aDescriptor descriptorForKeyword:keyAEKeyData] stringValue];
		theResultSpecifier = [[[NSNameSpecifier allocWithZone:[theContainerSpec zone]] initWithContainerClassDescription:theClassDesc containerSpecifier:theContainerSpec key:[theClassDesc keyWithAppleEventCode:theTypeDesc] name:theName] autorelease];
		
		return theResultSpecifier;
	}

	/* objectSpecifierForRelativePositionAppleEventDescriptor */
	static NSRelativeSpecifier * objectSpecifierForRelativePositionAppleEventDescriptor( NSAppleEventDescriptor * aDescriptor )
	{
		NSRelativeSpecifier			* theResultSpecifier = nil;
		NSScriptObjectSpecifier		* theContainerSpec = objectSpecifierForAppleEventDescriptor( [aDescriptor descriptorForKeyword:keyAEContainer] );	
		DescType		theTypeDesc = [[aDescriptor descriptorForKeyword:keyAEDesiredClass] fourCharCodeValue],
						theRelativePos = [[aDescriptor descriptorForKeyword:keyAEKeyData] fourCharCodeValue];
		
		NSScriptClassDescription	* theClassDesc = [[NSScriptSuiteRegistry sharedScriptSuiteRegistry] classDescriptionWithAppleEventCode:theTypeDesc];

NDUntestedMethod();

		theResultSpecifier = [[[NSRelativeSpecifier allocWithZone:[theContainerSpec zone]] initWithContainerClassDescription:theClassDesc containerSpecifier:theContainerSpec key:[theClassDesc keyWithAppleEventCode:theTypeDesc] relativePosition:theRelativePos == kAEPrevious ? NSRelativeBefore : NSRelativeAfter baseSpecifier:theContainerSpec] autorelease];
		
		return theResultSpecifier;
	}

#if 0
	static NSRelativeSpecifier * objectSpecifierForRangeAppleEventDescriptor( NSAppleEventDescriptor * )
	{
	}
#endif