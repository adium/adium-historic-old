/*
 *  NDAppleScriptObject.m
 *  NDAppleScriptObjectProjectAlpha
 *
 *  Created by Nathan Day on Mon May 17 2004.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */

#import "NDAppleScriptObject.h"
#import "NDProgrammerUtilities.h"
#import "NDResourceFork.h"
#import "NDComponentInstance.h"
#import "NSAppleEventDescriptor+NDAppleScriptObject.h"
//#import "NSArray+NDUtilities.h"

static NSString		* kScriptResourceName = @"script";
static const OSType	kScriptEditorCreatorCode = 'ToyS',
							kCompiledAppleScriptTypeCode = 'osas';

/*
 * category interface NDComponentInstance (Private)
 */
@interface NDComponentInstance (Private)
- (ComponentInstance)instanceRecord;
@end

/*
 * class interface NDScriptData (Private)
 */
@interface NDScriptData (Private)
+ (id)newWithScriptID:(OSAID)scriptID componentInstance:(NDComponentInstance *)component;
+ (id)scriptDataWithScriptID:(OSAID)scriptID componentInstance:(NDComponentInstance *)component;
+ (Class)classForScriptID:(OSAID)scriptID componentInstance:(NDComponentInstance *)componentInstance;
- (id)initWithComponentInstance:(NDComponentInstance *)componentInstance;
- (id)initWithScriptID:(OSAID)scriptID componentInstance:(NDComponentInstance *)component;
- (OSAID)scriptID;
- (ComponentInstance)instanceRecord;
- (BOOL)isCompiled;
@end
/*
 * class interface NDScriptContext (Private)
 */
@interface NDScriptContext (Private)
+ (OSAID)compileString:(NSString *)string modeFlags:(long)modeFlags scriptID:(OSAID)scriptID componentInstance:(NDComponentInstance *)aComponentInstance;
- (id)initWithScriptID:(OSAID)aScriptDataID parentScriptContext:(NDScriptContext *)aParentScriptContext;
@end

/*
 * class interface NDScriptHandler (Private)
 */
@interface NDScriptHandler (Private)
+ (OSAID)compileString:(NSString *)aString scriptID:(OSAID)aScriptID componentInstance:(NDComponentInstance *)aComponentInstance;
+ (OSAID)compileString:(NSString *)aString modeFlags:(long)aModeFlags scriptID:(OSAID)aScriptID componentInstance:(NDComponentInstance *)aComponentInstance;
- (void)setResultScriptDataID:(OSAID)aScriptDataID;
@end


@implementation NDAppleScriptObject

+ (id)compileExecuteString:(NSString *)aString componentInstance:(NDComponentInstance *)aComponentInstance
{
	return [[self compileExecuteSource:aString componentInstance:aComponentInstance] objectValue];
}

+ (id)compileExecuteString:(NSString *)aString
{
	return [[self compileExecuteSource:aString componentInstance:nil] objectValue];
}

- (id)initWithString:(NSString *)aString modeFlags:(long)aModeFlags componentInstance:(NDComponentInstance *)aComponentInstance
{
	if( (self = [self initWithComponentInstance:aComponentInstance]) != nil )
	{
		source = [aString retain];
		[self compileWithModeFlags:aModeFlags];
	}

	return self;
}


- (void)dealloc
{
	[source release];
	[error release];
	[super dealloc];
}

- (NSDictionary *)error
{
	if( error == nil )
		error = [[[self componentInstance] error] retain];

	return error;
}

- (NSString *)source
{
	return source ? source : [super source];
}

- (void)setSource:(NSString *)aSource
{
	if( aSource != nil && source != aSource )
	{
		[source release];
		source = [aSource retain];
		if( scriptID != kOSANullScript )
			NDLogOSStatus( OSADispose( [self instanceRecord], scriptID ));
		scriptID = kOSANullScript;
	}
}

- (BOOL)compileWithModeFlags:(long)aModeFlags
{
	if( ![self isCompiled] && source != nil )
	{
		scriptID = [NDAppleScriptObject compileString:source modeFlags:aModeFlags scriptID:kOSANullScript componentInstance:[self componentInstance]];

		if( scriptID != kOSANullScript )
		{
			[source release];		// don't need the source anymore
			source = nil;
		}
	}

	return [self isCompiled];
}

- (BOOL)isCompiled
{
	return scriptID != kOSANullScript;
}

- (BOOL)writeToURL:(NSURL *)aURL inDataFork:(BOOL)anInDataFork atomically:(BOOL)anAtomically
{
	return anInDataFork
			? [[self data] writeToURL:aURL atomically:anAtomically]
			: [self writeToURL:aURL Id:kScriptResourceID];
}

- (BOOL)writeToFile:(NSString *)aPath inDataFork:(BOOL)anInDataFork atomically:(BOOL)anAtomically
{
	return anInDataFork
			? [[self data] writeToFile:aPath atomically:anAtomically]
			: [self writeToFile:aPath Id:kScriptResourceID];
}

- (BOOL)writeToURL:(NSURL *)aURL Id:(short)anID
{
	NSData				* theData;
	BOOL					theResult = NO,
		theCanNotWriteTo = NO;

	if( [self isCompiled] && (theData = [self data]) )
	{
		if( ![[NSFileManager defaultManager] fileExistsAtPath:[aURL path] isDirectory:&theCanNotWriteTo] )
		{
			theCanNotWriteTo = ![[NSFileManager defaultManager] createFileAtPath:[aURL path] contents:nil attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedLong:kScriptEditorCreatorCode], NSFileHFSCreatorCode, [NSNumber numberWithUnsignedLong:kCompiledAppleScriptTypeCode], NSFileHFSTypeCode, nil]];
		}

		if( !theCanNotWriteTo )
			theResult = [theData writeToResourceForkURL:aURL type:kOSAScriptResourceType Id:anID name:kScriptResourceName];
	}

	return theResult;

}

- (BOOL)writeToFile:(NSString *)aPath Id:(short)anID
{
	NSData				* theData;
	BOOL					theResult = NO,
		theCanNotWriteTo = NO;

	if( [self isCompiled] && (theData = [self data]) )
	{
		if( ![[NSFileManager defaultManager] fileExistsAtPath:aPath isDirectory:&theCanNotWriteTo] )
		{
			theCanNotWriteTo = ![[NSFileManager defaultManager] createFileAtPath:aPath contents:nil attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedLong:kScriptEditorCreatorCode], NSFileHFSCreatorCode, [NSNumber numberWithUnsignedLong:kCompiledAppleScriptTypeCode], NSFileHFSTypeCode, nil]];
		}

		if( !theCanNotWriteTo )
			theResult = [theData writeToResourceForkFile:aPath type:kOSAScriptResourceType Id:anID name:kScriptResourceName];
	}

	return theResult;
}

+ (NSString *)description
{
	return @"AppleScript";
}

/*
 * -initWithScriptID:componentInstance:
 */
- (id)initWithScriptID:(OSAID)aScriptID componentInstance:(NDComponentInstance *)aComponentInstance
{
	if(NDLogFalse([[NDScriptData classForScriptID:aScriptID componentInstance:aComponentInstance] isSubclassOfClass:[NDScriptContext class]])
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

@end

@implementation NDAppleScriptObject (NDExtended)

+ (id)appleScriptObjectWithString:(NSString *)aString
{
	return [[[ self alloc] initWithString:aString modeFlags:kOSAModeNull componentInstance:nil] autorelease];
}

+ (id)appleScriptObjectWithString:(NSString *)aString componentInstance:(NDComponentInstance *)aComponentInstance
{
	return [[[ self alloc] initWithString:aString modeFlags:kOSAModeNull componentInstance:aComponentInstance] autorelease];
}

+ (id)appleScriptObjectWithData:(NSData *)aData
{
	return [[[self alloc] initWithData:aData componentInstance:nil] autorelease];
}

+ (id)appleScriptObjectWithData:(NSData *)aData componentInstance:(NDComponentInstance *)aComponentInstance
{
	return [[[self alloc] initWithData:aData componentInstance:aComponentInstance] autorelease];
}

+ (id)appleScriptObjectWithContentsOfFile:(NSString *)aPath
{
	return [[[self alloc] initWithContentsOfFile:aPath componentInstance:nil] autorelease];
}

+ (id)appleScriptObjectWithContentsOfFile:(NSString *)aPath componentInstance:(NDComponentInstance *)aComponentInstance
{
	return [[[self alloc] initWithContentsOfFile:aPath componentInstance:aComponentInstance] autorelease];
}

+ (id)appleScriptObjectWithContentsOfURL:(NSURL *)anURL
{
	return [[[self alloc] initWithContentsOfURL:anURL componentInstance:nil] autorelease];
}

+ (id)appleScriptObjectWithContentsOfURL:(NSURL *)anURL componentInstance:(NDComponentInstance *)aComponentInstance
{
	return [[[self alloc] initWithContentsOfURL:anURL componentInstance:aComponentInstance] autorelease];
}

- (id)initWithString:(NSString *)aString componentInstance:(NDComponentInstance *)aComponentInstance
{
	return [self initWithSource:aString modeFlags:kOSAModeNull componentInstance:aComponentInstance];
}

- (BOOL)compile
{
	return [self compileWithModeFlags:kOSAModeNull];
}

@end

