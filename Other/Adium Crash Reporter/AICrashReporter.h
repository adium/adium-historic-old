//
//  AICrashReporter.h
//  Adium
//
//  Created by Adam Iser on Mon Dec 22 2003.
//  Copyright 2003-2005 The Adium Team. All rights reserved.
//

#import <Foundation/Foundation.h>

#define RELATIVE_PATH_TO_CRASH_REPORTER	 @"/Contents/Resources/Adium Crash Reporter.app"
#define EXCEPTIONS_PATH					[@"~/Library/Logs/CrashReporter/Adium.exception.log" stringByExpandingTildeInPath]
#define CRASHES_PATH					[@"~/Library/Logs/CrashReporter/Adium.crash.log" stringByExpandingTildeInPath]

@interface AICrashReporter : NSObject {
    IBOutlet	NSWindow                    *window_MainWindow;
    IBOutlet	NSTextField                 *textField_emailAddress;
    IBOutlet	NSTextField                 *textField_accountIM;
    IBOutlet	NSTextField                 *textField_description;
    IBOutlet	ESTextViewWithPlaceholder   *textView_details;
    IBOutlet	NSProgressIndicator         *progress_sending;
    
    IBOutlet	NSPanel                     *panel_privacySheet;
    IBOutlet	NSTextView                  *textView_crashLog;
    
    NSString                                *crashLog;		//Current crash log
    
    NSString                                *buildNumber, *buildDate, *buildUser;
    NSAppleScript			    *slayerScript;
}

- (void)awakeFromNib;

- (IBAction)showPrivacyDetails:(id)sender;
- (IBAction)closePrivacyDetails:(id)sender;

- (BOOL)reportCrashForLogAtPath:(NSString *)inPath;
- (void)sendReport:(NSDictionary *)crashReport;
- (IBAction)send:(id)sender;

- (void)_loadBuildInformation;

@end
