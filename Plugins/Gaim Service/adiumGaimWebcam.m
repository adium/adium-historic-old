//
//  adiumGaimWebcam.m
//  Adium
//
//  Created by Evan Schoenberg on 1/22/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "adiumGaimWebcam.h"

#pragma mark Webcam
static void adiumGaimWebcamNew(GaimWebcam *gwc)
{
	NSLog(@"adiumGaimWebcamNew");
	//	GaimGtkWebcam *c;
	//	char *tmp;
	//	
	//	c = g_new0(GaimGtkWebcam, 1);
	//	
	//	gwc->ui_data = c;
	//	c->gwc = gwc;
	//	
	//	c->button = gaim_pixbuf_button_from_stock(_("Close"), GTK_STOCK_CLOSE, GAIM_BUTTON_HORIZONTAL);
	//	c->vbox = gtk_vbox_new(FALSE, 0);
	//	gtk_box_pack_end_defaults(GTK_BOX(c->vbox), GTK_WIDGET(c->button));
	//	
	//	c->window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
	//	tmp = g_strdup_printf(_("%s's Webcam"), gwc->name);
	//	gtk_window_set_title(GTK_WINDOW(c->window), tmp);
	//	g_free(tmp);
	//	
	//	gtk_container_add(GTK_CONTAINER(c->window), c->vbox);
	//	
	//	g_signal_connect(G_OBJECT(c->button), "clicked",
	//					 G_CALLBACK(gaim_gtk_webcam_close_clicked), c);
	//	
	//	g_signal_connect(G_OBJECT(c->window), "destroy",
	//					 G_CALLBACK(gaim_gtk_webcam_destroy), c);
	//	
	//	c->image = gtk_image_new_from_stock(GAIM_STOCK_LOGO, gtk_icon_size_from_name(GAIM_ICON_SIZE_LOGO));
	//	gtk_box_pack_start_defaults(GTK_BOX(c->vbox), c->image);
	//	gtk_widget_show(GTK_WIDGET(c->image));
	//	
	//	gtk_widget_show(GTK_WIDGET(c->button));
	//	gtk_widget_show(GTK_WIDGET(c->vbox));
	//	gtk_widget_show(GTK_WIDGET(c->window));
}

static NSMutableData	*frameData = nil;

static void adiumGaimWebcamUpdate(GaimWebcam *gwc,
								  const unsigned char *image, unsigned int size,
								  unsigned int timestamp, unsigned int id)
{
	NSLog(@"adiumGaimWebcamUpdate (Frame %i , %i bytes)", id, size);
	
	if(!frameData){
		frameData = [[NSMutableData alloc] init];		
	}
	
	[frameData appendBytes:image length:size];
	
	//	GaimGtkWebcam *cam;
	//	WCFrame *f;
	//	GError *e = NULL;
	//	
	//	gaim_debug_misc("gtkwebcam", "Got %d bytes of frame %d.\n", size, id);
	//	
	//	cam = gwc->ui_data;
	//	if (!cam)
	//		return;
	//	
	//	f = wcframe_find_by_no(cam->frames, id);
	//	if (!f) {
	//		f = wcframe_new(cam, id);
	//		cam->frames = g_list_append(cam->frames, f);
	//	}
	//	
	//	if (!gdk_pixbuf_loader_write(f->loader, image, size, &e)) {
	//		gaim_debug(GAIM_DEBUG_MISC, "gtkwebcam", "gdk_pixbuf_loader_write failed:%s\n", e->message);
	//		g_error_free(e);
	//	}
}

static void adiumGaimWebcamFrameFinished(GaimWebcam *wc, unsigned int id)
{
	NSLog(@"adiumGaimWebcamFrameFinished");
	
	NSBitmapImageRep *rep;
	rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:(unsigned char **)[frameData bytes]
												  pixelsWide:320
												  pixelsHigh:240
											   bitsPerSample:8
											 samplesPerPixel:3
													hasAlpha:NO
													isPlanar:NO
											  colorSpaceName:NSCalibratedRGBColorSpace
												 bytesPerRow:0
												bitsPerPixel:0]; 
	
	NSLog(@"rep = %@",rep);
	
	//	[[AIObject sharedAdiumInstance] performSelectorOnMainThread:@selector(showImage:) withObject:rep waitUntilDone:NO];
	
	//	NSImage *tmp = [[NSImage alloc] init];
	//	[tmp addRepresentation:rep];
	
	
	
	
	
	
	//	[rep release];
	[frameData release]; frameData = nil;
	
	
	
	
	
	//	NSLog(@"Bitmap?: %@",[NSImage initWithData:frameData]);
	
	//	GaimGtkWebcam *cam;
	//	WCFrame *f;
	//	
	//	cam = wc->ui_data;
	//	if (!cam)
	//		return;
	//	f = wcframe_find_by_no(cam->frames, id);
	//	if (!f)
	//		return;
	//	
	//	gdk_pixbuf_loader_close(f->loader, NULL);
	//	f->loader = NULL;
}

static void adiumGaimWebcamClose(GaimWebcam *gwc)
{
	NSLog(@"adiumGaimWebcamClose");
	//	GaimGtkWebcam *cam;
	//	
	//	cam = gwc->ui_data;
	//	if (!cam)
	//		return;
	//	
	//	cam->gwc = NULL;
	//	gwc->ui_data = NULL;
}

static void adiumGaimWebcamGotInvite(GaimConnection *gc, const gchar *who)
{
	NSLog(@"adiumGaimWebcamGotInvite");
	
	gaim_webcam_invite_accept(gc, who);
	
	
	//	gchar *str = g_strdup_printf(_("%s has invited you (%s) to view their Webcam."), who,
	//								 gaim_connection_get_display_name(gc));
	//	struct _ggwc_gcaw *g = g_new0(struct _ggwc_gcaw, 1);
	//	
	//	g->gc = gc;
	//	g->who = g_strdup(who);
	//	
	//	gaim_request_action(gc, _("Webcam Invite"), str, _("Will you accept this invitation?"), 0,
	//						g, 2, _("Accept"), G_CALLBACK(_invite_accept), _("Decline"),
	//						G_CALLBACK(_invite_decline));
	//	
	//	g_free(str);
}

static struct gaim_webcam_ui_ops adiumGaimWebcamOps =
{
	adiumGaimWebcamNew,
	adiumGaimWebcamUpdate,
	adiumGaimWebcamFrameFinished,
	adiumGaimWebcamClose,
	adiumGaimWebcamGotInvite
};

struct gaim_webcam_ui_ops *adium_gaim_webcam_get_ui_ops(void)
{
	return &adiumGaimWebcamOps;
}

