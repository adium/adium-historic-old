//
//  BGThemeManageView.h
//  Adium XCode
//
//  Created by Brian Ganninger on Sun Jan 11 2004.
//

@interface BGThemeManageView : NSView {
    IBOutlet AIAlternatingRowTableView *table;
    IBOutlet NSButton *removeButton;
    IBOutlet NSButton *applyButton;
    id themesPlugin;
    NSArray *themes;
    int themeCount;
	NSString	*defaultThemePath;
}
-(NSString *)selectedTheme;
-(IBAction)removeTheme:(id)sender;
-(IBAction)applyTheme:(id)sender;
-(void)setPlugin:(id)newPlugin;
-(void)buildThemesList;
@end
