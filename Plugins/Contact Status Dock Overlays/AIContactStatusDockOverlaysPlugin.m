/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import "AIContactStatusDockOverlaysPlugin.h"
#import "AIStatusOverlayPreferences.h"

#define SMALLESTRADIUS				15
#define RADIUSRANGE					36
#define SMALLESTFONTSIZE			14
#define FONTSIZERANGE				30

@interface AIContactStatusDockOverlaysPlugin (PRIVATE)
- (void)_setOverlay;
- (NSImage *)overlayImageFlash:(BOOL)flash;
- (void)preferencesChanged:(NSNotification *)notification;
- (void)flushPreferenceColorCache;
@end

@implementation AIContactStatusDockOverlaysPlugin

- (void)installPlugin
{
    //init
    unviewedObjectsArray = [[NSMutableArray alloc] init];
    overlayState = nil;
	
    //Install our preference view and register our default prefs
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:DOCK_OVERLAY_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_DOCK_OVERLAYS];
    preferences = [[AIStatusOverlayPreferences preferencePane] retain];
	
    //Register as a contact observer (For signed on / signed off)
    [[adium contactController] registerListObjectObserver:self];
	
	//Register as a chat observer (for unviewed content)
	[[adium contentController] registerChatObserver:self];
		
    //Prefs
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_LIST_THEME];
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_DOCK_OVERLAYS];
	
    //
    image1 = [[NSImage alloc] initWithSize:NSMakeSize(128,128)];
    image2 = [[NSImage alloc] initWithSize:NSMakeSize(128,128)];
}

- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{	
    if([group isEqualToString:PREF_GROUP_LIST_THEME]){
		//Snatch colors from status coloring plugin's prefs    
		[self flushPreferenceColorCache];
        signedOffColor = [[[prefDict objectForKey:KEY_SIGNED_OFF_COLOR] representedColor] retain];
        signedOnColor = [[[prefDict objectForKey:KEY_SIGNED_ON_COLOR] representedColor] retain];
        unviewedContentColor = [[[prefDict objectForKey:KEY_UNVIEWED_COLOR] representedColor] retain];
		
        backSignedOffColor = [[[prefDict objectForKey:KEY_LABEL_SIGNED_OFF_COLOR] representedColor] retain];
        backSignedOnColor = [[[prefDict objectForKey:KEY_LABEL_SIGNED_ON_COLOR] representedColor] retain];
        backUnviewedContentColor = [[[prefDict objectForKey:KEY_LABEL_UNVIEWED_COLOR] representedColor] retain];
    }
    
    if([group isEqualToString:PREF_GROUP_DOCK_OVERLAYS]){
        //
        showStatus = [[prefDict objectForKey:KEY_DOCK_SHOW_STATUS] boolValue];
        showContent = [[prefDict objectForKey:KEY_DOCK_SHOW_CONTENT] boolValue];
        overlayPosition = [[prefDict objectForKey:KEY_DOCK_OVERLAY_POSITION] boolValue];        
		
        //Reset our overlay
        [unviewedObjectsArray removeAllObjects];
        [self _setOverlay];
    }
    
}

- (void)flushPreferenceColorCache
{
	[signedOffColor release]; signedOffColor = nil;
	[signedOnColor release]; signedOnColor = nil;
	[unviewedContentColor release]; unviewedContentColor = nil;
	[backSignedOffColor release]; backSignedOffColor = nil;
	[backSignedOnColor release]; backSignedOnColor = nil;
	[backUnviewedContentColor release]; backUnviewedContentColor = nil;	
}

- (void)uninstallPlugin
{
	
}

- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	//Skip this entirely if overlays are off or this contact is within a metaContact
    if(showStatus){
		if([inObject isKindOfClass:[AIAccount class]]){
			//When an account signs on or off, force an overlay update as it may have silently changed
			//contacts' statuses
			if([inModifiedKeys containsObject:@"Online"]){
				NSEnumerator	*enumerator = [[[unviewedObjectsArray copy] autorelease] objectEnumerator];
				AIListObject	*listObject;
				while(listObject = [enumerator nextObject]){
					if(([listObject respondsToSelector:@selector(account)]) &&
					   ([listObject account] == inObject)){
						   [unviewedObjectsArray removeObject:listObject];
					   }
				}
				
				[self _setOverlay];
			}
			
		}else if(![[inObject containingObject] isKindOfClass:[AIMetaContact class]]){ 
			BOOL containsSignedOn = [inModifiedKeys containsObject:@"Signed On"];
			BOOL containsSignedOff = [inModifiedKeys containsObject:@"Signed Off"];
			
			if (containsSignedOn || containsSignedOff){
				if((containsSignedOn && [inObject integerStatusObjectForKey:@"Signed On"]) ||
				   (containsSignedOff && [inObject integerStatusObjectForKey:@"Signed Off"])){
					
					if(![unviewedObjectsArray containsObject:inObject]){
						[unviewedObjectsArray addObject:inObject];
					}
					
				}else{
					if([unviewedObjectsArray containsObject:inObject]){
						[unviewedObjectsArray removeObject:inObject];
					}
				}
				
				if(!silent){
					[self _setOverlay];
				}
			}
		}
	}

	return(nil);
}

- (NSSet *)updateChat:(AIChat *)inChat keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if(showContent){
		if (inModifiedKeys == nil || [inModifiedKeys containsObject:KEY_UNVIEWED_CONTENT]){
			
			if([inChat integerStatusObjectForKey:KEY_UNVIEWED_CONTENT]){
				if(![unviewedObjectsArray containsObjectIdenticalTo:inChat]){
					[unviewedObjectsArray addObject:inChat];
					[self _setOverlay];
				}
				
			}else{
				if([unviewedObjectsArray containsObjectIdenticalTo:inChat]){
					[unviewedObjectsArray removeObjectIdenticalTo:inChat];
					[self _setOverlay];
				}
			}
			
		}
	}
	
	return nil;
}

//
- (void)_setOverlay
{
    //Remove & release the current overlay state
    if(overlayState){
        [[adium dockController] removeIconStateNamed:@"ContactStatusOverlay"];
        [overlayState release]; overlayState = nil;
    }

    //Create & set the new overlay state
    if([unviewedObjectsArray count] != 0){
        //Set the state
        overlayState = [[AIIconState alloc] initWithImages:[NSArray arrayWithObjects:[self overlayImageFlash:NO], [self overlayImageFlash:YES], nil]
													 delay:0.5
												   looping:YES 
												   overlay:YES];
        [[adium dockController] setIconState:overlayState named:@"ContactStatusOverlay"];
    }   
}

//
- (NSImage *)overlayImageFlash:(BOOL)flash
{
    NSEnumerator		*enumerator;
    ESObjectWithStatus  *object;
    NSFont				*font;
    NSParagraphStyle	*paragraphStyle;
    float				dockIconScale;
    int					iconHeight;
    float				top, bottom;
    NSImage				*image = (flash ? image1 : image2);
	
    //Pre-calc some sizes
    dockIconScale = 1.0 - [[adium dockController] dockIconScale];
    iconHeight = (SMALLESTRADIUS + (RADIUSRANGE * dockIconScale));
    if(overlayPosition){
        top = 126;
        bottom = top - iconHeight;
    }else{
        bottom = 0;
        top = bottom + iconHeight;
    }
	
    //Set up the string details
    font = [NSFont boldSystemFontOfSize:(SMALLESTFONTSIZE + (FONTSIZERANGE * dockIconScale))];
    paragraphStyle = [NSParagraphStyle styleWithAlignment:NSCenterTextAlignment lineBreakMode:NSLineBreakByClipping];
	
    //Clear our image
    [image lockFocus];
    [[NSColor clearColor] set];
    NSRectFillUsingOperation(NSMakeRect(0, 0, 128, 128), NSCompositeCopy);
	
    //Draw overlays for each contact
    enumerator = [unviewedObjectsArray reverseObjectEnumerator];
    while((object = [enumerator nextObject]) && !(top < 0) && bottom < 128){
        float			left, right, arcRadius, stringInset;
        NSBezierPath	*path;
        NSColor			*backColor = nil, *textColor = nil, *borderColor = nil;
		
        //Create the pill frame
        arcRadius = (iconHeight / 2.0f);
        stringInset = (iconHeight / 4.0f);
        left = 1 + arcRadius;
        right = 127 - arcRadius;
		
        path = [NSBezierPath bezierPath];
        [path setLineWidth:((iconHeight/2.0) * 0.13333f)];
        //Top
        [path moveToPoint: NSMakePoint(left, top)];
        [path lineToPoint: NSMakePoint(right, top)];
		
        //Right rounded cap
        [path appendBezierPathWithArcWithCenter:NSMakePoint(right, top - arcRadius) 
										 radius:arcRadius
									 startAngle:90
									   endAngle:0
									  clockwise:YES];
        [path lineToPoint: NSMakePoint(right + arcRadius, bottom + arcRadius)];
        [path appendBezierPathWithArcWithCenter:NSMakePoint(right, bottom + arcRadius) 
										 radius:arcRadius
									 startAngle:0
									   endAngle:270
									  clockwise:YES];
		
        //Bottom
        [path moveToPoint: NSMakePoint(right, bottom)];
        [path lineToPoint: NSMakePoint(left, bottom)];
		
        //Left rounded cap
        [path appendBezierPathWithArcWithCenter:NSMakePoint(left, bottom + arcRadius)
										 radius:arcRadius
									 startAngle:270
									   endAngle:180
									  clockwise:YES];
        [path lineToPoint: NSMakePoint(left - arcRadius, top - arcRadius)];
        [path appendBezierPathWithArcWithCenter:NSMakePoint(left, top - arcRadius) radius:arcRadius startAngle:180 endAngle:90 clockwise:YES];
		
		/*
		 //Get our colors
		 if(!([contact integerStatusObjectForKey:KEY_UNVIEWED_CONTENT] && flash)){
			 backColor = [[contact displayArrayForKey:@"Label Color"] averageColor];
			 textColor = [[contact displayArrayForKey:@"Text Color"] averageColor];
		 }
		 */
		
        if([object integerStatusObjectForKey:KEY_UNVIEWED_CONTENT]){ //Unviewed
			if(flash){
                backColor = [NSColor whiteColor];
                textColor = [NSColor blackColor];
            }else{
                backColor = backUnviewedContentColor;
                textColor = unviewedContentColor;
            }
        }else if([object integerStatusObjectForKey:@"Signed On"]){ //Signed on
            backColor = backSignedOnColor;
            textColor = signedOnColor;
			
        }else if([object integerStatusObjectForKey:@"Signed Off"]){ //Signed off
            backColor = backSignedOffColor;
            textColor = signedOffColor;
			
        }
		
		if(!backColor){
			backColor = [NSColor whiteColor];
		}
		if(!textColor){
			textColor = [NSColor blackColor];
		}
		
        //Lighten/Darken the back color slightly
        if([backColor colorIsDark]){
            backColor = [backColor darkenBy:-0.15];
            borderColor = [backColor darkenBy:-0.3];
        }else{
            backColor = [backColor darkenBy:0.15];
            borderColor = [backColor darkenBy:0.3];
        }
		
        //Draw
        [backColor set];
        [path fill];
        [borderColor set];
        [path stroke];
		
        //Get the object's display name
        [[object displayName] drawInRect:NSMakeRect(0 + stringInset, bottom + 1, 128 - (stringInset * 2), top - bottom)
                           withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, paragraphStyle, NSParagraphStyleAttributeName, textColor, NSForegroundColorAttributeName, nil]];
		/*        
			nameString = [[[NSAttributedString alloc] initWithString:[contact displayName] attributes:[NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, paragraphStyle, NSParagraphStyleAttributeName, textColor, NSForegroundColorAttributeName, nil]] autorelease];
        [nameString drawInRect:NSMakeRect(0 + stringInset, bottom + 1, 128 - (stringInset * 2), top - bottom)];*/
		
        //Move up or down to the next pill
        if(overlayPosition){
            top -= (iconHeight + 7.0 * dockIconScale);
            bottom = top - iconHeight;
        }else{
            bottom += (iconHeight + 7.0 * dockIconScale);
            top = bottom + iconHeight;
        }
    }
	
    [image unlockFocus];
    
    return(image);
}

@end
