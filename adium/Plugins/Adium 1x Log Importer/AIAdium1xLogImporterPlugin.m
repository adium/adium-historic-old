//
//  AIAdium1xLogImporterPlugin.m
//  Adium
//
//  Created by Adam Iser on Sat Jun 28 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIAdium1xLogImporterPlugin.h"
#import "AILogImporter.h"


#define LOGGER_DEFAULT_PREFS		@"LoggerDefaults"
#define PREF_GROUP_LOGGING		@"Logging"
#define KEY_HAS_IMPORTED_16_LOGS	@"Has Imported Adium 1.6 Logs"

@implementation AIAdium1xLogImporterPlugin

- (void)installPlugin
{
    //Register our default preferences
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:LOGGER_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_LOGGING];

    //Install the 'import logs' menu item

    //Import Adium 1.6 logs (Automatically... will probably remove this)
    if(![[[[owner preferenceController] preferencesForGroup:PREF_GROUP_LOGGING] objectForKey:KEY_HAS_IMPORTED_16_LOGS] boolValue]){

        [[AILogImporter logImporterWithOwner:owner] showWindow:nil];

        [[owner preferenceController] setPreference:[NSNumber numberWithBool:YES]
                                             forKey:KEY_HAS_IMPORTED_16_LOGS
                                              group:PREF_GROUP_LOGGING];
    }    
}

- (IBAction)showImportWindow:(id)sender
{
    
}

- (IBAction)beginImport:(id)sender
{
    
}

- (IBAction)cancel:(id)sender
{
    
}







@end
