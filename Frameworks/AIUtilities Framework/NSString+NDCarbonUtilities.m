/*
 *  NSString+NDCarbonUtilities.m category
 *
 *  Created by Nathan Day on Sat Aug 03 2002.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */

#import "NSString+NDCarbonUtilities.h"

/*
 * class implementation NSString (NDCarbonUtilities)
 */
@implementation NSString (NDCarbonUtilitiesPaths)

/*
 * +stringWithFSRef:
 */
+ (NSString *)stringWithFSRef:(const FSRef *)aFSRef
{
	UInt8			thePath[PATH_MAX + 1];		// plus 1 for \0 terminator
	
	return (FSRefMakePath ( aFSRef, thePath, PATH_MAX ) == noErr) ? [NSString stringWithUTF8String:thePath] : nil;
}

/*
 * -getFSRef:
 */
- (BOOL)getFSRef:(FSRef *)aFSRef
{
	return FSPathMakeRef( [self UTF8String], aFSRef, NULL ) == noErr;
}

/*
 * -getFSRef:
 */
- (BOOL)getFSSpec:(FSSpec *)aFSSpec
{
	FSRef			aFSRef;

	return [self getFSRef:&aFSRef] && (FSGetCatalogInfo( &aFSRef, kFSCatInfoNone, NULL, NULL, aFSSpec, NULL ) == noErr);
}

/*
 * -fileSystemPathHFSStyle
 */
- (NSString *)fileSystemPathHFSStyle
{
	return [(NSString *)CFURLCopyFileSystemPath((CFURLRef)[NSURL fileURLWithPath:self], kCFURLHFSPathStyle) autorelease];
}

/*
 * -pathFromFileSystemPathHFSStyle
 */
- (NSString *)pathFromFileSystemPathHFSStyle
{
	return [[(NSURL *)CFURLCreateWithFileSystemPath( kCFAllocatorDefault, (CFStringRef)self, kCFURLHFSPathStyle, [self hasSuffix:@":"] ) autorelease] path];
}

/*
 * -resolveAliasFile
 */
- (NSString *)resolveAliasFile
{
	FSRef			theRef;
	Boolean		theIsTargetFolder,
					theWasAliased;
	NSString		* theResolvedAlias = nil;;

	[self getFSRef:&theRef];

	if( (FSResolveAliasFile( &theRef, YES, &theIsTargetFolder, &theWasAliased ) == noErr) )
	{
		theResolvedAlias = (theWasAliased) ? [NSString stringWithFSRef:&theRef] : self;
	}

	return theResolvedAlias ? theResolvedAlias : self;
}

/*
 * +stringWithPascalString:encoding:
 */
+ (NSString *)stringWithPascalString:(const ConstStr255Param )aPStr
{
	return (NSString*)CFStringCreateWithPascalString( kCFAllocatorDefault, aPStr, kCFStringEncodingMacRoman );
}

/*
 * -getPascalString:length:
 */
- (BOOL)getPascalString:(StringPtr)aBuffer length:(short)aLength
{
	return CFStringGetPascalString( (CFStringRef)self, aBuffer, aLength, kCFStringEncodingMacRoman) != 0;
}

/*
 * -pascalString
 */
- (const char *)pascalString
{
	const unsigned int	kPascalStringLen = 256;
	NSMutableData		* theData = [NSMutableData dataWithCapacity:kPascalStringLen];
	return [self getPascalString:(StringPtr)[theData mutableBytes] length:kPascalStringLen] ? [theData bytes] : NULL;
}

/*
 * -trimWhitespace
 */
- (NSString *)trimWhitespace
{
	CFMutableStringRef 		theString;

	theString = CFStringCreateMutableCopy( kCFAllocatorDefault, 0, (CFStringRef)self);
	CFStringTrimWhitespace( theString );

	return (NSMutableString *)theString;
}

/*
 * -getFinderInfoFlags:type:creator:
 */
- (BOOL)getFinderInfoFlags:(UInt16*)outFlags type:(OSType*)outType creator:(OSType*)outCreator
{
	FSRef					theRef;
	struct FSCatalogInfo	theInfo;

	if( [self getFSRef:&theRef] && (FSGetCatalogInfo( &theRef, kFSCatInfoFinderInfo, &theInfo, /*outName*/ NULL, /*fsSpec*/ NULL, /*parentRef*/ NULL) == noErr) )
	{
		struct FileInfo *finderInfo = (struct FileInfo *)&(theInfo.finderInfo);

		if( outFlags )   *outFlags   = finderInfo->finderFlags;
		if( outType )    *outType    = finderInfo->fileType;
		if( outCreator ) *outCreator = finderInfo->fileCreator;

		return YES;
	}
	else
		return NO;
}

/*
 * -finderLocation
 */
- (NSPoint)finderLocation
{
	FSRef					 theRef;
	struct FSCatalogInfo	 theInfo;
	NSPoint					 thePoint = { 0, 0 };

	if( [self getFSRef:&theRef] && (FSGetCatalogInfo( &theRef, kFSCatInfoFinderInfo, &theInfo, /*outName*/ NULL, /*fsSpec*/ NULL, /*parentRef*/ NULL) == noErr) )
	{
		struct FileInfo	*finderInfo = (struct FileInfo *)&(theInfo.finderInfo);
		thePoint = NSMakePoint(finderInfo->location.h, finderInfo->location.v);
 	}

	return thePoint;
}

/*
 * -setFinderInfoFlags:mask:type:creator:
 */
- (BOOL)setFinderInfoFlags:(UInt16)aFlags mask:(UInt16)aMask type:(OSType)aType creator:(OSType)aCreator
{
	BOOL  theResult = NO;

	FSRef theRef;
	if([self getFSRef:&theRef]) {
		struct FSCatalogInfo	 catalogInfo;
		struct FileInfo			*finderInfo = (struct FileInfo *)&(catalogInfo.finderInfo);
		struct FSRefParam		 pb = {
			.ref = &theRef,
			.whichInfo = kFSCatInfoFinderInfo,
			.catInfo = &catalogInfo,
			.spec = NULL,
			.parentRef = NULL,
			.outName = NULL,
		};
		if(PBGetCatalogInfoSync(&pb) == noErr) {
			finderInfo->finderFlags = (aFlags & aMask) | (finderInfo->finderFlags & !aMask);
			finderInfo->fileType    = aType;
			finderInfo->fileCreator = aCreator;

			theResult = (PBSetCatalogInfoSync(&pb) == noErr);
		}
	}

	return theResult;
}

/*
 * -setFinderLocation:
 */
- (BOOL)setFinderLocation:(NSPoint)aLocation
{
	BOOL  theResult = NO;
	
	FSRef theRef;
	if([self getFSRef:&theRef]) {
		struct FSCatalogInfo	 catalogInfo;
		struct FileInfo			*finderInfo = (struct FileInfo *)&(catalogInfo.finderInfo);
		struct FSRefParam		 pb = {
			.ref = &theRef,
			.whichInfo = kFSCatInfoFinderInfo,
			.catInfo = &catalogInfo,
			.spec = NULL,
			.parentRef = NULL,
			.outName = NULL,
		};
		if(PBGetCatalogInfoSync(&pb) == noErr) {
			finderInfo->location.h = aLocation.x;
			finderInfo->location.v = aLocation.y;
			
			theResult = (PBSetCatalogInfoSync(&pb) == noErr);
		}
	}
	
	return theResult;
}

@end





