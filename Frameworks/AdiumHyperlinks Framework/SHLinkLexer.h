//
//  SHLinkFavoritesManageView.m
//  Adium
//
//  Created by Stephen Holt on Wed Apr 21 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

typedef enum {
    SH_URL_INVALID = -1,
    SH_URL_VALID = 0,
    SH_MAILTO_VALID,
    SH_FILE_VALID,
    SH_URL_DEGENERATE,
    SH_MAILTO_DEGENERATE
} URI_VERIFICATION_STATUS;
