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
#define DISPLAYFORMAT_DEFAULT_PREFS	@"Display Format Defaults"

@interface AIAliasSupportPlugin (PRIVATE)
- (void)_applyAlias:(NSString *)inAlias toObject:(AIListObject *)inObject delayed:(BOOL)delayed;
@end

@implementation AIAliasSupportPlugin

- (void)installPlugin
{
    //Register our default preferences
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:ALIASES_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_ALIASES];
   [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:DISPLAYFORMAT_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_DISPLAYFORMAT];
   
    //Register ourself as a handle observer
    [[owner contactController] registerListObjectObserver:self];

    //Observe preferences changes
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(listObjectStatusChanged:) name:ListObject_StatusChanged object:nil];

    prefs = [[AIAliasSupportPreferences displayFormatPreferencesWithOwner:owner] retain];

    //load the formatting pref
    displayFormat = [[[owner preferenceController] preferenceForKey:@"Long Display Format" group:PREF_GROUP_DISPLAYFORMAT object:nil] intValue];
    
    //Install the contact info view
/*    [NSBundle loadNibNamed:CONTACT_ALIAS_NIB owner:self];
    contactView = [[AIPreferenceViewController controllerWithName:@"Alias" categoryName:@"None" view:view_contactAliasInfoView delegate:self] retain];
    [[owner contactController] addContactInfoView:contactView];*/

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
    [self _applyAlias:alias toObject:activeListObject delayed:NO];

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
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys delayed:(BOOL)delayed silent:(BOOL)silent
{
    if(inModifiedKeys == nil){ //Only set an alias on contact creation
        [self _applyAlias:[[owner preferenceController] preferenceForKey:@"Alias" group:PREF_GROUP_ALIASES object:inObject]
                 toObject:inObject
                  delayed:delayed];
    }
    
    return(nil);
}

- (void)preferencesChanged:(NSNotification *)notification
{
    if([(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_DISPLAYFORMAT] == 0){
        //load new displayFormat
        displayFormat = [[[owner preferenceController] preferenceForKey:@"Long Display Format" group:PREF_GROUP_DISPLAYFORMAT object:nil] intValue]; 

        //Update all existing contacts
        NSEnumerator * contactEnumerator = [[[owner contactController] allContactsInGroup:nil subgroups:YES] objectEnumerator];
        AIListObject * inObject;
        while (inObject = [contactEnumerator nextObject]){
            [self _applyAlias:[[inObject displayArrayForKey:@"Display Name"] objectWithOwner:self]
                     toObject:inObject
                      delayed:YES]; 
        }
    }
}

- (void)listObjectStatusChanged:(NSNotification *)notification
{
    NSArray		*keys = [[notification userInfo] objectForKey:@"Keys"];

    //Update the alias for this list object
    if([keys containsObject:@"Display Name"]){
        AIListObject 	*inObject = [notification object];
        
        [self _applyAlias:[[owner preferenceController] preferenceForKey:@"Alias" group:PREF_GROUP_ALIASES object:inObject]
                 toObject:inObject
                  delayed:NO];
    }
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
        [self _applyAlias:value toObject:contact delayed:NO];

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
- (void)_applyAlias:(NSString *)inAlias toObject:(AIListObject *)inObject delayed:(BOOL)delayed
{
    NSString		*displayName = nil;
    NSString		*longDisplayName = nil;

    //Setup the display names
    if(inAlias != nil && [inAlias length] != 0){
        //Display Name
        displayName = inAlias;
        
        //Long Display Name
        switch (displayFormat)
        {
            case DISPLAY_NAME: longDisplayName = displayName; break;
            case DISPLAY_NAME_SCREEN_NAME: longDisplayName = [NSString stringWithFormat:@"%@ (%@)",displayName,[inObject serverDisplayName]]; break;
            case SCREEN_NAME_DISPLAY_NAME: longDisplayName = [NSString stringWithFormat:@"%@ (%@)",[inObject serverDisplayName],displayName];  break;
            default: longDisplayName = nil; break;
        }
    }

    //Apply thevalues
    [[inObject displayArrayForKey:@"Display Name"] setObject:displayName withOwner:self];
    [[inObject displayArrayForKey:@"Long Display Name"] setObject:longDisplayName withOwner:self];
    [[owner contactController] listObjectAttributesChanged:inObject modifiedKeys:[NSArray arrayWithObject:@"Display Name"] delayed:delayed];
}

@end
