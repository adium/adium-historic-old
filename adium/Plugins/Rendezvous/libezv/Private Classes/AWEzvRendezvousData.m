/*
 * Project:     Libezv
 * File:        AWEzvRendezvousData.h
 *
 * Version:     1.0
 * CVS tag:     $Id: AWEzvRendezvousData.m,v 1.3 2004/07/16 02:16:47 proton Exp $
 * Author:      Andrew Wellington <proton[at]wiretapped.net>
 *
 * License:
 * Copyright (C) 2004 Andrew Wellington.
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
 
#import "AWEzvRendezvousData.h"
#import "AWEzvSupportRoutines.h"

@implementation AWEzvRendezvousData

/* subnegotiation that appears at start of rendezvous packet */
/*                             Reserved version? */
NSString	*subn = @"subn\x00\x00\x00\x01";

/* end of subnegotation. significance of value unknown */
/*                        Reserved unknown       */
NSString	*endn = @"\x00\x00\x00\x00";

/* initialisation, create our dictionary */
-(AWEzvRendezvousData *) init {
    self = [super init];
    
    keys = [[NSMutableDictionary dictionary] retain];
    serial = 1;

    return self;
}

/* intialise given an NSData containing an announcement */
-(AWEzvRendezvousData *) initWithData:(NSData *)data {
    UInt32	version;	/* the version of the iChat announcement (?) */
    UInt32	fieldCount;	/* number of fields in the announcement */
    UInt16	fieldLen;	/* length of field being read */
    UInt32	i;		/* read index into data buffer */
    NSString	*fieldName;	/* name of field */
    NSString	*fieldContent;	/* contents of field */
    NSData	*tmpData;	/* temporary data */
    NSRange	range;		/* range for reading of data */

    /* call the standard initialisation */
    self = [self init];
    
    /* check that the length is ok */
    if ([data length] < ([subn length] + 4 + [endn length])) {
	AWEzvLog(@"Invalid rendezvous announcement: length %u", [data length]);
	return nil;
    }
        
    /* check version (?) of iChat announcement */
    range.location = 4;
    range.length = 4;
    [data getBytes:&version range:range];
    if (version != 1) {
	AWEzvLog(@"Invalid rendezvous announcement: incorrect version: %u", version);
	return nil;
    }
    
    /* get serial of announcement */
    range.location = 8;
    range.length = 4;
    [data getBytes:&serial range:range];
    
    /* get field count of data */
    range.location = 16;
    range.length = 4;
    [data getBytes:&fieldCount range:range];
    
    /* read fields from data */
    for (i = [subn length] + 4 + [endn length] + 4; i < [data length];) {
	int binFlag = 0;
	
	/* read length of field name */
	if ([data length] < i + 2) {
	    AWEzvLog(@"Invalid rendezvous announcement at field name length");
	    return nil;
	}
	range.location = i;
	range.length = 2;
	[data getBytes:&fieldLen range:range];
	fieldLen = fieldLen & 0x7FFF;
        i = i + 2;
        
	/* read field data */
	if ([data length] < i + fieldLen) {
	    AWEzvLog(@"Invalid rendezvous announcement at field name");
	    return nil;
	}
        tmpData = [NSData dataWithBytes:[data bytes] + i length:fieldLen];
	fieldName = [[[NSString alloc] initWithData:tmpData encoding:NSUTF8StringEncoding] autorelease];
	i = i + fieldLen;
	
	/* read length of field data */
	if ([data length] < i + 2) {
	    AWEzvLog(@"Invalid rendezvous announcement at field data length");
	    return nil;
	}
	range.location = i;
	range.length = 2;
	[data getBytes:&fieldLen range:range];
	/* most significant bit in fieldLen is a binary data flag */
	if ((fieldLen & 0x7FFF) != fieldLen)
	    binFlag = 1;
        fieldLen = fieldLen & 0x7FFF;
	i = i + 2;
	
	/* read field data */
	if ([data length] < i + fieldLen) {
	    AWEzvLog(@"Invalid rendezvous announcement at field data");
	    return nil;
	}
        if (!binFlag) {
            tmpData = [NSData dataWithBytes:[data bytes] + i length:fieldLen];
            fieldContent = [[[NSString alloc] initWithData:tmpData encoding:NSUTF8StringEncoding] autorelease];
        } else {
            fieldContent = [NSString stringWithCString:[data bytes] + i length:fieldLen];
        }
        i = i + fieldLen;
	
	/* save field information */
	[self setField:fieldName content:fieldContent];
    }
    
    /* return initialised object */
    return self;
}

/* intialise rendezvous data with a plist of the data */
-(AWEzvRendezvousData *) initWithPlist:(NSString *)plist {
    id		extracted;	/* extracted data from plist */
    NSData	*xmlData;	/* XML data in NSData form */
    NSString	*error;		/* error from conversion of plist */
    NSPropertyListFormat format;/* something we can point at for the format pointer */
    
    error = [NSString string];
    
    /* create XML data */
    xmlData = [NSData dataWithBytes:[plist UTF8String] length:[plist length]];

    /* extract plist from XML data */
    format = NSPropertyListXMLFormat_v1_0;
    extracted = [NSPropertyListSerialization
		    propertyListFromData:xmlData
		    mutabilityOption:NSPropertyListImmutable
		    format:&format
		    errorDescription:&error];

    /* check if there was an error in extraction */
    if (extracted == nil) {
	AWEzvLog(@"Unable to extract XML into plist");
	return nil;
    }
    
    /* make sure it's an NSData, or reponds to getBytes:range: */
    if (![extracted respondsToSelector:@selector(getBytes:range:)]) {
	AWEzvLog(@"Extracted object from XML is not an NSData");
	return nil;  
    }

    /* pass it to another initialiser */
    return [self initWithData:extracted];
}

/* initialise object with a dictionary */
- (AWEzvRendezvousData *)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    
    keys = [dictionary retain];
    serial++;
    
    return self;
}

/* initialise object with an AV TXT record */
- (AWEzvRendezvousData *)initWithAVTxt:(NSString *)txt {
    NSArray *attribs;
    NSEnumerator    *enumerator;
    NSString *key;
    
    self = [self init];
    
    attribs = [txt componentsSeparatedByString:@"\001"];
    enumerator = [attribs objectEnumerator];

    while ((key = [enumerator nextObject])) {
	NSRange range;
	
	range = [key rangeOfString:@"="];
	if (range.location != NSNotFound) {
	    [self setField:[key substringToIndex:range.location]
		   content:[key substringFromIndex:range.location+1]];
	}
    }
    
    return self;
}

/* deallocate, destroy our dictionary */
- (void)dealloc
{
	[keys release];
	[super dealloc];
}

/* sets a field in the rendezvous data structures */
-(void) setField:(NSString *)fieldName content:(NSObject *)content {
    if (content == nil || fieldName == nil)
        return;
    
    [keys setObject:content forKey:fieldName];
    serial++;
}

/* delete a field in the rendezvous data structure */
-(void) deleteField:(NSString *)fieldName {
    if ([keys objectForKey:fieldName] != nil)
        [keys removeObjectForKey:fieldName];
}

/* get a field from the rendezvous data structure */
-(NSString *) getField:(NSString *)fieldName {
    return [[[keys objectForKey:fieldName] copy] autorelease];
}

/* return if a field exists */
-(BOOL) fieldExists:(NSString *)fieldName {
    return [keys objectForKey:fieldName] != nil;
}

/* return the serial number of the data */
-(UInt32) serial {
    return serial;
}

/* return the dictionary */
-(NSDictionary *)dictionary {
    return [[keys copy] autorelease];
}

/*
 * Generate data to be placed in the protocolSpecificInformation (TXT record)
 * of the rendezvous announcement. This is data shouldn't be used directly, but
 * should be used indirectly via dataAsDNSTXT or dataAsPackedPString
 */
-(NSString *) data {
    NSMutableData   *data;		/* binary representation of rendezvous data */
    NSData	    *xmlData;		/* data converted to an XML plist */
    NSMutableString *infoData;		/* XML plist as a string */
    NSString *key;			/* strings used when manipulating data */
    id value;				/* value for data field */
    NSString	    *error;		/* error from creation of plist */
    UInt32	    keycount;		/* a 32-bit integer, count of keys in data */
    UInt16	    fieldlen;		/* a 16-bit integer, length of field being added to data */
    NSEnumerator    *enumerator;	/* enumerator to loop dict */

    /* allocate NSData to create data in */
    data = [[NSMutableData alloc] init];
    [data autorelease];
    /* add the subnegotiation string */
    [data appendBytes:[subn UTF8String] length:[subn length]];
    [data appendBytes:&serial length:4];
    [data appendBytes:[endn UTF8String] length:[endn length]];
    /* add a field containing the number of fields for the rest of the data */
    keycount = [keys count] + 1; /* +1 for slumming field */
    [data appendBytes:&keycount length:4];

    /* enumerator to loop through fields for announcement */
    enumerator = [keys keyEnumerator];

    /* loop through fields to be added and add them to data */
    while ((key = [enumerator nextObject])) {	    
	/* add length of field name, then field name */
	fieldlen = [key length];
	[data appendBytes:&fieldlen length:2];
	[data appendBytes:[key UTF8String] length:[key length]];
	
	/* add length of field data, then field data */
	value = [keys objectForKey:key];
	if ([value isKindOfClass: [NSData class]]) {
	    fieldlen = fieldlen | ~0x7FFF;
	} else {
	    fieldlen = strlen([(NSString *)value UTF8String]);
	}
	[data appendBytes:&fieldlen length:2];
	if ([value isKindOfClass: [NSData class]]) {
	    [data appendBytes:[value bytes] length:[(NSData *)value length]];
	} else {
	    [data appendBytes:[value UTF8String] length:strlen([value UTF8String])];
	}
    }
    
    /* we're slumming it in iChat-land */
    key = @"slumming";
    fieldlen = [key length];
    [data appendBytes:&fieldlen length:2];
    [data appendBytes:[key UTF8String] length:[key length]];
    value = @"1";
    fieldlen = [(NSData *)value length];
    [data appendBytes:&fieldlen length:2];
    [data appendBytes:[value UTF8String] length:[(NSData *)value length]];
    
    /* create XML plist of data and convert to string */
    xmlData = [NSPropertyListSerialization dataFromPropertyList:data
    				    format:NSPropertyListXMLFormat_v1_0
    				    errorDescription:&error];
    infoData = [[NSMutableString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding];
    [infoData autorelease];
	
    /* and now we have the rendezvous data to return to the caller, the copy
       converts it to immutable */
    return [[infoData copy] autorelease];
}

/* 
 * Converts data: to a format appropriate for passing to service registration.
 * We add an ASCII 1 character every 255 characters for pascal string separation
 */
-(NSString *)dataAsDNSTXT {
    NSMutableString	*infoData = [[[self data] mutableCopy] autorelease]; /* data to be done */
    unsigned long	i;	/* loop counter */

    /* add the character \001 when we exceed 255 characters, required to allow announcement
    to be longer than 255 characters */
    for (i = 255; i < [infoData length]; i += 255)
    {
	[infoData insertString:@"\001" atIndex:i];
    }

    /* return a copy so it is immutable */
    return [[infoData copy] autorelease];
}

/* ichat AV style TXT record */
-(NSString *)avDataAsDNSTXT {
    NSMutableString *infoData = [NSMutableString string];
    NSEnumerator    *enumerator;
    id value;
    NSString	    *key;
    
    [infoData appendString:@"\001txtvers=1"];
    [infoData appendString:@"\001version=1"];
    
    /* enumerator to loop through fields for announcement */
    enumerator = [keys keyEnumerator];
    
    while ((key = [enumerator nextObject])) {	    
	[infoData appendString:@"\001"];	
	[infoData appendString:key];
	[infoData appendString:@"="];
	value = [keys objectForKey:key];
	
	if ([value isKindOfClass: [NSData class]]) {
	    /* convert binary to hex */
	    char *hexdata = (char *)malloc([(NSData *)value length] * 2 + 1);
	    int i;
	    
	    for (i = 0; i < 20; i++) {
		sprintf(hexdata + (i*2), "%.2x", ((unsigned char *)[(NSData *)value bytes])[i]);
	    }
	    hexdata[[(NSData *)value length] * 2] = '\0';
	    
	    [infoData appendString:[NSString stringWithCString:hexdata]];
	} else {
	    [infoData appendString:value];
	}
    }
    
    return infoData;
}

/*
 * Converts data: to packed PString format as required by the low level rendezvous
 * functions when passing an opaque RData structure
 */
-(NSData *) dataAsPackedPString {
    NSString		*origdata = [self data];	/* original data */
    NSMutableData	*data = [NSMutableData data];	/* modified data to return */
    unsigned char	pstring[256];			/* pascal string under construction */
    unsigned long	i;				/* loop counter */
    
    /* initialise pstring */
    pstring[0] = 0;
    
    /* create strings */
    for (i = 0; i < [origdata length]; i++) {
	pstring[0]++;
	pstring[pstring[0]] = [origdata characterAtIndex:i];
	if (pstring[0] == 254 || i == [origdata length] - 1) {
	    [data appendBytes:(char *)&pstring length:pstring[0] + 1];
	    pstring[0] = 0;
	}
    }
    
    /* return copy so it is immutable */
    return [[data copy] autorelease];
}

/* ichat AV style TXT record */
-(NSData *)avDataAsPackedPString {
    NSMutableString *infoData = [NSMutableString string];
    NSEnumerator    *enumerator;
    id value;
    NSString	    *key;
    
    [infoData appendString:@"\x09txtvers=1"];
    [infoData appendString:@"\x09version=1"];
    
    /* enumerator to loop through fields for announcement */
    enumerator = [keys keyEnumerator];
    
    while ((key = [enumerator nextObject])) {
	/* convert binary to hex */
	char *hexdata;
	int i;
	
	value = [keys objectForKey:key];
	
	if ([value isKindOfClass:[NSData class]]) {
	    hexdata = (char *)malloc([(NSData *)value length] * 2 + 1);
	    
	    for (i = 0; i < 20; i++) {
		sprintf(hexdata + (i*2), "%.2x", ((unsigned char *)[(NSData *)value bytes])[i]);
	    }
	    hexdata[[(NSData *)value length] * 2] = '\0';
	    
	    [infoData appendFormat:@"%c", ([(NSData *)value length] * 2 + [key length] + 1)];
	    [infoData appendString:key];
	    [infoData appendString:@"="];
	    [infoData appendString:[NSString stringWithCString:hexdata]];
	    
	} else {
	    
	    [infoData appendFormat:@"%c", [(NSString *)value length] + [key length] + 1];
	    [infoData appendString:key];
	    [infoData appendString:@"="];
	    [infoData appendString:value];
	}
    }
    
    return [NSData dataWithBytes:[infoData UTF8String] length:strlen([infoData UTF8String])];
}


@end
