//
//  AIFacebookAccount.m
//  Adium
//
//  Created by Evan Schoenberg on 5/8/08.
//

#import "AIFacebookAccount.h"
#import <JSON/JSON.h>
#import <WebKit/WebKit.h>
#import <AIUtilities/AIStringAdditions.h>
#import <Adium/AIContentMessage.h>
#import "AIFacebookBuddyListManager.h"
#import "AIFacebookOutgoingMessageManager.h"
#import "AIFacebookIncomingMessageManager.h"
#import "AIFacebookStatusManager.h"

#define LOGIN_PAGE	@"http://www.facebook.com/login.php"
#define FACEBOOK_HOME_PAGE	@"http://www.facebook.com/home.php"

@interface AIFacebookAccount (PRIVATE)
- (void)extractLoginInfoFromHomePage:(NSString *)homeString;
- (void)postDictionary:(NSDictionary *)inDict toURL:(NSURL *)inURL;
@end

/*!
 * @class AIFacebookAccount
 * @brief Facebook account class
 *
 * Huge thanks to coderrr for his analysis of the Facebook protocol and sample implementation in Ruby.
 * http://coderrr.wordpress.com/2008/05/06/facebook-chat-api/
 */
@implementation AIFacebookAccount

- (void)initAccount
{
	[super initAccount];

	webView = [[WebView alloc] initWithFrame:NSMakeRect(0, 0, 500, 500) frameName:nil groupName:nil];

	//We must be Safari 3.x or greater for Facebook to be willing to chat
	[webView setApplicationNameForUserAgent:@"Safari/525.18"];
	[webView setResourceLoadDelegate:self];
}

- (void)dealloc
{
	[webView release]; webView = nil;
	
	[super dealloc];
}

#pragma mark Connectivity

- (void)didConnect
{
	[super didConnect];
	
	[self silenceAllContactUpdatesForInterval:18.0];
	buddyListManager = [[AIFacebookBuddyListManager buddyListManagerForAccount:self] retain];
	incomingMessageManager = [[AIFacebookIncomingMessageManager incomingMessageManagerForAccount:self] retain];
}

//Connect this account (Our password should be in the instance variable 'password' all ready for us)
- (void)connect
{
	sentLogin = NO;

	[super connect];

	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:LOGIN_PAGE]
														   cachePolicy:NSURLRequestUseProtocolCachePolicy
													   timeoutInterval:120];
	[[webView mainFrame] loadRequest:request];
}

- (NSString *)host
{
	// Provide our host so that we know availability
	return @"www.facebook.com";
}

- (void)disconnect
{
	//XXX how do we disconnect?
	[buddyListManager disconnect];
	[buddyListManager release]; buddyListManager = nil;
	
	[incomingMessageManager disconnect];
	[incomingMessageManager release]; incomingMessageManager = nil;
	
	[super disconnect];
	
	[self didDisconnect];
}

- (BOOL)isSigningOn
{
	return silentAndDelayed;
}

- (NSString *)facebookUID
{
	return facebookUID;	
}

- (NSString *)channel
{
	return channel;
}

- (NSString *)postFormID
{
	return postFormID;
}

#pragma mark Messaging
- (BOOL)sendMessageObject:(AIContentMessage *)inContentMessage
{
	[AIFacebookOutgoingMessageManager sendMessageObject:inContentMessage];
	
	return YES;
}

- (NSString *)encodedAttributedStringForSendingContentMessage:(AIContentMessage *)inContentMessage
{
	return [[inContentMessage message] string];
}

//Initiate a new chat
- (BOOL)openChat:(AIChat *)chat
{
	return YES;
}

//Close a chat instance
- (BOOL)closeChat:(AIChat *)inChat
{
	return YES;
}

#pragma mark Status

- (void)setStatusState:(AIStatus *)statusState usingStatusMessage:(NSAttributedString *)statusMessage
{
	if ([statusState statusType] == AIOfflineStatusType) {
		[self disconnect];
	} else {
		if ([self online]) {
			/* This is not acceptable as-is; we'll be updating our status message way too often as this will follow global status as other accounts do */
			// [AIFacebookStatusManager setFacebookStatusMessage:[statusMessage string] forAccount:self];
		} else {
			[self connect];
		}
	}
}

#pragma mark Connection processing
+ (NSData *)postDataForDictionary:(NSDictionary *)inDict
{
	NSMutableString *post = [NSMutableString string];
	
	//Build post
	NSEnumerator *enumerator = [inDict keyEnumerator];
	NSString	*key;
	while ((key = [enumerator nextObject])) {
		if ([post length] != 0) [post appendString:@"&"];
		
		[post appendFormat:@"%@=%@",
		 [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
		 [[inDict objectForKey:key] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	}
	
	return [post dataUsingEncoding:NSUTF8StringEncoding];
}

- (void)postDictionary:(NSDictionary *)inDict toURL:(NSURL *)inURL
{
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:inURL
														   cachePolicy:NSURLRequestUseProtocolCachePolicy
													   timeoutInterval:120];	
	
	NSData *postData = [AIFacebookAccount postDataForDictionary:inDict];
	
	[request setHTTPMethod:@"POST"];
	[request setValue:[NSString stringWithFormat:@"%d", [postData length]] forHTTPHeaderField:@"Content-Length"];
	[request setHTTPBody:postData];
	[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	
	[[webView mainFrame] loadRequest:request];
}

- (id)webView:(WebView *)sender identifierForInitialRequest:(NSURLRequest *)request fromDataSource:(WebDataSource *)dataSource
{
	if ([[request URL] isEqual:[NSURL URLWithString:LOGIN_PAGE]]) {
		return @"Logging in";
	} else if ([[request URL] isEqual:[NSURL URLWithString:FACEBOOK_HOME_PAGE]]) {
		return @"Home";
	} else {
		return nil;
	}
}

- (void)webView:(WebView *)sender resource:(id)identifier didFinishLoadingFromDataSource:(WebDataSource *)dataSource
{
	AILogWithSignature(@"%@ resource %@ finished loading %@", sender, identifier, dataSource);

	if ([identifier isEqualToString:@"Logging in"]) {
		if (sentLogin) {
			//We sent our login; proceed with the home page
			[sender stopLoading:self];
			
			NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:FACEBOOK_HOME_PAGE]
																   cachePolicy:NSURLRequestUseProtocolCachePolicy
															   timeoutInterval:120];	
			
			[[webView mainFrame] loadRequest:request];
			
		} else {
			//We loaded login.php; now we can send the email and password
			sentLogin = YES;
			[sender stopLoading:self];
			
			[self postDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
								  [self UID], @"email",
								  password, @"pass",
								  nil]
						   toURL:[NSURL URLWithString:LOGIN_PAGE]];
		}
	} else if ([identifier isEqualToString:@"Home"]) {
		//We finished logging in and got the home page
		[self extractLoginInfoFromHomePage:[[dataSource representation] documentSource]];

		AILogWithSignature(@"facebookUID is %@, channel is %@, post form ID is %@", facebookUID, channel, postFormID);
		
		[sender stopLoading:self];
		
		if (facebookUID && channel && postFormID) {
			[self didConnect];
		} else {
			[self serverReportedInvalidPassword];
			[self setLastDisconnectionError:AILocalizedString(@"Could not log in", nil)];
			[self disconnect];
		}
	}
}

//These should be regexps, really
- (void)extractLoginInfoFromHomePage:(NSString *)homeString
{
	[facebookUID release]; facebookUID = nil;
	[channel release]; channel = nil;
	[postFormID release]; postFormID = nil;

	/* We need our own UID. It'll be inside:
	 * <a href="http://www.facebook.com/profile.php?id=XXXXX" class="profile_nav_link">Profile</a>
	 * where XXXXX is an integer. There is only one profile_nav_link item.
	 */
	NSRange profileRange = [homeString rangeOfString:@"\" class=\"profile_nav_link\"" options:NSLiteralSearch];
	if (profileRange.location != NSNotFound) {
		NSRange linkBeforeProfile = [homeString rangeOfString:@"<a href=\"http://www.facebook.com/profile.php?id="
													  options:(NSBackwardsSearch | NSLiteralSearch)
														range:NSMakeRange(0, profileRange.location)];
		if (linkBeforeProfile.location != NSNotFound) {
			facebookUID = [[homeString substringWithRange:NSMakeRange(NSMaxRange(linkBeforeProfile),
																	  profileRange.location - NSMaxRange(linkBeforeProfile))] retain];
		}
	}
	
	NSRange channelRange = [homeString rangeOfString:@", \"channel" options:NSLiteralSearch];
	if (channelRange.location != NSNotFound) {
		NSRange endChannelRange = [homeString rangeOfString:@"\"" options:NSLiteralSearch range:NSMakeRange(NSMaxRange(channelRange),
																										   [homeString length] - NSMaxRange(channelRange))];
		if (endChannelRange.location != NSNotFound) {
			channel = [[homeString substringWithRange:NSMakeRange(NSMaxRange(channelRange),
																  endChannelRange.location - NSMaxRange(channelRange))] retain];
		}
	}
	
	NSRange postFormIDRange = [homeString rangeOfString:@"<input type=\"hidden\" id=\"post_form_id\" name=\"post_form_id\" value=\"" options:NSLiteralSearch];
	if (postFormIDRange.location != NSNotFound) {
		NSRange endPostFormIDRange = [homeString rangeOfString:@"\" />"
													  options:NSLiteralSearch
														 range:NSMakeRange(NSMaxRange(postFormIDRange),
																		   [homeString length] - NSMaxRange(postFormIDRange))];
		if (endPostFormIDRange.location != NSNotFound) {
			postFormID = [[homeString substringWithRange:NSMakeRange(NSMaxRange(postFormIDRange),
																	  endPostFormIDRange.location - NSMaxRange(postFormIDRange))] retain];
		}
	}
}

@end
