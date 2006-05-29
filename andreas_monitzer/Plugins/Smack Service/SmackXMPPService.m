//
//  SmackXMPPService.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-05-28.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "SmackXMPPService.h"
#import "SmackXMPPAccount.h"
#import "SmackXMPPAccountViewController.h"
#import <AIUtilities/AIStringUtilities.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import "AIAdium.h"
#import "AIStatusController.h"

@implementation SmackXMPPService

- (Class)accountClass {
    return [SmackXMPPAccount class];
}

- (AIAccountViewController *)accountViewController{
    return [SmackXMPPAccountViewController accountViewController];
}

- (DCJoinChatViewController *)joinChatView{
//	return [SmackXMPPJoinChatViewController joinChatView];
    return nil;
}

- (NSString *)serviceClass
{
	return @"XMPP (Smack)";
}

- (AIServiceImportance)serviceImportance{
	return AIServicePrimary;
}

/*!
* @brief Placeholder string for the UID field
 */
- (NSString *)UIDPlaceholder
{
	return AILocalizedString(@"username@jabber.org","Sample name and server for new Jabber accounts");
}

/*!
 * @brief Allowed characters
 * 
 * Jabber IDs are generally of the form username@server.org
 *
 * Some rare Jabber servers assign actual IDs with %. Allow this for transport names such as
 * username%hotmail.com@msn.blah.jabber.org as well.
 */
- (NSCharacterSet *)allowedCharacters{
    /* Note that this are not all disallowed characters.
     * RFC3920 Appendix A specifies the allowed tables, but implementing this would require a few thousand lines of code probably.
     */
    
    NSCharacterSet *notAllowedCharacters = [NSCharacterSet characterSetWithCharactersInString:@"\"&'/:<>"];
    
    return [notAllowedCharacters invertedSet];
}

/*!
 * @brief Allowed characters for UIDs
 *
 * Same as allowedCharacters, but also allow / for specifying a resource.
 */
- (NSCharacterSet *)allowedCharactersForUIDs{
    /* Note that this are not all disallowed characters.
     * RFC3920 Appendix A specifies the allowed tables, but implementing this would require a few thousand lines of code probably.
    */
    
    NSCharacterSet *notAllowedCharacters = [NSCharacterSet characterSetWithCharactersInString:@"\"&':<>"];
    
    return [notAllowedCharacters invertedSet];
}

- (NSCharacterSet *)ignoredCharacters{
    // RFC 3454 Table B.1
    unichar ignoredChars[] = {
        0x00AD, 0x34F, 0x1806, 0x180B, 0x180C, 0x180D, 0x200B, 0x200C, 0x200D, 0x2060, 0xFE00, 0xFE01, 0xFE02,
        0xFE03, 0xFE04, 0xFE05, 0xFE06, 0xFE07, 0xFE08, 0xFE09, 0xFE0A, 0xFE0B, 0xFE0C, 0xFE0D, 0xFE0E, 0xFE0F, 0xFEFF
    };
    
	return [NSCharacterSet characterSetWithCharactersInString:[NSString stringWithBytes:ignoredChars length:sizeof(ignoredChars)/sizeof(unichar)
                                                                               encoding:NSUnicodeStringEncoding]];
}

/*
 * Official spec (RFC 3920, Section 3.1):
 *
 * Each allowable portion of a JID (node identifier, domain identifier,
 * and resource identifier) MUST NOT be more than 1023 bytes in length,
 * resulting in a maximum total size (including the '@' and '/'
 * separators) of 3071 bytes.
 */

- (int)allowedLength {
    return 1500; // arbitrary, Catfish_Man told me to do that
}

- (int)allowedLengthForUIDs {
    return 1500; // arbitrary, Catfish_Man told me to do that
}

- (int)allowedLengthForAccountName {
    return 1500; // arbitrary, Catfish_Man told me to do that
}

- (NSString *)serviceCodeUniqueID {
	return @"Smack-XMPP";
}

- (NSString *)shortDescription {
	return @"XMPP";
}

- (NSString *)longDescription {
	return @"XMPP Account";
}

- (NSString *)serviceID {
	return @"XMPP";
}

- (BOOL)caseSensitive {
	return YES; // only parts are case-sensitive actually ([Resourceprep])
}

- (BOOL)canCreateGroupChats {
    return YES;
}

- (BOOL)canRegisterNewAccounts {
    return YES;
}

- (BOOL)supportsProxySettings {
    return YES;
}

- (BOOL)requiresPassword {
    return YES;
}

- (void)registerStatuses {
	[[adium statusController] registerStatus:STATUS_NAME_AVAILABLE
							 withDescription:[[adium statusController] localizedDescriptionForCoreStatusName:STATUS_NAME_AVAILABLE]
									  ofType:AIAvailableStatusType
								  forService:self];
	
	[[adium statusController] registerStatus:STATUS_NAME_AWAY
							 withDescription:[[adium statusController] localizedDescriptionForCoreStatusName:STATUS_NAME_AWAY]
									  ofType:AIAwayStatusType
								  forService:self];
	
	[[adium statusController] registerStatus:STATUS_NAME_FREE_FOR_CHAT
							 withDescription:[[adium statusController] localizedDescriptionForCoreStatusName:STATUS_NAME_FREE_FOR_CHAT]
									  ofType:AIAvailableStatusType
								  forService:self];
	
	[[adium statusController] registerStatus:STATUS_NAME_DND
							 withDescription:[[adium statusController] localizedDescriptionForCoreStatusName:STATUS_NAME_DND]
									  ofType:AIAwayStatusType
								  forService:self];
	
	[[adium statusController] registerStatus:STATUS_NAME_EXTENDED_AWAY
							 withDescription:[[adium statusController] localizedDescriptionForCoreStatusName:STATUS_NAME_EXTENDED_AWAY]
									  ofType:AIAwayStatusType
								  forService:self];
	
	[[adium statusController] registerStatus:STATUS_NAME_INVISIBLE
							 withDescription:[[adium statusController] localizedDescriptionForCoreStatusName:STATUS_NAME_INVISIBLE]
									  ofType:AIInvisibleStatusType
								  forService:self];
}

/*
- (NSString *)filterUID:(NSString *)inUID removeIgnoredCharacters:(BOOL)removeIgnored {
    
}*/

- (NSString *)userNameLabel{
    /* RFC 3920, Section 3.1:
     *
     * For historical reasons, the address of an XMPP entity is called a Jabber Identifier or JID.
     */
    return AILocalizedString(@"Jabber ID",nil);
}

- (NSImage *)defaultServiceIcon
{
	static NSImage	*defaultServiceIcon = nil;
	if (!defaultServiceIcon) defaultServiceIcon = [[NSImage imageNamed:@"jabber" forClass:[self class]] retain];
	return defaultServiceIcon;
}


@end
