//
//  ESImageViewWithImagePicker.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Jun 06 2004.

#import "ESImageViewWithImagePicker.h"

/*
 An NSImageView subclass which supports:
	- Address book-style image picker on double-click or enter, with delegate notification
	- Copying and pasting, with delegate notification
	- Drag and drop into and out of the image well, with delegate notification
 	- Notifcation to the delegate of user's attempt to delete the image

 Note: ESImageViewWithImagePicker requires Panther or better for the Address book-style image picker to work.
 */

@interface ESImageViewWithImagePicker (PRIVATE)
- (void)_initImageViewWithImagePicker;
- (void)showPickerController;
- (void)delete;
@end

@implementation ESImageViewWithImagePicker

// Init ------------------------------------------------------------------------------------------
#pragma mark Init
- (id)initWithCoder:(NSCoder *)aDecoder
{
    [super initWithCoder:aDecoder];
    [self _initImageViewWithImagePicker];
    return(self);
}

- (id)initWithFrame:(NSRect)frameRect
{
    [super initWithFrame:frameRect];
	[self _initImageViewWithImagePicker];
	return(self);
}

- (void)_initImageViewWithImagePicker
{
	pickerController = nil;
	title = nil;
	delegate = nil;
	
	lastResp = nil;
	shouldDrawFocusRing = NO;
	
	useNSImagePickerController = [NSApp isOnPantherOrBetter];
	[self setImageFrameStyle:NSImageFramePhoto];
}

- (void)dealloc
{
	if (pickerController){
		[[pickerController window] close];
		[pickerController release]; pickerController = nil;
	}
	
	delegate = nil;
	[title release];
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

// Monitoring user interaction --------------------------------------------------------
#pragma mark Monitoring user interaction

- (void)mouseDown:(NSEvent *)theEvent
{
	[super mouseDown:theEvent];
	
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

//A new image was dragged into our view, changing [self image] to match it (NSImageView handles that)
- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
	[super concludeDragOperation:sender];
	
	if (pickerController){
		[pickerController selectionChanged];
	}
	
	//Inform the delegate
	if (delegate && [delegate respondsToSelector:@selector(imageViewWithImagePicker:didChangeToImage:)]){
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
    NSData			*imageData = [pb dataForType:NSTIFFPboardType];
	if (imageData){
		NSImage *image = [[[NSImage alloc] initWithData:imageData] autorelease];
		if (image){
			[self setImage:image];
			
			if (pickerController){
				[pickerController selectionChanged];
			}
			
			//Inform the delegate
			if (delegate && [delegate respondsToSelector:@selector(imageViewWithImagePicker:didChangeToImage:)]){
				[delegate performSelector:@selector(imageViewWithImagePicker:didChangeToImage:)
							   withObject:self
							   withObject:image];
			}
		}
	}
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
- (void)showPickerController
{
	if (useNSImagePickerController)
	{
		if (!pickerController){
			Class	imagePickerClass;
			NSPoint	pickerPoint;
			
			imagePickerClass = NSClassFromString(@"NSImagePickerController"); //HACK so we don't crash on launch in 10.2
			pickerController = [[imagePickerClass sharedImagePickerControllerCreate:YES] retain];
			[pickerController setDelegate:self];
			
			pickerPoint = [NSEvent mouseLocation];
			pickerPoint.y -= [[pickerController window] frame].size.height;
			
			[pickerController initAtPoint:pickerPoint inWindow: nil];
			[pickerController setHasChanged:NO];
		}
		
		[pickerController selectionChanged];
		[[pickerController window] makeKeyAndOrderFront: nil];
	}
}

// This gets called when the user selects OK on a new image
- (void)imagePicker: (id) sender selectedImage: (NSImage *) image
{
	//Update the NSImageView
	[self setImage:image];
	
	if (useNSImagePickerController)
	{
		//Inform the delegate
		if (delegate && [delegate respondsToSelector:@selector(imageViewWithImagePicker:didChangeToImage:)]){
			[delegate performSelector:@selector(imageViewWithImagePicker:didChangeToImage:)
						   withObject:self
						   withObject:image];
		}
		
		//Add the image to the list of recent images
		Class ipRecentPictureClass = NSClassFromString(@"NSIPRecentPicture"); //HACK so we don't crash on launch in 10.2
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
