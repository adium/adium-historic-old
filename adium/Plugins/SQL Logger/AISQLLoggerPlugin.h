/*-------------------------------------------------------------------------------------------------------*\
| AISQLLoggerPlugin 1.0 for Adium                                                                         |
| AISQLLoggerPlugin: Copyright (C) 2003 Jeffrey Melloy.                                                   |
| <jmelloy@visualdistortion.org> <http://www.visualdistortion.org/adium/>                                 |
| Adium: Copyright (C) 2001-2003 Adam Iser. <adamiser@mac.com> <http://www.adiumx.com>                    |---\
\---------------------------------------------------------------------------------------------------------/   |
  | This program is free software; you can redistribute it and/or modify it under the terms of the GNU        |
  | General Public License as published by the Free Software Foundation; either version 2 of the License,     |
  | or (at your option) any later version.                                                                    |
  |                                                                                                           |
  | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even    |
  | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General         |
  | Public License for more details.                                                                          |
  |                                                                                                           |
  | You should have received a copy of the GNU General Public License along with this program; if not,        |
  | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.    |
  \----------------------------------------------------------------------------------------------------------*/

/**
 * 
 * $Revision: 1.7 $
 * $Date: 2003/11/25 22:09:41 $
 * $Author: jmelloy $
 *
 **/
#define KEY_SQL_LOGGER_ENABLE	@"Enable SQL Logging"
#define PREF_GROUP_LOGGING	@"SQLLogging"

#import "libpq-fe.h"
@class JMSQLLoggerAdvancedPreferences;

@interface AISQLLoggerPlugin : AIPlugin <AIPluginInfo> {
    JMSQLLoggerAdvancedPreferences  *advancedPreferences;
    PGconn                          *conn;
}

@end
