//
//  ESMetaContactContentsPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on 8/11/04.
//

#import "ESMetaContactContentsPlugin.h"

#define META_TOOLTIP_ICON_SIZE NSMakeSize(10,10)

@implementation ESMetaContactContentsPlugin

- (void)installPlugin
{
    //Install our tooltip entry
    [[adium interfaceController] registerContactListTooltipEntry:self secondaryEntry:YES];	
}

- (void)uninstallPlugin
{
	
}

//Tooltip entry ---------------------------------------------------------------------------------------
- (NSString *)labelForObject:(AIListObject *)inObject
{
	if ([inObject isKindOfClass:[AIMetaContact class]]){
		return(@"Contacts");
	}
	
	return nil;
}

- (NSAttributedString *)entryForObject:(AIListObject *)inObject
{
    NSMutableAttributedString	*entry = nil;
	
	if([inObject isKindOfClass:[AIMetaContact class]]){
		NSArray				*listContacts = [(AIMetaContact *)inObject listContacts];
		
		//Only display the contents if it has more than one contact within it.
		if ([listContacts count] > 1){
			NSMutableString	*entryString;
			AIListContact	*contact;
			NSEnumerator	*enumerator;
			BOOL			shouldAppendString = NO;
			
			entry = [[NSMutableAttributedString alloc] init];
			entryString = [entry mutableString];
			
			enumerator = [listContacts objectEnumerator];
			while(contact = [enumerator nextObject]){
				NSImage	*statusIcon, *serviceIcon;
				
				if (shouldAppendString){
					[entryString appendString:@"\r"];
				}else{
					shouldAppendString = YES;
				}
				
				statusIcon = [[contact displayArrayObjectForKey:@"Tab Status Icon"] imageByScalingToSize:META_TOOLTIP_ICON_SIZE];
				
				if(statusIcon){
					NSTextAttachment		*attachment;
					NSTextAttachmentCell	*cell;
						
					cell = [[[NSTextAttachmentCell alloc] init] autorelease];
					[cell setImage:statusIcon];
					
					attachment = [[[NSTextAttachment alloc] init] autorelease];
					[attachment setAttachmentCell:cell];
					
					[entry appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
				}
				
				[entryString appendString:[contact formattedUID]];
				
				serviceIcon = [[AIServiceIcons serviceIconForObject:contact type:AIServiceIconSmall direction:AIIconNormal]
									imageByScalingToSize:META_TOOLTIP_ICON_SIZE];
				if (serviceIcon){
					NSTextAttachment		*attachment;
					NSTextAttachmentCell	*cell;
					
					cell = [[[NSTextAttachmentCell alloc] init] autorelease];
					[cell setImage:serviceIcon];
					
					attachment = [[[NSTextAttachment alloc] init] autorelease];
					[attachment setAttachmentCell:cell];
					
					[entryString appendString:@" "];
					[entry appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
				}
			}
		}
	}
    
    return([entry autorelease]);
}

@end
