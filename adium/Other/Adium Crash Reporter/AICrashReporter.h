//
//  AICrashReporter.h
//  Adium XCode
//
//  Created by Adam Iser on Mon Dec 22 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface AICrashReporter : NSObject {
    IBOutlet	NSWindow                    *window_MainWindow;
    IBOutlet	NSTextField                 *textField_emailAddress;
    IBOutlet	NSTextField                 *textField_accountIM;
    IBOutlet	NSTextField                 *textField_description;
    IBOutlet	NSTextView                  *textView_details;
    IBOutlet	NSProgressIndicator         *progress_sending;
    
    IBOutlet	NSPanel                     *panel_privacySheet;
    IBOutlet	NSTextView                  *textView_crashLog;
    
    NSString                                *crashLog;		//Current crash log
    
    NSString                                *buildNumber, *buildDate;
}

- (void)awakeFromNib;

- (IBAction)showPrivacyDetails:(id)sender;
- (IBAction)closePrivacyDetails:(id)sender;

- (IBAction)reportCrashForLogAtPath:(NSString *)inPath;
- (void)sendReport:(NSDictionary *)crashReport;
- (IBAction)send:(id)sender;

- (void)_loadBuildInformation;

@end
