//
//  AICrashReporter.h
//  Adium XCode
//
//  Created by Adam Iser on Mon Dec 22 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface AICrashReporter : NSObject {
    IBOutlet	NSWindow		*window_MainWindow;
	IBOutlet	NSTextField		*textField_emailAddress;
	IBOutlet	NSTextField		*textField_emailDescription;
	IBOutlet	NSTextView		*textView_details;
	
	NSString	*crashLog;		//Current crash log
}

- (void)sendReport:(NSString *)bugReport;
- (BOOL)tryToSendReport:(NSString *)bugReport;
- (IBAction)send:(id)sender;
- (void)awakeFromNib;
- (IBAction)reportCrashForLogAtPath:(NSString *)inPath;

@end
