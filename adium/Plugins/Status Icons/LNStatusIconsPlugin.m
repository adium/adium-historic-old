#import "LNStatusIcon.h"
#import "LNStatusIconsPlugin.h"
#import "LNStatusIconsPreferences.h"

@interface LNStatusIconsPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation LNStatusIconsPlugin

- (void)installPlugin
{
    displayStatusIcon = NO;

    //Register our default preferences
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:STATUS_ICONS_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_STATUS_ICONS];
    [self preferencesChanged:nil];

    //Our preference view
    preferences = [[LNStatusIconsPreferences statusIconsPreferences] retain];
    [[adium contactController] registerListObjectObserver:self];

    //Observe
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];

    idleImage = [[NSImage imageNamed:@"IdleIcon" forClass:[self class]] retain];
    awayImage = [[NSImage imageNamed:@"AwayIcon" forClass:[self class]] retain];
}

- (void)uninstallPlugin
{
    [idleImage release];
    [awayImage release];
}

- (void)dealloc
{
    [super dealloc];
}

- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{
    NSArray			*modifiedAttributes = nil;
	
    if(	inModifiedKeys == nil ||
        [inModifiedKeys containsObject:@"Away"] ||
        [inModifiedKeys containsObject:@"Idle"]){
		
		LNStatusIcon			*statusIcon;
		AIMutableOwnerArray		*iconArray;
		NSArray					*imageArray;
		double					idle = 0;
		int						away = 0;
		
		// For now, until dragging is implemented, they are right aligned.
		// Also, they do not always display in the proper order.
		iconArray = [inObject displayArrayForKey:@"Right View"];
		[[inObject displayArrayForKey:@"Left View"]  setObject:nil withOwner:self];
		
		statusIcon = [iconArray objectWithOwner:self];
		
		if(displayStatusIcon){
			if(!statusIcon){
				statusIcon = [LNStatusIcon statusIcon];
				[iconArray setObject:statusIcon withOwner:self];
			}
			
			idle = [[inObject numberStatusObjectForKey:@"Idle"] doubleValue];
			away = [inObject integerStatusObjectForKey:@"Away"];
			
			if((away != 0) && (idle != 0)){
				imageArray = [NSArray arrayWithObjects:awayImage, idleImage, nil];
				[statusIcon setImageArray:imageArray];
				
			}else if(away != 0){
				imageArray = [NSArray arrayWithObjects:awayImage, nil];
				[statusIcon setImageArray:imageArray];
				
			}else if(idle != 0){
				imageArray = [NSArray arrayWithObjects:idleImage, nil];
				[statusIcon setImageArray:imageArray];
			}else{
				[iconArray setObject:nil withOwner:self];
			}
			
		}else{
			if(statusIcon){
				[iconArray setObject:nil withOwner:self];
			}
		}
		
		modifiedAttributes = [NSArray arrayWithObjects:@"Left View", @"Right View", nil];
	}
	
    return(modifiedAttributes);
}

- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_STATUS_ICONS] == 0){
		
		NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_STATUS_ICONS];
		
		//Release the old values..
		//Cache the preference values
		displayStatusIcon  = [[prefDict objectForKey:KEY_DISPLAY_STATUS_ICONS] boolValue];
		
        //Update all our status icons
		[[adium contactController] updateAllListObjectsForObserver:self];
    }
}

@end
