//
//  AIFacebookOutgoingMessageManager.m
//  Adium
//
//  Created by Evan Schoenberg on 5/8/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "AIFacebookOutgoingMessageManager.h"
#import <Adium/AIContentMessage.h>
#import "AIFacebookAccount.h"

@implementation AIFacebookOutgoingMessageManager
+ (void)sendMessageObject:(AIContentMessage *)inContentMessage
{
	//This can not be https:// - the message fails to send
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://www.facebook.com/ajax/chat/send.php"]
														   cachePolicy:NSURLRequestUseProtocolCachePolicy
													   timeoutInterval:120];
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
						  [inContentMessage encodedMessage], @"msg_text",
						  [[NSNumber numberWithLong:(random() % 99999999)] stringValue], @"msg_id",
						  [[inContentMessage destination] UID], @"to",
						  [[NSNumber numberWithInt:[[NSDate date] timeIntervalSince1970]] stringValue], @"client_time",
						  [(AIFacebookAccount *)[inContentMessage source] postFormID], @"post_form_id",
						  nil];
	NSData *postData = [AIFacebookAccount postDataForDictionary:dict];
	[request setHTTPMethod:@"POST"];
	[request setValue:[NSString stringWithFormat:@"%d", [postData length]] forHTTPHeaderField:@"Content-Length"];
	[request setHTTPBody:postData];

	AILogWithSignature(@"Sending %@",dict);
	[[NSURLConnection alloc] initWithRequest:request delegate:self];
}

+ (void)connection:(NSURLConnection *)inConnection didReceiveResponse:(NSURLResponse *)response
{
    //This can be called multiple times, for example in the case of a redirect, so each time we reset the data.
}

+ (void)connection:(NSURLConnection *)inConnection didReceiveData:(NSData *)data
{
	NSMutableString *receivedString = [[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	AILogWithSignature(@"Received %@", receivedString);
	[receivedString release];
}

+ (void)connectionDidFinishLoading:(NSURLConnection *)inConnection
{
	[inConnection release];
}


@end
