/*
 *  NSAppleEventDescriptor+NDDebugging.m category
 *  NDAppleScriptObject
 *
 *  Created by Nathan Day on 16/12/04.
 *  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
 */

#import "NSAppleEventDescriptor+NDDebugging.h"
#import "NSAppleEventDescriptor+NDAppleScriptObject.h"
#import "NSString+NDUtilities.h"

#define STRINGFORFOURCHARCODE( XXXX ) case XXXX: return [NSString stringWithCString: #XXXX]
	//#define STRINGFORFOURCHARCODE( XXXX ) case XXXX: return @ ## #XXXX
#define DUALSTRINGFORFOURCHARCODE( XXXX, YYYY ) case XXXX: return [NSString stringWithFormat:@"%s/%s", #XXXX, #YYYY ];
	
@implementation NSAppleEventDescriptor (NDDebugging)

NSString * displayStringForType( OSType aType );
NSString * displayStringForASKeyWord( AEKeyword aType );
NSString * displayStringForAEKeyWord( AEKeyword aType );

- (NSString *)description
{
	OSType		theType = [self descriptorType];
	NSString		* theDescription = nil;
	switch(theType)
	{
		case typeBoolean:						//	1-byte Boolean value
		case typeShortInteger:				//	16-bit integer
		case typeLongInteger:				//	32-bit integer
		case typeShortFloat:					//	SANE single
		case typeFloat:						//	SANE double
		case typeMagnitude:					//	unsigned 32-bit integer
		case typeTrue:							//	TRUE Boolean value
		case typeFalse:						//	FALSE Boolean value
//		case typeChar:							//	unterminated string
		case typeAlias:						//	alias record
		case typeFileURL:
		case cScript:							// script data
		case cEventIdentifier:
			theDescription = [NSString stringWithFormat:@"<%@>%@", displayStringForType(theType), [self objectValue]];
			break;
		case typeText:							//	unterminated string
		case kTXNUnicodeTextData:			//	unicode string
			theDescription = [NSString stringWithFormat:@"<%@>\"%@\"", displayStringForType(theType), [self objectValue]];
			break;
		case typeType:
			theDescription = [NSString stringWithFormat:@"<typeType>%@", NSFileTypeForHFSTypeCode( *(OSType*)[[self data] bytes])];
			break;
		case typeEnumerated:
			theDescription = [NSString stringWithFormat:@"<typeEnumerated>%@", NSFileTypeForHFSTypeCode( *(OSType*)[[self data] bytes])];
			break;
		case typeAEList:						//	list of descriptor records
		{
			SInt32						theNumOfItems,
											theIndex;
			NSMutableString			* theString;

			theNumOfItems = [self numberOfItems];
			theString = [NSMutableString stringWithString:@"<typeAEList>( "];

			for( theIndex = 1; theIndex < theNumOfItems; theIndex++)
			{
				[theString appendFormat:@"%@, ", [self descriptorAtIndex:theIndex]];
			}
			[theString appendFormat:@"%@ )", [self descriptorAtIndex:theNumOfItems]];
			theDescription = theString;
			break;
		}
		case typeAERecord:					//	list of keyword-specified
		{
			unsigned int		theIndex,
									theNumOfItems = [self numberOfItems];
			NSMutableString	* theString = [NSMutableString stringWithString:@"<typeAERecord>{\n"];

			for( theIndex = 1; theIndex <= theNumOfItems; theIndex++)
			{
				AEKeyword		theKeyWord = [self keywordForDescriptorAtIndex:theIndex];
				[theString appendFormat:@"\t%@ = %@;\n", displayStringForAEKeyWord( theKeyWord ), [self descriptorForKeyword:theKeyWord]];
			}
			[theString appendString:@"}\n" ];
			theDescription = theString;
			break;
		}
		case typeNull:
			theDescription = @"<typeNull>null";
			break;
		case keyProcessSerialNumber:
		{
			ProcessSerialNumber		* theProcessSN = (ProcessSerialNumber*)[self data];
			theDescription = [NSString stringWithFormat:@"<keyProcessSerialNumber>0x%x %x", theProcessSN->highLongOfPSN, theProcessSN->lowLongOfPSN ];
			break;
		}
		case cObjectSpecifier:
		{
			NSMutableString		* theString;
			unsigned int			theIndex;
			AEKeyword			theDescKeys[] = { keyAEDesiredClass, keyAEContainer, keyAEKeyForm, keyAEKeyData, 0 };
			char					* theDescKeyStr[] = { "keyAEDesiredClass", "keyAEContainer", "keyAEKeyForm", "keyAEKeyData", NULL };
			theString = [NSMutableString stringWithFormat:@"<cObjectSpecifier>\n{\n"];
			for( theIndex = 0; theDescKeys[theIndex] != 0; theIndex++ )
			{
				NSString		* theDescString = [[[self descriptorForKeyword:theDescKeys[theIndex]] description] stringByReplacingString:@"\n" withString:@"\n\t"];
				[theString appendFormat:@"\t%s = %@;\n", theDescKeyStr[theIndex], theDescString];
			}
			[theString appendString:@"}"];
			theDescription = theString;
			break;
		}
		case typeAppleEvent:
		{
			int	theIndex,
			theNumberOfItems = [self numberOfItems];
			NSMutableString		* theString;
			AEKeyword			theAttKeys[] = { keyEventClassAttr, keyEventIDAttr, keyTransactionIDAttr, keyReturnIDAttr, keyAddressAttr, keyOptionalKeywordAttr, keyTimeoutAttr, keyInteractLevelAttr, keyEventSourceAttr, keyMissedKeywordAttr, keyOriginalAddressAttr, keyAcceptTimeoutAttr, 0 };
			theString = [NSMutableString stringWithString:@"<typeAppleEvent>{\nattributes\n"];
			
			for( theIndex = 0; theAttKeys[theIndex] != 0; theIndex++ )
			{
				NSAppleEventDescriptor		* theAtt = [self attributeDescriptorForKeyword:theAttKeys[theIndex]];
				if( theAtt )
					[theString appendFormat:@"\t%@ = %@;\n", displayStringForAEKeyWord(theAttKeys[theIndex]), theAtt];
			}

			[theString appendString:@"\nparameters\n" ];
			for( theIndex = 1; theIndex <= theNumberOfItems; theIndex++ )
			{
				AEKeyword		theKeyWord = [self keywordForDescriptorAtIndex:theIndex];
				[theString appendFormat:@"\t%@ = %@;\n", displayStringForAEKeyWord( theKeyWord ), [self descriptorForKeyword:theKeyWord]];
			}
			[theString appendString:@"}\n"];
			theDescription = theString;
		}
			break;
		default:
			theDescription = [NSString stringWithFormat:@"<%@>[%@]", NSFileTypeForHFSTypeCode(theType), [self data]];
			break;
	}
	return theDescription;
}

NSString * displayStringForType( OSType aType )
{
	switch( aType )
	{
		STRINGFORFOURCHARCODE( typeBoolean );
		STRINGFORFOURCHARCODE( typeShortInteger );
		STRINGFORFOURCHARCODE( typeLongInteger );
		STRINGFORFOURCHARCODE( typeShortFloat );
		STRINGFORFOURCHARCODE( typeFloat );
		STRINGFORFOURCHARCODE( typeMagnitude );
		STRINGFORFOURCHARCODE( typeTrue );
		STRINGFORFOURCHARCODE( typeFalse );
		STRINGFORFOURCHARCODE( typeEnumerated );
		STRINGFORFOURCHARCODE( typeText );
		STRINGFORFOURCHARCODE( kTXNUnicodeTextData );
		STRINGFORFOURCHARCODE( typeAEList );
		STRINGFORFOURCHARCODE( typeAERecord );
		STRINGFORFOURCHARCODE( typeAlias );
		STRINGFORFOURCHARCODE( typeFileURL );
		STRINGFORFOURCHARCODE( cScript );
		STRINGFORFOURCHARCODE( cEventIdentifier );
		STRINGFORFOURCHARCODE( typeNull );
		STRINGFORFOURCHARCODE( keyProcessSerialNumber );
		STRINGFORFOURCHARCODE( cObjectSpecifier );
		STRINGFORFOURCHARCODE( typeAppleEvent );
		STRINGFORFOURCHARCODE( typeType );
		STRINGFORFOURCHARCODE( typeProperty );
		default: return NSFileTypeForHFSTypeCode(aType);
	}
}

NSString * displayStringForASKeyWord( AEKeyword aType )
{
	switch( aType )
	{
		STRINGFORFOURCHARCODE( keyASReturning );
		STRINGFORFOURCHARCODE( keyASSubroutineName );
		STRINGFORFOURCHARCODE( keyASPositionalArgs );
		STRINGFORFOURCHARCODE( keyASArg );
		STRINGFORFOURCHARCODE( keyASUserRecordFields );
		STRINGFORFOURCHARCODE( keyASPrepositionAt );
		STRINGFORFOURCHARCODE( keyASPrepositionIn );
		STRINGFORFOURCHARCODE( keyASPrepositionFrom );
		STRINGFORFOURCHARCODE( keyASPrepositionFor );
		STRINGFORFOURCHARCODE( keyASPrepositionTo );
		STRINGFORFOURCHARCODE( keyASPrepositionThru );
		STRINGFORFOURCHARCODE( keyASPrepositionThrough );
		STRINGFORFOURCHARCODE( keyASPrepositionBy );
		STRINGFORFOURCHARCODE( keyASPrepositionOn );
		STRINGFORFOURCHARCODE( keyASPrepositionInto );
		STRINGFORFOURCHARCODE( keyASPrepositionOnto );
		STRINGFORFOURCHARCODE( keyASPrepositionBetween );
		STRINGFORFOURCHARCODE( keyASPrepositionAgainst );
		STRINGFORFOURCHARCODE( keyASPrepositionOutOf );
		STRINGFORFOURCHARCODE( keyASPrepositionInsteadOf );
		STRINGFORFOURCHARCODE( keyASPrepositionAsideFrom );
		STRINGFORFOURCHARCODE( keyASPrepositionAround );
		STRINGFORFOURCHARCODE( keyASPrepositionBeside );
		STRINGFORFOURCHARCODE( keyASPrepositionBeneath );
		STRINGFORFOURCHARCODE( keyASPrepositionUnder );
		STRINGFORFOURCHARCODE( keyASPrepositionOver );
		STRINGFORFOURCHARCODE( keyASPrepositionAbove );
		STRINGFORFOURCHARCODE( keyASPrepositionBelow );
		STRINGFORFOURCHARCODE( keyASPrepositionApartFrom );
		STRINGFORFOURCHARCODE( keyASPrepositionGiven );
		STRINGFORFOURCHARCODE( keyASPrepositionWith );
		STRINGFORFOURCHARCODE( keyASPrepositionWithout );
		STRINGFORFOURCHARCODE( keyASPrepositionAbout );
		STRINGFORFOURCHARCODE( keyASPrepositionSince );
		STRINGFORFOURCHARCODE( keyASPrepositionUntil );
		STRINGFORFOURCHARCODE( keyAEDesiredClass );
		STRINGFORFOURCHARCODE( keyAEKeyForm );
		STRINGFORFOURCHARCODE( keyAEKeyData );
		default: return NSFileTypeForHFSTypeCode(aType);
	}
}

NSString * displayStringForAEKeyWord( AEKeyword aType )
{
	switch( aType )
	{
		DUALSTRINGFORFOURCHARCODE( keyDirectObject, keyAEResult );
		STRINGFORFOURCHARCODE( keyErrorNumber );
		STRINGFORFOURCHARCODE( keyErrorString );
		STRINGFORFOURCHARCODE( keyProcessSerialNumber );
		STRINGFORFOURCHARCODE( keyPreDispatch );
		STRINGFORFOURCHARCODE( keySelectProc );
		STRINGFORFOURCHARCODE( keyAERecorderCount );
		STRINGFORFOURCHARCODE( keyAEVersion );

		STRINGFORFOURCHARCODE( keyAEAngle );
		STRINGFORFOURCHARCODE( keyAEArcAngle );
		STRINGFORFOURCHARCODE( keyAEBaseAddr );
		STRINGFORFOURCHARCODE( keyAEBestType );
		STRINGFORFOURCHARCODE( keyAEBgndColor );
		STRINGFORFOURCHARCODE( keyAEBgndPattern );
		STRINGFORFOURCHARCODE( keyAEBounds );
		STRINGFORFOURCHARCODE( keyAECellList );
		STRINGFORFOURCHARCODE( keyAEClassID );
		STRINGFORFOURCHARCODE( keyAEColor );
		STRINGFORFOURCHARCODE( keyAEColorTable );
		STRINGFORFOURCHARCODE( keyAECurveHeight );
		STRINGFORFOURCHARCODE( keyAECurveWidth );
		STRINGFORFOURCHARCODE( keyAEDashStyle );
		STRINGFORFOURCHARCODE( keyAEData );
		STRINGFORFOURCHARCODE( keyAEDefaultType );
		STRINGFORFOURCHARCODE( keyAEDefinitionRect );
		STRINGFORFOURCHARCODE( keyAEDescType );
		STRINGFORFOURCHARCODE( keyAEDestination );
		STRINGFORFOURCHARCODE( keyAEDoAntiAlias );
		STRINGFORFOURCHARCODE( keyAEDoDithered );
		STRINGFORFOURCHARCODE( keyAEDoRotate );
		STRINGFORFOURCHARCODE( keyAEDoScale );
		STRINGFORFOURCHARCODE( keyAEDoTranslate );
		STRINGFORFOURCHARCODE( keyAEEditionFileLoc );
		STRINGFORFOURCHARCODE( keyAEElements );
		STRINGFORFOURCHARCODE( keyAEEndPoint );
		DUALSTRINGFORFOURCHARCODE( keyAEEventClass, keyEventClassAttr );
		STRINGFORFOURCHARCODE( keyAEEventID );
		STRINGFORFOURCHARCODE( keyAEFile );
		STRINGFORFOURCHARCODE( keyAEFileType );
		STRINGFORFOURCHARCODE( keyAEFillColor );
		STRINGFORFOURCHARCODE( keyAEFillPattern );
		STRINGFORFOURCHARCODE( keyAEFlipHorizontal );
		STRINGFORFOURCHARCODE( keyAEFlipVertical );
		STRINGFORFOURCHARCODE( keyAEFont );
		STRINGFORFOURCHARCODE( keyAEFormula );
		STRINGFORFOURCHARCODE( keyAEGraphicObjects );
		STRINGFORFOURCHARCODE( keyAEID );
		STRINGFORFOURCHARCODE( keyAEImageQuality );
		STRINGFORFOURCHARCODE( keyAEInsertHere );
		STRINGFORFOURCHARCODE( keyAEKeyForms );
		STRINGFORFOURCHARCODE( keyAEKeyword );
		STRINGFORFOURCHARCODE( keyAELevel );
		STRINGFORFOURCHARCODE( keyAELineArrow );
		STRINGFORFOURCHARCODE( keyAEName );
		STRINGFORFOURCHARCODE( keyAENewElementLoc );
		STRINGFORFOURCHARCODE( keyAEObject );
		STRINGFORFOURCHARCODE( keyAEObjectClass );
//		STRINGFORFOURCHARCODE( keyAEOffStyles, keyAEOffset );
		STRINGFORFOURCHARCODE( keyAEOnStyles );
		STRINGFORFOURCHARCODE( keyAEParameters );
		STRINGFORFOURCHARCODE( keyAEParamFlags );
		STRINGFORFOURCHARCODE( keyAEPenColor );
		STRINGFORFOURCHARCODE( keyAEPenPattern );
		STRINGFORFOURCHARCODE( keyAEPenWidth );
		STRINGFORFOURCHARCODE( keyAEPixelDepth );
		STRINGFORFOURCHARCODE( keyAEPixMapMinus );
		STRINGFORFOURCHARCODE( keyAEPMTable );
		STRINGFORFOURCHARCODE( keyAEPointList );
		STRINGFORFOURCHARCODE( keyAEPointSize );
		STRINGFORFOURCHARCODE( keyAEPosition );
		STRINGFORFOURCHARCODE( keyAEPropData );
		STRINGFORFOURCHARCODE( keyAEProperties );
		STRINGFORFOURCHARCODE( keyAEProperty );
		STRINGFORFOURCHARCODE( keyAEPropFlags );
		STRINGFORFOURCHARCODE( keyAEPropID );
		STRINGFORFOURCHARCODE( keyAEProtection );
		STRINGFORFOURCHARCODE( keyAERenderAs );
		STRINGFORFOURCHARCODE( keyAERequestedType );
//		STRINGFORFOURCHARCODE( keyAEResult );
		STRINGFORFOURCHARCODE( keyAEResultInfo );
		STRINGFORFOURCHARCODE( keyAERotation );
		STRINGFORFOURCHARCODE( keyAERotPoint );
		STRINGFORFOURCHARCODE( keyAERowList );
		STRINGFORFOURCHARCODE( keyAESaveOptions );
		STRINGFORFOURCHARCODE( keyAEScale );
		STRINGFORFOURCHARCODE( keyAEScriptTag );
		STRINGFORFOURCHARCODE( keyAEShowWhere );
		STRINGFORFOURCHARCODE( keyAEStartAngle );
		STRINGFORFOURCHARCODE( keyAEStartPoint );
		STRINGFORFOURCHARCODE( keyAEStyles );
		STRINGFORFOURCHARCODE( keyAESuiteID );
		STRINGFORFOURCHARCODE( keyAEText );
		STRINGFORFOURCHARCODE( keyAETextColor );
		STRINGFORFOURCHARCODE( keyAETextFont );
		STRINGFORFOURCHARCODE( keyAETextPointSize );
		STRINGFORFOURCHARCODE( keyAETextStyles );
		STRINGFORFOURCHARCODE( keyAETextLineHeight );
		STRINGFORFOURCHARCODE( keyAETextLineAscent );
		STRINGFORFOURCHARCODE( keyAETheText );
		STRINGFORFOURCHARCODE( keyAETransferMode );
		STRINGFORFOURCHARCODE( keyAETranslation );
		STRINGFORFOURCHARCODE( keyAETryAsStructGraf );
		STRINGFORFOURCHARCODE( keyAEUniformStyles );
		STRINGFORFOURCHARCODE( keyAEUpdateOn );
		STRINGFORFOURCHARCODE( keyAEUserTerm );
		STRINGFORFOURCHARCODE( keyAEWindow );
		STRINGFORFOURCHARCODE( keyAEWritingCode );
		STRINGFORFOURCHARCODE( keyAETSMDocumentRefcon );
		STRINGFORFOURCHARCODE( keyAEServerInstance );
		STRINGFORFOURCHARCODE( keyAETheData );
		STRINGFORFOURCHARCODE( keyAEFixLength );
		STRINGFORFOURCHARCODE( keyAEUpdateRange );
		STRINGFORFOURCHARCODE( keyAECurrentPoint );
		STRINGFORFOURCHARCODE( keyAEBufferSize );
		STRINGFORFOURCHARCODE( keyAEMoveView );
		STRINGFORFOURCHARCODE( keyAENextBody );
		STRINGFORFOURCHARCODE( keyAETSMScriptTag );
		STRINGFORFOURCHARCODE( keyAETSMTextFont );
		STRINGFORFOURCHARCODE( keyAETSMTextFMFont );
		STRINGFORFOURCHARCODE( keyAETSMTextPointSize );
		STRINGFORFOURCHARCODE( keyAETSMEventRecord );
		STRINGFORFOURCHARCODE( keyAETSMEventRef );
		STRINGFORFOURCHARCODE( keyAETextServiceEncoding );
		STRINGFORFOURCHARCODE( keyAETextServiceMacEncoding );
		STRINGFORFOURCHARCODE( keyAETSMGlyphInfoArray );
		STRINGFORFOURCHARCODE( keyAEHiliteRange );
		STRINGFORFOURCHARCODE( keyAEPinRange );
		STRINGFORFOURCHARCODE( keyAEClauseOffsets );
//		STRINGFORFOURCHARCODE( keyAEOffset );
		STRINGFORFOURCHARCODE( keyAEPoint );
		STRINGFORFOURCHARCODE( keyAELeftSide );
		STRINGFORFOURCHARCODE( keyAERegionClass );
		STRINGFORFOURCHARCODE( keyAEDragging );

		STRINGFORFOURCHARCODE( keyAECompOperator );
		STRINGFORFOURCHARCODE( keyAELogicalTerms );
		STRINGFORFOURCHARCODE( keyAELogicalOperator );
		STRINGFORFOURCHARCODE( keyAEObject1 );
		STRINGFORFOURCHARCODE( keyAEObject2 );
		STRINGFORFOURCHARCODE( keyAEDesiredClass );
		DUALSTRINGFORFOURCHARCODE( keyAEContainer, keyOriginalAddressAttr );
		STRINGFORFOURCHARCODE( keyAEKeyForm );
		STRINGFORFOURCHARCODE( keyAEKeyData );
		STRINGFORFOURCHARCODE( keyAERangeStart );
		STRINGFORFOURCHARCODE( keyAERangeStop );
		STRINGFORFOURCHARCODE( keyAECompareProc );
		STRINGFORFOURCHARCODE( keyAECountProc );
		STRINGFORFOURCHARCODE( keyAEMarkTokenProc );
		STRINGFORFOURCHARCODE( keyAEMarkProc );
		STRINGFORFOURCHARCODE( keyAEAdjustMarksProc );
		STRINGFORFOURCHARCODE( keyAEGetErrDescProc );

		STRINGFORFOURCHARCODE( keyAEWhoseRangeStart );
		STRINGFORFOURCHARCODE( keyAEWhoseRangeStop );
		STRINGFORFOURCHARCODE( keyAEIndex );
		STRINGFORFOURCHARCODE( keyAETest );
		STRINGFORFOURCHARCODE( typeKeyword );
		STRINGFORFOURCHARCODE( keyTransactionIDAttr );
		STRINGFORFOURCHARCODE( keyReturnIDAttr );
//		STRINGFORFOURCHARCODE( keyEventClassAttr );
		STRINGFORFOURCHARCODE( keyEventIDAttr );
		STRINGFORFOURCHARCODE( keyAddressAttr );
		STRINGFORFOURCHARCODE( keyOptionalKeywordAttr );
		STRINGFORFOURCHARCODE( keyTimeoutAttr );
		STRINGFORFOURCHARCODE( keyInteractLevelAttr );
		STRINGFORFOURCHARCODE( keyEventSourceAttr );
		STRINGFORFOURCHARCODE( keyMissedKeywordAttr );
//		STRINGFORFOURCHARCODE( keyOriginalAddressAttr );
		STRINGFORFOURCHARCODE( keyAcceptTimeoutAttr );

		STRINGFORFOURCHARCODE( keyUserNameAttr );
		STRINGFORFOURCHARCODE( keyUserPasswordAttr );
		STRINGFORFOURCHARCODE( keyDisableAuthenticationAttr );
		STRINGFORFOURCHARCODE( keyXMLDebuggingAttr );
		STRINGFORFOURCHARCODE( keyRPCMethodName );
		STRINGFORFOURCHARCODE( keyRPCMethodParam );
		STRINGFORFOURCHARCODE( keyRPCMethodParamOrder );

		STRINGFORFOURCHARCODE( keyAEPOSTHeaderData );
		STRINGFORFOURCHARCODE( keyAEReplyHeaderData );
		STRINGFORFOURCHARCODE( keyAEXMLRequestData );
		STRINGFORFOURCHARCODE( keyAEXMLReplyData );
		STRINGFORFOURCHARCODE( keyAdditionalHTTPHeaders );
		STRINGFORFOURCHARCODE( keySOAPAction );
		STRINGFORFOURCHARCODE( keySOAPMethodNameSpace );
		STRINGFORFOURCHARCODE( keySOAPMethodNameSpaceURI );
		STRINGFORFOURCHARCODE( keySOAPSchemaVersion );
		STRINGFORFOURCHARCODE( keySOAPStructureMetaData );
		STRINGFORFOURCHARCODE( keySOAPSMDNamespace );
		STRINGFORFOURCHARCODE( keySOAPSMDNamespaceURI );
		STRINGFORFOURCHARCODE( keySOAPSMDType );
		default: return displayStringForASKeyWord( aType );
	}
}

@end
