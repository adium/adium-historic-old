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

@interface AIAliasSupportPlugin (PRIVATE)
- (NSArray *)_applyAlias:(NSString *)inAlias toObject:(AIListObject *)inObject notify:(BOOL)notify;
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

    prefs = [[AIAliasSupportPreferences displayFormatPreferences] retain];

    //load the formatting pref
    displayFormat = [[[[adium preferenceController] preferencesForGroup:PREF_GROUP_DISPLAYFORMAT] objectForKey:@"Long Display Format"] intValue];
    
    //Install the contact info view
    [NSBundle loadNibNamed:CONTACT_ALIAS_NIB owner:self];
    contactView = [[AIPreferenceViewController controllerWithName:@"Alias" 
													 categoryName:@"None" 
															 view:view_contactAliasInfoView 
														 delegate:self] retain];
    [[adium contactController] addContactInfoView:contactView];
    [textField_alias setDelegate:self];
    
    activeListObject = nil;
    delayedChangesTimer = nil;
}

- (void)uninstallPlugin
{
    [delayedChangesTimer release]; delayedChangesTimer = nil;
    [[adium contactController] unregisterListObjectObserver:self];
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

- (void)configurePreferenceViewController:(AIPreferenceViewController *)inController forObject:(id)inObject
{
    //Be sure we've set the last changes and invalidated the timer
    if(delayedChangesTimer) {
        [self setAlias:nil];
        if ([delayedChangesTimer isValid]) {
            [delayedChangesTimer invalidate]; 
        }
        [delayedChangesTimer release]; delayedChangesTimer = nil;
    }
    
    NSString	*alias;

    //Hold onto the object
    [activeListObject release]; activeListObject = nil;
    activeListObject = [inObject retain];

    //Fill in the current alias
    if(alias = [inObject preferenceForKey:@"Alias" group:PREF_GROUP_ALIASES ignoreInheritedValues:YES]){
        [textField_alias setStringValue:alias];
    }else{
        [textField_alias setStringValue:@""];
    }
}


//Called as contacts are created, load their alias
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{
    if((inModifiedKeys == nil) || ([inModifiedKeys containsObject:@"Formatted UID"])){
        return([self _applyAlias:[inObject preferenceForKey:@"Alias"
													  group:PREF_GROUP_ALIASES 
									  ignoreInheritedValues:YES]
						toObject:inObject
						  notify:YES]);
    }else{
		return(nil);
	}
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

//need to watch it as it changes as we can't catch the window closing
- (void)controlTextDidChange:(NSNotification *)theNotification
{
    if(delayedChangesTimer){
        if([delayedChangesTimer isValid]){
            [delayedChangesTimer invalidate]; 
        }
        [delayedChangesTimer release]; delayedChangesTimer = nil;
    }
    
    delayedChangesTimer = [[NSTimer scheduledTimerWithTimeInterval:0.5
                                                            target:self
                                                          selector:@selector(_delayedSetAlias:) 
                                                          userInfo:nil repeats:NO] retain];
}

- (void)_delayedSetAlias:(NSTimer *)inTimer
{
    [self setAlias:nil];
}

@end
