//
//  AIURL.m
//  Adium
//
//  Created by Adam Iser on Sun Mar 23 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIURLLoader.h"
#import "AISocket.h"
#import "AIStringAdditions.h"

@implementation AIURLLoader

+ (NSString *)loadHost:(NSString *)host port:(int)port path:(NSString *)path
{
    AISocket		*tempSocket;
    NSString		*result;
    NSArray		*resultArray;
    NSMutableData	*outData;
    NSMutableString	*data;
    int			offset = -1;
    int			loop;
    
    //Create a socket
    tempSocket = [AISocket socketWithHost:host port:port];

    while(![tempSocket readyForSending]){}
    
    //build our HTTP request
    [tempSocket sendData:[[NSString stringWithFormat:@"GET %@ HTTP/1.1\015\012",path] dataUsingEncoding:NSISOLatin1StringEncoding]];
    [tempSocket sendData:[[NSString stringWithFormat:@"Host: %@\015\012",host] dataUsingEncoding:NSISOLatin1StringEncoding]];
    [tempSocket sendData:[@"\015\012" dataUsingEncoding:NSISOLatin1StringEncoding]];

    //Fetch the data (Just block for now)
    while([tempSocket isValid]){
        if([tempSocket readyForReceiving] && [tempSocket getData:&outData ofLength:8000]){
            break;
        }
    }

    //Find the start of the data (skipping over the headers)
    result = [[NSString alloc] initWithData:outData encoding:NSISOLatin1StringEncoding];
    resultArray = [result componentsSeparatedByString:@"\015\012"];
    for(loop = 0;loop < [resultArray count];loop++){
        if([(NSString *)[resultArray objectAtIndex:loop] length] == 0){
            offset = loop; loop = [resultArray count]+1;
        }
    }
    if(offset == -1) NSLog(@"Invalid response");

    //decode the result
    if([result rangeOfString:@"Transfer-Encoding: chunked"].location != NSNotFound){ //chunked data
        int		length;

        //Create a new data string
        data = [[NSMutableString alloc] init];

        //Re-assemble the chunked data
        offset++;
        length = [[resultArray objectAtIndex:offset] intValueFromHex];
        while(length != 0){
            [data appendString:[[resultArray objectAtIndex:offset+1] substringToIndex:length]];

            offset += 2;
            length = [[resultArray objectAtIndex:offset] intValueFromHex];
        }
    }else{
        offset++;
        data = [resultArray objectAtIndex:offset];
    }

    return(data);
}

    
@end
