/*
 *  AIContactListPrefKeys.h
 *  Adium
 *
 *  Created by Vinay Venkatesh on Tue Dec 17 2002.
 *  Copyright (c) 2002 Vinay Venkatesh. All rights reserved.
 *
 */

#include <Carbon/Carbon.h>

//GENERAL KEYS
#define CL_GEN_BG_COLOR				@"GEN_BG_COLOR"
#define CL_GEN_DEFAULT_FONT			@"GEN_DEFAULT_FONT"
#define CL_GEN_SHOW_GRID			@"GEN_SHOW_GRID"
#define CL_GEN_ALTERNATING_GRID	@"GEN_ALTERNATING_GRID"
#define CL_GEN_GRID_COLOR			@"GEN_GRID_COLOR"
#define CL_GEN_AUTORESIZE			@"GEN_AUTORESIZE"

#define CL_GEN_ALPHABETIZE			@"GEN_ALPHABETIZE"
#define CL_GEN_SORT_IDLE_AWAY		@"GEN_SORT_IDLE_AWAY"
#define CL_GEN_AUTO_RESIZE			@"GEN_AUTO_RESIZE"

//GROUP KEYS
IBOutlet	NSColorWell		*groupGroupColor;

IBOutlet	NSButton		*groupUseCustomFont;
IBOutlet	NSPopUpButton	*groupFontPopUp;
IBOutlet	NSPopUpButton	*groupFacePopUp;
IBOutlet	NSPopUpButton	*groupSizePopUp;

IBOutlet	NSButton		*groupShowChats;
IBOutlet	NSButton		*groupShowStrangers;
IBOutlet	NSButton		*groupShowOffline;
IBOutlet	NSButton		*groupHideEmpty;
