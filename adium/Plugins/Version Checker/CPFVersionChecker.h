/* CPFVersionChecker */


@interface CPFVersionChecker : AIPlugin
{
    IBOutlet id textWithInformation;
    NSMenuItem *versionCheckerMenuItem;
    NSMenuItem *Version_Checker;
    
    //- (void)adiumIsUpToDate:(BOOL)upToDate;

}
- (IBAction)setDownloadsButtonPressed:(id)sender;

@end

/*
@interface CPFVersionChecker (PRIVATE)
- (void)adiumIsUpToDate:(BOOL)upToDate;
@end
*/
//@interface CPFVersionChecker : AIPlugin {
//    NSMutableDictionary		*typingDict;
//}



//@end