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
#import "AIContactListEditorPlugin.h"
#import "AIContactInfoWindowController.h"

#define	CONTACT_ALIAS_NIB			@"ContactAlias"		//Filename of the alias info view
#define	PREF_GROUP_ALIASES			@"Aliases"			//Preference group to store aliases in
#define ALIASES_DEFAULT_PREFS		@"Alias Defaults"
#define DISPLAYFORMAT_DEFAULT_PREFS	@"Display Format Defaults"

#define CONTACT_NAME_MENU_TITLE		AILocalizedString(@"Contact Name Format",nil)
#define ALIAS						AILocalizedString(@"Alias",nil)
#define ALIAS_SCREENNAME			AILocalizedString(@"Alias (Screen Name)",nil)
#define SCREENNAME_ALIAS			AILocalizedString(@"Screen Name (Alias)",nil)
#define SCREENNAME					AILocalizedString(@"Screen Name",nil)

@interface AIAliasSupportPlugin (PRIVATE)
- (NSArray *)_applyAlias:(NSString *)inAlias toObject:(AIListObject *)inObject notify:(BOOL)notify;
- (NSMenu *)_contactNameMenu;
@end

@implementation AIAliasSupportPlugin

- (void)installPlugin
{
    //Register our default preferences
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:ALIASES_DEFAULT_PREFS
																		forClass:[self class]]
										  forGroup:PREF_GROUP_ALIASES];
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:DISPLAYFORMAT_DEFAULT_PREFS
																		forClass:[self class]]
										  forGroup:PREF_GROUP_DISPLAYFORMAT];
   
    //Register ourself as a handle observer
    [[adium contactController] registerListObjectObserver:self];

    //Observe preferences changes
    [[adium notificationCenter] addObserver:self
								   selector:@selector(preferencesChanged:)
									   name:Preference_GroupChanged 
									 object:nil];

    //prefs = [[AIAliasSupportPreferences displayFormatPreferences] retain];

    //load the formatting pref
    //displayFormat = [[[[adium preferenceController] preferencesForGroup:PREF_GROUP_DISPLAYFORMAT] objectForKey:@"Long Display Format"] intValue];
    
    //Install the contact info view
    [NSBundle loadNibNamed:CONTACT_ALIAS_NIB owner:self];
    contactView = [[AIPreferenceViewController controllerWithName:@"Alias" 
													 categoryName:@"None" 
															 view:view_contactAliasInfoView 
														 delegate:self] retain];
    [[adium contactController] addContactInfoView:contactView];
    
	//Create the menu item
	menuItem_contactName = [[[NSMenuItem alloc] initWithTitle:CONTACT_NAME_MENU_TITLE
												target:nil
												action:nil
										 keyEquivalent:@""] autorelease];
	
	//Add the menu item (which will have _contactNameMenu as its submenu)
	[[adium menuController] addMenuItem:menuItem_contactName toLocation:LOC_View_Unnamed_A];
	
	menu_contactSubmenu = [[self _contactNameMenu] retain];
	[menuItem_contactName setSubmenu:menu_contactSubmenu];

    activeListObject = nil;
}

- (void)uninstallPlugin
{
    [[adium contactController] unregisterListObjectObserver:self];
	
	[menu_contactSubmenu release];
}

- (IBAction)setAlias:(id)sender
{
    if (activeListObject) {
        NSString	*alias = [textField_alias stringValue];
        
        //A 0 length alias is no alias at all.
        if ([alias length] == 0)
            alias = nil; 
        
        //Apply
        [self _applyAlias:alias toObject:activeListObject notify:YES];
        
        //Save the alias
        [activeListObject setPreference:alias forKey:@"Alias" group:PREF_GROUP_ALIASES];
    }
}

-(IBAction)changeFormat:(id)sender
{
    [[adium preferenceController] setPreference:[NSNumber numberWithInt:[sender tag]] forKey:@"Long Display Format" group:PREF_GROUP_DISPLAYFORMAT];
}

#warning Evan: We are not configuring the alias field properly when the contact switches.  I am not sure why not.
- (void)configurePreferenceViewController:(AIPreferenceViewController *)inController forObject:(id)inObject
{
	NSString	*alias;
	
//	NSLog(@"Alias preference is %@",[inObject preferenceForKey:@"Alias" group:PREF_GROUP_ALIASES ignoreInheritedValues:YES]);
    //Be sure we've set the last changes before changing which object we are editing
	[textField_alias fireImmediately];
    
    //Hold onto the object
    [activeListObject release]; activeListObject = nil;
    activeListObject = [inObject retain];

    //Fill in the current alias
    if(alias = [inObject preferenceForKey:@"Alias" group:PREF_GROUP_ALIASES ignoreInheritedValues:YES]){
        [textField_alias setStringValue:alias];
//		NSLog(@"After setting to %@ the stringValue is %@",alias,[textField_alias stringValue]);
    }else{
        [textField_alias setStringValue:@""];
    }
}


//Called as contacts are created, load their alias
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{
    if((inModifiedKeys == nil) || ([inModifiedKeys containsObject:@"FormattedUID"])){
		if([inObject isKindOfClass:[AIListContact class]]){
			return([self _applyAlias:[inObject preferenceForKey:@"Alias"
														  group:PREF_GROUP_ALIASES 
										  ignoreInheritedValues:YES]
							toObject:inObject
							  notify:YES]);
		}
    }
	
	return(nil);
}

- (void)preferencesChanged:(NSNotification *)notification
{
    if([(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_DISPLAYFORMAT] == 0){
        //load new displayFormat
        displayFormat = [[[[adium preferenceController] preferencesForGroup:PREF_GROUP_DISPLAYFORMAT] objectForKey:@"Long Display Format"] intValue]; 
		
        //Update all existing contacts
		[[adium contactController] updateAllListObjectsForObserver:self];
    }
}


//Private ---------------------------------------------------------------------------------------
//Apply an alias to an object (Does not save the alias!)
- (NSArray *)_applyAlias:(NSString *)inAlias toObject:(AIListObject *)inObject notify:(BOOL)notify
{
	NSArray				*modifiedAttributes;
    NSString			*displayName = nil;
    NSString			*longDisplayName = nil;
    NSString			*formattedUID = nil;

	AIMutableOwnerArray *displayNameArray = [inObject displayArrayForKey:@"Display Name"];
	
	//Apply the alias
	[[inObject displayArrayForKey:@"Adium Alias"] setObject:inAlias withOwner:self];
	[displayNameArray setObject:inAlias withOwner:self priorityLevel:High_Priority];

	//Get the displayName which is now active for the object
	displayName = [displayNameArray objectValue];
	
    //Build and set the Long Display Name
    switch(displayFormat)
    {
        case DISPLAY_NAME:
            longDisplayName = displayName;
		break;
            
        case DISPLAY_NAME_SCREEN_NAME:
            formattedUID = [inObject formattedUID];
            if(!displayName || [displayName compare:formattedUID] == 0){
                longDisplayName = displayName;
            }else{
                longDisplayName = [NSString stringWithFormat:@"%@ (%@)",displayName,formattedUID];
            }
		break;
            
        case SCREEN_NAME_DISPLAY_NAME:
            formattedUID = [inObject formattedUID];
            if(!displayName || [displayName compare:formattedUID] == 0){
                longDisplayName = displayName;
            }else{
                longDisplayName = [NSString stringWithFormat:@"%@ (%@)",formattedUID,displayName];
            }
		break;
            
        case SCREEN_NAME:
            longDisplayName = [inObject formattedUID];
		break;
			
        default:
			longDisplayName = nil;
		break;
    }
	
    //Apply the Long Display Name
    [[inObject displayArrayForKey:@"Long Display Name"] setObject:longDisplayName withOwner:self];
	
	//Notify
	modifiedAttributes = [NSArray arrayWithObjects:@"Display Name", @"Long Display Name", @"Adium Alias", nil];
	if(notify) [[adium contactController] listObjectAttributesChanged:inObject modifiedKeys:modifiedAttributes];
	
	return(modifiedAttributes);
}

- (NSMenu *)_contactNameMenu
{
	
	NSMenu		*choicesMenu;
	NSMenuItem  *menuItem;
	
	choicesMenu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
	
    menuItem = [[[NSMenuItem alloc] initWithTitle:ALIAS
                                           target:self
                                           action:@selector(changeFormat:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setTag:DISPLAY_NAME];
    [choicesMenu addItem:menuItem];
	
    menuItem = [[[NSMenuItem alloc] initWithTitle:ALIAS_SCREENNAME
                                           target:self
                                           action:@selector(changeFormat:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setTag:DISPLAY_NAME_SCREEN_NAME];
    [choicesMenu addItem:menuItem];
	
    menuItem = [[[NSMenuItem alloc] initWithTitle:SCREENNAME_ALIAS
                                           target:self
                                           action:@selector(changeFormat:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setTag:SCREEN_NAME_DISPLAY_NAME];
    [choicesMenu addItem:menuItem];
	
    menuItem = [[[NSMenuItem alloc] initWithTitle:SCREENNAME
                                           target:self
                                           action:@selector(changeFormat:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setTag:SCREEN_NAME];
    [choicesMenu addItem:menuItem];
	
	return choicesMenu;
}

@end
