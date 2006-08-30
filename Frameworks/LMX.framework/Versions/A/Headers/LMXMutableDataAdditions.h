/*
 *	LMXMutableDataAdditions.h
 *	LMX
 *
 *	Created by Mac-arena the Bored Zo on 2005-10-23.
 *	Copyright 2005 Mac-arena the Bored Zo. All rights reserved.
 */

@interface NSMutableData (LMXMutableDataAdditions)

//insert the given data before all the bytes in the receiver.
- (void)prependData:(NSData *)data;

@end
