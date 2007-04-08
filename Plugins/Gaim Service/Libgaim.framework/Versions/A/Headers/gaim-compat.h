/**
 * @file purple-compat.h Gaim Compat macros
 * @ingroup core
 *
 * pidgin
 *
 * Pidgin is the legal property of its developers, whose names are too numerous
 * to list here.  Please refer to the COPYRIGHT file distributed with this
 * source distribution.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 * @see @ref account-signals
 */
#ifndef _GAIM_COMPAT_H_
#define _GAIM_COMPAT_H_

/* from account.h */
#define GaimAccountUiOps GaimAccountUiOps
#define GaimAccount GaimAccount

#define GaimFilterAccountFunc GaimFilterAccountFunc
#define GaimAccountRequestAuthorizationCb GaimAccountRequestAuthorizationCb

#define purple_account_new           purple_account_new
#define purple_account_destroy       purple_account_destroy
#define purple_account_connect       purple_account_connect
#define purple_account_register      purple_account_register
#define purple_account_disconnect    purple_account_disconnect
#define purple_account_notify_added  purple_account_notify_added
#define purple_account_request_add   purple_account_request_add
#define purple_account_request_close   purple_account_request_close

#define purple_account_request_authorization     purple_account_request_authorization
#define purple_account_request_change_password   purple_account_request_change_password
#define purple_account_request_change_user_info  purple_account_request_change_user_info

#define purple_account_set_username            purple_account_set_username
#define purple_account_set_password            purple_account_set_password
#define purple_account_set_alias               purple_account_set_alias
#define purple_account_set_user_info           purple_account_set_user_info
#define purple_account_set_buddy_icon          purple_account_set_buddy_icon
#define purple_account_set_buddy_icon_path     purple_account_set_buddy_icon_path
#define purple_account_set_protocol_id         purple_account_set_protocol_id
#define purple_account_set_connection          purple_account_set_connection
#define purple_account_set_remember_password   purple_account_set_remember_password
#define purple_account_set_check_mail          purple_account_set_check_mail
#define purple_account_set_enabled             purple_account_set_enabled
#define purple_account_set_proxy_info          purple_account_set_proxy_info
#define purple_account_set_status_types        purple_account_set_status_types
#define purple_account_set_status              purple_account_set_status
#define purple_account_set_status_list         purple_account_set_status_list

#define purple_account_clear_settings   purple_account_clear_settings

#define purple_account_set_int    purple_account_set_int
#define purple_account_set_string purple_account_set_string
#define purple_account_set_bool   purple_account_set_bool

#define purple_account_set_ui_int     purple_account_set_ui_int
#define purple_account_set_ui_string  purple_account_set_ui_string
#define purple_account_set_ui_bool    purple_account_set_ui_bool

#define purple_account_is_connected     purple_account_is_connected
#define purple_account_is_connecting    purple_account_is_connecting
#define purple_account_is_disconnected  purple_account_is_disconnected

#define purple_account_get_username           purple_account_get_username
#define purple_account_get_password           purple_account_get_password
#define purple_account_get_alias              purple_account_get_alias
#define purple_account_get_user_info          purple_account_get_user_info
#define purple_account_get_buddy_icon         purple_account_get_buddy_icon
#define purple_account_get_buddy_icon_path    purple_account_get_buddy_icon_path
#define purple_account_get_protocol_id        purple_account_get_protocol_id
#define purple_account_get_protocol_name      purple_account_get_protocol_name
#define purple_account_get_connection         purple_account_get_connection
#define purple_account_get_remember_password  purple_account_get_remember_password
#define purple_account_get_check_mail         purple_account_get_check_mail
#define purple_account_get_enabled            purple_account_get_enabled
#define purple_account_get_proxy_info         purple_account_get_proxy_info
#define purple_account_get_active_status      purple_account_get_active_status
#define purple_account_get_status             purple_account_get_status
#define purple_account_get_status_type        purple_account_get_status_type
#define purple_account_get_status_type_with_primitive \
	purple_account_get_status_type_with_primitive

#define purple_account_get_presence       purple_account_get_presence
#define purple_account_is_status_active   purple_account_is_status_active
#define purple_account_get_status_types   purple_account_get_status_types

#define purple_account_get_int            purple_account_get_int
#define purple_account_get_string         purple_account_get_string
#define purple_account_get_bool           purple_account_get_bool

#define purple_account_get_ui_int     purple_account_get_ui_int
#define purple_account_get_ui_string  purple_account_get_ui_string
#define purple_account_get_ui_bool    purple_account_get_ui_bool


#define purple_account_get_log      purple_account_get_log
#define purple_account_destroy_log  purple_account_destroy_log

#define purple_account_add_buddy       purple_account_add_buddy
#define purple_account_add_buddies     purple_account_add_buddies
#define purple_account_remove_buddy    purple_account_remove_buddy
#define purple_account_remove_buddies  purple_account_remove_buddies

#define purple_account_remove_group  purple_account_remove_group

#define purple_account_change_password  purple_account_change_password

#define purple_account_supports_offline_message  purple_account_supports_offline_message

#define purple_accounts_add      purple_accounts_add
#define purple_accounts_remove   purple_accounts_remove
#define purple_accounts_delete   purple_accounts_delete
#define purple_accounts_reorder  purple_accounts_reorder

#define purple_accounts_get_all         purple_accounts_get_all
#define purple_accounts_get_all_active  purple_accounts_get_all_active

#define purple_accounts_find   purple_accounts_find

#define purple_accounts_restore_current_statuses  purple_accounts_restore_current_statuses

#define purple_accounts_set_ui_ops  purple_accounts_set_ui_ops
#define purple_accounts_get_ui_ops  purple_accounts_get_ui_ops

#define purple_accounts_get_handle  purple_accounts_get_handle

#define purple_accounts_init    purple_accounts_init
#define purple_accounts_uninit  purple_accounts_uninit

/* from accountopt.h */

#define GaimAccountOption     GaimAccountOption
#define GaimAccountUserSplit  GaimAccountUserSplit

#define purple_account_option_new         purple_account_option_new
#define purple_account_option_bool_new    purple_account_option_bool_new
#define purple_account_option_int_new     purple_account_option_int_new
#define purple_account_option_string_new  purple_account_option_string_new
#define purple_account_option_list_new    purple_account_option_list_new

#define purple_account_option_destroy  purple_account_option_destroy

#define purple_account_option_set_default_bool    purple_account_option_set_default_bool
#define purple_account_option_set_default_int     purple_account_option_set_default_int
#define purple_account_option_set_default_string  purple_account_option_set_default_string

#define purple_account_option_set_masked  purple_account_option_set_masked

#define purple_account_option_set_list  purple_account_option_set_list

#define purple_account_option_add_list_item  purple_account_option_add_list_item

#define purple_account_option_get_type     purple_account_option_get_type
#define purple_account_option_get_text     purple_account_option_get_text
#define purple_account_option_get_setting  purple_account_option_get_setting

#define purple_account_option_get_default_bool        purple_account_option_get_default_bool
#define purple_account_option_get_default_int         purple_account_option_get_default_int
#define purple_account_option_get_default_string      purple_account_option_get_default_string
#define purple_account_option_get_default_list_value  purple_account_option_get_default_list_value

#define purple_account_option_get_masked  purple_account_option_get_masked
#define purple_account_option_get_list    purple_account_option_get_list

#define purple_account_user_split_new      purple_account_user_split_new
#define purple_account_user_split_destroy  purple_account_user_split_destroy

#define purple_account_user_split_get_text           purple_account_user_split_get_text
#define purple_account_user_split_get_default_value  purple_account_user_split_get_default_value
#define purple_account_user_split_get_separator      purple_account_user_split_get_separator

/* from blist.h */

#define GaimBuddyList    GaimBuddyList
#define GaimBlistUiOps   GaimBlistUiOps
#define GaimBlistNode    GaimBlistNode

#define GaimChat     GaimChat
#define GaimGroup    GaimGroup
#define GaimContact  GaimContact
#define GaimBuddy    GaimBuddy

#define GAIM_BLIST_GROUP_NODE     GAIM_BLIST_GROUP_NODE
#define GAIM_BLIST_CONTACT_NODE   PURPLE_BLIST_CONTACT_NODE
#define GAIM_BLIST_BUDDY_NODE     GAIM_BLIST_BUDDY_NODE
#define GAIM_BLIST_CHAT_NODE      GAIM_BLIST_CHAT_NODE
#define GAIM_BLIST_OTHER_NODE     GAIM_BLIST_OTHER_NODE
#define GaimBlistNodeType         GaimBlistNodeType

#define GAIM_BLIST_NODE_IS_CHAT       GAIM_BLIST_NODE_IS_CHAT
#define GAIM_BLIST_NODE_IS_BUDDY      GAIM_BLIST_NODE_IS_BUDDY
#define GAIM_BLIST_NODE_IS_CONTACT    GAIM_BLIST_NODE_IS_CONTACT
#define GAIM_BLIST_NODE_IS_GROUP      GAIM_BLIST_NODE_IS_GROUP

#define GAIM_BUDDY_IS_ONLINE GAIM_BUDDY_IS_ONLINE

#define GAIM_BLIST_NODE_FLAG_NO_SAVE  GAIM_BLIST_NODE_FLAG_NO_SAVE
#define GaimBlistNodeFlags            GaimBlistNodeFlags

#define GAIM_BLIST_NODE_HAS_FLAG     GAIM_BLIST_NODE_HAS_FLAG
#define GAIM_BLIST_NODE_SHOULD_SAVE  GAIM_BLIST_NODE_SHOULD_SAVE

#define GAIM_BLIST_NODE_NAME   GAIM_BLIST_NODE_NAME


#define purple_blist_new  purple_blist_new
#define purple_set_blist  purple_set_blist
#define purple_get_blist  purple_get_blist

#define purple_blist_get_root   purple_blist_get_root
#define purple_blist_node_next  purple_blist_node_next

#define purple_blist_show  purple_blist_show

#define purple_blist_destroy  purple_blist_destroy

#define purple_blist_set_visible  purple_blist_set_visible

#define purple_blist_update_buddy_status  purple_blist_update_buddy_status
#define purple_blist_update_buddy_icon    purple_blist_update_buddy_icon


#define purple_blist_alias_contact       purple_blist_alias_contact
#define purple_blist_alias_buddy         purple_blist_alias_buddy
#define purple_blist_server_alias_buddy  purple_blist_server_alias_buddy
#define purple_blist_alias_chat          purple_blist_alias_chat

#define purple_blist_rename_buddy  purple_blist_rename_buddy
#define purple_blist_rename_group  purple_blist_rename_group

#define purple_chat_new        purple_chat_new
#define purple_blist_add_chat  purple_blist_add_chat

#define purple_buddy_new           purple_buddy_new
#define purple_buddy_set_icon      purple_buddy_set_icon
#define purple_buddy_get_account   purple_buddy_get_account
#define purple_buddy_get_name      purple_buddy_get_name
#define purple_buddy_get_icon      purple_buddy_get_icon
#define purple_buddy_get_contact   purple_buddy_get_contact
#define purple_buddy_get_presence  purple_buddy_get_presence

#define purple_blist_add_buddy  purple_blist_add_buddy

#define purple_group_new  purple_group_new

#define purple_blist_add_group  purple_blist_add_group

#define purple_contact_new  purple_contact_new

#define purple_blist_add_contact    purple_blist_add_contact
#define purple_blist_merge_contact  purple_blist_merge_contact

#define purple_contact_get_priority_buddy  purple_contact_get_priority_buddy
#define purple_contact_set_alias           purple_contact_set_alias
#define purple_contact_get_alias           purple_contact_get_alias
#define purple_contact_on_account          purple_contact_on_account

#define purple_contact_invalidate_priority_buddy  purple_contact_invalidate_priority_buddy

#define purple_blist_remove_buddy    purple_blist_remove_buddy
#define purple_blist_remove_contact  purple_blist_remove_contact
#define purple_blist_remove_chat     purple_blist_remove_chat
#define purple_blist_remove_group    purple_blist_remove_group

#define purple_buddy_get_alias_only     purple_buddy_get_alias_only
#define purple_buddy_get_server_alias   purple_buddy_get_server_alias
#define purple_buddy_get_contact_alias  purple_buddy_get_contact_alias
#define purple_buddy_get_local_alias    purple_buddy_get_local_alias
#define purple_buddy_get_alias          purple_buddy_get_alias

#define purple_chat_get_name  purple_chat_get_name

#define purple_find_buddy           purple_find_buddy
#define purple_find_buddy_in_group  purple_find_buddy_in_group
#define purple_find_buddies         purple_find_buddies

#define purple_find_group  purple_find_group

#define purple_blist_find_chat  purple_blist_find_chat

#define purple_chat_get_group   purple_chat_get_group
#define purple_buddy_get_group  purple_buddy_get_group

#define purple_group_get_accounts  purple_group_get_accounts
#define purple_group_on_account    purple_group_on_account

#define purple_blist_add_account     purple_blist_add_account
#define purple_blist_remove_account  purple_blist_remove_account

#define purple_blist_get_group_size          purple_blist_get_group_size
#define purple_blist_get_group_online_count  purple_blist_get_group_online_count

#define purple_blist_load           purple_blist_load
#define purple_blist_schedule_save  purple_blist_schedule_save

#define purple_blist_request_add_buddy  purple_blist_request_add_buddy
#define purple_blist_request_add_chat   purple_blist_request_add_chat
#define purple_blist_request_add_group  purple_blist_request_add_group

#define purple_blist_node_set_bool    purple_blist_node_set_bool
#define purple_blist_node_get_bool    purple_blist_node_get_bool
#define purple_blist_node_set_int     purple_blist_node_set_int
#define purple_blist_node_get_int     purple_blist_node_get_int
#define purple_blist_node_set_string  purple_blist_node_set_string
#define purple_blist_node_get_string  purple_blist_node_get_string

#define purple_blist_node_remove_setting  purple_blist_node_remove_setting

#define purple_blist_node_set_flags  purple_blist_node_set_flags
#define purple_blist_node_get_flags  purple_blist_node_get_flags

#define purple_blist_node_get_extended_menu  purple_blist_node_get_extended_menu

#define purple_blist_set_ui_ops  purple_blist_set_ui_ops
#define purple_blist_get_ui_ops  purple_blist_get_ui_ops

#define purple_blist_get_handle  purple_blist_get_handle

#define purple_blist_init    purple_blist_init
#define purple_blist_uninit  purple_blist_uninit


#define GaimBuddyIcon  GaimBuddyIcon

#define purple_buddy_icon_new      purple_buddy_icon_new
#define purple_buddy_icon_destroy  purple_buddy_icon_destroy
#define purple_buddy_icon_ref      purple_buddy_icon_ref
#define purple_buddy_icon_unref    purple_buddy_icon_unref
#define purple_buddy_icon_update   purple_buddy_icon_update
#define purple_buddy_icon_cache    purple_buddy_icon_cache
#define purple_buddy_icon_uncache  purple_buddy_icon_uncache

#define purple_buddy_icon_set_account   purple_buddy_icon_set_account
#define purple_buddy_icon_set_username  purple_buddy_icon_set_username
#define purple_buddy_icon_set_data      purple_buddy_icon_set_data
#define purple_buddy_icon_set_path      purple_buddy_icon_set_path

#define purple_buddy_icon_get_account   purple_buddy_icon_get_account
#define purple_buddy_icon_get_username  purple_buddy_icon_get_username
#define purple_buddy_icon_get_data      purple_buddy_icon_get_data
#define purple_buddy_icon_get_path      purple_buddy_icon_get_path
#define purple_buddy_icon_get_type      purple_buddy_icon_get_type

#define purple_buddy_icons_set_for_user   purple_buddy_icons_set_for_user
#define purple_buddy_icons_find           purple_buddy_icons_find
#define purple_buddy_icons_set_caching    purple_buddy_icons_set_caching
#define purple_buddy_icons_is_caching     purple_buddy_icons_is_caching
#define purple_buddy_icons_set_cache_dir  purple_buddy_icons_set_cache_dir
#define purple_buddy_icons_get_cache_dir  purple_buddy_icons_get_cache_dir
#define purple_buddy_icons_get_full_path  purple_buddy_icons_get_full_path
#define purple_buddy_icons_get_handle     purple_buddy_icons_get_handle

#define purple_buddy_icons_init    purple_buddy_icons_init
#define purple_buddy_icons_uninit  purple_buddy_icons_uninit

#define purple_buddy_icon_get_scale_size  purple_buddy_icon_get_scale_size

/* from cipher.h */

#define GAIM_CIPHER          GAIM_CIPHER
#define GAIM_CIPHER_OPS      GAIM_CIPHER_OPS
#define GAIM_CIPHER_CONTEXT  GAIM_CIPHER_CONTEXT

#define GaimCipher         GaimCipher
#define GaimCipherOps      GaimCipherOps
#define GaimCipherContext  GaimCipherContext

#define GAIM_CIPHER_CAPS_SET_OPT  GAIM_CIPHER_CAPS_SET_OPT
#define GAIM_CIPHER_CAPS_GET_OPT  GAIM_CIPHER_CAPS_GET_OPT
#define GAIM_CIPHER_CAPS_INIT     GAIM_CIPHER_CAPS_INIT
#define GAIM_CIPHER_CAPS_RESET    GAIM_CIPHER_CAPS_RESET
#define GAIM_CIPHER_CAPS_UNINIT   GAIM_CIPHER_CAPS_UNINIT
#define GAIM_CIPHER_CAPS_SET_IV   GAIM_CIPHER_CAPS_SET_IV
#define GAIM_CIPHER_CAPS_APPEND   GAIM_CIPHER_CAPS_APPEND
#define GAIM_CIPHER_CAPS_DIGEST   GAIM_CIPHER_CAPS_DIGEST
#define GAIM_CIPHER_CAPS_ENCRYPT  GAIM_CIPHER_CAPS_ENCRYPT
#define GAIM_CIPHER_CAPS_DECRYPT  GAIM_CIPHER_CAPS_DECRYPT
#define GAIM_CIPHER_CAPS_SET_SALT  GAIM_CIPHER_CAPS_SET_SALT
#define GAIM_CIPHER_CAPS_GET_SALT_SIZE  GAIM_CIPHER_CAPS_GET_SALT_SIZE
#define GAIM_CIPHER_CAPS_SET_KEY        GAIM_CIPHER_CAPS_SET_KEY
#define GAIM_CIPHER_CAPS_GET_KEY_SIZE   GAIM_CIPHER_CAPS_GET_KEY_SIZE
#define GAIM_CIPHER_CAPS_UNKNOWN        GAIM_CIPHER_CAPS_UNKNOWN

#define purple_cipher_get_name          purple_cipher_get_name
#define purple_cipher_get_capabilities  purple_cipher_get_capabilities
#define purple_cipher_digest_region     purple_cipher_digest_region

#define purple_ciphers_find_cipher        purple_ciphers_find_cipher
#define purple_ciphers_register_cipher    purple_ciphers_register_cipher
#define purple_ciphers_unregister_cipher  purple_ciphers_unregister_cipher
#define purple_ciphers_get_ciphers        purple_ciphers_get_ciphers

#define purple_ciphers_get_handle  purple_ciphers_get_handle
#define purple_ciphers_init        purple_ciphers_init
#define purple_ciphers_uninit      purple_ciphers_uninit

#define purple_cipher_context_set_option  purple_cipher_context_set_option
#define purple_cipher_context_get_option  purple_cipher_context_get_option

#define purple_cipher_context_new            purple_cipher_context_new
#define purple_cipher_context_new_by_name    purple_cipher_context_new_by_name
#define purple_cipher_context_reset          purple_cipher_context_reset
#define purple_cipher_context_destroy        purple_cipher_context_destroy
#define purple_cipher_context_set_iv         purple_cipher_context_set_iv
#define purple_cipher_context_append         purple_cipher_context_append
#define purple_cipher_context_digest         purple_cipher_context_digest
#define purple_cipher_context_digest_to_str  purple_cipher_context_digest_to_str
#define purple_cipher_context_encrypt        purple_cipher_context_encrypt
#define purple_cipher_context_decrypt        purple_cipher_context_decrypt
#define purple_cipher_context_set_salt       purple_cipher_context_set_salt
#define purple_cipher_context_get_salt_size  purple_cipher_context_get_salt_size
#define purple_cipher_context_set_key        purple_cipher_context_set_key
#define purple_cipher_context_get_key_size   purple_cipher_context_get_key_size
#define purple_cipher_context_set_data       purple_cipher_context_set_data
#define purple_cipher_context_get_data       purple_cipher_context_get_data

#define purple_cipher_http_digest_calculate_session_key \
	purple_cipher_http_digest_calculate_session_key

#define purple_cipher_http_digest_calculate_response \
	purple_cipher_http_digest_calculate_response

/* from circbuffer.h */

#define GaimCircBuffer  GaimCircBuffer

#define purple_circ_buffer_new           purple_circ_buffer_new
#define purple_circ_buffer_destroy       purple_circ_buffer_destroy
#define purple_circ_buffer_append        purple_circ_buffer_append
#define purple_circ_buffer_get_max_read  purple_circ_buffer_get_max_read
#define purple_circ_buffer_mark_read     purple_circ_buffer_mark_read

/* from cmds.h */

#define GaimCmdPriority  GaimCmdPriority
#define GaimCmdFlag      GaimCmdFlag
#define GaimCmdStatus    GaimCmdStatus
#define GaimCmdRet       GaimCmdRet

#define GAIM_CMD_STATUS_OK            GAIM_CMD_STATUS_OK
#define GAIM_CMD_STATUS_FAILED        GAIM_CMD_STATUS_FAILED
#define GAIM_CMD_STATUS_NOT_FOUND     GAIM_CMD_STATUS_NOT_FOUND
#define GAIM_CMD_STATUS_WRONG_ARGS    GAIM_CMD_STATUS_WRONG_ARGS
#define GAIM_CMD_STATUS_WRONG_PRPL    GAIM_CMD_STATUS_WRONG_PRPL
#define GAIM_CMD_STATUS_WRONG_TYPE    GAIM_CMD_STATUS_WRONG_TYPE

#define GAIM_CMD_FUNC  GAIM_CMD_FUNC

#define GaimCmdFunc  GaimCmdFunc

#define GaimCmdId  GaimCmdId

#define purple_cmd_register    purple_cmd_register
#define purple_cmd_unregister  purple_cmd_unregister
#define purple_cmd_do_command  purple_cmd_do_command
#define purple_cmd_list        purple_cmd_list
#define purple_cmd_help        purple_cmd_help

/* from connection.h */

#define GaimConnection  GaimConnection

#define GAIM_CONNECTION_HTML              GAIM_CONNECTION_HTML
#define GAIM_CONNECTION_NO_BGCOLOR        GAIM_CONNECTION_NO_BGCOLOR
#define GAIM_CONNECTION_AUTO_RESP         GAIM_CONNECTION_AUTO_RESP
#define PURPLE_CONNECTION_FORMATTING_WBFO   GAIM_CONNECTION_FORMATTING_WBFO
#define GAIM_CONNECTION_NO_NEWLINES       GAIM_CONNECTION_NO_NEWLINES
#define GAIM_CONNECTION_NO_FONTSIZE       GAIM_CONNECTION_NO_FONTSIZE
#define GAIM_CONNECTION_NO_URLDESC        GAIM_CONNECTION_NO_URLDESC
#define GAIM_CONNECTION_NO_IMAGES         GAIM_CONNECTION_NO_IMAGES

#define GaimConnectionFlags  GaimConnectionFlags

#define GAIM_DISCONNECTED  GAIM_DISCONNECTED
#define GAIM_CONNECTED     GAIM_CONNECTED
#define GAIM_CONNECTING    GAIM_CONNECTING

#define GaimConnectionState  GaimConnectionState

#define GaimConnectionUiOps  GaimConnectionUiOps

#define purple_connection_new      purple_connection_new
#define purple_connection_destroy  purple_connection_destroy

#define purple_connection_set_state         purple_connection_set_state
#define purple_connection_set_account       purple_connection_set_account
#define purple_connection_set_display_name  purple_connection_set_display_name
#define purple_connection_get_state         purple_connection_get_state

#define GAIM_CONNECTION_IS_CONNECTED  GAIM_CONNECTION_IS_CONNECTED

#define purple_connection_get_account       purple_connection_get_account
#define purple_connection_get_password      purple_connection_get_password
#define purple_connection_get_display_name  purple_connection_get_display_name

#define purple_connection_update_progress  purple_connection_update_progress

#define purple_connection_notice  purple_connection_notice
#define purple_connection_error   purple_connection_error

#define purple_connections_disconnect_all  purple_connections_disconnect_all

#define purple_connections_get_all         purple_connections_get_all
#define purple_connections_get_connecting  purple_connections_get_connecting

#define GAIM_CONNECTION_IS_VALID  GAIM_CONNECTION_IS_VALID

#define purple_connections_set_ui_ops  purple_connections_set_ui_ops
#define purple_connections_get_ui_ops  purple_connections_get_ui_ops

#define purple_connections_init    purple_connections_init
#define purple_connections_uninit  purple_connections_uninit
#define purple_connections_get_handle  purple_connections_get_handle


/* from conversation.h */

#define GaimConversationUiOps  GaimConversationUiOps
#define GaimConversation       GaimConversation
#define GaimConvIm             GaimConvIm
#define GaimConvChat           GaimConvChat
#define GaimConvChatBuddy      GaimConvChatBuddy

#define GAIM_CONV_TYPE_UNKNOWN  GAIM_CONV_TYPE_UNKNOWN
#define GAIM_CONV_TYPE_IM       GAIM_CONV_TYPE_IM
#define GAIM_CONV_TYPE_CHAT     GAIM_CONV_TYPE_CHAT
#define GAIM_CONV_TYPE_MISC     GAIM_CONV_TYPE_MISC
#define GAIM_CONV_TYPE_ANY      GAIM_CONV_TYPE_ANY

#define GaimConversationType  GaimConversationType

#define GAIM_CONV_UPDATE_ADD       GAIM_CONV_UPDATE_ADD
#define PURPLE_CONV_UPDATE_REMOVE    GAIM_CONV_UPDATE_REMOVE
#define GAIM_CONV_UPDATE_ACCOUNT   GAIM_CONV_UPDATE_ACCOUNT
#define GAIM_CONV_UPDATE_TYPING    GAIM_CONV_UPDATE_TYPING
#define GAIM_CONV_UPDATE_UNSEEN    GAIM_CONV_UPDATE_UNSEEN
#define GAIM_CONV_UPDATE_LOGGING   GAIM_CONV_UPDATE_LOGGING
#define GAIM_CONV_UPDATE_TOPIC     GAIM_CONV_UPDATE_TOPIC
#define GAIM_CONV_ACCOUNT_ONLINE   GAIM_CONV_ACCOUNT_ONLINE
#define GAIM_CONV_ACCOUNT_OFFLINE  GAIM_CONV_ACCOUNT_OFFLINE
#define GAIM_CONV_UPDATE_AWAY      GAIM_CONV_UPDATE_AWAY
#define GAIM_CONV_UPDATE_ICON      GAIM_CONV_UPDATE_ICON
#define GAIM_CONV_UPDATE_TITLE     GAIM_CONV_UPDATE_TITLE
#define GAIM_CONV_UPDATE_CHATLEFT  GAIM_CONV_UPDATE_CHATLEFT
#define GAIM_CONV_UPDATE_FEATURES  GAIM_CONV_UPDATE_FEATURES

#define GaimConvUpdateType  GaimConvUpdateType

#define GAIM_NOT_TYPING  GAIM_NOT_TYPING
#define GAIM_TYPING      GAIM_TYPING
#define GAIM_TYPED       GAIM_TYPED

#define GaimTypingState  GaimTypingState

#define GAIM_MESSAGE_SEND         GAIM_MESSAGE_SEND
#define GAIM_MESSAGE_RECV         GAIM_MESSAGE_RECV
#define GAIM_MESSAGE_SYSTEM       GAIM_MESSAGE_SYSTEM
#define GAIM_MESSAGE_AUTO_RESP    GAIM_MESSAGE_AUTO_RESP
#define GAIM_MESSAGE_ACTIVE_ONLY  GAIM_MESSAGE_ACTIVE_ONLY
#define GAIM_MESSAGE_NICK         GAIM_MESSAGE_NICK
#define GAIM_MESSAGE_NO_LOG       GAIM_MESSAGE_NO_LOG
#define GAIM_MESSAGE_WHISPER      GAIM_MESSAGE_WHISPER
#define GAIM_MESSAGE_ERROR        GAIM_MESSAGE_ERROR
#define GAIM_MESSAGE_DELAYED      GAIM_MESSAGE_DELAYED
#define GAIM_MESSAGE_RAW          GAIM_MESSAGE_RAW
#define GAIM_MESSAGE_IMAGES       GAIM_MESSAGE_IMAGES

#define GaimMessageFlags  GaimMessageFlags

#define GAIM_CBFLAGS_NONE     GAIM_CBFLAGS_NONE
#define GAIM_CBFLAGS_VOICE    GAIM_CBFLAGS_VOICE
#define GAIM_CBFLAGS_HALFOP   GAIM_CBFLAGS_HALFOP
#define GAIM_CBFLAGS_OP       GAIM_CBFLAGS_OP
#define GAIM_CBFLAGS_FOUNDER  GAIM_CBFLAGS_FOUNDER
#define GAIM_CBFLAGS_TYPING   GAIM_CBFLAGS_TYPING

#define GaimConvChatBuddyFlags  GaimConvChatBuddyFlags

#define purple_conversations_set_ui_ops  purple_conversations_set_ui_ops

#define purple_conversation_new          purple_conversation_new
#define purple_conversation_destroy      purple_conversation_destroy
#define purple_conversation_present      purple_conversation_present
#define purple_conversation_get_type     purple_conversation_get_type
#define purple_conversation_set_ui_ops   purple_conversation_set_ui_ops
#define purple_conversation_get_ui_ops   purple_conversation_get_ui_ops
#define purple_conversation_set_account  purple_conversation_set_account
#define purple_conversation_get_account  purple_conversation_get_account
#define purple_conversation_get_gc       purple_conversation_get_gc
#define purple_conversation_set_title    purple_conversation_set_title
#define purple_conversation_get_title    purple_conversation_get_title
#define purple_conversation_autoset_title  purple_conversation_autoset_title
#define purple_conversation_set_name       purple_conversation_set_name
#define purple_conversation_get_name       purple_conversation_get_name
#define purple_conversation_set_logging    purple_conversation_set_logging
#define purple_conversation_is_logging     purple_conversation_is_logging
#define purple_conversation_close_logs     purple_conversation_close_logs
#define purple_conversation_get_im_data    purple_conversation_get_im_data

#define GAIM_CONV_IM    GAIM_CONV_IM

#define purple_conversation_get_chat_data  purple_conversation_get_chat_data

#define GAIM_CONV_CHAT  GAIM_CONV_CHAT

#define purple_conversation_set_data       purple_conversation_set_data
#define purple_conversation_get_data       purple_conversation_get_data

#define purple_get_conversations  purple_get_conversations
#define purple_get_ims            purple_get_ims
#define purple_get_chats          purple_get_chats

#define purple_find_conversation_with_account \
	purple_find_conversation_with_account

#define purple_conversation_write         purple_conversation_write
#define purple_conversation_set_features  purple_conversation_set_features
#define purple_conversation_get_features  purple_conversation_get_features
#define purple_conversation_has_focus     purple_conversation_has_focus
#define purple_conversation_update        purple_conversation_update
#define purple_conversation_foreach       purple_conversation_foreach

#define purple_conv_im_get_conversation  purple_conv_im_get_conversation
#define purple_conv_im_set_icon          purple_conv_im_set_icon
#define purple_conv_im_get_icon          purple_conv_im_get_icon
#define purple_conv_im_set_typing_state  purple_conv_im_set_typing_state
#define purple_conv_im_get_typing_state  purple_conv_im_get_typing_state

#define purple_conv_im_start_typing_timeout  purple_conv_im_start_typing_timeout
#define purple_conv_im_stop_typing_timeout   purple_conv_im_stop_typing_timeout
#define purple_conv_im_get_typing_timeout    purple_conv_im_get_typing_timeout
#define purple_conv_im_set_type_again        purple_conv_im_set_type_again
#define purple_conv_im_get_type_again        purple_conv_im_get_type_again

#define purple_conv_im_start_send_typed_timeout \
	purple_conv_im_start_send_typed_timeout

#define purple_conv_im_stop_send_typed_timeout \
	purple_conv_im_stop_send_typed_timeout

#define purple_conv_im_get_send_typed_timeout \
	purple_conv_im_get_send_typed_timeout

#define purple_conv_present_error     purple_conv_present_error
#define purple_conv_send_confirm      purple_conv_send_confirm

#define purple_conv_im_update_typing    purple_conv_im_update_typing
#define purple_conv_im_write            purple_conv_im_write
#define purple_conv_im_send             purple_conv_im_send
#define purple_conv_im_send_with_flags  purple_conv_im_send_with_flags

#define purple_conv_custom_smiley_add    purple_conv_custom_smiley_add
#define purple_conv_custom_smiley_write  purple_conv_custom_smiley_write
#define purple_conv_custom_smiley_close  purple_conv_custom_smiley_close

#define purple_conv_chat_get_conversation  purple_conv_chat_get_conversation
#define purple_conv_chat_set_users         purple_conv_chat_set_users
#define purple_conv_chat_get_users         purple_conv_chat_get_users
#define purple_conv_chat_ignore            purple_conv_chat_ignore
#define purple_conv_chat_unignore          purple_conv_chat_unignore
#define purple_conv_chat_set_ignored       purple_conv_chat_set_ignored
#define purple_conv_chat_get_ignored       purple_conv_chat_get_ignored
#define purple_conv_chat_get_ignored_user  purple_conv_chat_get_ignored_user
#define purple_conv_chat_is_user_ignored   purple_conv_chat_is_user_ignored
#define purple_conv_chat_set_topic         purple_conv_chat_set_topic
#define purple_conv_chat_get_topic         purple_conv_chat_get_topic
#define purple_conv_chat_set_id            purple_conv_chat_set_id
#define purple_conv_chat_get_id            purple_conv_chat_get_id
#define purple_conv_chat_write             purple_conv_chat_write
#define purple_conv_chat_send              purple_conv_chat_send
#define purple_conv_chat_send_with_flags   purple_conv_chat_send_with_flags
#define purple_conv_chat_add_user          purple_conv_chat_add_user
#define purple_conv_chat_add_users         purple_conv_chat_add_users
#define purple_conv_chat_rename_user       purple_conv_chat_rename_user
#define purple_conv_chat_remove_user       purple_conv_chat_remove_user
#define purple_conv_chat_remove_users      purple_conv_chat_remove_users
#define purple_conv_chat_find_user         purple_conv_chat_find_user
#define purple_conv_chat_user_set_flags    purple_conv_chat_user_set_flags
#define purple_conv_chat_user_get_flags    purple_conv_chat_user_get_flags
#define purple_conv_chat_clear_users       purple_conv_chat_clear_users
#define purple_conv_chat_set_nick          purple_conv_chat_set_nick
#define purple_conv_chat_get_nick          purple_conv_chat_get_nick
#define purple_conv_chat_left              purple_conv_chat_left
#define purple_conv_chat_has_left          purple_conv_chat_has_left

#define purple_find_chat                   purple_find_chat

#define purple_conv_chat_cb_new            purple_conv_chat_cb_new
#define purple_conv_chat_cb_find           purple_conv_chat_cb_find
#define purple_conv_chat_cb_get_name       purple_conv_chat_cb_get_name
#define purple_conv_chat_cb_destroy        purple_conv_chat_cb_destroy

#define purple_conversations_get_handle    purple_conversations_get_handle
#define purple_conversations_init          purple_conversations_init
#define purple_conversations_uninit        purple_conversations_uninit

/* from core.h */

#define GaimCore  GaimCore

#define GaimCoreUiOps  GaimCoreUiOps

#define purple_core_init  purple_core_init
#define purple_core_quit  purple_core_quit

#define purple_core_quit_cb      purple_core_quit_cb
#define purple_core_get_version  purple_core_get_version
#define purple_core_get_ui       purple_core_get_ui
#define purple_get_core          purple_get_core
#define purple_core_set_ui_ops   purple_core_set_ui_ops
#define purple_core_get_ui_ops   purple_core_get_ui_ops

/* from debug.h */

#define GAIM_DEBUG_ALL      GAIM_DEBUG_ALL
#define GAIM_DEBUG_MISC     GAIM_DEBUG_MISC
#define GAIM_DEBUG_INFO     GAIM_DEBUG_INFO
#define GAIM_DEBUG_WARNING  GAIM_DEBUG_WARNING
#define GAIM_DEBUG_ERROR    GAIM_DEBUG_ERROR
#define GAIM_DEBUG_FATAL    GAIM_DEBUG_FATAL

#define GaimDebugLevel  GaimDebugLevel

#define GaimDebugUiOps  GaimDebugUiOps


#define purple_debug          purple_debug
#define purple_debug_misc     purple_debug_misc
#define purple_debug_info     purple_debug_info
#define purple_debug_warning  purple_debug_warning
#define purple_debug_error    purple_debug_error
#define purple_debug_fatal    purple_debug_fatal

#define purple_debug_set_enabled  purple_debug_set_enabled
#define purple_debug_is_enabled   purple_debug_is_enabled

#define purple_debug_set_ui_ops  purple_debug_set_ui_ops
#define purple_debug_get_ui_ops  purple_debug_get_ui_ops

#define purple_debug_init  purple_debug_init

/* from desktopitem.h */

#define GAIM_DESKTOP_ITEM_TYPE_NULL          GAIM_DESKTOP_ITEM_TYPE_NULL
#define GAIM_DESKTOP_ITEM_TYPE_OTHER         GAIM_DESKTOP_ITEM_TYPE_OTHER
#define GAIM_DESKTOP_ITEM_TYPE_APPLICATION   GAIM_DESKTOP_ITEM_TYPE_APPLICATION
#define GAIM_DESKTOP_ITEM_TYPE_LINK          GAIM_DESKTOP_ITEM_TYPE_LINK
#define GAIM_DESKTOP_ITEM_TYPE_FSDEVICE      GAIM_DESKTOP_ITEM_TYPE_FSDEVICE
#define GAIM_DESKTOP_ITEM_TYPE_MIME_TYPE     GAIM_DESKTOP_ITEM_TYPE_MIME_TYPE
#define GAIM_DESKTOP_ITEM_TYPE_DIRECTORY     GAIM_DESKTOP_ITEM_TYPE_DIRECTORY
#define GAIM_DESKTOP_ITEM_TYPE_SERVICE       GAIM_DESKTOP_ITEM_TYPE_SERVICE
#define GAIM_DESKTOP_ITEM_TYPE_SERVICE_TYPE  GAIM_DESKTOP_ITEM_TYPE_SERVICE_TYPE

#define GaimDesktopItemType  GaimDesktopItemType

#define GaimDesktopItem  GaimDesktopItem

#define GAIM_TYPE_DESKTOP_ITEM         GAIM_TYPE_DESKTOP_ITEM
#define purple_desktop_item_get_type     purple_desktop_item_get_type

/* standard */
/* ugh, i'm just copying these as strings, rather than pidginifying them */
#define GAIM_DESKTOP_ITEM_ENCODING	"Encoding" /* string */
#define GAIM_DESKTOP_ITEM_VERSION	"Version"  /* numeric */
#define GAIM_DESKTOP_ITEM_NAME		"Name" /* localestring */
#define GAIM_DESKTOP_ITEM_GENERIC_NAME	"GenericName" /* localestring */
#define GAIM_DESKTOP_ITEM_TYPE		"Type" /* string */
#define GAIM_DESKTOP_ITEM_FILE_PATTERN "FilePattern" /* regexp(s) */
#define GAIM_DESKTOP_ITEM_TRY_EXEC	"TryExec" /* string */
#define GAIM_DESKTOP_ITEM_NO_DISPLAY	"NoDisplay" /* boolean */
#define GAIM_DESKTOP_ITEM_COMMENT	"Comment" /* localestring */
#define GAIM_DESKTOP_ITEM_EXEC		"Exec" /* string */
#define GAIM_DESKTOP_ITEM_ACTIONS	"Actions" /* strings */
#define GAIM_DESKTOP_ITEM_ICON		"Icon" /* string */
#define GAIM_DESKTOP_ITEM_MINI_ICON	"MiniIcon" /* string */
#define GAIM_DESKTOP_ITEM_HIDDEN	"Hidden" /* boolean */
#define GAIM_DESKTOP_ITEM_PATH		"Path" /* string */
#define GAIM_DESKTOP_ITEM_TERMINAL	"Terminal" /* boolean */
#define GAIM_DESKTOP_ITEM_TERMINAL_OPTIONS "TerminalOptions" /* string */
#define GAIM_DESKTOP_ITEM_SWALLOW_TITLE "SwallowTitle" /* string */
#define GAIM_DESKTOP_ITEM_SWALLOW_EXEC	"SwallowExec" /* string */
#define GAIM_DESKTOP_ITEM_MIME_TYPE	"MimeType" /* regexp(s) */
#define GAIM_DESKTOP_ITEM_PATTERNS	"Patterns" /* regexp(s) */
#define GAIM_DESKTOP_ITEM_DEFAULT_APP	"DefaultApp" /* string */
#define GAIM_DESKTOP_ITEM_DEV		"Dev" /* string */
#define GAIM_DESKTOP_ITEM_FS_TYPE	"FSType" /* string */
#define GAIM_DESKTOP_ITEM_MOUNT_POINT	"MountPoint" /* string */
#define GAIM_DESKTOP_ITEM_READ_ONLY	"ReadOnly" /* boolean */
#define GAIM_DESKTOP_ITEM_UNMOUNT_ICON "UnmountIcon" /* string */
#define GAIM_DESKTOP_ITEM_SORT_ORDER	"SortOrder" /* strings */
#define GAIM_DESKTOP_ITEM_URL		"URL" /* string */
#define GAIM_DESKTOP_ITEM_DOC_PATH	"X-GNOME-DocPath" /* string */

#define purple_desktop_item_new_from_file   purple_desktop_item_new_from_file
#define purple_desktop_item_get_entry_type  purple_desktop_item_get_entry_type
#define purple_desktop_item_get_string      purple_desktop_item_get_string
#define purple_desktop_item_copy            purple_desktop_item_copy
#define purple_desktop_item_unref           purple_desktop_item_unref

/* from dnsquery.h */

#define GaimDnsQueryData  GaimDnsQueryData
#define GaimDnsQueryConnectFunction  GaimDnsQueryConnectFunction

#define purple_dnsquery_a        		purple_dnsquery_a
#define purple_dnsquery_destroy  		purple_dnsquery_destroy
#define purple_dnsquery_init     		purple_dnsquery_init
#define purple_dnsquery_uninit   		purple_dnsquery_uninit
#define purple_dnsquery_set_ui_ops	purple_dnsquery_set_ui_ops
#define purple_dnsquery_get_host 		purple_dnsquery_get_host
#define purple_dnsquery_get_port 		purple_dnsquery_get_port

/* from dnssrv.h */

#define GaimSrvResponse   GaimSrvResponse
#define GaimSrvQueryData  GaimSrvQueryData
#define GaimSrvCallback   GaimSrvCallback

#define purple_srv_resolve  purple_srv_resolve
#define purple_srv_cancel   purple_srv_cancel

/* from eventloop.h */

#define GAIM_INPUT_READ   GAIM_INPUT_READ
#define GAIM_INPUT_WRITE  GAIM_INPUT_WRITE

#define GaimInputCondition  GaimInputCondition
#define GaimInputFunction   GaimInputFunction
#define GaimEventLoopUiOps  GaimEventLoopUiOps

#define purple_timeout_add     purple_timeout_add
#define purple_timeout_remove  purple_timeout_remove
#define purple_input_add       purple_input_add
#define purple_input_remove    purple_input_remove

#define purple_eventloop_set_ui_ops  purple_eventloop_set_ui_ops
#define purple_eventloop_get_ui_ops  purple_eventloop_get_ui_ops

/* from ft.h */

#define GaimXfer  GaimXfer

#define GAIM_XFER_UNKNOWN  GAIM_XFER_UNKNOWN
#define GAIM_XFER_SEND     GAIM_XFER_SEND
#define GAIM_XFER_RECEIVE  GAIM_XFER_RECEIVE

#define GaimXferType  GaimXferType

#define GAIM_XFER_STATUS_UNKNOWN        GAIM_XFER_STATUS_UNKNOWN
#define GAIM_XFER_STATUS_NOT_STARTED    GAIM_XFER_STATUS_NOT_STARTED
#define GAIM_XFER_STATUS_ACCEPTED       GAIM_XFER_STATUS_ACCEPTED
#define GAIM_XFER_STATUS_STARTED        GAIM_XFER_STATUS_STARTED
#define GAIM_XFER_STATUS_DONE           GAIM_XFER_STATUS_DONE
#define GAIM_XFER_STATUS_CANCEL_LOCAL   GAIM_XFER_STATUS_CANCEL_LOCAL
#define GAIM_XFER_STATUS_CANCEL_REMOTE  GAIM_XFER_STATUS_CANCEL_REMOTE

#define GaimXferStatusType  GaimXferStatusType

#define GaimXferUiOps  GaimXferUiOps

#define purple_xfer_new                  purple_xfer_new
#define purple_xfer_ref                  purple_xfer_ref
#define purple_xfer_unref                purple_xfer_unref
#define purple_xfer_request              purple_xfer_request
#define purple_xfer_request_accepted     purple_xfer_request_accepted
#define purple_xfer_request_denied       purple_xfer_request_denied
#define purple_xfer_get_type             purple_xfer_get_type
#define purple_xfer_get_account          purple_xfer_get_account
#define purple_xfer_get_status           purple_xfer_get_status
#define purple_xfer_is_canceled          purple_xfer_is_canceled
#define purple_xfer_is_completed         purple_xfer_is_completed
#define purple_xfer_get_filename         purple_xfer_get_filename
#define purple_xfer_get_local_filename   purple_xfer_get_local_filename
#define purple_xfer_get_bytes_sent       purple_xfer_get_bytes_sent
#define purple_xfer_get_bytes_remaining  purple_xfer_get_bytes_remaining
#define purple_xfer_get_size             purple_xfer_get_size
#define purple_xfer_get_progress         purple_xfer_get_progress
#define purple_xfer_get_local_port       purple_xfer_get_local_port
#define purple_xfer_get_remote_ip        purple_xfer_get_remote_ip
#define purple_xfer_get_remote_port      purple_xfer_get_remote_port
#define purple_xfer_set_completed        purple_xfer_set_completed
#define purple_xfer_set_message          purple_xfer_set_message
#define purple_xfer_set_filename         purple_xfer_set_filename
#define purple_xfer_set_local_filename   purple_xfer_set_local_filename
#define purple_xfer_set_size             purple_xfer_set_size
#define purple_xfer_set_bytes_sent       purple_xfer_set_bytes_sent
#define purple_xfer_get_ui_ops           purple_xfer_get_ui_ops
#define purple_xfer_set_read_fnc         purple_xfer_set_read_fnc
#define purple_xfer_set_write_fnc        purple_xfer_set_write_fnc
#define purple_xfer_set_ack_fnc          purple_xfer_set_ack_fnc
#define purple_xfer_set_request_denied_fnc  purple_xfer_set_request_denied_fnc
#define purple_xfer_set_init_fnc         purple_xfer_set_init_fnc
#define purple_xfer_set_start_fnc        purple_xfer_set_start_fnc
#define purple_xfer_set_end_fnc          purple_xfer_set_end_fnc
#define purple_xfer_set_cancel_send_fnc  purple_xfer_set_cancel_send_fnc
#define purple_xfer_set_cancel_recv_fnc  purple_xfer_set_cancel_recv_fnc

#define purple_xfer_read                purple_xfer_read
#define purple_xfer_write               purple_xfer_write
#define purple_xfer_start               purple_xfer_start
#define purple_xfer_end                 purple_xfer_end
#define purple_xfer_add                 purple_xfer_add
#define purple_xfer_cancel_local        purple_xfer_cancel_local
#define purple_xfer_cancel_remote       purple_xfer_cancel_remote
#define purple_xfer_error               purple_xfer_error
#define purple_xfer_update_progress     purple_xfer_update_progress
#define purple_xfer_conversation_write  purple_xfer_conversation_write

#define purple_xfers_get_handle  purple_xfers_get_handle
#define purple_xfers_init        purple_xfers_init
#define purple_xfers_uninit      purple_xfers_uninit
#define purple_xfers_set_ui_ops  purple_xfers_set_ui_ops
#define purple_xfers_get_ui_ops  purple_xfers_get_ui_ops

/* from purple-client.h */

/* XXX: should this be purple_init, or pidgin_init */
#define purple_init  purple_init

/* from idle.h */

#define GaimIdleUiOps  GaimIdleUiOps

#define purple_idle_touch       purple_idle_touch
#define purple_idle_set         purple_idle_set
#define purple_idle_set_ui_ops  purple_idle_set_ui_ops
#define purple_idle_get_ui_ops  purple_idle_get_ui_ops
#define purple_idle_init        purple_idle_init
#define purple_idle_uninit      purple_idle_uninit

/* from imgstore.h */

#define GaimStoredImage  GaimStoredImage

#define purple_imgstore_add           purple_imgstore_add
#define purple_imgstore_get           purple_imgstore_get
#define purple_imgstore_get_data      purple_imgstore_get_data
#define purple_imgstore_get_size      purple_imgstore_get_size
#define purple_imgstore_get_filename  purple_imgstore_get_filename
#define purple_imgstore_ref           purple_imgstore_ref
#define purple_imgstore_unref         purple_imgstore_unref


/* from log.h */

#define GaimLog                  GaimLog
#define PurpleLogLogger            PurpleLogLogger
#define GaimLogCommonLoggerData  GaimLogCommonLoggerData
#define GaimLogSet               GaimLogSet

#define GAIM_LOG_IM      GAIM_LOG_IM
#define GAIM_LOG_CHAT    GAIM_LOG_CHAT
#define GAIM_LOG_SYSTEM  GAIM_LOG_SYSTEM

#define GaimLogType  GaimLogType

#define GAIM_LOG_READ_NO_NEWLINE  GAIM_LOG_READ_NO_NEWLINE

#define GaimLogReadFlags  GaimLogReadFlags

#define GaimLogSetCallback  GaimLogSetCallback

#define purple_log_new    purple_log_new
#define purple_log_free   purple_log_free
#define purple_log_write  purple_log_write
#define purple_log_read   purple_log_read

#define purple_log_get_logs         purple_log_get_logs
#define purple_log_get_log_sets     purple_log_get_log_sets
#define purple_log_get_system_logs  purple_log_get_system_logs
#define purple_log_get_size         purple_log_get_size
#define purple_log_get_total_size   purple_log_get_total_size
#define purple_log_get_log_dir      purple_log_get_log_dir
#define purple_log_compare          purple_log_compare
#define purple_log_set_compare      purple_log_set_compare
#define purple_log_set_free         purple_log_set_free

#define purple_log_common_writer       purple_log_common_writer
#define purple_log_common_lister       purple_log_common_lister
#define purple_log_common_total_sizer  purple_log_common_total_sizer
#define purple_log_common_sizer        purple_log_common_sizer

#define purple_log_logger_new     purple_log_logger_new
#define purple_log_logger_free    purple_log_logger_free
#define purple_log_logger_add     purple_log_logger_add
#define purple_log_logger_remove  purple_log_logger_remove
#define purple_log_logger_set     purple_log_logger_set
#define purple_log_logger_get     purple_log_logger_get

#define purple_log_logger_get_options  purple_log_logger_get_options

#define purple_log_init        purple_log_init
#define purple_log_get_handle  purple_log_get_handle
#define purple_log_uninit      purple_log_uninit

/* from mime.h */

#define GaimMimeDocument  GaimMimeDocument
#define GaimMimePart      GaimMimePart

#define purple_mime_document_new         purple_mime_document_new
#define purple_mime_document_free        purple_mime_document_free
#define purple_mime_document_parse       purple_mime_document_parse
#define purple_mime_document_parsen      purple_mime_document_parsen
#define purple_mime_document_write       purple_mime_document_write
#define purple_mime_document_get_fields  purple_mime_document_get_fields
#define purple_mime_document_get_field   purple_mime_document_get_field
#define purple_mime_document_set_field   purple_mime_document_set_field
#define purple_mime_document_get_parts   purple_mime_document_get_parts

#define purple_mime_part_new                purple_mime_part_new
#define purple_mime_part_get_fields         purple_mime_part_get_fields
#define purple_mime_part_get_field          purple_mime_part_get_field
#define purple_mime_part_get_field_decoded  purple_mime_part_get_field_decoded
#define purple_mime_part_set_field          purple_mime_part_set_field
#define purple_mime_part_get_data           purple_mime_part_get_data
#define purple_mime_part_get_data_decoded   purple_mime_part_get_data_decoded
#define purple_mime_part_get_length         purple_mime_part_get_length
#define purple_mime_part_set_data           purple_mime_part_set_data


/* from network.h */

#define GaimNetworkListenData  GaimNetworkListenData

#define GaimNetworkListenCallback  GaimNetworkListenCallback

#define purple_network_ip_atoi              purple_network_ip_atoi
#define purple_network_set_public_ip        purple_network_set_public_ip
#define purple_network_get_public_ip        purple_network_get_public_ip
#define purple_network_get_local_system_ip  purple_network_get_local_system_ip
#define purple_network_get_my_ip            purple_network_get_my_ip

#define purple_network_listen            purple_network_listen
#define purple_network_listen_range      purple_network_listen_range
#define purple_network_listen_cancel     purple_network_listen_cancel
#define purple_network_get_port_from_fd  purple_network_get_port_from_fd

#define purple_network_is_available  purple_network_is_available

#define purple_network_init    purple_network_init
#define purple_network_uninit  purple_network_uninit

/* from notify.h */


#define GaimNotifyUserInfoEntry  GaimNotifyUserInfoEntry
#define GaimNotifyUserInfo       GaimNotifyUserInfo

#define GaimNotifyCloseCallback  GaimNotifyCloseCallback

#define GAIM_NOTIFY_MESSAGE        GAIM_NOTIFY_MESSAGE
#define GAIM_NOTIFY_EMAIL          GAIM_NOTIFY_EMAIL
#define GAIM_NOTIFY_EMAILS         GAIM_NOTIFY_EMAILS
#define GAIM_NOTIFY_FORMATTED      GAIM_NOTIFY_FORMATTED
#define GAIM_NOTIFY_SEARCHRESULTS  GAIM_NOTIFY_SEARCHRESULTS
#define GAIM_NOTIFY_USERINFO       GAIM_NOTIFY_USERINFO
#define GAIM_NOTIFY_URI            GAIM_NOTIFY_URI

#define GaimNotifyType  GaimNotifyType

#define GAIM_NOTIFY_MSG_ERROR    GAIM_NOTIFY_MSG_ERROR
#define GAIM_NOTIFY_MSG_WARNING  GAIM_NOTIFY_MSG_WARNING
#define GAIM_NOTIFY_MSG_INFO     GAIM_NOTIFY_MSG_INFO

#define GaimNotifyMsgType  GaimNotifyMsgType

#define GAIM_NOTIFY_BUTTON_LABELED   GAIM_NOTIFY_BUTTON_LABELED
#define GAIM_NOTIFY_BUTTON_CONTINUE  GAIM_NOTIFY_BUTTON_CONTINUE
#define GAIM_NOTIFY_BUTTON_ADD       GAIM_NOTIFY_BUTTON_ADD
#define GAIM_NOTIFY_BUTTON_INFO      GAIM_NOTIFY_BUTTON_INFO
#define GAIM_NOTIFY_BUTTON_IM        GAIM_NOTIFY_BUTTON_IM
#define GAIM_NOTIFY_BUTTON_JOIN      GAIM_NOTIFY_BUTTON_JOIN
#define GAIM_NOTIFY_BUTTON_INVITE    GAIM_NOTIFY_BUTTON_INVITE

#define GaimNotifySearchButtonType  GaimNotifySearchButtonType

#define GaimNotifySearchResults  GaimNotifySearchResults

#define GAIM_NOTIFY_USER_INFO_ENTRY_PAIR            GAIM_NOTIFY_USER_INFO_ENTRY_PAIR
#define GAIM_NOTIFY_USER_INFO_ENTRY_SECTION_BREAK   GAIM_NOTIFY_USER_INFO_ENTRY_SECTION_BREAK
#define GAIM_NOTIFY_USER_INFO_ENTRY_SECTION_HEADER  GAIM_NOTIFY_USER_INFO_ENTRY_SECTION_HEADER

#define GaimNotifyUserInfoEntryType  GaimNotifyUserInfoEntryType

#define GaimNotifySearchColumn           GaimNotifySearchColumn
#define GaimNotifySearchResultsCallback  GaimNotifySearchResultsCallback
#define GaimNotifySearchButton           GaimNotifySearchButton

#define GaimNotifyUiOps  GaimNotifyUiOps

#define purple_notify_searchresults                     purple_notify_searchresults
#define purple_notify_searchresults_free                purple_notify_searchresults_free
#define purple_notify_searchresults_new_rows            purple_notify_searchresults_new_rows
#define purple_notify_searchresults_button_add          purple_notify_searchresults_button_add
#define purple_notify_searchresults_button_add_labeled  purple_notify_searchresults_button_add_labeled
#define purple_notify_searchresults_new                 purple_notify_searchresults_new
#define purple_notify_searchresults_column_new          purple_notify_searchresults_column_new
#define purple_notify_searchresults_column_add          purple_notify_searchresults_column_add
#define purple_notify_searchresults_row_add             purple_notify_searchresults_row_add
#define purple_notify_searchresults_get_rows_count      purple_notify_searchresults_get_rows_count
#define purple_notify_searchresults_get_columns_count   purple_notify_searchresults_get_columns_count
#define purple_notify_searchresults_row_get             purple_notify_searchresults_row_get
#define purple_notify_searchresults_column_get_title    purple_notify_searchresults_column_get_title

#define purple_notify_message    purple_notify_message
#define purple_notify_email      purple_notify_email
#define purple_notify_emails     purple_notify_emails
#define purple_notify_formatted  purple_notify_formatted
#define purple_notify_userinfo   purple_notify_userinfo

#define purple_notify_user_info_new                    purple_notify_user_info_new
#define purple_notify_user_info_destroy                purple_notify_user_info_destroy
#define purple_notify_user_info_get_entries            purple_notify_user_info_get_entries
#define purple_notify_user_info_get_text_with_newline  purple_notify_user_info_get_text_with_newline
#define purple_notify_user_info_add_pair               purple_notify_user_info_add_pair
#define purple_notify_user_info_prepend_pair           purple_notify_user_info_prepend_pair
#define purple_notify_user_info_remove_entry           purple_notify_user_info_remove_entry
#define purple_notify_user_info_entry_new              purple_notify_user_info_entry_new
#define purple_notify_user_info_add_section_break      purple_notify_user_info_add_section_break
#define purple_notify_user_info_add_section_header     purple_notify_user_info_add_section_header
#define purple_notify_user_info_remove_last_item       purple_notify_user_info_remove_last_item
#define purple_notify_user_info_entry_get_label        purple_notify_user_info_entry_get_label
#define purple_notify_user_info_entry_set_label        purple_notify_user_info_entry_set_label
#define purple_notify_user_info_entry_get_value        purple_notify_user_info_entry_get_value
#define purple_notify_user_info_entry_set_value        purple_notify_user_info_entry_set_value
#define purple_notify_user_info_entry_get_type         purple_notify_user_info_entry_get_type
#define purple_notify_user_info_entry_set_type         purple_notify_user_info_entry_set_type

#define purple_notify_uri                purple_notify_uri
#define purple_notify_close              purple_notify_close
#define purple_notify_close_with_handle  purple_notify_close_with_handle

#define purple_notify_info     purple_notify_info
#define purple_notify_warning  purple_notify_warning
#define purple_notify_error    purple_notify_error

#define purple_notify_set_ui_ops  purple_notify_set_ui_ops
#define purple_notify_get_ui_ops  purple_notify_get_ui_ops

#define purple_notify_get_handle  purple_notify_get_handle

#define purple_notify_init    purple_notify_init
#define purple_notify_uninit  purple_notify_uninit

/* from ntlm.h */

#define purple_ntlm_gen_type1    purple_ntlm_gen_type1
#define purple_ntlm_parse_type2  purple_ntlm_parse_type2
#define purple_ntlm_gen_type3    purple_ntlm_gen_type3

/* from plugin.h */

#define GaimPlugin            GaimPlugin
#define GaimPluginInfo        GaimPluginInfo
#define GaimPluginUiInfo      GaimPluginUiInfo
#define GaimPluginLoaderInfo  GaimPluginLoaderInfo
#define GaimPluginAction      GaimPluginAction
#define GaimPluginPriority    GaimPluginPriority

#define GAIM_PLUGIN_UNKNOWN   GAIM_PLUGIN_UNKNOWN
#define GAIM_PLUGIN_STANDARD  GAIM_PLUGIN_STANDARD
#define GAIM_PLUGIN_LOADER    GAIM_PLUGIN_LOADER
#define GAIM_PLUGIN_PROTOCOL  GAIM_PLUGIN_PROTOCOL

#define GaimPluginType        GaimPluginType

#define GAIM_PRIORITY_DEFAULT  GAIM_PRIORITY_DEFAULT
#define GAIM_PRIORITY_HIGHEST  GAIM_PRIORITY_HIGHEST
#define GAIM_PRIORITY_LOWEST   GAIM_PRIORITY_LOWEST

#define GAIM_PLUGIN_FLAG_INVISIBLE  GAIM_PLUGIN_FLAG_INVISIBLE

#define GAIM_PLUGIN_MAGIC  GAIM_PLUGIN_MAGIC

#define GAIM_PLUGIN_LOADER_INFO     GAIM_PLUGIN_LOADER_INFO
#define GAIM_PLUGIN_HAS_PREF_FRAME  GAIM_PLUGIN_HAS_PREF_FRAME
#define GAIM_PLUGIN_UI_INFO         GAIM_PLUGIN_UI_INFO

#define GAIM_PLUGIN_HAS_ACTIONS  GAIM_PLUGIN_HAS_ACTIONS
#define GAIM_PLUGIN_ACTIONS      GAIM_PLUGIN_ACTIONS

#define GAIM_INIT_PLUGIN  GAIM_INIT_PLUGIN

#define purple_plugin_new              purple_plugin_new
#define purple_plugin_probe            purple_plugin_probe
#define purple_plugin_register         purple_plugin_register
#define purple_plugin_load             purple_plugin_load
#define purple_plugin_unload           purple_plugin_unload
#define purple_plugin_reload           purple_plugin_reload
#define purple_plugin_destroy          purple_plugin_destroy
#define purple_plugin_is_loaded        purple_plugin_is_loaded
#define purple_plugin_is_unloadable    purple_plugin_is_unloadable
#define purple_plugin_get_id           purple_plugin_get_id
#define purple_plugin_get_name         purple_plugin_get_name
#define purple_plugin_get_version      purple_plugin_get_version
#define purple_plugin_get_summary      purple_plugin_get_summary
#define purple_plugin_get_description  purple_plugin_get_description
#define purple_plugin_get_author       purple_plugin_get_author
#define purple_plugin_get_homepage     purple_plugin_get_homepage

#define purple_plugin_ipc_register        purple_plugin_ipc_register
#define purple_plugin_ipc_unregister      purple_plugin_ipc_unregister
#define purple_plugin_ipc_unregister_all  purple_plugin_ipc_unregister_all
#define purple_plugin_ipc_get_params      purple_plugin_ipc_get_params
#define purple_plugin_ipc_call            purple_plugin_ipc_call

#define purple_plugins_add_search_path  purple_plugins_add_search_path
#define purple_plugins_unload_all       purple_plugins_unload_all
#define purple_plugins_destroy_all      purple_plugins_destroy_all
#define purple_plugins_save_loaded      purple_plugins_save_loaded
#define purple_plugins_load_saved       purple_plugins_load_saved
#define purple_plugins_probe            purple_plugins_probe
#define purple_plugins_enabled          purple_plugins_enabled

#define purple_plugins_register_probe_notify_cb     purple_plugins_register_probe_notify_cb
#define purple_plugins_unregister_probe_notify_cb   purple_plugins_unregister_probe_notify_cb
#define purple_plugins_register_load_notify_cb      purple_plugins_register_load_notify_cb
#define purple_plugins_unregister_load_notify_cb    purple_plugins_unregister_load_notify_cb
#define purple_plugins_register_unload_notify_cb    purple_plugins_register_unload_notify_cb
#define purple_plugins_unregister_unload_notify_cb  purple_plugins_unregister_unload_notify_cb

#define purple_plugins_find_with_name      purple_plugins_find_with_name
#define purple_plugins_find_with_filename  purple_plugins_find_with_filename
#define purple_plugins_find_with_basename  purple_plugins_find_with_basename
#define purple_plugins_find_with_id        purple_plugins_find_with_id

#define purple_plugins_get_loaded     purple_plugins_get_loaded
#define purple_plugins_get_protocols  purple_plugins_get_protocols
#define purple_plugins_get_all        purple_plugins_get_all

#define purple_plugins_get_handle  purple_plugins_get_handle
#define purple_plugins_init        purple_plugins_init
#define purple_plugins_uninit      purple_plugins_uninit

#define purple_plugin_action_new   purple_plugin_action_new
#define purple_plugin_action_free  purple_plugin_action_free

/* pluginpref.h */

#define GaimPluginPrefFrame  GaimPluginPrefFrame
#define GaimPluginPref       GaimPluginPref

#define GAIM_STRING_FORMAT_TYPE_NONE       GAIM_STRING_FORMAT_TYPE_NONE
#define GAIM_STRING_FORMAT_TYPE_MULTILINE  GAIM_STRING_FORMAT_TYPE_MULTILINE
#define GAIM_STRING_FORMAT_TYPE_HTML       GAIM_STRING_FORMAT_TYPE_HTML

#define GaimStringFormatType  GaimStringFormatType

#define GAIM_PLUGIN_PREF_NONE           GAIM_PLUGIN_PREF_NONE
#define GAIM_PLUGIN_PREF_CHOICE         GAIM_PLUGIN_PREF_CHOICE
#define GAIM_PLUGIN_PREF_INFO           GAIM_PLUGIN_PREF_INFO
#define GAIM_PLUGIN_PREF_STRING_FORMAT  GAIM_PLUGIN_PREF_STRING_FORMAT

#define GaimPluginPrefType  GaimPluginPrefType

#define purple_plugin_pref_frame_new        purple_plugin_pref_frame_new
#define purple_plugin_pref_frame_destroy    purple_plugin_pref_frame_destroy
#define purple_plugin_pref_frame_add        purple_plugin_pref_frame_add
#define purple_plugin_pref_frame_get_prefs  purple_plugin_pref_frame_get_prefs

#define purple_plugin_pref_new                      purple_plugin_pref_new
#define purple_plugin_pref_new_with_name            purple_plugin_pref_new_with_name
#define purple_plugin_pref_new_with_label           purple_plugin_pref_new_with_label
#define purple_plugin_pref_new_with_name_and_label  purple_plugin_pref_new_with_name_and_label
#define purple_plugin_pref_destroy                  purple_plugin_pref_destroy
#define purple_plugin_pref_set_name                 purple_plugin_pref_set_name
#define purple_plugin_pref_get_name                 purple_plugin_pref_get_name
#define purple_plugin_pref_set_label                purple_plugin_pref_set_label
#define purple_plugin_pref_get_label                purple_plugin_pref_get_label
#define purple_plugin_pref_set_bounds               purple_plugin_pref_set_bounds
#define purple_plugin_pref_get_bounds               purple_plugin_pref_get_bounds
#define purple_plugin_pref_set_type                 purple_plugin_pref_set_type
#define purple_plugin_pref_get_type                 purple_plugin_pref_get_type
#define purple_plugin_pref_add_choice               purple_plugin_pref_add_choice
#define purple_plugin_pref_get_choices              purple_plugin_pref_get_choices
#define purple_plugin_pref_set_max_length           purple_plugin_pref_set_max_length
#define purple_plugin_pref_get_max_length           purple_plugin_pref_get_max_length
#define purple_plugin_pref_set_masked               purple_plugin_pref_set_masked
#define purple_plugin_pref_get_masked               purple_plugin_pref_get_masked
#define purple_plugin_pref_set_format_type          purple_plugin_pref_set_format_type
#define purple_plugin_pref_get_format_type          purple_plugin_pref_get_format_type

/* from pounce.h */

#define GaimPounce  GaimPounce

#define GAIM_POUNCE_NONE              GAIM_POUNCE_NONE
#define GAIM_POUNCE_SIGNON            GAIM_POUNCE_SIGNON
#define GAIM_POUNCE_SIGNOFF           GAIM_POUNCE_SIGNOFF
#define GAIM_POUNCE_AWAY              GAIM_POUNCE_AWAY
#define GAIM_POUNCE_AWAY_RETURN       GAIM_POUNCE_AWAY_RETURN
#define GAIM_POUNCE_IDLE              GAIM_POUNCE_IDLE
#define GAIM_POUNCE_IDLE_RETURN       GAIM_POUNCE_IDLE_RETURN
#define GAIM_POUNCE_TYPING            GAIM_POUNCE_TYPING
#define GAIM_POUNCE_TYPED             GAIM_POUNCE_TYPED
#define GAIM_POUNCE_TYPING_STOPPED    GAIM_POUNCE_TYPING_STOPPED
#define GAIM_POUNCE_MESSAGE_RECEIVED  GAIM_POUNCE_MESSAGE_RECEIVED
#define GaimPounceEvent  GaimPounceEvent

#define GAIM_POUNCE_OPTION_NONE  GAIM_POUNCE_OPTION_NONE
#define GAIM_POUNCE_OPTION_AWAY  GAIM_POUNCE_OPTION_AWAY
#define GaimPounceOption  GaimPounceOption

#define GaimPounceCb  GaimPounceCb

#define purple_pounce_new                     purple_pounce_new
#define purple_pounce_destroy                 purple_pounce_destroy
#define purple_pounce_destroy_all_by_account  purple_pounce_destroy_all_by_account
#define purple_pounce_set_events              purple_pounce_set_events
#define purple_pounce_set_options             purple_pounce_set_options
#define purple_pounce_set_pouncer             purple_pounce_set_pouncer
#define purple_pounce_set_pouncee             purple_pounce_set_pouncee
#define purple_pounce_set_save                purple_pounce_set_save
#define purple_pounce_action_register         purple_pounce_action_register
#define purple_pounce_action_set_enabled      purple_pounce_action_set_enabled
#define purple_pounce_action_set_attribute    purple_pounce_action_set_attribute
#define purple_pounce_set_data                purple_pounce_set_data
#define purple_pounce_get_events              purple_pounce_get_events
#define purple_pounce_get_options             purple_pounce_get_options
#define purple_pounce_get_pouncer             purple_pounce_get_pouncer
#define purple_pounce_get_pouncee             purple_pounce_get_pouncee
#define purple_pounce_get_save                purple_pounce_get_save
#define purple_pounce_action_is_enabled       purple_pounce_action_is_enabled
#define purple_pounce_action_get_attribute    purple_pounce_action_get_attribute
#define purple_pounce_get_data                purple_pounce_get_data
#define purple_pounce_execute                 purple_pounce_execute

#define purple_find_pounce                 purple_find_pounce
#define purple_pounces_load                purple_pounces_load
#define purple_pounces_register_handler    purple_pounces_register_handler
#define purple_pounces_unregister_handler  purple_pounces_unregister_handler
#define purple_pounces_get_all             purple_pounces_get_all
#define purple_pounces_get_handle          purple_pounces_get_handle
#define purple_pounces_init                purple_pounces_init
#define purple_pounces_uninit              purple_pounces_uninit

/* from prefs.h */


#define GAIM_PREF_NONE         GAIM_PREF_NONE
#define GAIM_PREF_BOOLEAN      GAIM_PREF_BOOLEAN
#define PURPLE_PREF_INT          GAIM_PREF_INT
#define GAIM_PREF_STRING       GAIM_PREF_STRING
#define PURPLE_PREF_STRING_LIST  GAIM_PREF_STRING_LIST
#define GAIM_PREF_PATH         GAIM_PREF_PATH
#define GAIM_PREF_PATH_LIST    GAIM_PREF_PATH_LIST
#define GaimPrefType  GaimPrefType

#define GaimPrefCallback  GaimPrefCallback

#define purple_prefs_get_handle             purple_prefs_get_handle
#define purple_prefs_init                   purple_prefs_init
#define purple_prefs_uninit                 purple_prefs_uninit
#define purple_prefs_add_none               purple_prefs_add_none
#define purple_prefs_add_bool               purple_prefs_add_bool
#define purple_prefs_add_int                purple_prefs_add_int
#define purple_prefs_add_string             purple_prefs_add_string
#define purple_prefs_add_string_list        purple_prefs_add_string_list
#define purple_prefs_add_path               purple_prefs_add_path
#define purple_prefs_add_path_list          purple_prefs_add_path_list
#define purple_prefs_remove                 purple_prefs_remove
#define purple_prefs_rename                 purple_prefs_rename
#define purple_prefs_rename_boolean_toggle  purple_prefs_rename_boolean_toggle
#define purple_prefs_destroy                purple_prefs_destroy
#define purple_prefs_set_generic            purple_prefs_set_generic
#define purple_prefs_set_bool               purple_prefs_set_bool
#define purple_prefs_set_int                purple_prefs_set_int
#define purple_prefs_set_string             purple_prefs_set_string
#define purple_prefs_set_string_list        purple_prefs_set_string_list
#define purple_prefs_set_path               purple_prefs_set_path
#define purple_prefs_set_path_list          purple_prefs_set_path_list
#define purple_prefs_exists                 purple_prefs_exists
#define purple_prefs_get_type               purple_prefs_get_type
#define purple_prefs_get_bool               purple_prefs_get_bool
#define purple_prefs_get_int                purple_prefs_get_int
#define purple_prefs_get_string             purple_prefs_get_string
#define purple_prefs_get_string_list        purple_prefs_get_string_list
#define purple_prefs_get_path               purple_prefs_get_path
#define purple_prefs_get_path_list          purple_prefs_get_path_list
#define purple_prefs_connect_callback       purple_prefs_connect_callback
#define purple_prefs_disconnect_callback    purple_prefs_disconnect_callback
#define purple_prefs_disconnect_by_handle   purple_prefs_disconnect_by_handle
#define purple_prefs_trigger_callback       purple_prefs_trigger_callback
#define purple_prefs_load                   purple_prefs_load
#define purple_prefs_update_old             purple_prefs_update_old

/* from privacy.h */

#define GAIM_PRIVACY_ALLOW_ALL        GAIM_PRIVACY_ALLOW_ALL
#define GAIM_PRIVACY_DENY_ALL         PURPLE_PRIVACY_DENY_ALL
#define GAIM_PRIVACY_ALLOW_USERS      GAIM_PRIVACY_ALLOW_USERS
#define GAIM_PRIVACY_DENY_USERS       GAIM_PRIVACY_DENY_USERS
#define GAIM_PRIVACY_ALLOW_BUDDYLIST  GAIM_PRIVACY_ALLOW_BUDDYLIST
#define GaimPrivacyType  GaimPrivacyType

#define GaimPrivacyUiOps  GaimPrivacyUiOps

#define purple_privacy_permit_add     purple_privacy_permit_add
#define purple_privacy_permit_remove  purple_privacy_permit_remove
#define purple_privacy_deny_add       purple_privacy_deny_add
#define purple_privacy_deny_remove    purple_privacy_deny_remove
#define purple_privacy_allow          purple_privacy_allow
#define purple_privacy_deny           purple_privacy_deny
#define purple_privacy_check          purple_privacy_check
#define purple_privacy_set_ui_ops     purple_privacy_set_ui_ops
#define purple_privacy_get_ui_ops     purple_privacy_get_ui_ops
#define purple_privacy_init           purple_privacy_init

/* from proxy.h */

#define GAIM_PROXY_USE_GLOBAL  GAIM_PROXY_USE_GLOBAL
#define GAIM_PROXY_NONE        GAIM_PROXY_NONE
#define GAIM_PROXY_HTTP        GAIM_PROXY_HTTP
#define GAIM_PROXY_SOCKS4      GAIM_PROXY_SOCKS4
#define GAIM_PROXY_SOCKS5      GAIM_PROXY_SOCKS5
#define GAIM_PROXY_USE_ENVVAR  GAIM_PROXY_USE_ENVVAR
#define GaimProxyType  GaimProxyType

#define GaimProxyInfo  GaimProxyInfo

#define GaimProxyConnectData      GaimProxyConnectData
#define GaimProxyConnectFunction  GaimProxyConnectFunction

#define purple_proxy_info_new           purple_proxy_info_new
#define purple_proxy_info_destroy       purple_proxy_info_destroy
#define purple_proxy_info_set_type      purple_proxy_info_set_type
#define purple_proxy_info_set_host      purple_proxy_info_set_host
#define purple_proxy_info_set_port      purple_proxy_info_set_port
#define purple_proxy_info_set_username  purple_proxy_info_set_username
#define purple_proxy_info_set_password  purple_proxy_info_set_password
#define purple_proxy_info_get_type      purple_proxy_info_get_type
#define purple_proxy_info_get_host      purple_proxy_info_get_host
#define purple_proxy_info_get_port      purple_proxy_info_get_port
#define purple_proxy_info_get_username  purple_proxy_info_get_username
#define purple_proxy_info_get_password  purple_proxy_info_get_password

#define purple_global_proxy_get_info    purple_global_proxy_get_info
#define purple_proxy_get_handle         purple_proxy_get_handle
#define purple_proxy_init               purple_proxy_init
#define purple_proxy_uninit             purple_proxy_uninit
#define purple_proxy_get_setup          purple_proxy_get_setup

#define purple_proxy_connect                     purple_proxy_connect
#define purple_proxy_connect_socks5              purple_proxy_connect_socks5
#define purple_proxy_connect_cancel              purple_proxy_connect_cancel
#define purple_proxy_connect_cancel_with_handle  purple_proxy_connect_cancel_with_handle

/* from prpl.h */

#define GaimPluginProtocolInfo  GaimPluginProtocolInfo

#define GAIM_ICON_SCALE_DISPLAY  GAIM_ICON_SCALE_DISPLAY
#define GAIM_ICON_SCALE_SEND     GAIM_ICON_SCALE_SEND
#define GaimIconScaleRules  GaimIconScaleRules

#define GaimBuddyIconSpec  GaimBuddyIconSpec

#define GaimProtocolOptions  GaimProtocolOptions

#define GAIM_IS_PROTOCOL_PLUGIN  GAIM_IS_PROTOCOL_PLUGIN

#define GAIM_PLUGIN_PROTOCOL_INFO  GAIM_PLUGIN_PROTOCOL_INFO

#define purple_prpl_got_account_idle        purple_prpl_got_account_idle
#define purple_prpl_got_account_login_time  purple_prpl_got_account_login_time
#define purple_prpl_got_account_status      purple_prpl_got_account_status
#define purple_prpl_got_user_idle           purple_prpl_got_user_idle
#define purple_prpl_got_user_login_time     purple_prpl_got_user_login_time
#define purple_prpl_got_user_status         purple_prpl_got_user_status
#define purple_prpl_change_account_status   purple_prpl_change_account_status
#define purple_prpl_get_statuses            purple_prpl_get_statuses

#define purple_find_prpl  purple_find_prpl

/* from request.h */

#define GAIM_DEFAULT_ACTION_NONE  GAIM_DEFAULT_ACTION_NONE

#define GAIM_REQUEST_INPUT   GAIM_REQUEST_INPUT
#define GAIM_REQUEST_CHOICE  GAIM_REQUEST_CHOICE
#define GAIM_REQUEST_ACTION  GAIM_REQUEST_ACTION
#define GAIM_REQUEST_FIELDS  GAIM_REQUEST_FIELDS
#define GAIM_REQUEST_FILE    GAIM_REQUEST_FILE
#define GAIM_REQUEST_FOLDER  GAIM_REQUEST_FOLDER
#define GaimRequestType  GaimRequestType

#define GAIM_REQUEST_FIELD_NONE     GAIM_REQUEST_FIELD_NONE
#define GAIM_REQUEST_FIELD_STRING   GAIM_REQUEST_FIELD_STRING
#define GAIM_REQUEST_FIELD_INTEGER  GAIM_REQUEST_FIELD_INTEGER
#define GAIM_REQUEST_FIELD_BOOLEAN  GAIM_REQUEST_FIELD_BOOLEAN
#define GAIM_REQUEST_FIELD_CHOICE   GAIM_REQUEST_FIELD_CHOICE
#define GAIM_REQUEST_FIELD_LIST     GAIM_REQUEST_FIELD_LIST
#define GAIM_REQUEST_FIELD_LABEL    GAIM_REQUEST_FIELD_LABEL
#define GAIM_REQUEST_FIELD_IMAGE    GAIM_REQUEST_FIELD_IMAGE
#define GAIM_REQUEST_FIELD_ACCOUNT  GAIM_REQUEST_FIELD_ACCOUNT
#define GaimRequestFieldType  GaimRequestFieldType

#define GaimRequestFields  GaimRequestFields

#define GaimRequestFieldGroup  GaimRequestFieldGroup

#define GaimRequestField  GaimRequestField

#define GaimRequestUiOps  GaimRequestUiOps

#define GaimRequestInputCb   GaimRequestInputCb
#define GaimRequestActionCb  GaimRequestActionCb
#define GaimRequestChoiceCb  GaimRequestChoiceCb
#define GaimRequestFieldsCb  GaimRequestFieldsCb
#define GaimRequestFileCb    GaimRequestFileCb

#define purple_request_fields_new                  purple_request_fields_new
#define purple_request_fields_destroy              purple_request_fields_destroy
#define purple_request_fields_add_group            purple_request_fields_add_group
#define purple_request_fields_get_groups           purple_request_fields_get_groups
#define purple_request_fields_exists               purple_request_fields_exists
#define purple_request_fields_get_required         purple_request_fields_get_required
#define purple_request_fields_is_field_required    purple_request_fields_is_field_required
#define purple_request_fields_all_required_filled  purple_request_fields_all_required_filled
#define purple_request_fields_get_field            purple_request_fields_get_field
#define purple_request_fields_get_string           purple_request_fields_get_string
#define purple_request_fields_get_integer          purple_request_fields_get_integer
#define purple_request_fields_get_bool             purple_request_fields_get_bool
#define purple_request_fields_get_choice           purple_request_fields_get_choice
#define purple_request_fields_get_account          purple_request_fields_get_account

#define purple_request_field_group_new         purple_request_field_group_new
#define purple_request_field_group_destroy     purple_request_field_group_destroy
#define purple_request_field_group_add_field   purple_request_field_group_add_field
#define purple_request_field_group_get_title   purple_request_field_group_get_title
#define purple_request_field_group_get_fields  purple_request_field_group_get_fields

#define purple_request_field_new            purple_request_field_new
#define purple_request_field_destroy        purple_request_field_destroy
#define purple_request_field_set_label      purple_request_field_set_label
#define purple_request_field_set_visible    purple_request_field_set_visible
#define purple_request_field_set_type_hint  purple_request_field_set_type_hint
#define purple_request_field_set_required   purple_request_field_set_required
#define purple_request_field_get_type       purple_request_field_get_type
#define purple_request_field_get_id         purple_request_field_get_id
#define purple_request_field_get_label      purple_request_field_get_label
#define purple_request_field_is_visible     purple_request_field_is_visible
#define purple_request_field_get_type_hint  purple_request_field_get_type_hint
#define purple_request_field_is_required    purple_request_field_is_required

#define purple_request_field_string_new           purple_request_field_string_new
#define purple_request_field_string_set_default_value \
	purple_request_field_string_set_default_value
#define purple_request_field_string_set_value     purple_request_field_string_set_value
#define purple_request_field_string_set_masked    purple_request_field_string_set_masked
#define purple_request_field_string_set_editable  purple_request_field_string_set_editable
#define purple_request_field_string_get_default_value \
	purple_request_field_string_get_default_value
#define purple_request_field_string_get_value     purple_request_field_string_get_value
#define purple_request_field_string_is_multiline  purple_request_field_string_is_multiline
#define purple_request_field_string_is_masked     purple_request_field_string_is_masked
#define purple_request_field_string_is_editable   purple_request_field_string_is_editable

#define purple_request_field_int_new        purple_request_field_int_new
#define purple_request_field_int_set_default_value \
	purple_request_field_int_set_default_value
#define purple_request_field_int_set_value  purple_request_field_int_set_value
#define purple_request_field_int_get_default_value \
	purple_request_field_int_get_default_value
#define purple_request_field_int_get_value  purple_request_field_int_get_value

#define purple_request_field_bool_new        purple_request_field_bool_new
#define purple_request_field_bool_set_default_value \
	purple_request_field_book_set_default_value
#define purple_request_field_bool_set_value  purple_request_field_bool_set_value
#define purple_request_field_bool_get_default_value \
	purple_request_field_bool_get_default_value
#define purple_request_field_bool_get_value  purple_request_field_bool_get_value

#define purple_request_field_choice_new         purple_request_field_choice_new
#define purple_request_field_choice_add         purple_request_field_choice_add
#define purple_request_field_choice_set_default_value \
	purple_request_field_choice_set_default_value
#define purple_request_field_choice_set_value   purple_request_field_choice_set_value
#define purple_request_field_choice_get_default_value \
	purple_request_field_choice_get_default_value
#define purple_request_field_choice_get_value   purple_request_field_choice_get_value
#define purple_request_field_choice_get_labels  purple_request_field_choice_get_labels

#define purple_request_field_list_new               purple_request_field_list_new
#define purple_request_field_list_set_multi_select  purple_request_field_list_set_multi_select
#define purple_request_field_list_get_multi_select  purple_request_field_list_get_multi_select
#define purple_request_field_list_get_data          purple_request_field_list_get_data
#define purple_request_field_list_add               purple_request_field_list_add
#define purple_request_field_list_add_selected      purple_request_field_list_add_selected
#define purple_request_field_list_clear_selected    purple_request_field_list_clear_selected
#define purple_request_field_list_set_selected      purple_request_field_list_set_selected
#define purple_request_field_list_is_selected       purple_request_field_list_is_selected
#define purple_request_field_list_get_selected      purple_request_field_list_get_selected
#define purple_request_field_list_get_items         purple_request_field_list_get_items

#define purple_request_field_label_new  purple_request_field_label_new

#define purple_request_field_image_new          purple_request_field_image_new
#define purple_request_field_image_set_scale    purple_request_field_image_set_scale
#define purple_request_field_image_get_buffer   purple_request_field_image_get_buffer
#define purple_request_field_image_get_size     purple_request_field_image_get_size
#define purple_request_field_image_get_scale_x  purple_request_field_image_get_scale_x
#define purple_request_field_image_get_scale_y  purple_request_field_image_get_scale_y

#define purple_request_field_account_new                purple_request_field_account_new
#define purple_request_field_account_set_default_value  purple_request_field_account_set_default_value
#define purple_request_field_account_set_value          purple_request_field_account_set_value
#define purple_request_field_account_set_show_all       purple_request_field_account_set_show_all
#define purple_request_field_account_set_filter         purple_request_field_account_set_filter
#define purple_request_field_account_get_default_value  purple_request_field_account_get_default_value
#define purple_request_field_account_get_value          purple_request_field_account_get_value
#define purple_request_field_account_get_show_all       purple_request_field_account_get_show_all
#define purple_request_field_account_get_filter         purple_request_field_account_get_filter

#define purple_request_input              purple_request_input
#define purple_request_choice             purple_request_choice
#define purple_request_choice_varg        purple_request_choice_varg
#define purple_request_action             purple_request_action
#define purple_request_action_varg        purple_request_action_varg
#define purple_request_fields             purple_request_fields
#define purple_request_close              purple_request_close
#define purple_request_close_with_handle  purple_request_close_with_handle

#define purple_request_yes_no         purple_request_yes_no
#define purple_request_ok_cancel      purple_request_ok_cancel
#define purple_request_accept_cancel  purple_request_accept_cancel

#define purple_request_file    purple_request_file
#define purple_request_folder  purple_request_folder

#define purple_request_set_ui_ops  purple_request_set_ui_ops
#define purple_request_get_ui_ops  purple_request_get_ui_ops

/* from roomlist.h */

#define GaimRoomlist       GaimRoomlist
#define GaimRoomlistRoom   GaimRoomlistRoom
#define GaimRoomlistField  GaimRoomlistField
#define GaimRoomlistUiOps  GaimRoomlistUiOps

#define GAIM_ROOMLIST_ROOMTYPE_CATEGORY  GAIM_ROOMLIST_ROOMTYPE_CATEGORY
#define GAIM_ROOMLIST_ROOMTYPE_ROOM      GAIM_ROOMLIST_ROOMTYPE_ROOM
#define GaimRoomlistRoomType  GaimRoomlistRoomType

#define GAIM_ROOMLIST_FIELD_BOOL    GAIM_ROOMLIST_BOOL
#define GAIM_ROOMLIST_FIELD_INT     GAIM_ROOMLIST_INT
#define GAIM_ROOMLIST_FIELD_STRING  GAIM_ROOMLIST_STRING
#define GaimRoomlistFieldType  GaimRoomlistFieldType

#define purple_roomlist_show_with_account  purple_roomlist_show_with_account
#define purple_roomlist_new                purple_roomlist_new
#define purple_roomlist_ref                purple_roomlist_ref
#define purple_roomlist_unref              purple_roomlist_unref
#define purple_roomlist_set_fields         purple_roomlist_set_fields
#define purple_roomlist_set_in_progress    purple_roomlist_set_in_progress
#define purple_roomlist_get_in_progress    purple_roomlist_get_in_progress
#define purple_roomlist_room_add           purple_roomlist_room_add

#define purple_roomlist_get_list         purple_roomlist_get_list
#define purple_roomlist_cancel_get_list  purple_roomlist_cancel_get_list
#define purple_roomlist_expand_category  purple_roomlist_expand_category

#define purple_roomlist_room_new        purple_roomlist_room_new
#define purple_roomlist_room_add_field  purple_roomlist_room_add_field
#define purple_roomlist_room_join       purple_roomlist_room_join
#define purple_roomlist_field_new       purple_roomlist_field_new

#define purple_roomlist_set_ui_ops  purple_roomlist_set_ui_ops
#define purple_roomlist_get_ui_ops  purple_roomlist_get_ui_ops

/* from savedstatuses.h */

#define GaimSavedStatus     GaimSavedStatus
#define GaimSavedStatusSub  GaimSavedStatusSub

#define purple_savedstatus_new              purple_savedstatus_new
#define purple_savedstatus_set_title        purple_savedstatus_set_title
#define purple_savedstatus_set_type         purple_savedstatus_set_type
#define purple_savedstatus_set_message      purple_savedstatus_set_message
#define purple_savedstatus_set_substatus    purple_savedstatus_set_substatus
#define purple_savedstatus_unset_substatus  purple_savedstatus_unset_substatus
#define purple_savedstatus_delete           purple_savedstatus_delete

#define purple_savedstatuses_get_all              purple_savedstatuses_get_all
#define purple_savedstatuses_get_popular          purple_savedstatuses_get_popular
#define purple_savedstatus_get_current            purple_savedstatus_get_current
#define purple_savedstatus_get_default            purple_savedstatus_get_default
#define purple_savedstatus_get_idleaway           purple_savedstatus_get_idleaway
#define purple_savedstatus_is_idleaway            purple_savedstatus_is_idleaway
#define purple_savedstatus_set_idleaway           purple_savedstatus_set_idleaway
#define purple_savedstatus_get_startup            purple_savedstatus_get_startup
#define purple_savedstatus_find                   purple_savedstatus_find
#define purple_savedstatus_find_by_creation_time  purple_savedstatus_find_by_creation_time
#define purple_savedstatus_find_transient_by_type_and_message \
	purple_savedstatus_find_transient_by_type_and_message

#define purple_savedstatus_is_transient           purple_savedstatus_is_transient
#define purple_savedstatus_get_title              purple_savedstatus_get_title
#define purple_savedstatus_get_type               purple_savedstatus_get_type
#define purple_savedstatus_get_message            purple_savedstatus_get_message
#define purple_savedstatus_get_creation_time      purple_savedstatus_get_creation_time
#define purple_savedstatus_has_substatuses        purple_savedstatus_has_substatuses
#define purple_savedstatus_get_substatus          purple_savedstatus_get_substatus
#define purple_savedstatus_substatus_get_type     purple_savedstatus_substatus_get_type
#define purple_savedstatus_substatus_get_message  purple_savedstatus_substatus_get_message
#define purple_savedstatus_activate               purple_savedstatus_activate
#define purple_savedstatus_activate_for_account   purple_savedstatus_activate_for_account

#define purple_savedstatuses_get_handle  purple_savedstatuses_get_handle
#define purple_savedstatuses_init        purple_savedstatuses_init
#define purple_savedstatuses_uninit      purple_savedstatuses_uninit

/* from signals.h */

#define GAIM_CALLBACK  GAIM_CALLBACK

#define GaimCallback           GaimCallback
#define GaimSignalMarshalFunc  GaimSignalMarshalFunc

#define GAIM_SIGNAL_PRIORITY_DEFAULT  GAIM_SIGNAL_PRIORITY_DEFAULT
#define GAIM_SIGNAL_PRIORITY_HIGHEST  GAIM_SIGNAL_PRIORITY_HIGHEST
#define GAIM_SIGNAL_PRIORITY_LOWEST   GAIM_SIGNAL_PRIORITY_LOWEST

#define purple_signal_register    purple_signal_register
#define purple_signal_unregister  purple_signal_unregister

#define purple_signals_unregister_by_instance  purple_signals_unregister_by_instance

#define purple_signal_get_values              purple_signal_get_values
#define purple_signal_connect_priority        purple_signal_connect_priority
#define purple_signal_connect                 purple_signal_connect
#define purple_signal_connect_priority_vargs  purple_signal_connect_priority_vargs
#define purple_signal_connect_vargs           purple_signal_connect_vargs
#define purple_signal_disconnect              purple_signal_disconnect

#define purple_signals_disconnect_by_handle  purple_signals_disconnect_by_handle

#define purple_signal_emit                 purple_signal_emit
#define purple_signal_emit_vargs           purple_signal_emit_vargs
#define purple_signal_emit_return_1        purple_signal_emit_vargs
#define purple_signal_emit_vargs_return_1  purple_signal_emit_vargs_return_1

#define purple_signals_init    purple_signals_init
#define purple_signals_uninit  purple_signals_uninit

#define purple_marshal_VOID \
	purple_marshal_VOID
#define purple_marshal_VOID__INT \
	purple_marshal_VOID__INT
#define purple_marshal_VOID__INT_INT \
	purple_marshal_VOID_INT_INT
#define purple_marshal_VOID__POINTER \
	purple_marshal_VOID__POINTER
#define purple_marshal_VOID__POINTER_UINT \
	purple_marshal_VOID__POINTER_UINT
#define purple_marshal_VOID__POINTER_INT_INT \
	purple_marshal_VOID__POINTER_INT_INT
#define purple_marshal_VOID__POINTER_POINTER \
	purple_marshal_VOID__POINTER_POINTER
#define purple_marshal_VOID__POINTER_POINTER_UINT \
	purple_marshal_VOID__POINTER_POINTER_UINT
#define purple_marshal_VOID__POINTER_POINTER_UINT_UINT \
	purple_marshal_VOID__POINTER_POINTER_UINT_UINT
#define purple_marshal_VOID__POINTER_POINTER_POINTER \
	purple_marshal_VOID__POINTER_POINTER_POINTER
#define purple_marshal_VOID__POINTER_POINTER_POINTER_POINTER \
	purple_marshal_VOID__POINTER_POINTER_POINTER_POINTER
#define purple_marshal_VOID__POINTER_POINTER_POINTER_POINTER_POINTER \
	purple_marshal_VOID__POINTER_POINTER_POINTER_POINTER_POINTER
#define purple_marshal_VOID__POINTER_POINTER_POINTER_UINT \
	purple_marshal_VOID__POINTER_POINTER_POINTER_UINT
#define purple_marshal_VOID__POINTER_POINTER_POINTER_POINTER_UINT \
	purple_marshal_VOID__POINTER_POINTER_POINTER_POINTER_UINT
#define purple_marshal_VOID__POINTER_POINTER_POINTER_UINT_UINT \
	purple_marshal_VOID__POINTER_POINTER_POINTER_UINT_UINT

#define purple_marshal_INT__INT \
	purple_marshal_INT__INT
#define purple_marshal_INT__INT_INT \
	purple_marshal_INT__INT_INT
#define purple_marshal_INT__POINTER_POINTER_POINTER_POINTER_POINTER \
	purple_marshal_INT__POINTER_POINTER_POINTER_POINTER_POINTER

#define purple_marshal_BOOLEAN__POINTER \
	purple_marshal_BOOLEAN__POINTER
#define purple_marshal_BOOLEAN__POINTER_POINTER \
	purple_marshal_BOOLEAN__POINTER_POINTER
#define purple_marshal_BOOLEAN__POINTER_POINTER_POINTER \
	purple_marshal_BOOLEAN__POINTER_POINTER_POINTER
#define purple_marshal_BOOLEAN__POINTER_POINTER_UINT \
	purple_marshal_BOOLEAN__POINTER_POINTER_UINT
#define purple_marshal_BOOLEAN__POINTER_POINTER_POINTER_UINT \
	purple_marshal_BOOLEAN__POINTER_POINTER_POINTER_UINT
#define purple_marshal_BOOLEAN__POINTER_POINTER_POINTER_POINTER \
	purple_marshal_BOOLEAN__POINTER_POINTER_POINTER_POINTER
#define purple_marshal_BOOLEAN__POINTER_POINTER_POINTER_POINTER_POINTER \
	purple_marshal_BOOLEAN__POINTER_POINTER_POINTER_POINTER_POINTER

#define purple_marshal_BOOLEAN__INT_POINTER \
	purple_marshal_BOOLEAN__INT_POINTER

#define purple_marshal_POINTER__POINTER_INT \
	purple_marshal_POINTER__POINTER_INT
#define purple_marshal_POINTER__POINTER_INT64 \
	purple_marshal_POINTER__POINTER_INT64
#define purple_marshal_POINTER__POINTER_INT_BOOLEAN \
	purple_marshal_POINTER__POINTER_INT_BOOLEAN
#define purple_marshal_POINTER__POINTER_INT64_BOOLEAN \
	purple_marshal_POINTER__POINTER_INT64_BOOLEAN
#define purple_marshal_POINTER__POINTER_POINTER \
	purple_marshal_POINTER__POINTER_POINTER

/* from sound.h */

#define GAIM_SOUND_BUDDY_ARRIVE    GAIM_SOUND_BUDDY_ARRIVE
#define GAIM_SOUND_BUDDY_LEAVE     GAIM_SOUND_BUDDY_LEAVE
#define GAIM_SOUND_RECEIVE         GAIM_SOUND_RECEIVE
#define GAIM_SOUND_FIRST_RECEIVE   GAIM_SOUND_FIRST_RECEIVE
#define GAIM_SOUND_SEND            GAIM_SOUND_SEND
#define GAIM_SOUND_CHAT_JOIN       GAIM_SOUND_CHAT_JOIN
#define GAIM_SOUND_CHAT_LEAVE      GAIM_SOUND_CHAT_LEAVE
#define GAIM_SOUND_CHAT_YOU_SAY    GAIM_SOUND_CHAT_YOU_SAY
#define GAIM_SOUND_CHAT_SAY        GAIM_SOUND_CHAT_SAY
#define GAIM_SOUND_POUNCE_DEFAULT  GAIM_SOUND_POUNCE_DEFAULT
#define GAIM_SOUND_CHAT_NICK       GAIM_SOUND_CHAT_NICK
#define GAIM_NUM_SOUNDS            GAIM_NUM_SOUNDS
#define GaimSoundEventID  GaimSoundEventID

#define GaimSoundUiOps  GaimSoundUiOps

#define purple_sound_play_file   purple_sound_play_file
#define purple_sound_play_event  purple_sound_play_event
#define purple_sound_set_ui_ops  purple_sound_set_ui_ops
#define purple_sound_get_ui_ops  purple_sound_get_ui_ops
#define purple_sound_init        purple_sound_init
#define purple_sound_uninit      purple_sound_uninit

#define purple_sounds_get_handle  purple_sounds_get_handle

/* from sslconn.h */

#define GAIM_SSL_DEFAULT_PORT  GAIM_SSL_DEFAULT_PORT

#define GAIM_SSL_HANDSHAKE_FAILED  GAIM_SSL_HANDSHAKE_FAILED
#define GAIM_SSL_CONNECT_FAILED    GAIM_SSL_CONNECT_FAILED
#define GaimSslErrorType  GaimSslErrorType

#define GaimSslConnection  GaimSslConnection

#define GaimSslInputFunction  GaimSslInputFunction
#define GaimSslErrorFunction  GaimSslErrorFunction

#define GaimSslOps  GaimSslOps

#define purple_ssl_is_supported  purple_ssl_is_supported
#define purple_ssl_connect       purple_ssl_connect
#define purple_ssl_connect_fd    purple_ssl_connect_fd
#define purple_ssl_input_add     purple_ssl_input_add
#define purple_ssl_close         purple_ssl_close
#define purple_ssl_read          purple_ssl_read
#define purple_ssl_write         purple_ssl_write

#define purple_ssl_set_ops  purple_ssl_set_ops
#define purple_ssl_get_ops  purple_ssl_get_ops
#define purple_ssl_init     purple_ssl_init
#define purple_ssl_uninit   purple_ssl_uninit

/* from status.h */

#define GaimStatusType  GaimStatusType
#define GaimStatusAttr  GaimStatusAttr
#define GaimPresence    GaimPresence
#define GaimStatus      GaimStatus

#define GAIM_PRESENCE_CONTEXT_UNSET    GAIM_PRESENCE_CONTEXT_UNSET
#define GAIM_PRESENCE_CONTEXT_ACCOUNT  GAIM_PRESENCE_CONTEXT_ACCOUNT
#define GAIM_PRESENCE_CONTEXT_CONV     GAIM_PRESENCE_CONTEXT_CONV
#define GAIM_PRESENCE_CONTEXT_BUDDY    GAIM_PRESENCE_CONTEXT_BUDDY
#define GaimPresenceContext  GaimPresenceContext

#define GAIM_STATUS_UNSET           GAIM_STATUS_UNSET
#define GAIM_STATUS_OFFLINE         GAIM_STATUS_OFFLINE
#define GAIM_STATUS_AVAILABLE       GAIM_STATUS_AVAILABLE
#define GAIM_STATUS_UNAVAILABLE     GAIM_STATUS_UNAVAILABLE
#define GAIM_STATUS_INVISIBLE       GAIM_STATUS_INVISIBLE
#define GAIM_STATUS_AWAY            GAIM_STATUS_AWAY
#define GAIM_STATUS_EXTENDED_AWAY   GAIM_STATUS_EXTENDED_AWAY
#define GAIM_STATUS_MOBILE          GAIM_STATUS_MOBILE
#define GAIM_STATUS_NUM_PRIMITIVES  GAIM_STATUS_NUM_PRIMITIVES
#define GaimStatusPrimitive  GaimStatusPrimitive

#define purple_primitive_get_id_from_type    purple_primitive_get_id_from_type
#define purple_primitive_get_name_from_type  purple_primitive_get_name_from_type
#define purple_primitive_get_type_from_id    purple_primitive_get_type_from_id

#define purple_status_type_new_full          purple_status_type_new_full
#define purple_status_type_new               purple_status_type_new
#define purple_status_type_new_with_attrs    purple_status_type_new_with_attrs
#define purple_status_type_destroy           purple_status_type_destroy
#define purple_status_type_set_primary_attr  purple_status_type_set_primary_attr
#define purple_status_type_add_attr          purple_status_type_add_attr
#define purple_status_type_add_attrs         purple_status_type_add_attrs
#define purple_status_type_add_attrs_vargs   purple_status_type_add_attrs_vargs
#define purple_status_type_get_primitive     purple_status_type_get_primitive
#define purple_status_type_get_id            purple_status_type_get_id
#define purple_status_type_get_name          purple_status_type_get_name
#define purple_status_type_is_saveable       purple_status_type_is_saveable
#define purple_status_type_is_user_settable  purple_status_type_is_user_settable
#define purple_status_type_is_independent    purple_status_type_is_independent
#define purple_status_type_is_exclusive      purple_status_type_is_exclusive
#define purple_status_type_is_available      purple_status_type_is_available
#define purple_status_type_get_primary_attr  purple_status_type_get_primary_attr
#define purple_status_type_get_attr          purple_status_type_get_attr
#define purple_status_type_get_attrs         purple_status_type_get_attrs
#define purple_status_type_find_with_id      purple_status_type_find_with_id

#define purple_status_attr_new        purple_status_attr_new
#define purple_status_attr_destroy    purple_status_attr_destroy
#define purple_status_attr_get_id     purple_status_attr_get_id
#define purple_status_attr_get_name   purple_status_attr_get_name
#define purple_status_attr_get_value  purple_status_attr_get_value

#define purple_status_new                         purple_status_new
#define purple_status_destroy                     purple_status_destroy
#define purple_status_set_active                  purple_status_set_active
#define purple_status_set_active_with_attrs       purple_status_set_active_with_attrs
#define purple_status_set_active_with_attrs_list  purple_status_set_active_with_attrs_list
#define purple_status_set_attr_boolean            purple_status_set_attr_boolean
#define purple_status_set_attr_int                purple_status_set_attr_int
#define purple_status_set_attr_string             purple_status_set_attr_string
#define purple_status_get_type                    purple_status_get_type
#define purple_status_get_presence                purple_status_get_presence
#define purple_status_get_id                      purple_status_get_id
#define purple_status_get_name                    purple_status_get_name
#define purple_status_is_independent              purple_status_is_independent
#define purple_status_is_exclusive                purple_status_is_exclusive
#define purple_status_is_available                purple_status_is_available
#define purple_status_is_active                   purple_status_is_active
#define purple_status_is_online                   purple_status_is_online
#define purple_status_get_attr_value              purple_status_get_attr_value
#define purple_status_get_attr_boolean            purple_status_get_attr_boolean
#define purple_status_get_attr_int                purple_status_get_attr_int
#define purple_status_get_attr_string             purple_status_get_attr_string
#define purple_status_compare                     purple_status_compare

#define purple_presence_new                purple_presence_new
#define purple_presence_new_for_account    purple_presence_new_for_account
#define purple_presence_new_for_conv       purple_presence_new_for_conv
#define purple_presence_new_for_buddy      purple_presence_new_for_buddy
#define purple_presence_destroy            purple_presence_destroy
#define purple_presence_remove_buddy       purple_presence_remove_buddy
#define purple_presence_add_status         purple_presence_add_status
#define purple_presence_add_list           purple_presence_add_list
#define purple_presence_set_status_active  purple_presence_set_status_active
#define purple_presence_switch_status      purple_presence_switch_status
#define purple_presence_set_idle           purple_presence_set_idle
#define purple_presence_set_login_time     purple_presence_set_login_time
#define purple_presence_get_context        purple_presence_get_context
#define purple_presence_get_account        purple_presence_get_account
#define purple_presence_get_conversation   purple_presence_get_conversation
#define purple_presence_get_chat_user      purple_presence_get_chat_user
#define purple_presence_get_buddies        purple_presence_get_buddies
#define purple_presence_get_statuses       purple_presence_get_statuses
#define purple_presence_get_status         purple_presence_get_status
#define purple_presence_get_active_status  purple_presence_get_active_status
#define purple_presence_is_available       purple_presence_is_available
#define purple_presence_is_online          purple_presence_is_online
#define purple_presence_is_status_active   purple_presence_is_status_active
#define purple_presence_is_status_primitive_active \
	purple_presence_is_status_primitive_active
#define purple_presence_is_idle            purple_presence_is_idle
#define purple_presence_get_idle_time      purple_presence_get_idle_time
#define purple_presence_get_login_time     purple_presence_get_login_time
#define purple_presence_compare            purple_presence_compare

#define purple_status_get_handle  purple_status_get_handle
#define purple_status_init        purple_status_init
#define purple_status_uninit      purple_status_uninit

/* from stringref.h */

#define GaimStringref  GaimStringref

#define purple_stringref_new        purple_stringref_new
#define purple_stringref_new_noref  purple_stringref_new_noref
#define purple_stringref_printf     purple_stringref_printf
#define purple_stringref_ref        purple_stringref_ref
#define purple_stringref_unref      purple_stringref_unref
#define purple_stringref_value      purple_stringref_value
#define purple_stringref_cmp        purple_stringref_cmp
#define purple_stringref_len        purple_stringref_len

/* from stun.h */

#define GaimStunNatDiscovery  GaimStunNatDiscovery

#define GAIM_STUN_STATUS_UNDISCOVERED  GAIM_STUN_STATUS_UNDISCOVERED
#define GAIM_STUN_STATUS_UNKNOWN       GAIM_STUN_STATUS_UNKNOWN
#define GAIM_STUN_STATUS_DISCOVERING   GAIM_STUN_STATUS_DISCOVERING
#define GAIM_STUN_STATUS_DISCOVERED    GAIM_STUN_STATUS_DISCOVERED
#define GaimStunStatus  GaimStunStatus

#define GAIM_STUN_NAT_TYPE_PUBLIC_IP             GAIM_STUN_NAT_TYPE_PUBLIC_IP
#define GAIM_STUN_NAT_TYPE_UNKNOWN_NAT           GAIM_STUN_NAT_TYPE_UNKNOWN_NAT
#define GAIM_STUN_NAT_TYPE_FULL_CONE             GAIM_STUN_NAT_TYPE_FULL_CONE
#define GAIM_STUN_NAT_TYPE_RESTRICTED_CONE       GAIM_STUN_NAT_TYPE_RESTRICTED_CONE
#define GAIM_STUN_NAT_TYPE_PORT_RESTRICTED_CONE  GAIM_STUN_NAT_TYPE_PORT_RESTRICTED_CONE
#define GAIM_STUN_NAT_TYPE_SYMMETRIC             GAIM_STUN_NAT_TYPE_SYMMETRIC
#define GaimStunNatType  GaimStunNatType

/* why didn't this have a Gaim prefix before? */
#define StunCallback  GaimStunCallback

#define purple_stun_discover  purple_stun_discover
#define purple_stun_init      purple_stun_init

/* from upnp.h */

/* suggested rename: GaimUPnpMappingHandle */
#define UPnPMappingAddRemove  GaimUPnPMappingAddRemove

#define GaimUPnPCallback  GaimUPnPCallback

#define purple_upnp_discover             purple_upnp_discover
#define purple_upnp_get_public_ip        purple_upnp_get_public_ip
#define purple_upnp_cancel_port_mapping  purple_upnp_cancel_port_mapping
#define purple_upnp_set_port_mapping     purple_upnp_set_port_mapping

#define purple_upnp_remove_port_mapping  purple_upnp_remove_port_mapping

/* from util.h */

#define GaimUtilFetchUrlData  GaimUtilFetchUrlData
#define GaimMenuAction        GaimMenuAction

#define GaimInfoFieldFormatCallback  GaimIntoFieldFormatCallback

#define GaimKeyValuePair  GaimKeyValuePair

#define purple_menu_action_new   purple_menu_action_new
#define purple_menu_action_free  purple_menu_action_free

#define purple_base16_encode   purple_base16_encode
#define purple_base16_decode   purple_base16_decode
#define purple_base64_encode   purple_base64_encode
#define purple_base64_decode   purple_base64_decode
#define purple_quotedp_decode  purple_quotedp_decode

#define purple_mime_decode_field  purple_mime_deco_field

#define purple_utf8_strftime      purple_utf8_strftime
#define purple_date_format_short  purple_date_format_short
#define purple_date_format_long   purple_date_format_long
#define purple_date_format_full   purple_date_format_full
#define purple_time_format        purple_time_format
#define purple_time_build         purple_time_build

#define GAIM_NO_TZ_OFF  GAIM_NO_TZ_OFF

#define purple_str_to_time  purple_str_to_time

#define purple_markup_find_tag            purple_markup_find_tag
#define purple_markup_extract_info_field  purple_markup_extract_info_field
#define purple_markup_html_to_xhtml       purple_markup_html_to_xhtml
#define purple_markup_strip_html          purple_markup_strip_html
#define purple_markup_linkify             purple_markup_linkify
#define purple_markup_slice               purple_markup_slice
#define purple_markup_get_tag_name        purple_markup_get_tag_name
#define purple_unescape_html              purple_unescape_html

#define purple_home_dir  purple_home_dir
#define purple_user_dir  purple_user_dir

#define purple_util_set_user_dir  purple_util_set_user_dir

#define purple_build_dir  purple_build_dir

#define purple_util_write_data_to_file  purple_util_write_data_to_file

#define purple_util_read_xml_from_file  purple_util_read_xml_from_file

#define purple_mkstemp  purple_mkstemp

#define purple_program_is_valid  purple_program_is_valid

#define purple_running_gnome  purple_running_gnome
#define purple_running_kde    purple_running_kde
#define purple_running_osx    purple_running_osx

#define purple_fd_get_ip  purple_fd_get_ip

#define purple_normalize         purple_normalize
#define purple_normalize_nocase  purple_normalize_nocase

#define purple_strdup_withhtml  purple_strdup_withhtml

#define purple_str_has_prefix  purple_str_has_prefix
#define purple_str_has_suffix  purple_str_has_suffix
#define purple_str_add_cr      purple_str_add_cr
#define purple_str_strip_char  purple_str_strip_char

#define purple_util_chrreplace  purple_util_chrreplace

#define purple_strreplace  purple_strreplace

#define purple_utf8_ncr_encode  purple_utf8_ncr_encode
#define purple_utf8_ncr_decode  purple_utf8_ncr_decode

#define purple_strcasereplace  purple_strcasereplace
#define purple_strcasestr      purple_strcasestr

#define purple_str_size_to_units      purple_str_size_to_units
#define purple_str_seconds_to_string  purple_str_seconds_to_string
#define purple_str_binary_to_ascii    purple_str_binary_to_ascii


#define purple_got_protocol_handler_uri  purple_got_protocol_handler_uri

#define purple_url_parse  purple_url_parse

#define GaimUtilFetchUrlCallback  GaimUtilFetchUrlCallback
#define purple_util_fetch_url          purple_util_fetch_url
#define purple_util_fetch_url_request  purple_util_fetch_url_request
#define purple_util_fetch_url_cancel   purple_util_fetch_url_cancel

#define purple_url_decode  purple_url_decode
#define purple_url_encode  purple_url_encode

#define purple_email_is_valid  purple_email_is_valid

#define purple_uri_list_extract_uris       purple_uri_list_extract_uris
#define purple_uri_list_extract_filenames  purple_uri_list_extract_filenames

#define purple_utf8_try_convert  purple_utf8_try_convert
#define purple_utf8_salvage      purple_utf8_salvage
#define purple_utf8_strcasecmp   purple_utf8_strcasecmp
#define purple_utf8_has_word     purple_utf8_has_word

#define purple_print_utf8_to_console  purple_print_utf8_to_console

#define purple_message_meify  purple_message_meify

#define purple_text_strip_mnemonic  purple_text_strip_mnemonic

#define purple_unescape_filename  purple_unescape_filename
#define purple_escape_filename    purple_escape_filename

/* from value.h */

#define GAIM_TYPE_UNKNOWN  GAIM_TYPE_UNKNOWN
#define GAIM_TYPE_SUBTYPE  GAIM_TYPE_SUBTYPE
#define GAIM_TYPE_CHAR     GAIM_TYPE_CHAR
#define GAIM_TYPE_UCHAR    GAIM_TYPE_UCHAR
#define GAIM_TYPE_BOOLEAN  GAIM_TYPE_BOOLEAN
#define GAIM_TYPE_SHORT    GAIM_TYPE_SHORT
#define GAIM_TYPE_USHORT   GAIM_TYPE_USHORT
#define GAIM_TYPE_INT      GAIM_TYPE_INT
#define GAIM_TYPE_UINT     GAIM_TYPE_UINT
#define GAIM_TYPE_LONG     GAIM_TYPE_LONG
#define GAIM_TYPE_ULONG    GAIM_TYPE_ULONG
#define GAIM_TYPE_INT64    GAIM_TYPE_INT64
#define GAIM_TYPE_UINT64   GAIM_TYPE_UINT64
#define GAIM_TYPE_STRING   GAIM_TYPE_STRING
#define GAIM_TYPE_OBJECT   GAIM_TYPE_OBJECT
#define GAIM_TYPE_POINTER  GAIM_TYPE_POINTER
#define GAIM_TYPE_ENUM     GAIM_TYPE_ENUM
#define GAIM_TYPE_BOXED    GAIM_TYPE_BOXED
#define GaimType  GaimType


#define GAIM_SUBTYPE_UNKNOWN       GAIM_SUBTYPE_UNKNOWN
#define GAIM_SUBTYPE_ACCOUNT       GAIM_SUBTYPE_ACCOUNT
#define GAIM_SUBTYPE_BLIST         GAIM_SUBTYPE_BLIST
#define GAIM_SUBTYPE_BLIST_BUDDY   GAIM_SUBTYPE_BLIST_BUDDY
#define GAIM_SUBTYPE_BLIST_GROUP   GAIM_SUBTYPE_BLIST_GROUP
#define GAIM_SUBTYPE_BLIST_CHAT    GAIM_SUBTYPE_BLIST_CHAT
#define GAIM_SUBTYPE_BUDDY_ICON    GAIM_SUBTYPE_BUDDY_ICON
#define GAIM_SUBTYPE_CONNECTION    GAIM_SUBTYPE_CONNECTION
#define GAIM_SUBTYPE_CONVERSATION  GAIM_SUBTYPE_CONVERSATION
#define GAIM_SUBTYPE_PLUGIN        GAIM_SUBTYPE_PLUGIN
#define GAIM_SUBTYPE_BLIST_NODE    GAIM_SUBTYPE_BLIST_NODE
#define GAIM_SUBTYPE_CIPHER        GAIM_SUBTYPE_CIPHER
#define GAIM_SUBTYPE_STATUS        GAIM_SUBTYPE_STATUS
#define GAIM_SUBTYPE_LOG           GAIM_SUBTYPE_LOG
#define GAIM_SUBTYPE_XFER          GAIM_SUBTYPE_XFER
#define GAIM_SUBTYPE_SAVEDSTATUS   GAIM_SUBTYPE_SAVEDSTATUS
#define GAIM_SUBTYPE_XMLNODE       GAIM_SUBTYPE_XMLNODE
#define GAIM_SUBTYPE_USERINFO      GAIM_SUBTYPE_USERINFO
#define GaimSubType  GaimSubType

#define GaimValue  GaimValue

#define purple_value_new                purple_value_new
#define purple_value_new_outgoing       purple_value_new_outgoing
#define purple_value_destroy            purple_value_destroy
#define purple_value_dup                purple_value_dup
#define purple_value_get_type           purple_value_get_type
#define purple_value_get_subtype        purple_value_get_subtype
#define purple_value_get_specific_type  purple_value_get_specific_type
#define purple_value_is_outgoing        purple_value_is_outgoing
#define purple_value_set_char           purple_value_set_char
#define purple_value_set_uchar          purple_value_set_uchar
#define purple_value_set_boolean        purple_value_set_boolean
#define purple_value_set_short          purple_value_set_short
#define purple_value_set_ushort         purple_value_set_ushort
#define purple_value_set_int            purple_value_set_int
#define purple_value_set_uint           purple_value_set_uint
#define purple_value_set_long           purple_value_set_long
#define purple_value_set_ulong          purple_value_set_ulong
#define purple_value_set_int64          purple_value_set_int64
#define purple_value_set_uint64         purple_value_set_uint64
#define purple_value_set_string         purple_value_set_string
#define purple_value_set_object         purple_value_set_object
#define purple_value_set_pointer        purple_value_set_pointer
#define purple_value_set_enum           purple_value_set_enum
#define purple_value_set_boxed          purple_value_set_boxed
#define purple_value_get_char           purple_value_get_char
#define purple_value_get_uchar          purple_value_get_uchar
#define purple_value_get_boolean        purple_value_get_boolean
#define purple_value_get_short          purple_value_get_short
#define purple_value_get_ushort         purple_value_get_ushort
#define purple_value_get_int            purple_value_get_int
#define purple_value_get_uint           purple_value_get_uint
#define purple_value_get_long           purple_value_get_long
#define purple_value_get_ulong          purple_value_get_ulong
#define purple_value_get_int64          purple_value_get_int64
#define purple_value_get_uint64         purple_value_get_uint64
#define purple_value_get_string         purple_value_get_string
#define purple_value_get_object         purple_value_get_object
#define purple_value_get_pointer        purple_value_get_pointer
#define purple_value_get_enum           purple_value_get_enum
#define purple_value_get_boxed          purple_value_get_boxed

/* from version.h */

#define GAIM_MAJOR_VERSION  GAIM_MAJOR_VERSION
#define GAIM_MINOR_VERSION  GAIM_MINOR_VERSION
#define GAIM_MICRO_VERSION  GAIM_MICRO_VERSION

#define GAIM_VERSION_CHECK  GAIM_VERSION_CHECK

/* from whiteboard.h */

#define GaimWhiteboardPrplOps  GaimWhiteboardPrplOps
#define GaimWhiteboard         GaimWhiteboard
#define GaimWhiteboardUiOps    GaimWhiteboardUiOps

#define purple_whiteboard_set_ui_ops    purple_whiteboard_set_ui_ops
#define purple_whiteboard_set_prpl_ops  purple_whiteboard_set_prpl_ops

#define purple_whiteboard_create             purple_whiteboard_create
#define purple_whiteboard_destroy            purple_whiteboard_destroy
#define purple_whiteboard_start              purple_whiteboard_start
#define purple_whiteboard_get_session        purple_whiteboard_get_session
#define purple_whiteboard_draw_list_destroy  purple_whiteboard_draw_list_destroy
#define purple_whiteboard_get_dimensions     purple_whiteboard_get_dimensions
#define purple_whiteboard_set_dimensions     purple_whiteboard_set_dimensions
#define purple_whiteboard_draw_point         purple_whiteboard_draw_point
#define purple_whiteboard_send_draw_list     purple_whiteboard_send_draw_list
#define purple_whiteboard_draw_line          purple_whiteboard_draw_line
#define purple_whiteboard_clear              purple_whiteboard_clear
#define purple_whiteboard_send_clear         purple_whiteboard_send_clear
#define purple_whiteboard_send_brush         purple_whiteboard_send_brush
#define purple_whiteboard_get_brush          purple_whiteboard_get_brush
#define purple_whiteboard_set_brush          purple_whiteboard_set_brush

/* for static plugins */
#define purple_init_ssl_plugin			purple_init_ssl_plugin
#define purple_init_ssl_openssl_plugin	purple_init_ssl_openssl_plugin
#define purple_init_ssl_gnutls_plugin		purple_init_ssl_gnutls_plugin
#define purple_init_gg_plugin				purple_init_gg_plugin
#define purple_init_jabber_plugin			purple_init_jabber_plugin
#define purple_init_sametime_plugin		purple_init_sametime_plugin
#define purple_init_msn_plugin			purple_init_msn_plugin
#define purple_init_novell_plugin			purple_init_novell_plugin
#define purple_init_qq_plugin				purple_init_qq_plugin
#define purple_init_simple_plugin			purple_init_simple_plugin
#define purple_init_yahoo_plugin			purple_init_yahoo_plugin
#define purple_init_zephyr_plugin			purple_init_zephyr_plugin
#define purple_init_aim_plugin			purple_init_aim_plugin
#define purple_init_icq_plugin			purple_init_icq_plugin

#endif /* _GAIM_COMPAT_H_ */
