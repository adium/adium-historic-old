//
//  adiumGaimRoomlist.m
//  Adium
//
//  Created by Evan Schoenberg on 1/22/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "adiumGaimRoomlist.h"

static void adiumGaimRoomlistDialogShowWithAccount(GaimAccount *account)
{
}
static void adiumGaimRoomlistNew(GaimRoomlist *list)
{
	GaimDebug (@"adiumGaimRoomlistNew");
}
static void adiumGaimRoomlistSetFields(GaimRoomlist *list, GList *fields)
{
}
static void adiumGaimRoomlistAddRoom(GaimRoomlist *list, GaimRoomlistRoom *room)
{
	GaimDebug (@"adiumGaimRoomlistAddRoom");
}
static void adiumGaimRoomlistInProgress(GaimRoomlist *list, gboolean flag)
{
}
static void adiumGaimRoomlistDestroy(GaimRoomlist *list)
{
}

static GaimRoomlistUiOps adiumGaimRoomlistOps = {
	adiumGaimRoomlistDialogShowWithAccount,
	adiumGaimRoomlistNew,
	adiumGaimRoomlistSetFields,
	adiumGaimRoomlistAddRoom,
	adiumGaimRoomlistInProgress,
	adiumGaimRoomlistDestroy
};

GaimRoomlistUiOps *adium_gaim_roomlist_get_ui_ops()
{
	return &adiumGaimRoomlistOps;
}
