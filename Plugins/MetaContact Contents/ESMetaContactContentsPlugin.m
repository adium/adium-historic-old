//
//  ESMetaContactContentsPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on 8/11/04.
//

#import "ESMetaContactContentsPlugin.h"


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
				NSImage	*statusIcon,	*serviceIcon;
				NSTextAttachmentCell	*cell;
				NSTextAttachment		*attachment;
				
				cell = [[NSTextAttachmentCell alloc] init];
				attachment = [[NSTextAttachment alloc] init];
				
				if (shouldAppendString){
					[entryString appendString:@"\r"];
				}else{
					shouldAppendString = YES;
				}
				
				statusIcon = [[contact displayArrayObjectForKey:@"Tab Status Icon"] imageByScalingToSize:NSMakeSize(9,9)];
				
				if(statusIcon){
					[cell setImage:statusIcon];
					[attachment setAttachmentCell:cell];
					
					[entry appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
				}
				
				[entryString appendString:[contact formattedUID]];
				
				serviceIcon = [AIServiceIcons serviceIconForObject:contact type:AIServiceIconSmall direction:AIIconNormal];
				//[[[listContact account] menuImage] imageByScalingToSize:NSMakeSize(9,9)];
				if (serviceIcon){

					[cell setImage:serviceIcon];
					[attachment setAttachmentCell:cell];
					
					[entryString appendString:@" "];
					[entry appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
				}
				
				[cell release];
				[attachment release];				
			}
		}
	}
    
    return([entry autorelease]);
}

@end
