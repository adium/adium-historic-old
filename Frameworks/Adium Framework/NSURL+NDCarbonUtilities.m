/*
 *  NSURL+NDCarbonUtilities.m category
 *  AppleScriptObjectProject
 *
 *  Created by nathan on Wed Dec 05 2001.
 *  Copyright (c) 2001 __CompanyName__. All rights reserved.
 */

#import "NSURL+NDCarbonUtilities.h"

/*
 * category implementation NSURL (NDCarbonUtilities)
 */
@implementation NSURL (NDCarbonUtilities)

/*
 * +URLWithFSRef:
 */
+ (NSURL *)URLWithFSRef:(const FSRef *)aFsRef
{
	return [(NSURL *)CFURLCreateFromFSRef( kCFAllocatorDefault, aFsRef ) autorelease];
}

/*
 * +URLWithFileSystemPathHFSStyle:
 */
+ (NSURL *)URLWithFileSystemPathHFSStyle:(NSString *)aHFSString
{
	return [(NSURL *)CFURLCreateWithFileSystemPath( kCFAllocatorDefault, (CFStringRef)aHFSString, kCFURLHFSPathStyle, [aHFSString hasSuffix:@":"] ) autorelease];
}

/*
 * -getFSRef:
 */
- (BOOL)getFSRef:(FSRef *)aFsRef
{
	return CFURLGetFSRef( (CFURLRef)self, aFsRef ) != 0;
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
 * -URLByDeletingLastPathComponent
 */
- (NSURL *)URLByDeletingLastPathComponent
{
	return [(NSURL *)CFURLCreateCopyDeletingLastPathComponent( kCFAllocatorDefault, (CFURLRef)self) autorelease];
}

/*
 * -fileSystemPathHFSStyle
 */
- (NSString *)fileSystemPathHFSStyle
{
    return [(NSString *)CFURLCopyFileSystemPath((CFURLRef)self, kCFURLHFSPathStyle) autorelease];
}

/*
 * -resolveAliasFile
 */
- (NSURL *)resolveAliasFile
{
	FSRef			theRef;
	Boolean		theIsTargetFolder,
					theWasAliased;
	NSURL			* theResolvedAlias = nil;;

	[self getFSRef:&theRef];

	if( (FSResolveAliasFile ( &theRef, YES, &theIsTargetFolder, &theWasAliased ) == noErr) )
	{
		theResolvedAlias = (theWasAliased) ? [NSURL URLWithFSRef:&theRef] : self;
	}

	return theResolvedAlias;
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

@implementation NSURL (NDCarbonUtilitiesInfoFlags)

- (BOOL)hasCustomIcon
{
	UInt16	theFlags;
	return [self getFinderInfoFlags:&theFlags type:NULL creator:NULL] == YES && (theFlags & kHasCustomIcon) != 0;
}

@end
