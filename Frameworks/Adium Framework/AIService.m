/* 
Adium, Copyright 2001-2005, Adam Iser
 
 This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 General Public License as published by the Free Software Foundation; either version 2 of the License,
 or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 Public License for more details.
 
 You should have received a copy of the GNU General Public License along with this program; if not,
 write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIService.h"

/*!
 * @class AIService
 * @brief An IM Service
 *
 * This abstract class represents a service that Adium supports.  Subclass this for every service.
 */
@implementation AIService

/*!
 * Init
 */
- (id)init
{
	[super init];
	
	//Register this service with Adium
    [[adium accountController] registerService:self];
	
	return(self);
}


//Account Creation -----------------------------------------------------------------------------------------------------
#pragma mark Account Creation
/*!
 * @brief Create a new account for this service
 *
 * Creates a new account of this service.  Accounts are identified by a unique number.  We can't use service or
 * UID, since both those values may change.
 * @param inUID A unique identifier for the account being created.
 * @param inAccountNumber A unique number for the account being created.
 * @return An <tt>AIAccount</tt> object for this service.
 */
- (id)accountWithUID:(NSString *)inUID internalObjectID:(NSString *)inInternalObjectID
{
	return([[[[self accountClass] alloc] initWithUID:inUID internalObjectID:inInternalObjectID service:self] autorelease]);
}

/*!
 * @brief Account class associated with this service
 *
 * Subclass to return the account class associated with this service ([AISomethingAccount class]).
 * @return The account class associated with this service.
 */
- (Class)accountClass
{
	return(nil);
}

/*!
 * @brief Account view controller for this service
 *
 * Subclass to return an account view controller which provides the necessary controls for configuring an account
 * on this service.
 * @return An <tt>AIAccountViewController</tt> or subclass for this service.
 */
- (AIAccountViewController *)accountView
{
	return(nil);
}

/*!
 * @brief Join chat view controller for this service
 *
 * Subclass to return a join chat view controller which provides the necessary controls for joining a chat on this
 * service.
 * @return An <tt>DCJoinChatViewController</tt> or subclass for this service.
 */
- (DCJoinChatViewController *)joinChatView
{
	return(nil);
}


//Service Description --------------------------------------------------------------------------------------------------
#pragma mark Service Description
/*!
 * @brief Unique ID for this class
 *
 * Subclass to return a unique string ID which identifies this class.  No two classes should have the same uniqueID.
 * This value is used to determine which protocol code to use for the user's accounts.
 * Examples: "libgaim-aim", "aim-toc2", "imservices-aim-.mac"
 * @return NSString unique ID
 */
- (NSString *)serviceCodeUniqueID{
    return(@"");
}

/*!
 * @brief Service ID for this service
 *
 * Subclass to return a string which identifies this service.  If multiple service classes are supporting the same
 * service they should have the same serviceID.  Not for user-display.
 * Examples: "aim", "msn", "jabber", "icq", ".mac"
 * @return NSString service ID
 */
- (NSString *)serviceID{
    return(@"");
}

/*!
 * @brief Service class for this service
 *
 * Some separate services can communicate with eachother.  These services, while they have separate serviceID's,
 * are all part of a common service class.  For instance, AIM, ICQ, and .Mac are all part of the "AIM" service class.
 * For many services, the serviceClass will be identical to the serviceID.  Not for user-display.
 * Service classes may change, do not use them for any permenant storage (logs, preferences, etc).
 * Examples: "aim-compatible", "jabber", "msn", "icq"
 * @return NSString service class
 */
- (NSString *)serviceClass{
	return(@"");
}

/*!
 * @brief Human readable short description
 *
 * Human readable, short description of this service
 * This value is used in tooltips and the message window.
 * Examples: "Jabber", "MSN", "AIM", ".Mac"
 * @return NSString short description
 */
- (NSString *)shortDescription{
    return(@"");
}

/*!
 * @brief Human readable long description
 *
 * Human readable, long description of this service
 * If there are multiple classes available for the same service, this description should briefly show the difference
 * between the implementations.  This value is used in the account preferences service menu.
 * Examples: "Jabber", "MSN", "AIM (Oscar)", "AIM (TOC)", ".Mac"
 * @return NSString long description
 */
- (NSString *)longDescription{
    return(@"");
}

/*!
 * @brief Label for user name
 *
 * String to use for describing the UID/username of this service.  This value varies by service, but should be something
 * along the lines of "User name", "Account name", "Screen name", "Member name", etc.
 * @return NSString label for username
 */
- (NSString *)userNameLabel
{
    return(nil);    
}

/*!
 * @brief Service importance
 *
 * Importance grouping of this service.  Used to make service listings and menus more organized by placing more important
 * services at the top of lists or displaying them with more visibility.
 * @return <tt>AIServiceImportance</tt> importance of this service
 */
- (AIServiceImportance)serviceImportance
{
	return(AIServiceUnsupported);
}


//Service Properties ---------------------------------------------------------------------------------------------------
#pragma mark Service Properties
/*!
 * @brief Allowed characters
 *
 * Characters allowed in user names on this service.  The user will not be allowed to type any characters not in this
 * set as a contact or account name.
 * @return <tt>NSCharacterSet</tt> of allowed characters
 */
- (NSCharacterSet *)allowedCharacters
{
    return(nil);
}

/*!
 * @brief Allowed characters for UIDs
 *
 * Offers further distinction of allowed characters, for situations where certain characters are allowed
 * for our account name only, or characters which are allowed in user names are forbidden in our own account name.
 * If this distinction is not made, do not subclass this methods and instead subclass allowedCharacters.
 * @return <tt>NSCharacterSet</tt> of allowed characters
 */
- (NSCharacterSet *)allowedCharactersForAccountName
{
	return ([self allowedCharacters]);
}

/*!
 * @brief Allowed characters for our account name
 *
 * Offers further distinction of allowed characters, for situations where certain characters are allowed
 * for our account name only, or characters which are allowed in user names are forbidden in our own account name.
 * If this distinction is not made, do not subclass this methods and instead subclass allowedCharacters.
 * @return <tt>NSCharacterSet</tt> of allowed characters
 */
- (NSCharacterSet *)allowedCharactersForUIDs
{
	return([self allowedCharacters]);
}

/*!
 * @brief Ignored characters
 *
 * Ignored characters for user names on this service.  Ignored characters are stripped from account and contact names
 * before they are used, but the user is free to type them and they may be used by the service code.  For instance, 
 * spaces are allowed in AIM usernames, but "ad am" is treated as equal to "adam" because space is an ignored character.
 * @return <tt>NSCharacterSet</tt> of ignored characters
 */
- (NSCharacterSet *)ignoredCharacters
{
    return(nil);
}

/*!
 * @brief Allowed name length
 *
 * Max allowed length of user names of this service.  Account and contact names longer than this will not be allowed.
 * @return Max name length
 */
- (int)allowedLength
{
    return(0);
}

/*!
 * @brief Allowed UID length
 *
 * Offers further distinction of allowed name length, for situations where our account name has a different
 * length restriction than the names of our contacts.  If this distinction is not made, do not subclass these methods
 * and instead subclass allowedLength.
 * @return Max name length
 */
- (int)allowedLengthForAccountName
{
	return([self allowedLength]);
}

/*!
 * @brief Allowed account name length
 *
 * Offers further distinction of allowed name length, for situations where our account name has a different
 * length restriction than the names of our contacts.  If this distinction is not made, do not subclass these methods
 * and instead subclass allowedLength.
 * @return Max name length
 */
- (int)allowedLengthForUIDs
{
	return([self allowedLength]);
}

/*!
 * @brief Case sensitivity of names
 *
 * Determines if usernames such as "Adam" and "adam" are unique.
 * @return Case sensitivity
 */
- (BOOL)caseSensitive
{
    return(NO);
}

/*!
 * @brief Can create group chats?
 *
 * Does this service support group chats (Also known as multi-user chats, chat rooms, conferences, etc)?  Services
 * which do not support group chats are automatically excluded from the group chat interface elements.
 * @return Can create group chats
 */
- (BOOL)canCreateGroupChats
{
	return NO;
}

/*!
 * @brief Can register accounts?
 *
 * Does this service support registering new accounts from within Adium?  This is here for Jabber.
 * @return Can register accounts
 */
- (BOOL)canRegisterNewAccounts
{
	return NO;
}


//Utilities ------------------------------------------------------------------------------------------------------------
#pragma mark Utilities
/*!
 * @brief Filter a UID
 *
 * Filters a UID.  All invalid characters and ignored characters are removed.
 * UID's are ONLY filtered when creating contacts, and when renaming contacts.
 * - When changing ownership of a contact, a filter is not necessary, since all the accounts should have the same service
 *   types and requirements.
 * - When account code retrieves contacts from the contact list, filtering is NOT done.  It is up to the account to
 *   ensure it passes UID's in the proper format for its service type.
 * - Filter UIDs only when the user has entered or mucked with them in some way... UD's TO and FROM account code
 *   SHOULD ALWAYS BE VALID.
 * @return NSString filtered UID
 */
- (NSString *)filterUID:(NSString *)inUID removeIgnoredCharacters:(BOOL)removeIgnored
{
	NSString		*workingString = ([self caseSensitive] ? inUID : [inUID lowercaseString]);
	NSCharacterSet	*allowedCharacters = [self allowedCharactersForUIDs];
	NSCharacterSet	*ignoredCharacters = [self ignoredCharacters];

	//Prepare a little buffer for our filtered UID
	unsigned	destLength = 0;
	unsigned	workingStringLength = [workingString length];
	unichar		*dest = malloc(workingStringLength * sizeof(unichar));

	//Filter the UID
	unsigned	pos;
	for(pos = 0; pos < workingStringLength; pos++){
		unichar c = [workingString characterAtIndex:pos];
		
        if([allowedCharacters characterIsMember:c] && (!removeIgnored || ![ignoredCharacters characterIsMember:c])){
            dest[destLength] = (removeIgnored ? c : [inUID characterAtIndex:pos]);
			destLength++;
		}
	}

	//Turn it back into a string and return
    NSString *filteredString = [NSString stringWithCharacters:dest length:destLength];
	free(dest);

	return(filteredString);
}

@end
