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

#import "ESPurpleNotifyEmailController.h"
#import "adiumPurpleNotify.h"
#import <AdiumLibpurple/SLPurpleCocoaAdapter.h>
#import <AIUtilities/AIObjectAdditions.h>
#import "ESPurpleMeanwhileContactAdditionController.h"

static void *adiumPurpleNotifyMessage(PurpleNotifyMsgType type, const char *title, const char *primary, const char *secondary)
{
	PurpleDebug (@"adiumPurpleNotifyMessage: type: %i\n%s\n%s\n%s ",
			   type,
			   (title ? title : ""),
			   (primary ? primary : ""),
			   (secondary ? secondary : ""));

	return ([[SLPurpleCocoaAdapter sharedInstance] handleNotifyMessageOfType:type
																 withTitle:title
																   primary:primary
																 secondary:secondary]);
}

static void *adiumPurpleNotifyEmails(PurpleConnection *gc, size_t count, gboolean detailed, const char **subjects, const char **froms, const char **tos, const char **urls)
{
    //Values passed can be null
	AIAccount	*account = (PURPLE_CONNECTION_IS_VALID(gc) ?
							accountLookup(purple_connection_get_account(gc)) :
							nil);
			
    return [ESPurpleNotifyEmailController handleNotifyEmailsForAccount:account
															   count:count 
															detailed:detailed
															subjects:subjects
															   froms:froms
																 tos:tos
																urls:urls];
}

static void *adiumPurpleNotifyEmail(PurpleConnection *gc, const char *subject, const char *from, const char *to, const char *url)
{
	return adiumPurpleNotifyEmails(gc,
								 1,
								 TRUE,
								 (subject ? &subject : NULL),
								 (from ? &from : NULL),
								 (to ? &to : NULL),
								 (url ? &url : NULL));
}

static void *adiumPurpleNotifyFormatted(const char *title, const char *primary, const char *secondary, const char *text)
{
	PurpleDebug (@"adiumPurpleNotifyFormatted: %s\n%s\n%s\n%s ",
			   (title ? title : ""),
			   (primary ? primary : ""),
			   (secondary ? secondary : ""),
			   (text ? text : ""));

	return ([[SLPurpleCocoaAdapter sharedInstance] handleNotifyFormattedWithTitle:title
																		primary:primary
																	  secondary:secondary
																		   text:text]);	
}

static void *adiumPurpleNotifySearchResults(PurpleConnection *gc, const char *title,
										  const char *primary, const char *secondary,
										  PurpleNotifySearchResults *results, gpointer user_data)
{
	NSString *primaryString = (primary ? [NSString stringWithUTF8String:primary] : nil);
	if (primaryString &&
		[primaryString rangeOfString:@"An ambiguous user ID was entered"].location != NSNotFound) {
		/* Meanwhile ambiguous ID... hack implementation until a full search results UI exists */
		NSDictionary			*infoDict;

		/* secondary is 
		 * ("The identifier '%s' may possibly refer to any of the following"
		 * " users. Please select the correct user from the list below to"
		 * " add them to your buddy list.");
		 */
		NSString	*secondaryString = [NSString stringWithUTF8String:secondary];
		NSString	*originalName;
		NSRange		preRange,postRange;
		preRange = [secondaryString rangeOfString:@"The identifier '"];
		postRange = [secondaryString rangeOfString:@"' may possibly refer to any of the following"];
		originalName = [secondaryString substringWithRange:NSMakeRange(preRange.location+preRange.length,
																	   postRange.location - (preRange.location+preRange.length))];		
		
		infoDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			[NSValue valueWithPointer:gc], @"PurpleConnection",
			[NSValue valueWithPointer:user_data],@"userData",
			[NSValue valueWithPointer:results], @"PurpleNotifySearchResultsValue",
			originalName, @"Original Name",
			nil];
		
		ESPurpleMeanwhileContactAdditionController *requestController = [ESPurpleMeanwhileContactAdditionController showContactAdditionListWithDict:infoDict];
		
		return requestController;
	}
		
	return adium_purple_get_handle();
}

static void adiumPurpleNotifySearchResultsNewRows(PurpleConnection *gc,
												 PurpleNotifySearchResults *results,
												 void *data)
{

}

static void *adiumPurpleNotifyUserinfo(PurpleConnection *gc, const char *who,
									 PurpleNotifyUserInfo *user_info)
{	
	if (PURPLE_CONNECTION_IS_VALID(gc)) {
		PurpleAccount		*account = purple_connection_get_account(gc);
		PurpleBuddy		*buddy = purple_find_buddy(account, who);
		CBPurpleAccount	*adiumAccount = accountLookup(account);
		AIListContact	*contact;

		contact = contactLookupFromBuddy(buddy);
		if (!contact) {
			NSString *UID = [NSString stringWithUTF8String:purple_normalize(account, who)];
			
			contact = [accountLookup(account) contactWithUID:UID];
		}
		
		[adiumAccount updateUserInfo:contact
							withData:user_info];
	}
	
    return NULL;
}

static void *adiumPurpleNotifyUri(const char *uri)
{
	if (uri) {
		NSURL   *notifyURI = [NSURL URLWithString:[NSString stringWithUTF8String:uri]];
		[[NSWorkspace sharedWorkspace] openURL:notifyURI];
	}
	
    return NULL;
}

static void adiumPurpleNotifyClose(PurpleNotifyType type,void *uiHandle)
{
	PurpleDebug (@"adiumPurpleNotifyClose");
}

static PurpleNotifyUiOps adiumPurpleNotifyOps = {
    adiumPurpleNotifyMessage,
    adiumPurpleNotifyEmail,
    adiumPurpleNotifyEmails,
    adiumPurpleNotifyFormatted,
	adiumPurpleNotifySearchResults,
	adiumPurpleNotifySearchResultsNewRows,
	adiumPurpleNotifyUserinfo,
    adiumPurpleNotifyUri,
    adiumPurpleNotifyClose
};

PurpleNotifyUiOps *adium_purple_notify_get_ui_ops(void)
{
	return &adiumPurpleNotifyOps;
}
