//
//  AICrashReporter.m
//  Adium XCode
//
//  Created by Adam Iser on Mon Dec 22 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <AIUtilities/AIUtilities.h>
#import "AICrashReporter.h"

#define BUG_REPORT_URL		@"http://www.visualdistortion.org/crash/post.jsp"
#define EXCEPTIONS_PATH		[@"~/Library/Logs/CrashReporter/Adium.exception.log" stringByExpandingTildeInPath]
#define CRASHES_PATH		[@"~/Library/Logs/CrashReporter/Adium.crash.log" stringByExpandingTildeInPath]

#define KEY_CRASH_EMAIL_ADDRESS		@"AdiumCrashReporterEmailAddress"
#define KEY_CRASH_AIM_ACCOUNT		@"AdiumCrashReporterAIMAccount"

@implementation AICrashReporter

//
- (id)init
{
    [super init];
    
    crashLog = nil;
    
    return(self);
}

//
- (void)dealloc
{
    [crashLog release];
    [super dealloc];
}

//
- (void)awakeFromNib
{
    NSFileManager 	*fileManager = [NSFileManager defaultManager];

	//Search for an exception log
    if([fileManager fileExistsAtPath:EXCEPTIONS_PATH]){
        [self reportCrashForLogAtPath:EXCEPTIONS_PATH];
    }else{
		int seconds = 10;
		
		while(seconds){
			//As soon as we find a log, snatch it and move on
			if([fileManager fileExistsAtPath:CRASHES_PATH] && [[NSString stringWithContentsOfFile:CRASHES_PATH] length]){
				[self reportCrashForLogAtPath:CRASHES_PATH];
				break;
			}	
			NSLog(@"No log yet, waiting a second... (%i)",seconds);
			[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
		}
	}
}

//Display the report crash window for the passed log
- (IBAction)reportCrashForLogAtPath:(NSString *)inPath
{
    NSString	*emailAddress, *aimAccount;
    NSRange		binaryRange;
    
	NSLog(@"LostAt:%@",inPath);
	NSLog(@"---");
    //Fetch and delete the log
    crashLog = [[NSString stringWithContentsOfFile:inPath] retain];
    //[[NSFileManager defaultManager] trashFileAtPath:inPath];
	NSLog(@"CrashLog:%@",crashLog);
    
    //Strip off binary descriptions.. we don't need to send all that
    binaryRange = [crashLog rangeOfString:@"Binary Images Description:"];
    if(binaryRange.location != NSNotFound){
        NSString	*shortLog = [crashLog substringToIndex:binaryRange.location];
        [crashLog release]; crashLog = [shortLog retain];
    }
    
    //Restore the user's email address and account if they've entered it previously
    if(emailAddress = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_CRASH_EMAIL_ADDRESS]){
        [textField_emailAddress setStringValue:emailAddress];
    }
    if(aimAccount = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_CRASH_AIM_ACCOUNT]){
        [textField_accountIM setStringValue:aimAccount];
    }
    
    //Open our window
    [window_MainWindow center];
    [window_MainWindow makeKeyAndOrderFront:nil];
}

//
- (BOOL)windowShouldClose:(id)sender
{
    //Remember the user's email address, account name
    [[NSUserDefaults standardUserDefaults] setObject:[textField_emailAddress stringValue]
                                              forKey:KEY_CRASH_EMAIL_ADDRESS];	
    [[NSUserDefaults standardUserDefaults] setObject:[textField_accountIM stringValue]
                                              forKey:KEY_CRASH_AIM_ACCOUNT];	
    
    return(YES);
}

//Display privacy information sheet
- (IBAction)showPrivacyDetails:(id)sender
{
    NSDictionary		*attributes = [NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:11] forKey:NSFontAttributeName];
    NSAttributedString	*attrLogString = [[[NSAttributedString alloc] initWithString:crashLog attributes:attributes] autorelease];
    
    //Fill in crash log
    [[textView_crashLog textStorage] setAttributedString:attrLogString];
	NSLog(@"%@",[attrLogString string]);
    
    //Display the sheet
    [NSApp beginSheet:panel_privacySheet
       modalForWindow:window_MainWindow
        modalDelegate:nil
       didEndSelector:nil
          contextInfo:nil];
}

//Close the privacy details sheet
- (IBAction)closePrivacyDetails:(id)sender
{
    [panel_privacySheet orderOut:nil];
    [NSApp endSheet:panel_privacySheet returnCode:0];
}

//User wants to send the report
- (IBAction)send:(id)sender
{
    NSString	*shortDescription = [textField_description stringValue];
    
    //Truncate description field to 300 characters
    if([shortDescription length] > 300){
        shortDescription = [shortDescription substringToIndex:300];
    }
    
    //Load the build information
    [self _loadBuildInformation];
    
    //Build the report
    NSDictionary	*crashReport = [NSDictionary dictionaryWithObjectsAndKeys:
        [[NSDate date] description], @"time",
        [NSString stringWithFormat:@"%@	(%@)",buildDate,buildNumber], @"build",
        [textField_emailAddress stringValue], @"email",
        [textField_accountIM stringValue], @"uid",
        shortDescription, @"short_desc",
        [textView_details string], @"desc",
        crashLog, @"log",
        nil];
    
    //Send
    [self sendReport:crashReport];
    
    //Close our window to terminate
    [window_MainWindow performClose:nil];
}

- (void)sendReport:(NSDictionary *)crashReport
{
    NSMutableString *reportString = [[[NSMutableString alloc] init] autorelease];
    NSEnumerator	*enumerator;
    NSString		*key;
    NSData 			*data = nil;
    
    //Compact the fields of the report into a long URL string
    enumerator = [[crashReport allKeys] objectEnumerator];
    while(key = [enumerator nextObject]){
        if([reportString length] != 0) [reportString appendString:@"&"];
        [reportString appendFormat:@"%@=%@", key, [[crashReport objectForKey:key] stringByEncodingURLEscapes]];
    }
    
    //
    while(!data || [data length] == 0){
        NSError 			*error;
        NSURLResponse 		*reply;
        NSMutableURLRequest *request;
        
        //Build the URL request
        request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:BUG_REPORT_URL]
                                          cachePolicy:NSURLRequestReloadIgnoringCacheData
                                      timeoutInterval:120];
        [request addValue:@"Adium 2.0a" forHTTPHeaderField:@"X-Adium-Bug-Report"];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:[reportString dataUsingEncoding:NSUTF8StringEncoding]];
        
        //start the progress spinner (using multi-threading)
        [progress_sending setUsesThreadedAnimation:YES];
        [progress_sending startAnimation:nil];
        
        //Attempt to send report
        data = [NSURLConnection sendSynchronousRequest:request returningResponse:&reply error:&error];
        
        //stop the progress spinner
        [progress_sending stopAnimation:nil];
        
        //Alert on failure, and offer the option to quit or retry
        if(!data || [data length] == 0){
            if(NSRunAlertPanel(@"Unable to send crash report",
                               [error localizedDescription],
                               @"Try Again", 
                               @"Quit",
                               nil) == NSAlertAlternateReturn){
                break;
            }
        }
    }
}

//Terminate if our window is closed
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}

//Load the current build date and our cryptic, non-sequential build number ;)
- (void)_loadBuildInformation
{
    //Grab the info from our buildnum script
    char *path, unixDate[256], num[256];
    if(path = (char *)[[[NSBundle mainBundle] pathForResource:@"buildnum" ofType:nil] fileSystemRepresentation])
    {
        FILE *f = fopen(path, "r");
        fscanf(f, "%s | %s", num, unixDate);
        fclose(f);
	
        if(*num){
            buildNumber = [[NSString stringWithFormat:@"%s", num] retain];
	}
	
	if(*unixDate){
	    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] initWithDateFormat:@"%B %e, %Y" allowNaturalLanguage:NO] autorelease];
            NSDate	    *date;
	    
	    date = [NSDate dateWithTimeIntervalSince1970:[[NSString stringWithCString:unixDate] doubleValue]];
            buildDate = [[dateFormatter stringForObjectValue:date] retain];
	}
    }
    
    //Default to empty strings if something goes wrong
    if(!buildDate) buildDate = [@"" retain];
    if(!buildNumber) buildNumber = [@"" retain];
}

@end

