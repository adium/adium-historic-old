//
//  ESImageViewWithImagePicker.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Jun 06 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "ESImageViewWithImagePicker.h"
#import "NSImagePicker.h"
#import "CBApplicationAdditions.h"
#import "ESImageAdditions.h"
#import "AIStringUtilities.h"

/*
 An NSImageView subclass which supports:
	- Address book-style image picker on double-click or enter, with delegate notification
		- Or, alternately, an Open Panel on double-click or enter, with delegate notification
	- Copying and pasting, with delegate notification
	- Drag and drop into and out of the image well, with delegate notification, 
		with support for animated GIFs and transparency
 	- Notifcation to the delegate of user's attempt to delete the image

 Note: ESImageViewWithImagePicker requires Panther or better for the Address book-style image picker to work.
 */

#define DRAGGING_THRESHOLD 6.0*6.0

@interface ESImageViewWithImagePicker (PRIVATE)
- (void)_initImageViewWithImagePicker;
- (void)showPickerController;
- (void)copy:(id)sender;
- (void)paste:(id)sender;
- (void)delete;
@end

@implementation ESImageViewWithImagePicker

// Init ------------------------------------------------------------------------------------------
#pragma mark Init
- (id)initWithCoder:(NSCoder *)aDecoder
{
    if((self = [super initWithCoder:aDecoder])) {
		[self _initImageViewWithImagePicker];
	}
    return self;
}

- (id)initWithFrame:(NSRect)frameRect
{
	if((self = [super initWithFrame:frameRect])) {
		[self _initImageViewWithImagePicker];
	}
	return self;
}

- (void)_initImageViewWithImagePicker
{
	pickerController = nil;
	title = nil;
	delegate = nil;
	
	lastResp = nil;
	shouldDrawFocusRing = NO;

	mouseDownPos = NSZeroPoint;
	
	useNSImagePickerController = YES;
	imagePickerClassIsAvailable = (NSClassFromString(@"NSImagePickerController") != nil);
}

- (void)dealloc
{
	if (pickerController){
		[[pickerController window] close];
		[pickerController release]; pickerController = nil;
	}
	
	delegate = nil;
	[title release];
	
	[super dealloc];
}

// Getters and Setters ----------------------------------------------------------------
#pragma mark Getters and Setters
- (void)setDelegate:(id)inDelegate
{
	delegate = inDelegate;
}
- (id)delegate
{
	return delegate;
}

- (void)setImage:(NSImage *)inImage
{
	[super setImage:inImage];
	if (pickerController){
		[pickerController selectionChanged];
	}
}

- (void)setTitle:(NSString *)inTitle
{
	[title release]; title = [inTitle retain];
	if (pickerController){
		[pickerController selectionChanged];
	}
}
- (NSString *)title
{
	return title;
}

- (void)setUseNSImagePickerController:(BOOL)inUseNSImagePickerController
{
	useNSImagePickerController = inUseNSImagePickerController;
}

// Monitoring user interaction --------------------------------------------------------
#pragma mark Monitoring user interaction

- (void)mouseDown:(NSEvent *)theEvent
{
	NSEvent *nextEvent;

	//Wait for the next event
	nextEvent = [[self window] nextEventMatchingMask:(NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask)
										   untilDate:[NSDate distantFuture]
											  inMode:NSEventTrackingRunLoopMode
											 dequeue:NO];

	mouseDownPos = [self convertPoint:[theEvent locationInWindow] fromView:nil];

	/* If the user starts dragging, don't call mouse down as we won't receive mouse dragged events, as it seems that
	 * NSImageView does some sort of event loop modification in response to a click. We didn't dequeue the event, so
	 * we don't have to handle it ourselves -- instead, the event loop will handle it after this invocation is complete. 
	 */
	if([nextEvent type] != NSLeftMouseDragged){
		[super mouseDown:theEvent];   
	}

	if ([theEvent clickCount] == 2){
		[self showPickerController];
	}
}

- (void)keyDown:(NSEvent *)theEvent
{
	unichar key = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
	
	if (key == NSDeleteCharacter || key == NSBackspaceCharacter){
		[self delete];
	}else if (key == NSEnterCharacter || key == NSCarriageReturnCharacter){
		[self showPickerController];
	}else{
		[super keyDown:theEvent];
	}
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	// Work out if the mouse has been dragged far enough - it stops accidental drags
	NSPoint mousePos = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	float dx = mousePos.x-mouseDownPos.x;
	float dy = mousePos.y-mouseDownPos.y;	
	if ((dx*dx) * (dy*dy) < DRAGGING_THRESHOLD){
		return;
	}
	
	NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
	
	//Add the images we can send data as (when requested)
	[pboard declareTypes:[NSArray arrayWithObjects:NSTIFFPboardType,NSPDFPboardType,nil]
				   owner:self];
	
	NSImage *dragImage = [[NSImage alloc] initWithSize:[[self image] size]];
	
	//Draw our original image as 50% transparent
	[dragImage lockFocus];
	[[self image] dissolveToPoint: NSZeroPoint fraction: .5];
	[dragImage unlockFocus];
	
	//We want the image to resize
	[dragImage setScalesWhenResized:YES];
	//Change to the size we are displaying
	[dragImage setSize:[self bounds].size];
	
	//Start the drag
	[self dragImage:dragImage
				 at:[self bounds].origin
			 offset:NSZeroSize
			  event:theEvent
		 pasteboard:pboard
			 source:self
		  slideBack:YES];
	[dragImage release];
}

//Declare what operations we can participate in as a drag and drop source
- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)flag
{
	return NSDragOperationCopy;
}

// Method called to support drag types we said we could offer
- (void)pasteboard:(NSPasteboard *)sender provideDataForType:(NSString *)type
{
    //sender has accepted the drag and now we need to send the data for the type we promised
    if([type isEqualToString:NSTIFFPboardType]){
		//set data for TIFF type on the pasteboard as requested
		[sender setData:[[self image] TIFFRepresentation] 
				forType:NSTIFFPboardType];
		
    }else if([type isEqualToString:NSPDFPboardType]){
		[sender setData:[self dataWithPDFInsideRect:[self bounds]] 
				forType:NSPDFPboardType];
    }
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	NSLog(@"draggingEntered: %@ : %@",[sender draggingSource],self);
	if([sender draggingSource] == self){
		return NSDragOperationNone;
	}else{
		return [super draggingEntered:sender];
	}
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
		NSLog(@"draggingUpdated: %@ : %@",[sender draggingSource],self);
	if([sender draggingSource] == self){
		return NSDragOperationNone;
	}else{
		return [super draggingUpdated:sender];
	}
}

//A new image was dragged into our view, changing [self image] to match it (NSImageView handles that)
- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
	BOOL notified = NO;
	
	[super concludeDragOperation:sender];
	
	if (pickerController){
		[pickerController selectionChanged];
	}
	
	//Use the file's data if possible
	if ([delegate respondsToSelector:@selector(imageViewWithImagePicker:didChangeToImageData:)]){
		NSPasteboard	*pboard = [sender draggingPasteboard];

		if([[pboard types] containsObject:NSFilenamesPboardType]){
			NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
		
			if([files count]){
				NSString	*imageFile = [files objectAtIndex:0];
				NSData		*imageData = [NSData dataWithContentsOfFile:imageFile];

				if(imageData){
					[delegate performSelector:@selector(imageViewWithImagePicker:didChangeToImageData:)
								   withObject:self
								   withObject:[NSData dataWithContentsOfFile:imageFile]];
					
					notified = YES;
				}
			}
		}
	}

	//Inform the delegate if we haven't informed it yet
	if (!notified && [delegate respondsToSelector:@selector(imageViewWithImagePicker:didChangeToImage:)]){
		[delegate performSelector:@selector(imageViewWithImagePicker:didChangeToImage:)
					   withObject:self
					   withObject:[self image]];
	}
}

// Copy / Paste ----------------------------------------------------------------
#pragma mark Copy / Paste
- (void)copy:(id)sender
{
	NSImage *image = [self image];
	if (image){
		[[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject:NSTIFFPboardType] owner:nil];
		[[NSPasteboard generalPasteboard] setData:[image TIFFRepresentation] forType:NSTIFFPboardType];
	}
}

- (void)paste:(id)sender
{
	NSPasteboard	*pb = [NSPasteboard generalPasteboard];
	NSString		*type = [pb availableTypeFromArray:
		[NSArray arrayWithObjects:NSTIFFPboardType, NSPDFPboardType, NSPICTPboardType,nil]];
	BOOL			success = NO;

    NSData			*imageData = (type ? [pb dataForType:type] : nil);
	if (imageData){
		NSImage *image = [[[NSImage alloc] initWithData:imageData] autorelease];
		if (image){
			[self setImage:image];
			
			if (pickerController){
				[pickerController selectionChanged];
			}
			
			//Inform the delegate
			if(delegate){
				if ([delegate respondsToSelector:@selector(imageViewWithImagePicker:didChangeToImageData:)]){
					[delegate performSelector:@selector(imageViewWithImagePicker:didChangeToImageData:)
								   withObject:self
								   withObject:imageData];
				}else if ([delegate respondsToSelector:@selector(imageViewWithImagePicker:didChangeToImage:)]){
					[delegate performSelector:@selector(imageViewWithImagePicker:didChangeToImage:)
								   withObject:self
								   withObject:image];
				}
			}
			
			success = YES;
		}
	}
	
	if(!success) NSBeep();
}

//Cut = copy + delete
- (void)cut:(id)sender
{
	[self copy:sender];
	[self delete];
}

- (void)delete
{
	if (delegate && [delegate respondsToSelector:@selector(deleteInImageViewWithImagePicker:)]){
		[delegate performSelector:@selector(deleteInImageViewWithImagePicker:)
					   withObject:self];
	}	
}

// NSImagePicker Access and Delegate ----------------------------------------------------------------
#pragma mark NSImagePicker Access and Delegate
//Public method for showing the image picker
- (IBAction)showImagePicker:(id)sender
{
	[self showPickerController];
}

- (void)showPickerController
{
	if (imagePickerClassIsAvailable && useNSImagePickerController){
		if (!pickerController){
			Class	imagePickerClass;
			NSPoint	pickerPoint;
			
			imagePickerClass = NSClassFromString(@"NSImagePickerController"); //10.2 doesn't have NSImagePickerController
			pickerController = [[imagePickerClass sharedImagePickerControllerCreate:YES] retain];
			[pickerController setDelegate:self];
			
			pickerPoint = [NSEvent mouseLocation];
			pickerPoint.y -= [[pickerController window] frame].size.height;
			
			[pickerController initAtPoint:pickerPoint inWindow: nil];
			[pickerController setHasChanged:NO];
		}
		
		[pickerController selectionChanged];
		[[pickerController window] makeKeyAndOrderFront: nil];

	}else{
		/* If we aren't using or can't use the image picker, use an open panel  */
		
		NSOpenPanel *openPanel;
		
		openPanel = [NSOpenPanel openPanel];
		[openPanel setTitle:[NSString stringWithFormat:AILocalizedString(@"Select Image",nil)]];
		
		if ([openPanel runModalForDirectory:nil file:nil types:[NSImage imageFileTypes]] == NSOKButton) {
			NSData	*imageData;
			NSImage *image;
			
			imageData = [NSData dataWithContentsOfFile:[openPanel filename]];
			image = (imageData ? [[[NSImage alloc] initWithData:imageData] autorelease] : nil);

			//Update the image view
			[self setImage:image];
			
			//Inform the delegate
			if(delegate){
				if ([delegate respondsToSelector:@selector(imageViewWithImagePicker:didChangeToImageData:)]){
					[delegate performSelector:@selector(imageViewWithImagePicker:didChangeToImageData:)
								   withObject:self
								   withObject:imageData];
					
				}else if ([delegate respondsToSelector:@selector(imageViewWithImagePicker:didChangeToImage:)]){
					[delegate performSelector:@selector(imageViewWithImagePicker:didChangeToImage:)
								   withObject:self
								   withObject:image];
				}
			}
		}
	}
}

// This gets called when the user selects OK on a new image
- (void)imagePicker: (id) sender selectedImage: (NSImage *) image
{
	//Update the NSImageView
	[self setImage:image];
	
	if (imagePickerClassIsAvailable){
		//Inform the delegate
		if(delegate){
			if ([delegate respondsToSelector:@selector(imageViewWithImagePicker:didChangeToImageData:)]){
				[delegate performSelector:@selector(imageViewWithImagePicker:didChangeToImageData:)
							   withObject:self
							   withObject:[image PNGRepresentation]];
				
			}else if ([delegate respondsToSelector:@selector(imageViewWithImagePicker:didChangeToImage:)]){
				[delegate performSelector:@selector(imageViewWithImagePicker:didChangeToImage:)
							   withObject:self
							   withObject:image];
			}
		}
		
		//Add the image to the list of recent images
		Class ipRecentPictureClass = NSClassFromString(@"NSIPRecentPicture"); //10.2 doesn't have NSIPRecentPicture 
		id recentPicture = [[[ipRecentPictureClass alloc] initWithOriginalImage:image] autorelease];
		[recentPicture setCurrent];
		[ipRecentPictureClass _saveChanges]; //Saves to ~/Library/Images/iChat Recent Pictures... but whatever, it works.

		//Picker controller is closing
		[pickerController release]; pickerController = nil;
	}
}

// This is called if the user cancels an image selection
- (void)imagePickerCanceled: (id) sender
{
	[[pickerController window] close];

	//Picker controller is closing
	[pickerController release]; pickerController = nil;
}

// This is called to provide an image when the delegate is first set and
// following selectionChanged messages to the controller.
// The junk on the end seems to be the selector name for the method itself
- (NSImage *)displayImageInPicker: junk
{
	NSImage	*theImage = nil;
	
	//Give the delegate an opportunity to supply an image which differs from the NSImageView's image
	if (delegate && [delegate respondsToSelector:@selector(imageForImageViewWithImagePicker:)]){
		theImage = [delegate imageForImageViewWithImagePicker:self];
	}
	
	return (theImage ? theImage : [self image]);
}

// This is called to give a title for the picker. It is called as above.
// Note that you must not return nil or the window gets upset
- (NSString *)displayTitleInPicker: junk
{
	return (title ? title : AILocalizedString(@"Image Picker",nil));
}


// Drawing ------------------------------------------------------------------------
#pragma mark Drawing
//Focus ring drawing code by Nicholas Riley, posted on cocoadev and available at:
//http://cocoa.mamasam.com/COCOADEV/2002/03/2/29535.php
- (BOOL)needsDisplay
{
	NSResponder *resp = nil;
	NSWindow	*window = [self window];
	
	if([window isKeyWindow]){
		resp = [window firstResponder];
		if(resp == lastResp){
			return([super needsDisplay]);
		}
		
	}else if(lastResp == nil){
		return([super needsDisplay]);
		
	}
	
	shouldDrawFocusRing = (resp != nil &&
						   [resp isKindOfClass:[NSView class]] &&
						   [(NSView *)resp isDescendantOf:self]); // [sic]
	lastResp = resp;
	
	[self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
	return(YES);
}

//Draw a focus ring around our view
- (void)drawRect:(NSRect)rect
{
	[super drawRect:rect];
	
	if(shouldDrawFocusRing){
		NSSetFocusRingStyle(NSFocusRingOnly);
		NSRectFill(rect);
	}
} 

@end
