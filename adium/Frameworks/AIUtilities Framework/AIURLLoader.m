/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

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
