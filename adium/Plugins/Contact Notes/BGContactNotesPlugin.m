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

#import <AddressBook/AddressBook.h>
#import "BGContactNotesPlugin.h"
#import "AIContactListEditorPlugin.h"
#import "AIContactInfoWindowController.h"

#define	CONTACT_NOTES_NIB			@"ContactNotes"		 //Filename of the notes info view
#define	PREF_GROUP_NOTES			@"Notes"                //Preference group to store notes in
#define PREF_GROUP_ADDRESSBOOK                  @"Address Book"
#define KEY_AB_NOTE_SYNC                        @"AB Note Sync"

@interface BGContactNotesPlugin (PRIVATE) // should call an internal method to add to the list object :)
- (NSArray *)_addNotes:(NSString *)inNotes toObject:(AIListObject *)inObject notify:(BOOL)notify;
@end

@implementation BGContactNotesPlugin
// here follows a shameless hack of the alias support and idle time into a notes monstrosity
// with another hacked on limb attaching it to the address book

- (void)installPlugin
{    
    //Register ourself as a handle observer
    [[adium contactController] registerListObjectObserver:self];
    
    //Install the contact info view
    [NSBundle loadNibNamed:CONTACT_NOTES_NIB owner:self];
//    contactView = [[AIPreferenceViewController controllerWithName:@"Notes" 
//                                                     categoryName:@"None" 
//                                                             view:view_contactNotesInfoView 
//                                                         delegate:self] retain];
#warning    [[adium contactController] addContactInfoView:contactView];
    [textField_notes setDelegate:self];
    
    //Install our tooltip entry
    [[adium interfaceController] registerContactListTooltipEntry:self secondaryEntry:YES];
    
    //Observe preferences changes
    [[adium notificationCenter] addObserver:self 
                                   selector:@selector(preferencesChanged:) 
                                       name:Preference_GroupChanged 
                                     object:nil];
    
    //Observe external address book changes
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addressBookChanged:)
                                                 name:kABDatabaseChangedExternallyNotification
                                               object:nil];    
    
    activeListObject = nil;
    delayedChangesTimer = nil;
}

- (void)uninstallPlugin
{
    [delayedChangesTimer release]; delayedChangesTimer = nil;
    [[adium contactController] unregisterListObjectObserver:self];
}

- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_ADDRESSBOOK] == 0){
        NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_ADDRESSBOOK];
        noteSync = [[prefDict objectForKey:KEY_AB_NOTE_SYNC] boolValue];        
        [self updateAllContacts];
    }
}

- (void)addressBookChanged:(NSNotification *)notification
{
    [self updateAllContacts];
}

//Update all existing contacts
- (void)updateAllContacts
{
    [[adium contactController] updateAllListObjectsForObserver:self];
}

//Tooltip entry ---------------------------------------------------------------------------------------
- (NSString *)labelForObject:(AIListObject *)inObject
{
    return(@"Notes");
}

- (NSAttributedString *)entryForObject:(AIListObject *)inObject
{
    NSAttributedString * entry = nil;
    if([inObject preferenceForKey:@"Notes" group:PREF_GROUP_NOTES ignoreInheritedValues:YES]){
        NSString *currentNotes;
        currentNotes = [(AIListContact *)inObject preferenceForKey:@"Notes" group:PREF_GROUP_NOTES ignoreInheritedValues:YES];
        entry = [[NSAttributedString alloc] initWithString:currentNotes];
    }
    
    return([entry autorelease]);
}
// end tooltip ----------------------------------

- (IBAction)setNotes:(id)sender
{
    if (activeListObject) {
        NSString *notes = [textField_notes stringValue];
        
        //A 0 length note is no note at all.
        if ([notes length] == 0)
            notes = nil; 
        
        //Apply
        [self _addNotes:notes toObject:activeListObject notify:YES];
        
        //Save the note
        [activeListObject setPreference:notes forKey:@"Notes" group:PREF_GROUP_NOTES];
    }
}

- (void)configurePreferenceViewController:(AIPreferenceViewController *)inController forObject:(id)inObject
{
    //Be sure we've set the last changes and invalidated the timer
    if(delayedChangesTimer) {
        [self setNotes:nil];
        if ([delayedChangesTimer isValid]) {
            [delayedChangesTimer invalidate]; 
        }
        [delayedChangesTimer release]; delayedChangesTimer = nil;
    }
    
    NSString	*note;
    
    //Hold onto the object
    [activeListObject release]; activeListObject = nil;
    activeListObject = [inObject retain];
    
    //Fill in the current note
    if(note = [inObject preferenceForKey:@"Notes" group:PREF_GROUP_NOTES ignoreInheritedValues:YES]){
        [textField_notes setStringValue:note];
    }else{
        [textField_notes setStringValue:@""];
    }
}

//Called as contacts are created, load their notes
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{    
    return(nil);
}

//Private ---------------------------------------------------------------------------------------
- (NSArray *)_addNotes:(NSString *)inNotes toObject:(AIListObject *)inObject notify:(BOOL)notify;
{    
    return(nil);
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
                                                          selector:@selector(_delayedSetNotes:) 
                                                          userInfo:nil repeats:NO] retain];
}

- (void)_delayedSetNotes:(NSTimer *)inTimer
{
    [self setNotes:nil];
}

@end
