/*
 Copyright (c) 2001, Blackhole Media
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list
 of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this
 list of conditions and the following disclaimer in the documentation and/or other
 materials provided with the distribution.
 * Neither the name of Blackhole Media nor the names of its contributors may be
 used to endorse or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANYWAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE. 
 
 ---
 
 English non-authoritative interpretation of the license:
 
 This is pretty much the BSD license. This means you can take the source and do
 whatever you please with it. While it is not a requirement of the license, we
 would appreciate a mention in the credits of your application if you use our
 source.
*/
/*
 Source modified and trimmed by Adam Iser <adamiser@mac.com>
 */

#include "pxmLib.h"

static UInt32	_HardMaskSize( pxmRef inRef );
static UInt32	_PixelDataSize( pxmRef inRef );
static void*	_GetPixelDataLoc( pxmRef inRef, UInt32 imageIndex );
static pxmErr	_Render32( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS );
static CTabPtr	_DefaultCLUT();

pxmRef
pxmCreate( void* data, UInt32 inSize )
{
	pxmRef	newPxmRef;
	
	if( data == NULL || inSize == 0 )
		return NULL;
	
	newPxmRef = (pxmRef)NewPtr(inSize);
	if( newPxmRef == NULL )
		return NULL;
	BlockMoveData( data, newPxmRef, inSize );
	
	if( newPxmRef->pixelType == pxmTypeIndexed || ( newPxmRef->pixelType == pxmTypeDefault && newPxmRef->pixelSize == 8 ) )
		newPxmRef->clutAddr = _DefaultCLUT();
	
	return newPxmRef;
}

pxmErr
pxmDispose( pxmRef inRef )
{
	if( inRef == NULL )
		return pxmErrBadParams;
	
	if( inRef->clutAddr != _DefaultCLUT() )
		DisposePtr( (Ptr)inRef->clutAddr );
	
	DisposePtr( (Ptr)inRef );
	return pxmErrNone;
}

#pragma mark -

UInt32
pxmSize( pxmRef inRef )
{
	return pxmDataSize + _HardMaskSize(inRef) + _PixelDataSize(inRef);
}

pxmErr
pxmBounds( pxmRef inRef, Rect* outRect )
{
	if( inRef == NULL || outRect == NULL )
		return pxmErrBadParams;
	
	*outRect = inRef->bounds;
	return pxmErrNone;
}

bool
pxmHasAlpha( pxmRef inRef )
{
	if( inRef )
		return inRef->hasAlpha;
	return NULL;
}

UInt16
pxmPixelSize( pxmRef inRef )
{
	if( inRef )
		return inRef->pixelSize;
	return 0;
}

UInt16
pxmPixelType( pxmRef inRef )
{
	if( inRef )
		return inRef->pixelType;
	return 0;
}

UInt16
pxmImageCount( pxmRef inRef )
{
	if( inRef )
		return inRef->imageCount;
	return 0;
}

bool
pxmIsMultiMask( pxmRef inRef )
{
	if( inRef )
		return inRef->maskCount == pxmMultiMask;
	return false;
}

#pragma mark -

pxmErr
pxmMakeGWorld( pxmRef inRef, GWorldPtr* outGWorld )
{
	OSStatus	status;
	
	if( inRef == NULL )
		return pxmErrBadParams;
	
	status = NewGWorld( outGWorld, 32, &inRef->bounds, NULL, NULL, 0 );
	if( status ){ *outGWorld = NULL; return pxmErrMemFull; }
	
	return pxmErrNone;
}

#pragma mark -

pxmErr
pxmRenderImage( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS )
{
	if( inRef == NULL  || inOS == NULL )
		return pxmErrBadParams;
	
	if( imageIndex >= inRef->imageCount )
		return pxmErrBadIndex;
	
	if( inRef->pixelType == pxmTypeDirect32 )
		return _Render32( inRef, imageIndex, inOS );
	
	if( inRef->pixelType == pxmTypeDirect16 )
		return _Render32( inRef, imageIndex, inOS );
	
	if( inRef->pixelType == pxmTypeIndexed || ( inRef->pixelType == pxmTypeDefault && inRef->pixelSize == 8 ) )
		return _Render32( inRef, imageIndex, inOS );
	
	return pxmErrBadDepth;
}

#pragma mark -

UInt32
_HardMaskSize( pxmRef inRef )
{
	UInt32		out;
	UInt32		a;
	UInt32		b;
	
	a = inRef->bounds.right >> 4;
	b = ((inRef->bounds.right & 0x000F) != 0);
	out = (a + b) * 2;
	
	out = out * inRef->bounds.bottom;
	a = inRef->maskCount ? 1 : (inRef->imageCount);
	out = out * a;
	
	return out;
}

UInt32
_PixelDataSize( pxmRef inRef )
{
	return inRef->bounds.right * inRef->bounds.bottom * (4) * inRef->imageCount;
	return inRef->bounds.right * inRef->bounds.bottom * (inRef->pixelSize/8) * inRef->imageCount;
}

void*
_GetPixelDataLoc( pxmRef inRef, UInt32 imageIndex )
{
	char*	out = (char*)inRef;
	
	out += pxmDataSize;
	out += _HardMaskSize(inRef);
//	out += inRef->bounds.right * inRef->bounds.bottom * ( inRef->pixelSize / 8 ) * imageIndex;
	out += inRef->bounds.right * inRef->bounds.bottom * ( 4 ) * imageIndex;
	
	return out;
}

#pragma mark -

pxmErr
_Render32( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS )
{
	UInt16		dstRB;
	UInt32*		dstBA;
	UInt16		srcRL;
	UInt32*		srcBA;
	UInt32		i, j;
	
	LockPixels(GetGWorldPixMap(inOS));
	
	dstBA = (UInt32*)GetPixBaseAddr(GetGWorldPixMap(inOS));
	dstRB = GetPixRowBytes(GetGWorldPixMap(inOS));
	srcBA = (UInt32*)_GetPixelDataLoc( inRef, imageIndex );
	srcRL = inRef->bounds.right;
	
	for( i = 0; i < inRef->bounds.bottom; i++ )
	{
		for( j = 0; j < inRef->bounds.right; j++ )
		    dstBA[j] = srcBA[j];
		
		srcBA += srcRL;
		dstBA = (UInt32*)((UInt8*)dstBA + dstRB);
	}
	
	UnlockPixels(GetGWorldPixMap(inOS));
	return pxmErrNone;
}

CTabPtr
_DefaultCLUT()
{
	return NULL;
}
