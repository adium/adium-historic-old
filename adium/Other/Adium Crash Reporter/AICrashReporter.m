//
//  AICrashReporter.m
//  Adium XCode
//
//  Created by Adam Iser on Mon Dec 22 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <AIUtilities/AIUtilities.h>
#import "AICrashReporter.h"

#define BUG_REPORT_URL		@"http://www.penguinmilitia.com/bugs.php"
#define EXCEPTIONS_PATH		[@"~/Desktop/crashLog.txt" stringByExpandingTildeInPath]
#define CRASHES_PATH		[@"~/NOEMPTYPATHS" stringByExpandingTildeInPath]

#define KEY_CRASH_EMAIL_ADDRESS		@"AdiumCrashReporterEmailAddress"

@implementation AICrashReporter

- (id)init
{
	[super init];
	
	crashLog = nil;
	
	return(self);
}

- (void)dealloc
{
	[crashLog release];
	[super dealloc];
}

- (void)awakeFromNib
{
    NSFileManager 	*fileManager = [NSFileManager defaultManager];
    
	//Search for either an exception log or a crash log
    if([fileManager fileExistsAtPath:EXCEPTIONS_PATH]){
		[self reportCrashForLogAtPath:EXCEPTIONS_PATH];
		
    }else if([fileManager fileExistsAtPath:CRASHES_PATH]){
		[self reportCrashForLogAtPath:CRASHES_PATH];
		
    }
	
}

//Display the report crash window for the passed log
- (IBAction)reportCrashForLogAtPath:(NSString *)inPath
{
	NSString	*emailAddress;
	
	//Fetch and delete the log
	crashLog = [[NSString stringWithContentsOfFile:inPath] retain];
	//[[NSFileManager defaultManager] trashFileAtPath:inPath];

	//Restore the user's email address if they've entered it previously
	if(emailAddress = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_CRASH_EMAIL_ADDRESS]){
		[textField_emailAddress setStringValue:emailAddress];
	}
	
	//Open our window
	[window_MainWindow center];
	[window_MainWindow makeKeyAndOrderFront:nil];
}

//
- (BOOL)windowShouldClose:(id)sender
{
	//Remember the user's email address
	[[NSUserDefaults standardUserDefaults] setObject:[textField_emailAddress stringValue]
											  forKey:KEY_CRASH_EMAIL_ADDRESS];	
	
	return(YES);
}

//Display privacy information sheet
- (IBAction)showPrivacyDetails:(id)sender
{
	NSDictionary		*attributes = [NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:11] forKey:NSFontAttributeName];
	NSAttributedString	*attrLogString = [[[NSAttributedString alloc] initWithString:crashLog attributes:attributes] autorelease];
	
	//Fill in crash log
	[[textView_crashLog textStorage] setAttributedString:attrLogString];
	
	//Display the sheet
    [NSApp beginSheet:panel_privacySheet
	   modalForWindow:window_MainWindow
		modalDelegate:nil//self
	   didEndSelector:nil//@selector(sheetDidEnd:returnCode:contextInfo:)
		  contextInfo:nil];
}

//
- (IBAction)closePrivacyDetails:(id)sender
{
	[panel_privacySheet orderOut:nil];
    [NSApp endSheet:panel_privacySheet returnCode:0];
}



- (IBAction)send:(id)sender
{
    NSString *bugReport;
    
    //construct the bug report via the entered fields
    
    //URL encode it
    
    [self sendReport:bugReport];
}

- (void)sendReport:(NSString *)bugReport
{    
    while(1)
    {
        if([self tryToSendReport:bugReport])
        {
            [NSApp terminate:nil];
            break;
        }
    }
}

- (BOOL)tryToSendReport:(NSString *)bugReport
{
    NSError 		*error;
    NSURLResponse 	*reply;
    NSMutableURLRequest *request;
    
    request = [NSMutableURLRequest 
        requestWithURL:[NSURL URLWithString:BUG_REPORT_URL]
	   cachePolicy:NSURLRequestReloadIgnoringCacheData
       timeoutInterval:120];
    [request addValue:@"Adium 2.0a" forHTTPHeaderField:@"X-Adium-Bug-Report"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[bugReport dataUsingEncoding:NSUTF8StringEncoding]];
    
    //start the barbershop pole (using multi-threading)
    
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&reply error:&error];

    //stop the pole
    if(data)      
        return YES;
    
    if(NSRunAlertPanel(
		       @"Unable to send crash report",
		       [error localizedDescription],
		       @"Try Again", 
		       @"Cancel",
		       nil) == NSAlertAlternateReturn)
    {
        [NSApp terminate:nil];
        return YES;
    }
    
    return NO;
}

//Terminate if our window is closed
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}

@end

