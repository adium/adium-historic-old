/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "ESGaimNotifyEmailController.h"
#import "SLGaimCocoaAdapter.h"
#import "GaimCommon.h"
#import "ESTextAndButtonsWindowController.h"
#import "ESContactAlertsController.h"
#import <AIUtilities/AIObjectAdditions.h>

@interface ESGaimNotifyEmailController (PRIVATE)
+ (void)openURLString:(NSString *)urlString;
@end

@implementation ESGaimNotifyEmailController

/*!
 * @brief Handle the notification of emails
 *
 * This may be called from the gaim thread.
 */
+ (void *)handleNotifyEmails:(size_t)count detailed:(BOOL)detailed subjects:(const char **)subjects froms:(const char **)froms tos:(const char **)tos urls:(const char **)urls
{
	NSFontManager				*fontManager = [NSFontManager sharedFontManager];
	NSFont						*messageFont = [NSFont messageFontOfSize:11];
	NSMutableParagraphStyle		*centeredParagraphStyle;
	NSMutableAttributedString   *message;
	
	centeredParagraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
	[centeredParagraphStyle setAlignment:NSCenterTextAlignment];
	message = [[NSMutableAttributedString alloc] init];
	
	//Title
	NSString		*title;
	NSFont			*titleFont;
	NSDictionary	*titleAttributes;
	
	title = AILocalizedString(@"You have mail!\n",nil);
	titleFont = [fontManager convertFont:[NSFont messageFontOfSize:12]
							 toHaveTrait:NSBoldFontMask];
	titleAttributes = [NSDictionary dictionaryWithObjectsAndKeys:titleFont,NSFontAttributeName,
		centeredParagraphStyle,NSParagraphStyleAttributeName,nil];
	
	[message appendAttributedString:[[[NSAttributedString alloc] initWithString:title
																	 attributes:titleAttributes] autorelease]];
	
	//Message
	NSString		*numberMessage;
	NSDictionary	*numberMessageAttributes;
	
	if (tos && *tos) {
		numberMessage = ((count == 1) ? 
						 [NSString stringWithFormat:AILocalizedString(@"%s has 1 new message.",nil), *tos] :
						 [NSString stringWithFormat:AILocalizedString(@"%s has %i new messages.",nil), *tos,count]);

	} else {
		numberMessage = ((count == 1) ? 
						 AILocalizedString(@"You have 1 new message.",nil) :
						 [NSString stringWithFormat:AILocalizedString(@"You have %i new messages.",nil), count]);		
	}

	numberMessageAttributes = [NSDictionary dictionaryWithObjectsAndKeys:messageFont,NSFontAttributeName,
		centeredParagraphStyle,NSParagraphStyleAttributeName,nil];
	
	[message appendAttributedString:[[[NSAttributedString alloc] initWithString:numberMessage
																	 attributes:numberMessageAttributes] autorelease]];
	
	if (count == 1) {
		BOOL	haveFroms    = (froms    && *froms);
		BOOL	haveSubjects = (subjects && *subjects);
		
		if (haveFroms || haveSubjects) {
			NSFont			*fieldFont;
			NSDictionary	*fieldAttributed, *infoAttributed;
			
			fieldFont =  [fontManager convertFont:messageFont
									  toHaveTrait:NSBoldFontMask];
			fieldAttributed = [NSDictionary dictionaryWithObjectsAndKeys:fieldFont,NSFontAttributeName,nil];
			infoAttributed = [NSDictionary dictionaryWithObjectsAndKeys:messageFont,NSFontAttributeName,nil];
			
			//Skip a line
			[[message mutableString] appendString:@"\n\n"];
			
			if (haveFroms) {
				[message appendAttributedString:[[[NSAttributedString alloc] initWithString:AILocalizedString(@"From: ",nil)
																				 attributes:fieldAttributed] autorelease]];
				[message appendAttributedString:[[[NSAttributedString alloc] initWithString:[NSString stringWithUTF8String:(*froms)]
																				 attributes:infoAttributed] autorelease]];
			}
			if (haveFroms && haveSubjects) {
				[[message mutableString] appendString:@"\n"];
			}
			if (haveSubjects) {
				NSAttributedString *temp = [[NSAttributedString alloc] initWithString:AILocalizedString(@"Subject: ",nil)
																					 attributes:fieldAttributed];
				AILog(@"(Subject header) String: '%@'; attributes: %@; attributed string: %@", AILocalizedString(@"Subject: ",nil), fieldAttributed, temp);
				[temp release];
				[message appendAttributedString:[[[NSAttributedString alloc] initWithString:AILocalizedString(@"Subject: ",nil)
																				 attributes:fieldAttributed] autorelease]];

				temp = [[NSAttributedString alloc] initWithString:[NSString stringWithUTF8String:(*subjects)]
																				 attributes:infoAttributed];
				AILog(@"(Subject string) String: '%@'; attributes: %@; attributed string: %@", (*subjects), infoAttributed, temp);
				[temp release];
				[message appendAttributedString:[[[NSAttributedString alloc] initWithString:[NSString stringWithUTF8String:(*subjects)]
																				 attributes:infoAttributed] autorelease]];				
				AILog(@"workie!");
			}
		}
	}
	
	NSMutableDictionary *infoDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:title,@"Title",
		message,@"Message",nil];
	
	if (urls != NULL) {
		[infoDict setObject:[NSString stringWithUTF8String:urls[0]] forKey:@"URL"];
	}
	
	[self mainPerformSelector:@selector(showNotifyEmailWindowWithMessage:URLString:)
				   withObject:message
				   withObject:(urls ? [NSString stringWithUTF8String:urls[0]] : nil)];

	[centeredParagraphStyle release];
	[message release];
	
	return adium_gaim_get_handle();
}

/*!
 * @brief Show the New Mail message
 *
 * Displays the New Mail message, optionally offerring an Open Mail button (if a URL to open the webmail is passed).
 *
 * @param inMessage An attributed message describing the new mail
 * @param inURLString The URL to the appropriate webmail, or nil if no webmail link is available
 */
+ (void)showNotifyEmailWindowWithMessage:(NSAttributedString *)inMessage URLString:(NSString *)inURLString
{	
	[ESTextAndButtonsWindowController showTextAndButtonsWindowWithTitle:AILocalizedString(@"New Mail",nil)
														  defaultButton:nil
														alternateButton:(inURLString ? 
																		 AILocalizedString(@"Open Mail",nil) :
																		 nil)
															otherButton:nil
															   onWindow:nil
													  withMessageHeader:nil
															 andMessage:inMessage
																 target:self
															   userInfo:inURLString];	
	
	//XXX - Hook this to the account for listobject
	[[[AIObject sharedAdiumInstance] contactAlertsController] generateEvent:ACCOUNT_RECEIVED_EMAIL
															  forListObject:nil
																   userInfo:nil
											   previouslyPerformedActionIDs:nil];	
}

/*!
 * @brief Window was closed, either by a button being clicked or the user closing it
 */
+ (BOOL)textAndButtonsWindowDidEnd:(NSWindow *)window returnCode:(AITextAndButtonsReturnCode)returnCode userInfo:(id)userInfo
{
	switch (returnCode) {
		case AITextAndButtonsAlternateReturn:
			if (userInfo) [self openURLString:userInfo];
			break;

		case AITextAndButtonsDefaultReturn:
		case AITextAndButtonsOtherReturn:
		case AITextAndButtonsClosedWithoutResponse:
			//No action needed
			break;
	}
	
	return YES;
}

/*!
 * @brief Open a URL string from the open mail window
 *
 * The urlString could either be a web address or a path to a local HTML file we are supposed to load.
 * The local HTML file will be in the user's temp directory, which Gaim obtains with g_get_tmp_dir()...  
 * so we will, too.
 */ 
+ (void)openURLString:(NSString *)urlString
{
	if ([urlString rangeOfString:[NSString stringWithUTF8String:g_get_tmp_dir()]].location != NSNotFound) {
		//Local HTML file
		CFURLRef	appURL = NULL;
		OSStatus	err;
		
		//Obtain the default http:// handler
		err = LSGetApplicationForURL((CFURLRef)[NSURL URLWithString:urlString],
									 kLSRolesViewer,
									 /*outAppRef*/ NULL,
									 &appURL);
		
		//Use it to open the specified file (if we just told NSWorkspace to open it, it might be opened instead
		//by an HTML editor or other program
		if (err == noErr) {
			[[NSWorkspace sharedWorkspace] openFile:[urlString stringByExpandingTildeInPath]
									withApplication:[(NSURL *)appURL path]];			
		} else {
			NSURL		*url;
			
			//Web address
			url = [NSURL URLWithString:urlString];
			[[NSWorkspace sharedWorkspace] openURL:url];
		}
		
		if (appURL) {
			//LSGetApplicationForURL() requires us to release the appURL when we are done with it
			CFRelease(appURL);
		}
		
	} else {
		NSURL		*emailURL;
		
		//Web address
		emailURL = [NSURL URLWithString:urlString];
		[[NSWorkspace sharedWorkspace] openURL:emailURL];
	}
}

@end
