//
//  SmackXMPPPrivacyPlugin.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-08-04.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "SmackXMPPPrivacyPlugin.h"
#import "SmackXMPPAccount.h"
#import "SmackCocoaAdapter.h"
#import "SmackInterfaceDefinitions.h"
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <AIUtilities/AIStringUtilities.h>

//#define SmackAdiumPrivacyAIPrivacyOptionAllowAll @"http://adiumx.com/plugins/xmpp/AIPrivacyOptionAllowAll"
#define SmackAdiumPrivacyAIPrivacyOptionDenyAll @"http://adiumx.com/plugins/xmpp/AIPrivacyOptionDenyAll"
#define SmackAdiumPrivacyAIPrivacyOptionAllowUsers @"http://adiumx.com/plugins/xmpp/AIPrivacyOptionAllowUsers"
#define SmackAdiumPrivacyAIPrivacyOptionDenyUsers @"http://adiumx.com/plugins/xmpp/AIPrivacyOptionDenyUsers"
#define SmackAdiumPrivacyAIPrivacyOptionAllowContactList @"http://adiumx.com/plugins/xmpp/AIPrivacyOptionAllowContactList"

static NSMutableDictionary *privacyplugins = nil;

@interface SmackCocoaAdapter (PrivacyPlugin)

+ (SmackPrivacyListManager*)privacyListManagerForConnection:(SmackXMPPConnection*)conn;
+ (SmackPrivacyItem*)privacyItemWithType:(NSString *)type allow:(BOOL)allow order:(int)order;
+ (JavaVector *)getAllPrivacyListsForConnection:(SmackXMPPConnection*)conn;

@end

@implementation SmackCocoaAdapter (PrivacyPlugin)

+ (SmackPrivacyListManager *)privacyListManagerForConnection:(SmackXMPPConnection *)conn
{
    return [(Class <SmackPrivacyListManager>)[[self classLoader] loadClass:@"org.jivesoftware.smack.PrivacyListManager"] getInstanceFor:conn];
}

+ (SmackPrivacyItem *)privacyItemWithType:(NSString *)type allow:(BOOL)allow order:(int)order
{
    return [[[[self classLoader] loadClass:@"org.jivesoftware.smack.packet.PrivacyItem"] newWithSignature:@"(Ljava/lang/String;ZI)",type,allow,order] autorelease];
}

+ (JavaVector *)getAllPrivacyListsForConnection:(SmackXMPPConnection *)conn
{
    return [(Class <AdiumSmackBridge>)[[self classLoader] loadClass:@"net.adium.smackBridge.SmackBridge"] getAllPrivacyLists:conn];
}

@end

@implementation SmackXMPPAccount (PrivacyPlugin)

// just forward everything to our plugin, it's easier to handle the stuff there

-(BOOL)addListObject:(AIListObject *)inObject toPrivacyList:(AIPrivacyType)type
{
    SmackXMPPPrivacyPlugin *plugin = [privacyplugins objectForKey:[NSValue valueWithNonretainedObject:self]];
    if (plugin)
        return [plugin addListObject:inObject toPrivacyList:type];
    return NO;
}

-(BOOL)removeListObject:(AIListObject *)inObject fromPrivacyList:(AIPrivacyType)type
{
    SmackXMPPPrivacyPlugin *plugin = [privacyplugins objectForKey:[NSValue valueWithNonretainedObject:self]];
    if (plugin)
        return [plugin removeListObject:inObject fromPrivacyList:type];
    return NO;
}

-(NSArray *)listObjectsOnPrivacyList:(AIPrivacyType)type
{
    SmackXMPPPrivacyPlugin *plugin = [privacyplugins objectForKey:[NSValue valueWithNonretainedObject:self]];
    if (plugin)
        return [plugin listObjectsOnPrivacyList:type];
    return nil;
}

-(NSArray *)listObjectIDsOnPrivacyList:(AIPrivacyType)type
{
    SmackXMPPPrivacyPlugin *plugin = [privacyplugins objectForKey:[NSValue valueWithNonretainedObject:self]];
    if (plugin)
        return [plugin listObjectIDsOnPrivacyList:type];
    return nil;
}

-(void)setPrivacyOptions:(AIPrivacyOption)option
{
    SmackXMPPPrivacyPlugin *plugin = [privacyplugins objectForKey:[NSValue valueWithNonretainedObject:self]];
    if (plugin)
        [plugin setPrivacyOptions:option];
}

-(AIPrivacyOption)privacyOptions
{
    SmackXMPPPrivacyPlugin *plugin = [privacyplugins objectForKey:[NSValue valueWithNonretainedObject:self]];
    if (plugin)
        return [plugin privacyOptions];
    return AIPrivacyOptionUnknown;
}

@end

@implementation SmackXMPPPrivacyPlugin

- (id)initWithAccount:(SmackXMPPAccount*)a {
    if ((self = [super init])) {
        account = a;
        if (!privacyplugins)
            privacyplugins = [[NSMutableDictionary alloc] init];
        
        [privacyplugins setObject:self forKey:[NSValue valueWithNonretainedObject:account]];
    }
    return self;
}

- (void)dealloc
{
    [privacyplugins removeObjectForKey:[NSValue valueWithNonretainedObject:account]];
    if ([privacyplugins count] == 0) {
        [privacyplugins release];
        privacyplugins = nil;
    }
    [privacyLists release];
    [defaultListName release];

    [super dealloc];
}

// loads the permit and deny lists from the server
- (void)initializeLists
{
    privacyLists = [[NSMutableDictionary alloc] init];
    
    @try {
        //Look for the two permit and deny lists
        JavaVector		 *lists = [SmackCocoaAdapter getAllPrivacyListsForConnection:[account connection]];
        JavaIterator	 *privacyListsIterator = [lists iterator];
        SmackPrivacyList *list;
        while (([privacyListsIterator hasNext]) && (list = [privacyListsIterator next])) {
            if ([list isDefaultList]) {
				//XXX Woah, scary random retain.  This needs to be documented or fixed. -evands
                defaultListName = [[list description] retain];
            }

            NSMutableArray *locallist = [[NSMutableArray alloc] init];

            // convert to a list of AIListContacts
            JavaIterator	 *thisListIterator = [[list getItems] iterator];
            SmackPrivacyItem *item;
			
            while (([thisListIterator hasNext]) && (item = [thisListIterator next])) {
                if (![[item getType] isEqualToString:@"jid"]) {
                    continue; // ignore all non-jid entries
				}
	
                [locallist addObject:[[adium contactController] contactWithService:[account service] 
																		   account:account
																			   UID:[item getValue]]];
            }

            [privacyLists setObject:locallist forKey:[list description]];
			[locallist release];
        }

    } @catch(NSException *e) {
		//XXX Ugly error message, and it shouldn't be all caps. Fix long before localization occurs!
        [[adium interfaceController] handleErrorMessage:AILocalizedString(@"Error Getting Privacy Lists", nil) withDescription:[e reason]];
        return;
    }
}

- (void)uploadPrivacyList:(AIPrivacyType)type
{
    if (!privacyLists) {
        [self initializeLists];
	}

    SmackPrivacyListManager *listManager = [SmackCocoaAdapter privacyListManagerForConnection:[account connection]];

    if (type == AIPrivacyTypePermit) {
        JavaVector *list = [SmackCocoaAdapter vector];

        //Regenerate permit list from scratch
        NSEnumerator *enumerator = [[privacyLists objectForKey:SmackAdiumPrivacyAIPrivacyOptionAllowUsers] objectEnumerator];
        AIListObject *contact;
        int index = 1;
        
        while ((contact = [enumerator nextObject])) {
            SmackPrivacyItem *item = [SmackCocoaAdapter privacyItemWithType:@"jid" allow:YES order:index];
            [SmackCocoaAdapter invokeObject:item methodWithParamTypeAndParam:@"setValue",@"java.lang.String",[contact UID],nil];
            [list add:item];
            
            index++;
        }

        //The fallthrough rule is deny
        [list add:[SmackCocoaAdapter privacyItemWithType:nil allow:NO order:index]];
        
        [listManager updatePrivacyList:SmackAdiumPrivacyAIPrivacyOptionAllowUsers :list];

    } else {
        JavaVector *list = [SmackCocoaAdapter vector];
        
        // regenerate deny list from scratch
        NSEnumerator *enumerator = [[privacyLists objectForKey:SmackAdiumPrivacyAIPrivacyOptionDenyUsers] objectEnumerator];
        AIListObject *contact;
        int index = 1;
        
        while ((contact = [enumerator nextObject])) {
            SmackPrivacyItem *item = [SmackCocoaAdapter privacyItemWithType:@"jid" allow:NO order:index];
//            [item setValue:[contact UID]];
            [SmackCocoaAdapter invokeObject:item methodWithParamTypeAndParam:@"setValue",@"java.lang.String",[contact UID],nil];
            [list add:item];
            
            index++;
        }
        // there's no fallthrough rule, since allow is the default anyways
        
        [listManager updatePrivacyList:SmackAdiumPrivacyAIPrivacyOptionDenyUsers :list];
    }
}

//Add a list object to the privacy list (either AIPrivacyTypePermit or AIPrivacyTypeDeny). Return value indicates success.
-(BOOL)addListObject:(AIListObject *)inObject toPrivacyList:(AIPrivacyType)type
{
#warning Holy busted encapsulation, Batman. What is the story here?
    NSMutableArray *array = (NSMutableArray*)[self listObjectsOnPrivacyList:type];
    if (![array containsObject:inObject]) {
        [array addObject:inObject];
        @try {
            [self uploadPrivacyList:type];
        } @catch(NSException *e) {
            [[adium interfaceController] handleErrorMessage:AILocalizedString(@"Error Uploading Privacy List","Error Uploading Privacy List") withDescription:[e reason]];
            // remove it again
            [array removeObject:inObject];
            return NO;
        }
    }
    return YES;
}

//Remove a list object from the privacy list (either AIPrivacyTypePermit or AIPrivacyTypeDeny). Return value indicates success
-(BOOL)removeListObject:(AIListObject *)inObject fromPrivacyList:(AIPrivacyType)type
{
//XXX As above.
    NSMutableArray *array = (NSMutableArray*)[self listObjectsOnPrivacyList:type];
    if ([array containsObject:inObject]) {
        [array removeObject:inObject];
        @try {
            [self uploadPrivacyList:type];
        } @catch(NSException *e) {
            [[adium interfaceController] handleErrorMessage:AILocalizedString(@"Error Uploading Privacy List","Error Uploading Privacy List") withDescription:[e reason]];
            // re-add item
            [array addObject:inObject];
            return NO;
        }
    }
    return YES;
}

//Return an array of AIListContacts on the specified privacy list.  Returns an empty array if no contacts are on the list.
-(NSArray *)listObjectsOnPrivacyList:(AIPrivacyType)type
{
    if (!privacyLists)
        [self initializeLists];

    return [privacyLists objectForKey:((type == AIPrivacyTypePermit) ? 
									   SmackAdiumPrivacyAIPrivacyOptionAllowUsers :
									   SmackAdiumPrivacyAIPrivacyOptionDenyUsers)];
}

//Identical to the above method, except it returns an array of strings, not list objects
-(NSArray *)listObjectIDsOnPrivacyList:(AIPrivacyType)type
{
    if (!privacyLists)
        [self initializeLists];
    return [[self listObjectsOnPrivacyList:type] valueForKey:@"UID"];
}

//Set the privacy options
-(void)setPrivacyOptions:(AIPrivacyOption)option
{
    if (!privacyLists)
        [self initializeLists];
    SmackPrivacyListManager *listManager = [SmackCocoaAdapter privacyListManagerForConnection:[account connection]];

    NSMutableArray *list;
    [defaultListName release];
    switch (option) {
        case AIPrivacyOptionDenyAll:
            list = [privacyLists objectForKey:SmackAdiumPrivacyAIPrivacyOptionDenyAll];
            
            if (!list) {
                JavaVector *vector = [SmackCocoaAdapter vector];
                [vector add:[SmackCocoaAdapter privacyItemWithType:nil allow:NO order:1]];
                [listManager updatePrivacyList:SmackAdiumPrivacyAIPrivacyOptionDenyAll :vector];
                [privacyLists setObject:[NSArray array] forKey:SmackAdiumPrivacyAIPrivacyOptionDenyAll];
            }
            
            [listManager setDefaultListName:SmackAdiumPrivacyAIPrivacyOptionDenyAll];
            defaultListName = SmackAdiumPrivacyAIPrivacyOptionDenyAll;
            break;

        case AIPrivacyOptionAllowUsers:
            list = [privacyLists objectForKey:SmackAdiumPrivacyAIPrivacyOptionAllowUsers];
            
            if (!list) {
                JavaVector *vector = [SmackCocoaAdapter vector];
                
                // default list: don't allow anybody
                [vector add:[SmackCocoaAdapter privacyItemWithType:nil allow:NO order:1]];
                [listManager updatePrivacyList:SmackAdiumPrivacyAIPrivacyOptionAllowUsers :vector];
                [privacyLists setObject:[NSMutableArray array] forKey:SmackAdiumPrivacyAIPrivacyOptionAllowUsers];
            }
                
            [listManager setDefaultListName:SmackAdiumPrivacyAIPrivacyOptionAllowUsers];
            defaultListName = SmackAdiumPrivacyAIPrivacyOptionAllowUsers;
            break;

        case AIPrivacyOptionDenyUsers:
            list = [privacyLists objectForKey:SmackAdiumPrivacyAIPrivacyOptionDenyUsers];
            
            if (!list) {
                JavaVector *vector = [SmackCocoaAdapter vector];
                
                // default list: allow everybody
                [vector add:[SmackCocoaAdapter privacyItemWithType:nil allow:YES order:1]];
                [listManager updatePrivacyList:SmackAdiumPrivacyAIPrivacyOptionDenyUsers :vector];
                [privacyLists setObject:[NSMutableArray array] forKey:SmackAdiumPrivacyAIPrivacyOptionDenyUsers];
            }
                
            [listManager setDefaultListName:SmackAdiumPrivacyAIPrivacyOptionDenyUsers];
            defaultListName = SmackAdiumPrivacyAIPrivacyOptionDenyUsers;
            break;

        case AIPrivacyOptionAllowContactList:
            list = [privacyLists objectForKey:SmackAdiumPrivacyAIPrivacyOptionAllowContactList];
            
            if (!list) {
                JavaVector *vector = [SmackCocoaAdapter vector];
                
                // deny all users with subscription none
                SmackPrivacyItem *item = [SmackCocoaAdapter privacyItemWithType:@"subscription" allow:NO order:1];
//                [item setValue:@"none"];
                [SmackCocoaAdapter invokeObject:item methodWithParamTypeAndParam:@"setValue",@"java.lang.String",@"none",nil];
                [vector add:item];
                
                [listManager updatePrivacyList:SmackAdiumPrivacyAIPrivacyOptionAllowContactList :vector];
                [privacyLists setObject:[NSArray array] forKey:SmackAdiumPrivacyAIPrivacyOptionAllowContactList];
            }
                
            [listManager setDefaultListName:SmackAdiumPrivacyAIPrivacyOptionAllowContactList];
            defaultListName = SmackAdiumPrivacyAIPrivacyOptionAllowContactList;
            break;

//      case AIPrivacyOptionAllowAll:
        default:
            // remove the default list, which means that everything is coming through
            [listManager declineDefaultList];
            defaultListName = nil;
    }
}

//Get the privacy options
-(AIPrivacyOption)privacyOptions
{
    if (!privacyLists)
        [self initializeLists];
    if (defaultListName == nil)
        return AIPrivacyOptionAllowAll;
    if ([defaultListName isEqualToString:SmackAdiumPrivacyAIPrivacyOptionDenyAll])
        return AIPrivacyOptionDenyAll;
    if ([defaultListName isEqualToString:SmackAdiumPrivacyAIPrivacyOptionAllowUsers])
        return AIPrivacyOptionAllowUsers;
    if ([defaultListName isEqualToString:SmackAdiumPrivacyAIPrivacyOptionDenyUsers])
        return AIPrivacyOptionDenyUsers;
    if ([defaultListName isEqualToString:SmackAdiumPrivacyAIPrivacyOptionAllowContactList])
        return AIPrivacyOptionAllowContactList;
    
    // might be set by another client?
    return AIPrivacyOptionUnknown;
}

@end
