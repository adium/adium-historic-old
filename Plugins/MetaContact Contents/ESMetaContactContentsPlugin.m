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
	NSArray						*listContacts = [inObject listContacts];
	unsigned int				count = [listContacts count];
	
	if (count > 1){
		NSMutableString	*entryString;
		AIListContact	*listContact;
		
		entry = [[NSMutableAttributedString alloc] init];
		entryString = [entry mutableString];
		
		unsigned int i;
		
		for (i = 0; i < count; i++){
			listContact = [listContacts objectAtIndex:i];

			if (i > 0){
				[entryString appendString:@"\r"];
			}
			
			NSImage	*statusIcon = [[listContact displayArrayObjectForKey:@"Tab Status Icon"] imageByScalingToSize:NSMakeSize(9,9)];

			if (statusIcon){
				NSTextAttachment		*attachment;
				
				NSTextAttachmentCell	*cell = [[[NSTextAttachmentCell alloc] init] autorelease];
				[cell setImage:statusIcon];
				
				attachment = [[[NSTextAttachment alloc] init] autorelease];
				[attachment setAttachmentCell:cell];
				
				[entry appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
			}
			
			[entryString appendString:[listContact formattedUID]];
			
			NSImage	*serviceIcon = [[[listContact account] menuImage] imageByScalingToSize:NSMakeSize(9,9)];
			if (serviceIcon){
				NSTextAttachment		*attachment;
				
				NSTextAttachmentCell	*cell = [[[NSTextAttachmentCell alloc] init] autorelease];
				[cell setImage:serviceIcon];
				
				attachment = [[[NSTextAttachment alloc] init] autorelease];
				[attachment setAttachmentCell:cell];
				
				[entryString appendString:@" "];
				[entry appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
			}

		}
	}
    
    return([entry autorelease]);
}

@end
