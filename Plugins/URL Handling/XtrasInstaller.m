//
//  XtrasInstaller.m
//  IMGamesPluginInstaller
//
//  Created by Sam McCandlish on 10/12/04.
//

#import "XtrasInstaller.h"

@interface XtrasInstaller (PRIVATE)
- (void)closeInstaller;
@end

@implementation XtrasInstaller
+ (XtrasInstaller *)installer
{
	return([[XtrasInstaller alloc] init]);
}

- (id)init
{
	if(self = [super init]){
		download = nil;
		window = nil;
	}

	return(self);
}

- (void)dealloc
{
	[download release];

	[super dealloc];
}

- (IBAction)cancel:(id)sender;
{
	[download cancel];
}

- (void)sheetDidDismiss:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if(download) [download cancel];

	[self closeInstaller];
}

- (void)closeInstaller
{
	if(window) [window close];
	[self autorelease];	
}

- (void)installXtraAtURL:(NSURL *)url
{
	if([[url host] isEqualToString:@"www.adiumxtras.com"] || TRUE){
		NSURL	*urlToDownload;

		[NSBundle loadNibNamed:@"XtraProgressWindow" owner:self];
		[progressBar setUsesThreadedAnimation:YES];
		
		[progressBar setDoubleValue:0];
		[percentText setStringValue:@"0%"];
		[cancelButton setStringValue:AILocalizedString(@"Cancel",nil)];
		[window setTitle:AILocalizedString(@"Xtra Download",nil)];
		[window makeKeyAndOrderFront:self];

		urlToDownload = [[NSURL alloc] initWithScheme:@"http" host:[url host] path:[url path]];
		dest = [NSTemporaryDirectory() stringByAppendingPathComponent:[[urlToDownload path] lastPathComponent]];

		download = [[NSURLDownload alloc] initWithRequest:[NSURLRequest requestWithURL:urlToDownload] delegate:self];
		[download setDestination:dest allowOverwrite:YES];

		[urlToDownload release];

	}else{
		NSRunAlertPanel(AILocalizedString(@"Nontrusted Xtra", nil),
						AILocalizedString(@"This Xtra is not hosted by adiumxtras.com. Automatic installation is not allowed.", nil),
						AILocalizedString(@"Cancel", nil),
						nil, nil);
		[self closeInstaller];
	}
}

- (void)download:(NSURLDownload *)connection didReceiveResponse:(NSURLResponse *)response
{
	amountDownloaded = 0;
	downloadSize = [response expectedContentLength];
	[progressBar setMaxValue:(long long)downloadSize];
	[progressBar setDoubleValue:0.0];
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(unsigned)length
{
	amountDownloaded += (long long)length;
	if(downloadSize != NSURLResponseUnknownLength){
		[progressBar setDoubleValue:(double)amountDownloaded];
		[percentText setStringValue:[NSString stringWithFormat:@"%f%",(double)((amountDownloaded / (double)downloadSize) * 100)]];
	}
	else
		[progressBar setIndeterminate:YES];
}

- (BOOL)download:(NSURLDownload *)download shouldDecodeSourceDataOfMIMEType:(NSString *)encodingType {
    return(NO);
}

- (void)download:(NSURLDownload *)inDownload didFailWithError:(NSError *)error {
	NSString	*errorMsg;
	NSLog(@"Error: %@",error);
	errorMsg = [NSString stringWithFormat:@"An error occurred while downloading this Xtra: %@.",[error localizedDescription]];
	
	NSBeginAlertSheet(@"Xtra Downloading Error", @"Cancel", nil, nil, window, self,
					 NULL, @selector(sheetDidDismiss:returnCode:contextInfo:), nil, errorMsg);
}

- (void)downloadDidFinish:(NSURLDownload *)download {
	NSTask			*uncompress, *untar;
	NSPipe			*outputPipe;
	NSFileHandle	*output;
	NSString		*fileName;
	
	uncompress = [[NSTask alloc] init];
	[uncompress setLaunchPath:@"/usr/bin/gunzip"];
	[uncompress setArguments:[NSArray arrayWithObjects:@"-df" , [dest lastPathComponent] ,  nil]];
	[uncompress setCurrentDirectoryPath:[dest stringByDeletingLastPathComponent]];
	
	[uncompress launch];
	[uncompress waitUntilExit];
	[uncompress release];
	
	dest = [dest substringToIndex:[dest length] - 3];//remove the .gz
		
	untar = [[NSTask alloc] init];
	outputPipe = [NSPipe pipe];
	[untar setLaunchPath:@"/usr/bin/tar"];
	[untar setArguments:[NSArray arrayWithObjects:@"-xvf", [dest lastPathComponent]  , nil]];
	[untar setStandardOutput:outputPipe];
	[untar setCurrentDirectoryPath:[dest stringByDeletingLastPathComponent]];
		
	[untar launch];
	[untar waitUntilExit];
	[untar release];
	
	[[NSFileManager defaultManager] removeFileAtPath:dest handler:nil];
	
	//get the name of the untared file.
	output = [outputPipe fileHandleForReading];
	fileName = [[[[[NSString alloc] initWithData:[output readDataToEndOfFile]
									   encoding:NSASCIIStringEncoding] autorelease] componentsSeparatedByString:@"\n"] objectAtIndex:0];

	dest = [[dest stringByDeletingLastPathComponent] stringByAppendingPathComponent:fileName];

	//Open the file so Adium can install it and then delete it
	[[NSWorkspace sharedWorkspace] openTempFile:dest];
	
	[self closeInstaller];
}

@end
