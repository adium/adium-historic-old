//
//  XtrasInstaller.h
//
//  Created by Sam McCandlish on 10/12/04.
//	Adapted by David Smith on 10/26/04
//

#import <Cocoa/Cocoa.h>

@interface XtrasInstaller : NSObject {
	IBOutlet NSWindow				*window;
	IBOutlet NSProgressIndicator	*progressBar;
	IBOutlet NSTextField			*percentText;
	IBOutlet NSButton				*cancelButton;
	
	NSURLDownload					*download;
	NSString						*dest;

	long long downloadSize;
	long long amountDownloaded;
}

-(IBAction)cancel:(id)sender;
-(void)installXtraAtURL:(NSURL *)url;
+(XtrasInstaller *)installer;
@end
