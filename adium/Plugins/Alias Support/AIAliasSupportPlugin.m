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

#import "AIAliasSupportPlugin.h"
#import "AIAdium.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AIContactListEditorPlugin.h"

#define	CONTACT_ALIAS_NIB		@"ContactAlias"		//Filename of the alias info view
#define	PREF_GROUP_ALIASES		@"Aliases"		//Preference group to store aliases in
#define ALIASES_DEFAULT_PREFS		@"Alias Defaults"

@interface AIAliasSupportPlugin (PRIVATE)
- (void)_applyAlias:(NSString *)inAlias toObject:(AIListObject *)inObject;
@end

@implementation AIAliasSupportPlugin

- (void)installPlugin
{
    //Register our default preferences
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:ALIASES_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_ALIASES];

    //Register ourself as a handle observer
    [[owner contactController] registerListObjectObserver:self];
    
    //Install the contact info view
    [NSBundle loadNibNamed:CONTACT_ALIAS_NIB owner:self];
    contactView = [[AIPreferenceViewController controllerWithName:@"Alias" categoryName:@"None" view:view_contactAliasInfoView delegate:self] retain];
    [[owner contactController] addContactInfoView:contactView];

    //Wait for the contact list editor to init so we can add our column
    [[owner notificationCenter] addObserver:self selector:@selector(registerColumn:) name:CONTACT_EDITOR_REGISTER_COLUMNS object:nil];
    
    activeListObject = nil;
}

- (void)uninstallPlugin
{
    //[[owner contactController] unregisterHandleObserver:self];
}

- (IBAction)setAlias:(id)sender
{
    NSString	*alias = [textField_alias stringValue];
    
    //Apply
    [self _applyAlias:alias toObject:activeListObject];

    //Save the alias
    [[owner preferenceController] setPreference:alias forKey:@"Alias" group:PREF_GROUP_ALIASES object:activeListObject];
}

- (void)configurePreferenceViewController:(AIPreferenceViewController *)inController forObject:(id)inObject
{
    NSString	*alias;

    //Hold onto the object
    [activeListObject release]; activeListObject = nil;
    activeListObject = [inObject retain];

    //Fill in the current alias
    alias = [[owner preferenceController] preferenceForKey:@"Alias" group:PREF_GROUP_ALIASES object:inObject];
    if(alias){
        [textField_alias setStringValue:alias];
    }else{
        [textField_alias setStringValue:@""];
    }        

}

//Called as contacts are created, load their alias
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys
{
    if(inModifiedKeys == nil){ //Only set an alias on contact creation
        NSString	*alias = [[owner preferenceController] preferenceForKey:@"Alias" group:PREF_GROUP_ALIASES object:inObject];

        if(alias != nil && [alias length] != 0){
            [self _applyAlias:alias toObject:inObject];
        }
    }
    
    return(nil);
}


//Contact Editor Column ----------------------------------------------------------------------
//Called as the contact list editor opens.
//In response to this notification, we need to register our editor column for editing aliases.
- (void)registerColumn:(NSNotification *)notification
{
    id <AIListEditor>	editorController = [notification object];

    //Register our editor column
    [editorController registerListEditorColumnController:self];

    //Remove the observer so we only register once
    [[owner notificationCenter] removeObserver:self name:CONTACT_EDITOR_REGISTER_COLUMNS object:nil];
}

- (NSString *)editorColumnLabel
{
    return(@"Alias");
}

- (NSString *)editorColumnStringForServiceID:(NSString *)inServiceID UID:(NSString *)inUID
{
    NSString	*alias = [[owner preferenceController] preferenceForKey:@"Alias" group:PREF_GROUP_ALIASES objectKey:[NSString stringWithFormat:@"(%@.%@)", inServiceID, inUID]];

    return(alias != nil ? alias : @"");
}

- (BOOL)editorColumnSetStringValue:(NSString *)value forServiceID:(NSString *)inServiceID UID:(NSString *)inUID
{
    AIListContact	*contact;

    contact = [[owner contactController] contactInGroup:nil
                                            withService:inServiceID
                                                    UID:inUID];

    if(contact){
        //Apply the alias
        [self _applyAlias:value toObject:contact];

        //Save the alias
        [[owner preferenceController] setPreference:value
                                             forKey:@"Alias"
                                              group:PREF_GROUP_ALIASES
                                          objectKey:[NSString stringWithFormat:@"(%@.%@)", inServiceID, inUID]];
    }

    return(YES);
}



//Private ---------------------------------------------------------------------------------------
//Apply an alias to an object (Does not save the alias!)
- (void)_applyAlias:(NSString *)inAlias toObject:(AIListObject *)inObject
{
    AIMutableOwnerArray	*displayNameArray;
    
    displayNameArray = [inObject displayArrayForKey:@"Display Name"];
    if(inAlias != nil && [inAlias length] != 0){
        [displayNameArray setObject:inAlias withOwner:self]; //Set the new alias
    }else{
        [displayNameArray setObject:nil withOwner:self]; //Remove the alias
    }
    
    [[owner contactController] listObjectAttributesChanged:activeListObject modifiedKeys:[NSArray arrayWithObject:@"Display Name"]];
}

@end




