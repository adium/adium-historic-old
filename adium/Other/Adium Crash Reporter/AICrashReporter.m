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
#define EXCEPTIONS_PATH		[@"~/Desktop/accountstuff.txt" stringByExpandingTildeInPath]
#define CRASHES_PATH		[@"~/NOEMPTYPATHS" stringByExpandingTildeInPath]

@implementation AICrashReporter

- (void)awakeFromNib
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *theLog;
    
    if([fileManager fileExistsAtPath:EXCEPTIONS_PATH]){
		theLog = [NSString stringWithContentsOfFile:EXCEPTIONS_PATH];
//		[fileManager trashFileAtPath:EXCEPTIONS_PATH];
		
    }else if([fileManager fileExistsAtPath:CRASHES_PATH]){
		theLog = [NSString stringWithContentsOfFile:CRASHES_PATH];
		[fileManager trashFileAtPath:CRASHES_PATH];
		
    }else{
		[NSApp terminate:nil];
		return;
		
    }
    
	[window_MainWindow center];
	[window_MainWindow makeKeyAndOrderFront:nil];
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

