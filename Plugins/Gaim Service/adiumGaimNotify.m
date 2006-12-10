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
#import "adiumGaimNotify.h"
#import "SLGaimCocoaAdapter.h"
#import <AIUtilities/AIObjectAdditions.h>
#import "ESGaimMeanwhileContactAdditionController.h"

static void *adiumGaimNotifyMessage(GaimNotifyMsgType type, const char *title, const char *primary, const char *secondary)
{
	GaimDebug (@"adiumGaimNotifyMessage: type: %i\n%s\n%s\n%s ",
			   type,
			   (title ? title : ""),
			   (primary ? primary : ""),
			   (secondary ? secondary : ""));

	return ([[SLGaimCocoaAdapter sharedInstance] handleNotifyMessageOfType:type
																 withTitle:title
																   primary:primary
																 secondary:secondary]);
}

static void *adiumGaimNotifyEmails(GaimConnection *gc, size_t count, gboolean detailed, const char **subjects, const char **froms, const char **tos, const char **urls)
{
    //Values passed can be null
	AIAccount	*account = (GAIM_CONNECTION_IS_VALID(gc) ?
							accountLookup(gaim_connection_get_account(gc)) :
							nil);
			
    return [ESGaimNotifyEmailController handleNotifyEmailsForAccount:account
															   count:count 
															detailed:detailed
															subjects:subjects
															   froms:froms
																 tos:tos
																urls:urls];
}

static void *adiumGaimNotifyEmail(GaimConnection *gc, const char *subject, const char *from, const char *to, const char *url)
{
	return adiumGaimNotifyEmails(gc,
								 1,
								 TRUE,
								 (subject ? &subject : NULL),
								 (from ? &from : NULL),
								 (to ? &to : NULL),
								 (url ? &url : NULL));
}

static void *adiumGaimNotifyFormatted(const char *title, const char *primary, const char *secondary, const char *text)
{
	GaimDebug (@"adiumGaimNotifyFormatted: %s\n%s\n%s\n%s ",
			   (title ? title : ""),
			   (primary ? primary : ""),
			   (secondary ? secondary : ""),
			   (text ? text : ""));

	return ([[SLGaimCocoaAdapter sharedInstance] handleNotifyFormattedWithTitle:title
																		primary:primary
																	  secondary:secondary
																		   text:text]);	
}

static void *adiumGaimNotifySearchResults(GaimConnection *gc, const char *title,
										  const char *primary, const char *secondary,
										  GaimNotifySearchResults *results, gpointer user_data)
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
			[NSValue valueWithPointer:gc], @"GaimConnection",
			[NSValue valueWithPointer:user_data],@"userData",
			[NSValue valueWithPointer:results], @"GaimNotifySearchResultsValue",
			originalName, @"Original Name",
			nil];
		
		ESGaimMeanwhileContactAdditionController *requestController = [ESGaimMeanwhileContactAdditionController showContactAdditionListWithDict:infoDict];
		
		return requestController;
	}
		
	return adium_gaim_get_handle();
}

static void adiumGaimNotifySearchResultsNewRows(GaimConnection *gc,
												 GaimNotifySearchResults *results,
												 void *data)
{

}

static void *adiumGaimNotifyUserinfo(GaimConnection *gc, const char *who,
									 GaimNotifyUserInfo *user_info)
{	
	if (GAIM_CONNECTION_IS_VALID(gc)) {
		GaimAccount		*account = gaim_connection_get_account(gc);
		GaimBuddy		*buddy = gaim_find_buddy(account, who);
		CBGaimAccount	*adiumAccount = accountLookup(account);
		AIListContact	*contact;

		contact = contactLookupFromBuddy(buddy);
		if (!contact) {
			NSString *UID = [NSString stringWithUTF8String:gaim_normalize(account, who)];
			
			contact = [accountLookup(account) mainThreadContactWithUID:UID];
		}
		
		[adiumAccount updateUserInfo:contact
							withData:user_info];
	}
	
    return NULL;
}

static void *adiumGaimNotifyUri(const char *uri)
{
	if (uri) {
		NSURL   *notifyURI = [NSURL URLWithString:[NSString stringWithUTF8String:uri]];
		[[NSWorkspace sharedWorkspace] openURL:notifyURI];
	}
	
    return NULL;
}

static void adiumGaimNotifyClose(GaimNotifyType type,void *uiHandle)
{
	GaimDebug (@"adiumGaimNotifyClose");
}

static GaimNotifyUiOps adiumGaimNotifyOps = {
    adiumGaimNotifyMessage,
    adiumGaimNotifyEmail,
    adiumGaimNotifyEmails,
    adiumGaimNotifyFormatted,
	adiumGaimNotifySearchResults,
	adiumGaimNotifySearchResultsNewRows,
	adiumGaimNotifyUserinfo,
    adiumGaimNotifyUri,
    adiumGaimNotifyClose
};

GaimNotifyUiOps *adium_gaim_notify_get_ui_ops(void)
{
	return &adiumGaimNotifyOps;
}
