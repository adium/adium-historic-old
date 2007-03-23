/**
 * @file gaim-compat.h Gaim Compat macros
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

#define gaim_account_new           gaim_account_new
#define gaim_account_destroy       gaim_account_destroy
#define gaim_account_connect       gaim_account_connect
#define gaim_account_register      gaim_account_register
#define gaim_account_disconnect    gaim_account_disconnect
#define gaim_account_notify_added  gaim_account_notify_added
#define gaim_account_request_add   gaim_account_request_add
#define gaim_account_request_close   gaim_account_request_close

#define gaim_account_request_authorization     gaim_account_request_authorization
#define gaim_account_request_change_password   gaim_account_request_change_password
#define gaim_account_request_change_user_info  gaim_account_request_change_user_info

#define gaim_account_set_username            gaim_account_set_username
#define gaim_account_set_password            gaim_account_set_password
#define gaim_account_set_alias               gaim_account_set_alias
#define gaim_account_set_user_info           gaim_account_set_user_info
#define gaim_account_set_buddy_icon          gaim_account_set_buddy_icon
#define gaim_account_set_buddy_icon_path     gaim_account_set_buddy_icon_path
#define gaim_account_set_protocol_id         gaim_account_set_protocol_id
#define gaim_account_set_connection          gaim_account_set_connection
#define gaim_account_set_remember_password   gaim_account_set_remember_password
#define gaim_account_set_check_mail          gaim_account_set_check_mail
#define gaim_account_set_enabled             gaim_account_set_enabled
#define gaim_account_set_proxy_info          gaim_account_set_proxy_info
#define gaim_account_set_status_types        gaim_account_set_status_types
#define gaim_account_set_status              gaim_account_set_status
#define gaim_account_set_status_list         gaim_account_set_status_list

#define gaim_account_clear_settings   gaim_account_clear_settings

#define gaim_account_set_int    gaim_account_set_int
#define gaim_account_set_string gaim_account_set_string
#define gaim_account_set_bool   gaim_account_set_bool

#define gaim_account_set_ui_int     gaim_account_set_ui_int
#define gaim_account_set_ui_string  gaim_account_set_ui_string
#define gaim_account_set_ui_bool    gaim_account_set_ui_bool

#define gaim_account_is_connected     gaim_account_is_connected
#define gaim_account_is_connecting    gaim_account_is_connecting
#define gaim_account_is_disconnected  gaim_account_is_disconnected

#define gaim_account_get_username           gaim_account_get_username
#define gaim_account_get_password           gaim_account_get_password
#define gaim_account_get_alias              gaim_account_get_alias
#define gaim_account_get_user_info          gaim_account_get_user_info
#define gaim_account_get_buddy_icon         gaim_account_get_buddy_icon
#define gaim_account_get_buddy_icon_path    gaim_account_get_buddy_icon_path
#define gaim_account_get_protocol_id        gaim_account_get_protocol_id
#define gaim_account_get_protocol_name      gaim_account_get_protocol_name
#define gaim_account_get_connection         gaim_account_get_connection
#define gaim_account_get_remember_password  gaim_account_get_remember_password
#define gaim_account_get_check_mail         gaim_account_get_check_mail
#define gaim_account_get_enabled            gaim_account_get_enabled
#define gaim_account_get_proxy_info         gaim_account_get_proxy_info
#define gaim_account_get_active_status      gaim_account_get_active_status
#define gaim_account_get_status             gaim_account_get_status
#define gaim_account_get_status_type        gaim_account_get_status_type
#define gaim_account_get_status_type_with_primitive \
	gaim_account_get_status_type_with_primitive

#define gaim_account_get_presence       gaim_account_get_presence
#define gaim_account_is_status_active   gaim_account_is_status_active
#define gaim_account_get_status_types   gaim_account_get_status_types

#define gaim_account_get_int            gaim_account_get_int
#define gaim_account_get_string         gaim_account_get_string
#define gaim_account_get_bool           gaim_account_get_bool

#define gaim_account_get_ui_int     gaim_account_get_ui_int
#define gaim_account_get_ui_string  gaim_account_get_ui_string
#define gaim_account_get_ui_bool    gaim_account_get_ui_bool


#define gaim_account_get_log      gaim_account_get_log
#define gaim_account_destroy_log  gaim_account_destroy_log

#define gaim_account_add_buddy       gaim_account_add_buddy
#define gaim_account_add_buddies     gaim_account_add_buddies
#define gaim_account_remove_buddy    gaim_account_remove_buddy
#define gaim_account_remove_buddies  gaim_account_remove_buddies

#define gaim_account_remove_group  gaim_account_remove_group

#define gaim_account_change_password  gaim_account_change_password

#define gaim_account_supports_offline_message  gaim_account_supports_offline_message

#define gaim_accounts_add      gaim_accounts_add
#define gaim_accounts_remove   gaim_accounts_remove
#define gaim_accounts_delete   gaim_accounts_delete
#define gaim_accounts_reorder  gaim_accounts_reorder

#define gaim_accounts_get_all         gaim_accounts_get_all
#define gaim_accounts_get_all_active  gaim_accounts_get_all_active

#define gaim_accounts_find   gaim_accounts_find

#define gaim_accounts_restore_current_statuses  gaim_accounts_restore_current_statuses

#define gaim_accounts_set_ui_ops  gaim_accounts_set_ui_ops
#define gaim_accounts_get_ui_ops  gaim_accounts_get_ui_ops

#define gaim_accounts_get_handle  gaim_accounts_get_handle

#define gaim_accounts_init    gaim_accounts_init
#define gaim_accounts_uninit  gaim_accounts_uninit

/* from accountopt.h */

#define GaimAccountOption     GaimAccountOption
#define GaimAccountUserSplit  GaimAccountUserSplit

#define gaim_account_option_new         gaim_account_option_new
#define gaim_account_option_bool_new    gaim_account_option_bool_new
#define gaim_account_option_int_new     gaim_account_option_int_new
#define gaim_account_option_string_new  gaim_account_option_string_new
#define gaim_account_option_list_new    gaim_account_option_list_new

#define gaim_account_option_destroy  gaim_account_option_destroy

#define gaim_account_option_set_default_bool    gaim_account_option_set_default_bool
#define gaim_account_option_set_default_int     gaim_account_option_set_default_int
#define gaim_account_option_set_default_string  gaim_account_option_set_default_string

#define gaim_account_option_set_masked  gaim_account_option_set_masked

#define gaim_account_option_set_list  gaim_account_option_set_list

#define gaim_account_option_add_list_item  gaim_account_option_add_list_item

#define gaim_account_option_get_type     gaim_account_option_get_type
#define gaim_account_option_get_text     gaim_account_option_get_text
#define gaim_account_option_get_setting  gaim_account_option_get_setting

#define gaim_account_option_get_default_bool        gaim_account_option_get_default_bool
#define gaim_account_option_get_default_int         gaim_account_option_get_default_int
#define gaim_account_option_get_default_string      gaim_account_option_get_default_string
#define gaim_account_option_get_default_list_value  gaim_account_option_get_default_list_value

#define gaim_account_option_get_masked  gaim_account_option_get_masked
#define gaim_account_option_get_list    gaim_account_option_get_list

#define gaim_account_user_split_new      gaim_account_user_split_new
#define gaim_account_user_split_destroy  gaim_account_user_split_destroy

#define gaim_account_user_split_get_text           gaim_account_user_split_get_text
#define gaim_account_user_split_get_default_value  gaim_account_user_split_get_default_value
#define gaim_account_user_split_get_separator      gaim_account_user_split_get_separator

/* from blist.h */

#define GaimBuddyList    GaimBuddyList
#define GaimBlistUiOps   GaimBlistUiOps
#define GaimBlistNode    GaimBlistNode

#define GaimChat     GaimChat
#define GaimGroup    GaimGroup
#define GaimContact  GaimContact
#define GaimBuddy    GaimBuddy

#define GAIM_BLIST_GROUP_NODE     GAIM_BLIST_GROUP_NODE
#define GAIM_BLIST_CONTACT_NODE   GAIM_BLIST_CONTACT_NODE
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


#define gaim_blist_new  gaim_blist_new
#define gaim_set_blist  gaim_set_blist
#define gaim_get_blist  gaim_get_blist

#define gaim_blist_get_root   gaim_blist_get_root
#define gaim_blist_node_next  gaim_blist_node_next

#define gaim_blist_show  gaim_blist_show

#define gaim_blist_destroy  gaim_blist_destroy

#define gaim_blist_set_visible  gaim_blist_set_visible

#define gaim_blist_update_buddy_status  gaim_blist_update_buddy_status
#define gaim_blist_update_buddy_icon    gaim_blist_update_buddy_icon


#define gaim_blist_alias_contact       gaim_blist_alias_contact
#define gaim_blist_alias_buddy         gaim_blist_alias_buddy
#define gaim_blist_server_alias_buddy  gaim_blist_server_alias_buddy
#define gaim_blist_alias_chat          gaim_blist_alias_chat

#define gaim_blist_rename_buddy  gaim_blist_rename_buddy
#define gaim_blist_rename_group  gaim_blist_rename_group

#define gaim_chat_new        gaim_chat_new
#define gaim_blist_add_chat  gaim_blist_add_chat

#define gaim_buddy_new           gaim_buddy_new
#define gaim_buddy_set_icon      gaim_buddy_set_icon
#define gaim_buddy_get_account   gaim_buddy_get_account
#define gaim_buddy_get_name      gaim_buddy_get_name
#define gaim_buddy_get_icon      gaim_buddy_get_icon
#define gaim_buddy_get_contact   gaim_buddy_get_contact
#define gaim_buddy_get_presence  gaim_buddy_get_presence

#define gaim_blist_add_buddy  gaim_blist_add_buddy

#define gaim_group_new  gaim_group_new

#define gaim_blist_add_group  gaim_blist_add_group

#define gaim_contact_new  gaim_contact_new

#define gaim_blist_add_contact    gaim_blist_add_contact
#define gaim_blist_merge_contact  gaim_blist_merge_contact

#define gaim_contact_get_priority_buddy  gaim_contact_get_priority_buddy
#define gaim_contact_set_alias           gaim_contact_set_alias
#define gaim_contact_get_alias           gaim_contact_get_alias
#define gaim_contact_on_account          gaim_contact_on_account

#define gaim_contact_invalidate_priority_buddy  gaim_contact_invalidate_priority_buddy

#define gaim_blist_remove_buddy    gaim_blist_remove_buddy
#define gaim_blist_remove_contact  gaim_blist_remove_contact
#define gaim_blist_remove_chat     gaim_blist_remove_chat
#define gaim_blist_remove_group    gaim_blist_remove_group

#define gaim_buddy_get_alias_only     gaim_buddy_get_alias_only
#define gaim_buddy_get_server_alias   gaim_buddy_get_server_alias
#define gaim_buddy_get_contact_alias  gaim_buddy_get_contact_alias
#define gaim_buddy_get_local_alias    gaim_buddy_get_local_alias
#define gaim_buddy_get_alias          gaim_buddy_get_alias

#define gaim_chat_get_name  gaim_chat_get_name

#define gaim_find_buddy           gaim_find_buddy
#define gaim_find_buddy_in_group  gaim_find_buddy_in_group
#define gaim_find_buddies         gaim_find_buddies

#define gaim_find_group  gaim_find_group

#define gaim_blist_find_chat  gaim_blist_find_chat

#define gaim_chat_get_group   gaim_chat_get_group
#define gaim_buddy_get_group  gaim_buddy_get_group

#define gaim_group_get_accounts  gaim_group_get_accounts
#define gaim_group_on_account    gaim_group_on_account

#define gaim_blist_add_account     gaim_blist_add_account
#define gaim_blist_remove_account  gaim_blist_remove_account

#define gaim_blist_get_group_size          gaim_blist_get_group_size
#define gaim_blist_get_group_online_count  gaim_blist_get_group_online_count

#define gaim_blist_load           gaim_blist_load
#define gaim_blist_schedule_save  gaim_blist_schedule_save

#define gaim_blist_request_add_buddy  gaim_blist_request_add_buddy
#define gaim_blist_request_add_chat   gaim_blist_request_add_chat
#define gaim_blist_request_add_group  gaim_blist_request_add_group

#define gaim_blist_node_set_bool    gaim_blist_node_set_bool
#define gaim_blist_node_get_bool    gaim_blist_node_get_bool
#define gaim_blist_node_set_int     gaim_blist_node_set_int
#define gaim_blist_node_get_int     gaim_blist_node_get_int
#define gaim_blist_node_set_string  gaim_blist_node_set_string
#define gaim_blist_node_get_string  gaim_blist_node_get_string

#define gaim_blist_node_remove_setting  gaim_blist_node_remove_setting

#define gaim_blist_node_set_flags  gaim_blist_node_set_flags
#define gaim_blist_node_get_flags  gaim_blist_node_get_flags

#define gaim_blist_node_get_extended_menu  gaim_blist_node_get_extended_menu

#define gaim_blist_set_ui_ops  gaim_blist_set_ui_ops
#define gaim_blist_get_ui_ops  gaim_blist_get_ui_ops

#define gaim_blist_get_handle  gaim_blist_get_handle

#define gaim_blist_init    gaim_blist_init
#define gaim_blist_uninit  gaim_blist_uninit


#define GaimBuddyIcon  GaimBuddyIcon

#define gaim_buddy_icon_new      gaim_buddy_icon_new
#define gaim_buddy_icon_destroy  gaim_buddy_icon_destroy
#define gaim_buddy_icon_ref      gaim_buddy_icon_ref
#define gaim_buddy_icon_unref    gaim_buddy_icon_unref
#define gaim_buddy_icon_update   gaim_buddy_icon_update
#define gaim_buddy_icon_cache    gaim_buddy_icon_cache
#define gaim_buddy_icon_uncache  gaim_buddy_icon_uncache

#define gaim_buddy_icon_set_account   gaim_buddy_icon_set_account
#define gaim_buddy_icon_set_username  gaim_buddy_icon_set_username
#define gaim_buddy_icon_set_data      gaim_buddy_icon_set_data
#define gaim_buddy_icon_set_path      gaim_buddy_icon_set_path

#define gaim_buddy_icon_get_account   gaim_buddy_icon_get_account
#define gaim_buddy_icon_get_username  gaim_buddy_icon_get_username
#define gaim_buddy_icon_get_data      gaim_buddy_icon_get_data
#define gaim_buddy_icon_get_path      gaim_buddy_icon_get_path
#define gaim_buddy_icon_get_type      gaim_buddy_icon_get_type

#define gaim_buddy_icons_set_for_user   gaim_buddy_icons_set_for_user
#define gaim_buddy_icons_find           gaim_buddy_icons_find
#define gaim_buddy_icons_set_caching    gaim_buddy_icons_set_caching
#define gaim_buddy_icons_is_caching     gaim_buddy_icons_is_caching
#define gaim_buddy_icons_set_cache_dir  gaim_buddy_icons_set_cache_dir
#define gaim_buddy_icons_get_cache_dir  gaim_buddy_icons_get_cache_dir
#define gaim_buddy_icons_get_full_path  gaim_buddy_icons_get_full_path
#define gaim_buddy_icons_get_handle     gaim_buddy_icons_get_handle

#define gaim_buddy_icons_init    gaim_buddy_icons_init
#define gaim_buddy_icons_uninit  gaim_buddy_icons_uninit

#define gaim_buddy_icon_get_scale_size  gaim_buddy_icon_get_scale_size

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

#define gaim_cipher_get_name          gaim_cipher_get_name
#define gaim_cipher_get_capabilities  gaim_cipher_get_capabilities
#define gaim_cipher_digest_region     gaim_cipher_digest_region

#define gaim_ciphers_find_cipher        gaim_ciphers_find_cipher
#define gaim_ciphers_register_cipher    gaim_ciphers_register_cipher
#define gaim_ciphers_unregister_cipher  gaim_ciphers_unregister_cipher
#define gaim_ciphers_get_ciphers        gaim_ciphers_get_ciphers

#define gaim_ciphers_get_handle  gaim_ciphers_get_handle
#define gaim_ciphers_init        gaim_ciphers_init
#define gaim_ciphers_uninit      gaim_ciphers_uninit

#define gaim_cipher_context_set_option  gaim_cipher_context_set_option
#define gaim_cipher_context_get_option  gaim_cipher_context_get_option

#define gaim_cipher_context_new            gaim_cipher_context_new
#define gaim_cipher_context_new_by_name    gaim_cipher_context_new_by_name
#define gaim_cipher_context_reset          gaim_cipher_context_reset
#define gaim_cipher_context_destroy        gaim_cipher_context_destroy
#define gaim_cipher_context_set_iv         gaim_cipher_context_set_iv
#define gaim_cipher_context_append         gaim_cipher_context_append
#define gaim_cipher_context_digest         gaim_cipher_context_digest
#define gaim_cipher_context_digest_to_str  gaim_cipher_context_digest_to_str
#define gaim_cipher_context_encrypt        gaim_cipher_context_encrypt
#define gaim_cipher_context_decrypt        gaim_cipher_context_decrypt
#define gaim_cipher_context_set_salt       gaim_cipher_context_set_salt
#define gaim_cipher_context_get_salt_size  gaim_cipher_context_get_salt_size
#define gaim_cipher_context_set_key        gaim_cipher_context_set_key
#define gaim_cipher_context_get_key_size   gaim_cipher_context_get_key_size
#define gaim_cipher_context_set_data       gaim_cipher_context_set_data
#define gaim_cipher_context_get_data       gaim_cipher_context_get_data

#define gaim_cipher_http_digest_calculate_session_key \
	gaim_cipher_http_digest_calculate_session_key

#define gaim_cipher_http_digest_calculate_response \
	gaim_cipher_http_digest_calculate_response

/* from circbuffer.h */

#define GaimCircBuffer  GaimCircBuffer

#define gaim_circ_buffer_new           gaim_circ_buffer_new
#define gaim_circ_buffer_destroy       gaim_circ_buffer_destroy
#define gaim_circ_buffer_append        gaim_circ_buffer_append
#define gaim_circ_buffer_get_max_read  gaim_circ_buffer_get_max_read
#define gaim_circ_buffer_mark_read     gaim_circ_buffer_mark_read

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

#define gaim_cmd_register    gaim_cmd_register
#define gaim_cmd_unregister  gaim_cmd_unregister
#define gaim_cmd_do_command  gaim_cmd_do_command
#define gaim_cmd_list        gaim_cmd_list
#define gaim_cmd_help        gaim_cmd_help

/* from connection.h */

#define GaimConnection  GaimConnection

#define GAIM_CONNECTION_HTML              GAIM_CONNECTION_HTML
#define GAIM_CONNECTION_NO_BGCOLOR        GAIM_CONNECTION_NO_BGCOLOR
#define GAIM_CONNECTION_AUTO_RESP         GAIM_CONNECTION_AUTO_RESP
#define GAIM_CONNECTION_FORMATTING_WBFO   GAIM_CONNECTION_FORMATTING_WBFO
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

#define gaim_connection_new      gaim_connection_new
#define gaim_connection_destroy  gaim_connection_destroy

#define gaim_connection_set_state         gaim_connection_set_state
#define gaim_connection_set_account       gaim_connection_set_account
#define gaim_connection_set_display_name  gaim_connection_set_display_name
#define gaim_connection_get_state         gaim_connection_get_state

#define GAIM_CONNECTION_IS_CONNECTED  GAIM_CONNECTION_IS_CONNECTED

#define gaim_connection_get_account       gaim_connection_get_account
#define gaim_connection_get_password      gaim_connection_get_password
#define gaim_connection_get_display_name  gaim_connection_get_display_name

#define gaim_connection_update_progress  gaim_connection_update_progress

#define gaim_connection_notice  gaim_connection_notice
#define gaim_connection_error   gaim_connection_error

#define gaim_connections_disconnect_all  gaim_connections_disconnect_all

#define gaim_connections_get_all         gaim_connections_get_all
#define gaim_connections_get_connecting  gaim_connections_get_connecting

#define GAIM_CONNECTION_IS_VALID  GAIM_CONNECTION_IS_VALID

#define gaim_connections_set_ui_ops  gaim_connections_set_ui_ops
#define gaim_connections_get_ui_ops  gaim_connections_get_ui_ops

#define gaim_connections_init    gaim_connections_init
#define gaim_connections_uninit  gaim_connections_uninit
#define gaim_connections_get_handle  gaim_connections_get_handle


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
#define GAIM_CONV_UPDATE_REMOVE    GAIM_CONV_UPDATE_REMOVE
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

#define gaim_conversations_set_ui_ops  gaim_conversations_set_ui_ops

#define gaim_conversation_new          gaim_conversation_new
#define gaim_conversation_destroy      gaim_conversation_destroy
#define gaim_conversation_present      gaim_conversation_present
#define gaim_conversation_get_type     gaim_conversation_get_type
#define gaim_conversation_set_ui_ops   gaim_conversation_set_ui_ops
#define gaim_conversation_get_ui_ops   gaim_conversation_get_ui_ops
#define gaim_conversation_set_account  gaim_conversation_set_account
#define gaim_conversation_get_account  gaim_conversation_get_account
#define gaim_conversation_get_gc       gaim_conversation_get_gc
#define gaim_conversation_set_title    gaim_conversation_set_title
#define gaim_conversation_get_title    gaim_conversation_get_title
#define gaim_conversation_autoset_title  gaim_conversation_autoset_title
#define gaim_conversation_set_name       gaim_conversation_set_name
#define gaim_conversation_get_name       gaim_conversation_get_name
#define gaim_conversation_set_logging    gaim_conversation_set_logging
#define gaim_conversation_is_logging     gaim_conversation_is_logging
#define gaim_conversation_close_logs     gaim_conversation_close_logs
#define gaim_conversation_get_im_data    gaim_conversation_get_im_data

#define GAIM_CONV_IM    GAIM_CONV_IM

#define gaim_conversation_get_chat_data  gaim_conversation_get_chat_data

#define GAIM_CONV_CHAT  GAIM_CONV_CHAT

#define gaim_conversation_set_data       gaim_conversation_set_data
#define gaim_conversation_get_data       gaim_conversation_get_data

#define gaim_get_conversations  gaim_get_conversations
#define gaim_get_ims            gaim_get_ims
#define gaim_get_chats          gaim_get_chats

#define gaim_find_conversation_with_account \
	gaim_find_conversation_with_account

#define gaim_conversation_write         gaim_conversation_write
#define gaim_conversation_set_features  gaim_conversation_set_features
#define gaim_conversation_get_features  gaim_conversation_get_features
#define gaim_conversation_has_focus     gaim_conversation_has_focus
#define gaim_conversation_update        gaim_conversation_update
#define gaim_conversation_foreach       gaim_conversation_foreach

#define gaim_conv_im_get_conversation  gaim_conv_im_get_conversation
#define gaim_conv_im_set_icon          gaim_conv_im_set_icon
#define gaim_conv_im_get_icon          gaim_conv_im_get_icon
#define gaim_conv_im_set_typing_state  gaim_conv_im_set_typing_state
#define gaim_conv_im_get_typing_state  gaim_conv_im_get_typing_state

#define gaim_conv_im_start_typing_timeout  gaim_conv_im_start_typing_timeout
#define gaim_conv_im_stop_typing_timeout   gaim_conv_im_stop_typing_timeout
#define gaim_conv_im_get_typing_timeout    gaim_conv_im_get_typing_timeout
#define gaim_conv_im_set_type_again        gaim_conv_im_set_type_again
#define gaim_conv_im_get_type_again        gaim_conv_im_get_type_again

#define gaim_conv_im_start_send_typed_timeout \
	gaim_conv_im_start_send_typed_timeout

#define gaim_conv_im_stop_send_typed_timeout \
	gaim_conv_im_stop_send_typed_timeout

#define gaim_conv_im_get_send_typed_timeout \
	gaim_conv_im_get_send_typed_timeout

#define gaim_conv_present_error     gaim_conv_present_error
#define gaim_conv_send_confirm      gaim_conv_send_confirm

#define gaim_conv_im_update_typing    gaim_conv_im_update_typing
#define gaim_conv_im_write            gaim_conv_im_write
#define gaim_conv_im_send             gaim_conv_im_send
#define gaim_conv_im_send_with_flags  gaim_conv_im_send_with_flags

#define gaim_conv_custom_smiley_add    gaim_conv_custom_smiley_add
#define gaim_conv_custom_smiley_write  gaim_conv_custom_smiley_write
#define gaim_conv_custom_smiley_close  gaim_conv_custom_smiley_close

#define gaim_conv_chat_get_conversation  gaim_conv_chat_get_conversation
#define gaim_conv_chat_set_users         gaim_conv_chat_set_users
#define gaim_conv_chat_get_users         gaim_conv_chat_get_users
#define gaim_conv_chat_ignore            gaim_conv_chat_ignore
#define gaim_conv_chat_unignore          gaim_conv_chat_unignore
#define gaim_conv_chat_set_ignored       gaim_conv_chat_set_ignored
#define gaim_conv_chat_get_ignored       gaim_conv_chat_get_ignored
#define gaim_conv_chat_get_ignored_user  gaim_conv_chat_get_ignored_user
#define gaim_conv_chat_is_user_ignored   gaim_conv_chat_is_user_ignored
#define gaim_conv_chat_set_topic         gaim_conv_chat_set_topic
#define gaim_conv_chat_get_topic         gaim_conv_chat_get_topic
#define gaim_conv_chat_set_id            gaim_conv_chat_set_id
#define gaim_conv_chat_get_id            gaim_conv_chat_get_id
#define gaim_conv_chat_write             gaim_conv_chat_write
#define gaim_conv_chat_send              gaim_conv_chat_send
#define gaim_conv_chat_send_with_flags   gaim_conv_chat_send_with_flags
#define gaim_conv_chat_add_user          gaim_conv_chat_add_user
#define gaim_conv_chat_add_users         gaim_conv_chat_add_users
#define gaim_conv_chat_rename_user       gaim_conv_chat_rename_user
#define gaim_conv_chat_remove_user       gaim_conv_chat_remove_user
#define gaim_conv_chat_remove_users      gaim_conv_chat_remove_users
#define gaim_conv_chat_find_user         gaim_conv_chat_find_user
#define gaim_conv_chat_user_set_flags    gaim_conv_chat_user_set_flags
#define gaim_conv_chat_user_get_flags    gaim_conv_chat_user_get_flags
#define gaim_conv_chat_clear_users       gaim_conv_chat_clear_users
#define gaim_conv_chat_set_nick          gaim_conv_chat_set_nick
#define gaim_conv_chat_get_nick          gaim_conv_chat_get_nick
#define gaim_conv_chat_left              gaim_conv_chat_left
#define gaim_conv_chat_has_left          gaim_conv_chat_has_left

#define gaim_find_chat                   gaim_find_chat

#define gaim_conv_chat_cb_new            gaim_conv_chat_cb_new
#define gaim_conv_chat_cb_find           gaim_conv_chat_cb_find
#define gaim_conv_chat_cb_get_name       gaim_conv_chat_cb_get_name
#define gaim_conv_chat_cb_destroy        gaim_conv_chat_cb_destroy

#define gaim_conversations_get_handle    gaim_conversations_get_handle
#define gaim_conversations_init          gaim_conversations_init
#define gaim_conversations_uninit        gaim_conversations_uninit

/* from core.h */

#define GaimCore  GaimCore

#define GaimCoreUiOps  GaimCoreUiOps

#define gaim_core_init  gaim_core_init
#define gaim_core_quit  gaim_core_quit

#define gaim_core_quit_cb      gaim_core_quit_cb
#define gaim_core_get_version  gaim_core_get_version
#define gaim_core_get_ui       gaim_core_get_ui
#define gaim_get_core          gaim_get_core
#define gaim_core_set_ui_ops   gaim_core_set_ui_ops
#define gaim_core_get_ui_ops   gaim_core_get_ui_ops

/* from debug.h */

#define GAIM_DEBUG_ALL      GAIM_DEBUG_ALL
#define GAIM_DEBUG_MISC     GAIM_DEBUG_MISC
#define GAIM_DEBUG_INFO     GAIM_DEBUG_INFO
#define GAIM_DEBUG_WARNING  GAIM_DEBUG_WARNING
#define GAIM_DEBUG_ERROR    GAIM_DEBUG_ERROR
#define GAIM_DEBUG_FATAL    GAIM_DEBUG_FATAL

#define GaimDebugLevel  GaimDebugLevel

#define GaimDebugUiOps  GaimDebugUiOps


#define gaim_debug          gaim_debug
#define gaim_debug_misc     gaim_debug_misc
#define gaim_debug_info     gaim_debug_info
#define gaim_debug_warning  gaim_debug_warning
#define gaim_debug_error    gaim_debug_error
#define gaim_debug_fatal    gaim_debug_fatal

#define gaim_debug_set_enabled  gaim_debug_set_enabled
#define gaim_debug_is_enabled   gaim_debug_is_enabled

#define gaim_debug_set_ui_ops  gaim_debug_set_ui_ops
#define gaim_debug_get_ui_ops  gaim_debug_get_ui_ops

#define gaim_debug_init  gaim_debug_init

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
#define gaim_desktop_item_get_type     gaim_desktop_item_get_type

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

#define gaim_desktop_item_new_from_file   gaim_desktop_item_new_from_file
#define gaim_desktop_item_get_entry_type  gaim_desktop_item_get_entry_type
#define gaim_desktop_item_get_string      gaim_desktop_item_get_string
#define gaim_desktop_item_copy            gaim_desktop_item_copy
#define gaim_desktop_item_unref           gaim_desktop_item_unref

/* from dnsquery.h */

#define GaimDnsQueryData  GaimDnsQueryData
#define GaimDnsQueryConnectFunction  GaimDnsQueryConnectFunction

#define gaim_dnsquery_a        		gaim_dnsquery_a
#define gaim_dnsquery_destroy  		gaim_dnsquery_destroy
#define gaim_dnsquery_init     		gaim_dnsquery_init
#define gaim_dnsquery_uninit   		gaim_dnsquery_uninit
#define gaim_dnsquery_set_ui_ops	gaim_dnsquery_set_ui_ops
#define gaim_dnsquery_get_host 		gaim_dnsquery_get_host
#define gaim_dnsquery_get_port 		gaim_dnsquery_get_port

/* from dnssrv.h */

#define GaimSrvResponse   GaimSrvResponse
#define GaimSrvQueryData  GaimSrvQueryData
#define GaimSrvCallback   GaimSrvCallback

#define gaim_srv_resolve  gaim_srv_resolve
#define gaim_srv_cancel   gaim_srv_cancel

/* from eventloop.h */

#define GAIM_INPUT_READ   GAIM_INPUT_READ
#define GAIM_INPUT_WRITE  GAIM_INPUT_WRITE

#define GaimInputCondition  GaimInputCondition
#define GaimInputFunction   GaimInputFunction
#define GaimEventLoopUiOps  GaimEventLoopUiOps

#define gaim_timeout_add     gaim_timeout_add
#define gaim_timeout_remove  gaim_timeout_remove
#define gaim_input_add       gaim_input_add
#define gaim_input_remove    gaim_input_remove

#define gaim_eventloop_set_ui_ops  gaim_eventloop_set_ui_ops
#define gaim_eventloop_get_ui_ops  gaim_eventloop_get_ui_ops

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

#define gaim_xfer_new                  gaim_xfer_new
#define gaim_xfer_ref                  gaim_xfer_ref
#define gaim_xfer_unref                gaim_xfer_unref
#define gaim_xfer_request              gaim_xfer_request
#define gaim_xfer_request_accepted     gaim_xfer_request_accepted
#define gaim_xfer_request_denied       gaim_xfer_request_denied
#define gaim_xfer_get_type             gaim_xfer_get_type
#define gaim_xfer_get_account          gaim_xfer_get_account
#define gaim_xfer_get_status           gaim_xfer_get_status
#define gaim_xfer_is_canceled          gaim_xfer_is_canceled
#define gaim_xfer_is_completed         gaim_xfer_is_completed
#define gaim_xfer_get_filename         gaim_xfer_get_filename
#define gaim_xfer_get_local_filename   gaim_xfer_get_local_filename
#define gaim_xfer_get_bytes_sent       gaim_xfer_get_bytes_sent
#define gaim_xfer_get_bytes_remaining  gaim_xfer_get_bytes_remaining
#define gaim_xfer_get_size             gaim_xfer_get_size
#define gaim_xfer_get_progress         gaim_xfer_get_progress
#define gaim_xfer_get_local_port       gaim_xfer_get_local_port
#define gaim_xfer_get_remote_ip        gaim_xfer_get_remote_ip
#define gaim_xfer_get_remote_port      gaim_xfer_get_remote_port
#define gaim_xfer_set_completed        gaim_xfer_set_completed
#define gaim_xfer_set_message          gaim_xfer_set_message
#define gaim_xfer_set_filename         gaim_xfer_set_filename
#define gaim_xfer_set_local_filename   gaim_xfer_set_local_filename
#define gaim_xfer_set_size             gaim_xfer_set_size
#define gaim_xfer_set_bytes_sent       gaim_xfer_set_bytes_sent
#define gaim_xfer_get_ui_ops           gaim_xfer_get_ui_ops
#define gaim_xfer_set_read_fnc         gaim_xfer_set_read_fnc
#define gaim_xfer_set_write_fnc        gaim_xfer_set_write_fnc
#define gaim_xfer_set_ack_fnc          gaim_xfer_set_ack_fnc
#define gaim_xfer_set_request_denied_fnc  gaim_xfer_set_request_denied_fnc
#define gaim_xfer_set_init_fnc         gaim_xfer_set_init_fnc
#define gaim_xfer_set_start_fnc        gaim_xfer_set_start_fnc
#define gaim_xfer_set_end_fnc          gaim_xfer_set_end_fnc
#define gaim_xfer_set_cancel_send_fnc  gaim_xfer_set_cancel_send_fnc
#define gaim_xfer_set_cancel_recv_fnc  gaim_xfer_set_cancel_recv_fnc

#define gaim_xfer_read                gaim_xfer_read
#define gaim_xfer_write               gaim_xfer_write
#define gaim_xfer_start               gaim_xfer_start
#define gaim_xfer_end                 gaim_xfer_end
#define gaim_xfer_add                 gaim_xfer_add
#define gaim_xfer_cancel_local        gaim_xfer_cancel_local
#define gaim_xfer_cancel_remote       gaim_xfer_cancel_remote
#define gaim_xfer_error               gaim_xfer_error
#define gaim_xfer_update_progress     gaim_xfer_update_progress
#define gaim_xfer_conversation_write  gaim_xfer_conversation_write

#define gaim_xfers_get_handle  gaim_xfers_get_handle
#define gaim_xfers_init        gaim_xfers_init
#define gaim_xfers_uninit      gaim_xfers_uninit
#define gaim_xfers_set_ui_ops  gaim_xfers_set_ui_ops
#define gaim_xfers_get_ui_ops  gaim_xfers_get_ui_ops

/* from gaim-client.h */

/* XXX: should this be gaim_init, or pidgin_init */
#define gaim_init  gaim_init

/* from idle.h */

#define GaimIdleUiOps  GaimIdleUiOps

#define gaim_idle_touch       gaim_idle_touch
#define gaim_idle_set         gaim_idle_set
#define gaim_idle_set_ui_ops  gaim_idle_set_ui_ops
#define gaim_idle_get_ui_ops  gaim_idle_get_ui_ops
#define gaim_idle_init        gaim_idle_init
#define gaim_idle_uninit      gaim_idle_uninit

/* from imgstore.h */

#define GaimStoredImage  GaimStoredImage

#define gaim_imgstore_add           gaim_imgstore_add
#define gaim_imgstore_get           gaim_imgstore_get
#define gaim_imgstore_get_data      gaim_imgstore_get_data
#define gaim_imgstore_get_size      gaim_imgstore_get_size
#define gaim_imgstore_get_filename  gaim_imgstore_get_filename
#define gaim_imgstore_ref           gaim_imgstore_ref
#define gaim_imgstore_unref         gaim_imgstore_unref


/* from log.h */

#define GaimLog                  GaimLog
#define GaimLogLogger            GaimLogLogger
#define GaimLogCommonLoggerData  GaimLogCommonLoggerData
#define GaimLogSet               GaimLogSet

#define GAIM_LOG_IM      GAIM_LOG_IM
#define GAIM_LOG_CHAT    GAIM_LOG_CHAT
#define GAIM_LOG_SYSTEM  GAIM_LOG_SYSTEM

#define GaimLogType  GaimLogType

#define GAIM_LOG_READ_NO_NEWLINE  GAIM_LOG_READ_NO_NEWLINE

#define GaimLogReadFlags  GaimLogReadFlags

#define GaimLogSetCallback  GaimLogSetCallback

#define gaim_log_new    gaim_log_new
#define gaim_log_free   gaim_log_free
#define gaim_log_write  gaim_log_write
#define gaim_log_read   gaim_log_read

#define gaim_log_get_logs         gaim_log_get_logs
#define gaim_log_get_log_sets     gaim_log_get_log_sets
#define gaim_log_get_system_logs  gaim_log_get_system_logs
#define gaim_log_get_size         gaim_log_get_size
#define gaim_log_get_total_size   gaim_log_get_total_size
#define gaim_log_get_log_dir      gaim_log_get_log_dir
#define gaim_log_compare          gaim_log_compare
#define gaim_log_set_compare      gaim_log_set_compare
#define gaim_log_set_free         gaim_log_set_free

#define gaim_log_common_writer       gaim_log_common_writer
#define gaim_log_common_lister       gaim_log_common_lister
#define gaim_log_common_total_sizer  gaim_log_common_total_sizer
#define gaim_log_common_sizer        gaim_log_common_sizer

#define gaim_log_logger_new     gaim_log_logger_new
#define gaim_log_logger_free    gaim_log_logger_free
#define gaim_log_logger_add     gaim_log_logger_add
#define gaim_log_logger_remove  gaim_log_logger_remove
#define gaim_log_logger_set     gaim_log_logger_set
#define gaim_log_logger_get     gaim_log_logger_get

#define gaim_log_logger_get_options  gaim_log_logger_get_options

#define gaim_log_init        gaim_log_init
#define gaim_log_get_handle  gaim_log_get_handle
#define gaim_log_uninit      gaim_log_uninit

/* from mime.h */

#define GaimMimeDocument  GaimMimeDocument
#define GaimMimePart      GaimMimePart

#define gaim_mime_document_new         gaim_mime_document_new
#define gaim_mime_document_free        gaim_mime_document_free
#define gaim_mime_document_parse       gaim_mime_document_parse
#define gaim_mime_document_parsen      gaim_mime_document_parsen
#define gaim_mime_document_write       gaim_mime_document_write
#define gaim_mime_document_get_fields  gaim_mime_document_get_fields
#define gaim_mime_document_get_field   gaim_mime_document_get_field
#define gaim_mime_document_set_field   gaim_mime_document_set_field
#define gaim_mime_document_get_parts   gaim_mime_document_get_parts

#define gaim_mime_part_new                gaim_mime_part_new
#define gaim_mime_part_get_fields         gaim_mime_part_get_fields
#define gaim_mime_part_get_field          gaim_mime_part_get_field
#define gaim_mime_part_get_field_decoded  gaim_mime_part_get_field_decoded
#define gaim_mime_part_set_field          gaim_mime_part_set_field
#define gaim_mime_part_get_data           gaim_mime_part_get_data
#define gaim_mime_part_get_data_decoded   gaim_mime_part_get_data_decoded
#define gaim_mime_part_get_length         gaim_mime_part_get_length
#define gaim_mime_part_set_data           gaim_mime_part_set_data


/* from network.h */

#define GaimNetworkListenData  GaimNetworkListenData

#define GaimNetworkListenCallback  GaimNetworkListenCallback

#define gaim_network_ip_atoi              gaim_network_ip_atoi
#define gaim_network_set_public_ip        gaim_network_set_public_ip
#define gaim_network_get_public_ip        gaim_network_get_public_ip
#define gaim_network_get_local_system_ip  gaim_network_get_local_system_ip
#define gaim_network_get_my_ip            gaim_network_get_my_ip

#define gaim_network_listen            gaim_network_listen
#define gaim_network_listen_range      gaim_network_listen_range
#define gaim_network_listen_cancel     gaim_network_listen_cancel
#define gaim_network_get_port_from_fd  gaim_network_get_port_from_fd

#define gaim_network_is_available  gaim_network_is_available

#define gaim_network_init    gaim_network_init
#define gaim_network_uninit  gaim_network_uninit

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

#define gaim_notify_searchresults                     gaim_notify_searchresults
#define gaim_notify_searchresults_free                gaim_notify_searchresults_free
#define gaim_notify_searchresults_new_rows            gaim_notify_searchresults_new_rows
#define gaim_notify_searchresults_button_add          gaim_notify_searchresults_button_add
#define gaim_notify_searchresults_button_add_labeled  gaim_notify_searchresults_button_add_labeled
#define gaim_notify_searchresults_new                 gaim_notify_searchresults_new
#define gaim_notify_searchresults_column_new          gaim_notify_searchresults_column_new
#define gaim_notify_searchresults_column_add          gaim_notify_searchresults_column_add
#define gaim_notify_searchresults_row_add             gaim_notify_searchresults_row_add
#define gaim_notify_searchresults_get_rows_count      gaim_notify_searchresults_get_rows_count
#define gaim_notify_searchresults_get_columns_count   gaim_notify_searchresults_get_columns_count
#define gaim_notify_searchresults_row_get             gaim_notify_searchresults_row_get
#define gaim_notify_searchresults_column_get_title    gaim_notify_searchresults_column_get_title

#define gaim_notify_message    gaim_notify_message
#define gaim_notify_email      gaim_notify_email
#define gaim_notify_emails     gaim_notify_emails
#define gaim_notify_formatted  gaim_notify_formatted
#define gaim_notify_userinfo   gaim_notify_userinfo

#define gaim_notify_user_info_new                    gaim_notify_user_info_new
#define gaim_notify_user_info_destroy                gaim_notify_user_info_destroy
#define gaim_notify_user_info_get_entries            gaim_notify_user_info_get_entries
#define gaim_notify_user_info_get_text_with_newline  gaim_notify_user_info_get_text_with_newline
#define gaim_notify_user_info_add_pair               gaim_notify_user_info_add_pair
#define gaim_notify_user_info_prepend_pair           gaim_notify_user_info_prepend_pair
#define gaim_notify_user_info_remove_entry           gaim_notify_user_info_remove_entry
#define gaim_notify_user_info_entry_new              gaim_notify_user_info_entry_new
#define gaim_notify_user_info_add_section_break      gaim_notify_user_info_add_section_break
#define gaim_notify_user_info_add_section_header     gaim_notify_user_info_add_section_header
#define gaim_notify_user_info_remove_last_item       gaim_notify_user_info_remove_last_item
#define gaim_notify_user_info_entry_get_label        gaim_notify_user_info_entry_get_label
#define gaim_notify_user_info_entry_set_label        gaim_notify_user_info_entry_set_label
#define gaim_notify_user_info_entry_get_value        gaim_notify_user_info_entry_get_value
#define gaim_notify_user_info_entry_set_value        gaim_notify_user_info_entry_set_value
#define gaim_notify_user_info_entry_get_type         gaim_notify_user_info_entry_get_type
#define gaim_notify_user_info_entry_set_type         gaim_notify_user_info_entry_set_type

#define gaim_notify_uri                gaim_notify_uri
#define gaim_notify_close              gaim_notify_close
#define gaim_notify_close_with_handle  gaim_notify_close_with_handle

#define gaim_notify_info     gaim_notify_info
#define gaim_notify_warning  gaim_notify_warning
#define gaim_notify_error    gaim_notify_error

#define gaim_notify_set_ui_ops  gaim_notify_set_ui_ops
#define gaim_notify_get_ui_ops  gaim_notify_get_ui_ops

#define gaim_notify_get_handle  gaim_notify_get_handle

#define gaim_notify_init    gaim_notify_init
#define gaim_notify_uninit  gaim_notify_uninit

/* from ntlm.h */

#define gaim_ntlm_gen_type1    gaim_ntlm_gen_type1
#define gaim_ntlm_parse_type2  gaim_ntlm_parse_type2
#define gaim_ntlm_gen_type3    gaim_ntlm_gen_type3

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

#define gaim_plugin_new              gaim_plugin_new
#define gaim_plugin_probe            gaim_plugin_probe
#define gaim_plugin_register         gaim_plugin_register
#define gaim_plugin_load             gaim_plugin_load
#define gaim_plugin_unload           gaim_plugin_unload
#define gaim_plugin_reload           gaim_plugin_reload
#define gaim_plugin_destroy          gaim_plugin_destroy
#define gaim_plugin_is_loaded        gaim_plugin_is_loaded
#define gaim_plugin_is_unloadable    gaim_plugin_is_unloadable
#define gaim_plugin_get_id           gaim_plugin_get_id
#define gaim_plugin_get_name         gaim_plugin_get_name
#define gaim_plugin_get_version      gaim_plugin_get_version
#define gaim_plugin_get_summary      gaim_plugin_get_summary
#define gaim_plugin_get_description  gaim_plugin_get_description
#define gaim_plugin_get_author       gaim_plugin_get_author
#define gaim_plugin_get_homepage     gaim_plugin_get_homepage

#define gaim_plugin_ipc_register        gaim_plugin_ipc_register
#define gaim_plugin_ipc_unregister      gaim_plugin_ipc_unregister
#define gaim_plugin_ipc_unregister_all  gaim_plugin_ipc_unregister_all
#define gaim_plugin_ipc_get_params      gaim_plugin_ipc_get_params
#define gaim_plugin_ipc_call            gaim_plugin_ipc_call

#define gaim_plugins_add_search_path  gaim_plugins_add_search_path
#define gaim_plugins_unload_all       gaim_plugins_unload_all
#define gaim_plugins_destroy_all      gaim_plugins_destroy_all
#define gaim_plugins_save_loaded      gaim_plugins_save_loaded
#define gaim_plugins_load_saved       gaim_plugins_load_saved
#define gaim_plugins_probe            gaim_plugins_probe
#define gaim_plugins_enabled          gaim_plugins_enabled

#define gaim_plugins_register_probe_notify_cb     gaim_plugins_register_probe_notify_cb
#define gaim_plugins_unregister_probe_notify_cb   gaim_plugins_unregister_probe_notify_cb
#define gaim_plugins_register_load_notify_cb      gaim_plugins_register_load_notify_cb
#define gaim_plugins_unregister_load_notify_cb    gaim_plugins_unregister_load_notify_cb
#define gaim_plugins_register_unload_notify_cb    gaim_plugins_register_unload_notify_cb
#define gaim_plugins_unregister_unload_notify_cb  gaim_plugins_unregister_unload_notify_cb

#define gaim_plugins_find_with_name      gaim_plugins_find_with_name
#define gaim_plugins_find_with_filename  gaim_plugins_find_with_filename
#define gaim_plugins_find_with_basename  gaim_plugins_find_with_basename
#define gaim_plugins_find_with_id        gaim_plugins_find_with_id

#define gaim_plugins_get_loaded     gaim_plugins_get_loaded
#define gaim_plugins_get_protocols  gaim_plugins_get_protocols
#define gaim_plugins_get_all        gaim_plugins_get_all

#define gaim_plugins_get_handle  gaim_plugins_get_handle
#define gaim_plugins_init        gaim_plugins_init
#define gaim_plugins_uninit      gaim_plugins_uninit

#define gaim_plugin_action_new   gaim_plugin_action_new
#define gaim_plugin_action_free  gaim_plugin_action_free

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

#define gaim_plugin_pref_frame_new        gaim_plugin_pref_frame_new
#define gaim_plugin_pref_frame_destroy    gaim_plugin_pref_frame_destroy
#define gaim_plugin_pref_frame_add        gaim_plugin_pref_frame_add
#define gaim_plugin_pref_frame_get_prefs  gaim_plugin_pref_frame_get_prefs

#define gaim_plugin_pref_new                      gaim_plugin_pref_new
#define gaim_plugin_pref_new_with_name            gaim_plugin_pref_new_with_name
#define gaim_plugin_pref_new_with_label           gaim_plugin_pref_new_with_label
#define gaim_plugin_pref_new_with_name_and_label  gaim_plugin_pref_new_with_name_and_label
#define gaim_plugin_pref_destroy                  gaim_plugin_pref_destroy
#define gaim_plugin_pref_set_name                 gaim_plugin_pref_set_name
#define gaim_plugin_pref_get_name                 gaim_plugin_pref_get_name
#define gaim_plugin_pref_set_label                gaim_plugin_pref_set_label
#define gaim_plugin_pref_get_label                gaim_plugin_pref_get_label
#define gaim_plugin_pref_set_bounds               gaim_plugin_pref_set_bounds
#define gaim_plugin_pref_get_bounds               gaim_plugin_pref_get_bounds
#define gaim_plugin_pref_set_type                 gaim_plugin_pref_set_type
#define gaim_plugin_pref_get_type                 gaim_plugin_pref_get_type
#define gaim_plugin_pref_add_choice               gaim_plugin_pref_add_choice
#define gaim_plugin_pref_get_choices              gaim_plugin_pref_get_choices
#define gaim_plugin_pref_set_max_length           gaim_plugin_pref_set_max_length
#define gaim_plugin_pref_get_max_length           gaim_plugin_pref_get_max_length
#define gaim_plugin_pref_set_masked               gaim_plugin_pref_set_masked
#define gaim_plugin_pref_get_masked               gaim_plugin_pref_get_masked
#define gaim_plugin_pref_set_format_type          gaim_plugin_pref_set_format_type
#define gaim_plugin_pref_get_format_type          gaim_plugin_pref_get_format_type

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

#define gaim_pounce_new                     gaim_pounce_new
#define gaim_pounce_destroy                 gaim_pounce_destroy
#define gaim_pounce_destroy_all_by_account  gaim_pounce_destroy_all_by_account
#define gaim_pounce_set_events              gaim_pounce_set_events
#define gaim_pounce_set_options             gaim_pounce_set_options
#define gaim_pounce_set_pouncer             gaim_pounce_set_pouncer
#define gaim_pounce_set_pouncee             gaim_pounce_set_pouncee
#define gaim_pounce_set_save                gaim_pounce_set_save
#define gaim_pounce_action_register         gaim_pounce_action_register
#define gaim_pounce_action_set_enabled      gaim_pounce_action_set_enabled
#define gaim_pounce_action_set_attribute    gaim_pounce_action_set_attribute
#define gaim_pounce_set_data                gaim_pounce_set_data
#define gaim_pounce_get_events              gaim_pounce_get_events
#define gaim_pounce_get_options             gaim_pounce_get_options
#define gaim_pounce_get_pouncer             gaim_pounce_get_pouncer
#define gaim_pounce_get_pouncee             gaim_pounce_get_pouncee
#define gaim_pounce_get_save                gaim_pounce_get_save
#define gaim_pounce_action_is_enabled       gaim_pounce_action_is_enabled
#define gaim_pounce_action_get_attribute    gaim_pounce_action_get_attribute
#define gaim_pounce_get_data                gaim_pounce_get_data
#define gaim_pounce_execute                 gaim_pounce_execute

#define gaim_find_pounce                 gaim_find_pounce
#define gaim_pounces_load                gaim_pounces_load
#define gaim_pounces_register_handler    gaim_pounces_register_handler
#define gaim_pounces_unregister_handler  gaim_pounces_unregister_handler
#define gaim_pounces_get_all             gaim_pounces_get_all
#define gaim_pounces_get_handle          gaim_pounces_get_handle
#define gaim_pounces_init                gaim_pounces_init
#define gaim_pounces_uninit              gaim_pounces_uninit

/* from prefs.h */


#define GAIM_PREF_NONE         GAIM_PREF_NONE
#define GAIM_PREF_BOOLEAN      GAIM_PREF_BOOLEAN
#define GAIM_PREF_INT          GAIM_PREF_INT
#define GAIM_PREF_STRING       GAIM_PREF_STRING
#define GAIM_PREF_STRING_LIST  GAIM_PREF_STRING_LIST
#define GAIM_PREF_PATH         GAIM_PREF_PATH
#define GAIM_PREF_PATH_LIST    GAIM_PREF_PATH_LIST
#define GaimPrefType  GaimPrefType

#define GaimPrefCallback  GaimPrefCallback

#define gaim_prefs_get_handle             gaim_prefs_get_handle
#define gaim_prefs_init                   gaim_prefs_init
#define gaim_prefs_uninit                 gaim_prefs_uninit
#define gaim_prefs_add_none               gaim_prefs_add_none
#define gaim_prefs_add_bool               gaim_prefs_add_bool
#define gaim_prefs_add_int                gaim_prefs_add_int
#define gaim_prefs_add_string             gaim_prefs_add_string
#define gaim_prefs_add_string_list        gaim_prefs_add_string_list
#define gaim_prefs_add_path               gaim_prefs_add_path
#define gaim_prefs_add_path_list          gaim_prefs_add_path_list
#define gaim_prefs_remove                 gaim_prefs_remove
#define gaim_prefs_rename                 gaim_prefs_rename
#define gaim_prefs_rename_boolean_toggle  gaim_prefs_rename_boolean_toggle
#define gaim_prefs_destroy                gaim_prefs_destroy
#define gaim_prefs_set_generic            gaim_prefs_set_generic
#define gaim_prefs_set_bool               gaim_prefs_set_bool
#define gaim_prefs_set_int                gaim_prefs_set_int
#define gaim_prefs_set_string             gaim_prefs_set_string
#define gaim_prefs_set_string_list        gaim_prefs_set_string_list
#define gaim_prefs_set_path               gaim_prefs_set_path
#define gaim_prefs_set_path_list          gaim_prefs_set_path_list
#define gaim_prefs_exists                 gaim_prefs_exists
#define gaim_prefs_get_type               gaim_prefs_get_type
#define gaim_prefs_get_bool               gaim_prefs_get_bool
#define gaim_prefs_get_int                gaim_prefs_get_int
#define gaim_prefs_get_string             gaim_prefs_get_string
#define gaim_prefs_get_string_list        gaim_prefs_get_string_list
#define gaim_prefs_get_path               gaim_prefs_get_path
#define gaim_prefs_get_path_list          gaim_prefs_get_path_list
#define gaim_prefs_connect_callback       gaim_prefs_connect_callback
#define gaim_prefs_disconnect_callback    gaim_prefs_disconnect_callback
#define gaim_prefs_disconnect_by_handle   gaim_prefs_disconnect_by_handle
#define gaim_prefs_trigger_callback       gaim_prefs_trigger_callback
#define gaim_prefs_load                   gaim_prefs_load
#define gaim_prefs_update_old             gaim_prefs_update_old

/* from privacy.h */

#define GAIM_PRIVACY_ALLOW_ALL        GAIM_PRIVACY_ALLOW_ALL
#define GAIM_PRIVACY_DENY_ALL         GAIM_PRIVACY_DENY_ALL
#define GAIM_PRIVACY_ALLOW_USERS      GAIM_PRIVACY_ALLOW_USERS
#define GAIM_PRIVACY_DENY_USERS       GAIM_PRIVACY_DENY_USERS
#define GAIM_PRIVACY_ALLOW_BUDDYLIST  GAIM_PRIVACY_ALLOW_BUDDYLIST
#define GaimPrivacyType  GaimPrivacyType

#define GaimPrivacyUiOps  GaimPrivacyUiOps

#define gaim_privacy_permit_add     gaim_privacy_permit_add
#define gaim_privacy_permit_remove  gaim_privacy_permit_remove
#define gaim_privacy_deny_add       gaim_privacy_deny_add
#define gaim_privacy_deny_remove    gaim_privacy_deny_remove
#define gaim_privacy_allow          gaim_privacy_allow
#define gaim_privacy_deny           gaim_privacy_deny
#define gaim_privacy_check          gaim_privacy_check
#define gaim_privacy_set_ui_ops     gaim_privacy_set_ui_ops
#define gaim_privacy_get_ui_ops     gaim_privacy_get_ui_ops
#define gaim_privacy_init           gaim_privacy_init

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

#define gaim_proxy_info_new           gaim_proxy_info_new
#define gaim_proxy_info_destroy       gaim_proxy_info_destroy
#define gaim_proxy_info_set_type      gaim_proxy_info_set_type
#define gaim_proxy_info_set_host      gaim_proxy_info_set_host
#define gaim_proxy_info_set_port      gaim_proxy_info_set_port
#define gaim_proxy_info_set_username  gaim_proxy_info_set_username
#define gaim_proxy_info_set_password  gaim_proxy_info_set_password
#define gaim_proxy_info_get_type      gaim_proxy_info_get_type
#define gaim_proxy_info_get_host      gaim_proxy_info_get_host
#define gaim_proxy_info_get_port      gaim_proxy_info_get_port
#define gaim_proxy_info_get_username  gaim_proxy_info_get_username
#define gaim_proxy_info_get_password  gaim_proxy_info_get_password

#define gaim_global_proxy_get_info    gaim_global_proxy_get_info
#define gaim_proxy_get_handle         gaim_proxy_get_handle
#define gaim_proxy_init               gaim_proxy_init
#define gaim_proxy_uninit             gaim_proxy_uninit
#define gaim_proxy_get_setup          gaim_proxy_get_setup

#define gaim_proxy_connect                     gaim_proxy_connect
#define gaim_proxy_connect_socks5              gaim_proxy_connect_socks5
#define gaim_proxy_connect_cancel              gaim_proxy_connect_cancel
#define gaim_proxy_connect_cancel_with_handle  gaim_proxy_connect_cancel_with_handle

/* from prpl.h */

#define GaimPluginProtocolInfo  GaimPluginProtocolInfo

#define GAIM_ICON_SCALE_DISPLAY  GAIM_ICON_SCALE_DISPLAY
#define GAIM_ICON_SCALE_SEND     GAIM_ICON_SCALE_SEND
#define GaimIconScaleRules  GaimIconScaleRules

#define GaimBuddyIconSpec  GaimBuddyIconSpec

#define GaimProtocolOptions  GaimProtocolOptions

#define GAIM_IS_PROTOCOL_PLUGIN  GAIM_IS_PROTOCOL_PLUGIN

#define GAIM_PLUGIN_PROTOCOL_INFO  GAIM_PLUGIN_PROTOCOL_INFO

#define gaim_prpl_got_account_idle        gaim_prpl_got_account_idle
#define gaim_prpl_got_account_login_time  gaim_prpl_got_account_login_time
#define gaim_prpl_got_account_status      gaim_prpl_got_account_status
#define gaim_prpl_got_user_idle           gaim_prpl_got_user_idle
#define gaim_prpl_got_user_login_time     gaim_prpl_got_user_login_time
#define gaim_prpl_got_user_status         gaim_prpl_got_user_status
#define gaim_prpl_change_account_status   gaim_prpl_change_account_status
#define gaim_prpl_get_statuses            gaim_prpl_get_statuses

#define gaim_find_prpl  gaim_find_prpl

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

#define gaim_request_fields_new                  gaim_request_fields_new
#define gaim_request_fields_destroy              gaim_request_fields_destroy
#define gaim_request_fields_add_group            gaim_request_fields_add_group
#define gaim_request_fields_get_groups           gaim_request_fields_get_groups
#define gaim_request_fields_exists               gaim_request_fields_exists
#define gaim_request_fields_get_required         gaim_request_fields_get_required
#define gaim_request_fields_is_field_required    gaim_request_fields_is_field_required
#define gaim_request_fields_all_required_filled  gaim_request_fields_all_required_filled
#define gaim_request_fields_get_field            gaim_request_fields_get_field
#define gaim_request_fields_get_string           gaim_request_fields_get_string
#define gaim_request_fields_get_integer          gaim_request_fields_get_integer
#define gaim_request_fields_get_bool             gaim_request_fields_get_bool
#define gaim_request_fields_get_choice           gaim_request_fields_get_choice
#define gaim_request_fields_get_account          gaim_request_fields_get_account

#define gaim_request_field_group_new         gaim_request_field_group_new
#define gaim_request_field_group_destroy     gaim_request_field_group_destroy
#define gaim_request_field_group_add_field   gaim_request_field_group_add_field
#define gaim_request_field_group_get_title   gaim_request_field_group_get_title
#define gaim_request_field_group_get_fields  gaim_request_field_group_get_fields

#define gaim_request_field_new            gaim_request_field_new
#define gaim_request_field_destroy        gaim_request_field_destroy
#define gaim_request_field_set_label      gaim_request_field_set_label
#define gaim_request_field_set_visible    gaim_request_field_set_visible
#define gaim_request_field_set_type_hint  gaim_request_field_set_type_hint
#define gaim_request_field_set_required   gaim_request_field_set_required
#define gaim_request_field_get_type       gaim_request_field_get_type
#define gaim_request_field_get_id         gaim_request_field_get_id
#define gaim_request_field_get_label      gaim_request_field_get_label
#define gaim_request_field_is_visible     gaim_request_field_is_visible
#define gaim_request_field_get_type_hint  gaim_request_field_get_type_hint
#define gaim_request_field_is_required    gaim_request_field_is_required

#define gaim_request_field_string_new           gaim_request_field_string_new
#define gaim_request_field_string_set_default_value \
	gaim_request_field_string_set_default_value
#define gaim_request_field_string_set_value     gaim_request_field_string_set_value
#define gaim_request_field_string_set_masked    gaim_request_field_string_set_masked
#define gaim_request_field_string_set_editable  gaim_request_field_string_set_editable
#define gaim_request_field_string_get_default_value \
	gaim_request_field_string_get_default_value
#define gaim_request_field_string_get_value     gaim_request_field_string_get_value
#define gaim_request_field_string_is_multiline  gaim_request_field_string_is_multiline
#define gaim_request_field_string_is_masked     gaim_request_field_string_is_masked
#define gaim_request_field_string_is_editable   gaim_request_field_string_is_editable

#define gaim_request_field_int_new        gaim_request_field_int_new
#define gaim_request_field_int_set_default_value \
	gaim_request_field_int_set_default_value
#define gaim_request_field_int_set_value  gaim_request_field_int_set_value
#define gaim_request_field_int_get_default_value \
	gaim_request_field_int_get_default_value
#define gaim_request_field_int_get_value  gaim_request_field_int_get_value

#define gaim_request_field_bool_new        gaim_request_field_bool_new
#define gaim_request_field_bool_set_default_value \
	gaim_request_field_book_set_default_value
#define gaim_request_field_bool_set_value  gaim_request_field_bool_set_value
#define gaim_request_field_bool_get_default_value \
	gaim_request_field_bool_get_default_value
#define gaim_request_field_bool_get_value  gaim_request_field_bool_get_value

#define gaim_request_field_choice_new         gaim_request_field_choice_new
#define gaim_request_field_choice_add         gaim_request_field_choice_add
#define gaim_request_field_choice_set_default_value \
	gaim_request_field_choice_set_default_value
#define gaim_request_field_choice_set_value   gaim_request_field_choice_set_value
#define gaim_request_field_choice_get_default_value \
	gaim_request_field_choice_get_default_value
#define gaim_request_field_choice_get_value   gaim_request_field_choice_get_value
#define gaim_request_field_choice_get_labels  gaim_request_field_choice_get_labels

#define gaim_request_field_list_new               gaim_request_field_list_new
#define gaim_request_field_list_set_multi_select  gaim_request_field_list_set_multi_select
#define gaim_request_field_list_get_multi_select  gaim_request_field_list_get_multi_select
#define gaim_request_field_list_get_data          gaim_request_field_list_get_data
#define gaim_request_field_list_add               gaim_request_field_list_add
#define gaim_request_field_list_add_selected      gaim_request_field_list_add_selected
#define gaim_request_field_list_clear_selected    gaim_request_field_list_clear_selected
#define gaim_request_field_list_set_selected      gaim_request_field_list_set_selected
#define gaim_request_field_list_is_selected       gaim_request_field_list_is_selected
#define gaim_request_field_list_get_selected      gaim_request_field_list_get_selected
#define gaim_request_field_list_get_items         gaim_request_field_list_get_items

#define gaim_request_field_label_new  gaim_request_field_label_new

#define gaim_request_field_image_new          gaim_request_field_image_new
#define gaim_request_field_image_set_scale    gaim_request_field_image_set_scale
#define gaim_request_field_image_get_buffer   gaim_request_field_image_get_buffer
#define gaim_request_field_image_get_size     gaim_request_field_image_get_size
#define gaim_request_field_image_get_scale_x  gaim_request_field_image_get_scale_x
#define gaim_request_field_image_get_scale_y  gaim_request_field_image_get_scale_y

#define gaim_request_field_account_new                gaim_request_field_account_new
#define gaim_request_field_account_set_default_value  gaim_request_field_account_set_default_value
#define gaim_request_field_account_set_value          gaim_request_field_account_set_value
#define gaim_request_field_account_set_show_all       gaim_request_field_account_set_show_all
#define gaim_request_field_account_set_filter         gaim_request_field_account_set_filter
#define gaim_request_field_account_get_default_value  gaim_request_field_account_get_default_value
#define gaim_request_field_account_get_value          gaim_request_field_account_get_value
#define gaim_request_field_account_get_show_all       gaim_request_field_account_get_show_all
#define gaim_request_field_account_get_filter         gaim_request_field_account_get_filter

#define gaim_request_input              gaim_request_input
#define gaim_request_choice             gaim_request_choice
#define gaim_request_choice_varg        gaim_request_choice_varg
#define gaim_request_action             gaim_request_action
#define gaim_request_action_varg        gaim_request_action_varg
#define gaim_request_fields             gaim_request_fields
#define gaim_request_close              gaim_request_close
#define gaim_request_close_with_handle  gaim_request_close_with_handle

#define gaim_request_yes_no         gaim_request_yes_no
#define gaim_request_ok_cancel      gaim_request_ok_cancel
#define gaim_request_accept_cancel  gaim_request_accept_cancel

#define gaim_request_file    gaim_request_file
#define gaim_request_folder  gaim_request_folder

#define gaim_request_set_ui_ops  gaim_request_set_ui_ops
#define gaim_request_get_ui_ops  gaim_request_get_ui_ops

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

#define gaim_roomlist_show_with_account  gaim_roomlist_show_with_account
#define gaim_roomlist_new                gaim_roomlist_new
#define gaim_roomlist_ref                gaim_roomlist_ref
#define gaim_roomlist_unref              gaim_roomlist_unref
#define gaim_roomlist_set_fields         gaim_roomlist_set_fields
#define gaim_roomlist_set_in_progress    gaim_roomlist_set_in_progress
#define gaim_roomlist_get_in_progress    gaim_roomlist_get_in_progress
#define gaim_roomlist_room_add           gaim_roomlist_room_add

#define gaim_roomlist_get_list         gaim_roomlist_get_list
#define gaim_roomlist_cancel_get_list  gaim_roomlist_cancel_get_list
#define gaim_roomlist_expand_category  gaim_roomlist_expand_category

#define gaim_roomlist_room_new        gaim_roomlist_room_new
#define gaim_roomlist_room_add_field  gaim_roomlist_room_add_field
#define gaim_roomlist_room_join       gaim_roomlist_room_join
#define gaim_roomlist_field_new       gaim_roomlist_field_new

#define gaim_roomlist_set_ui_ops  gaim_roomlist_set_ui_ops
#define gaim_roomlist_get_ui_ops  gaim_roomlist_get_ui_ops

/* from savedstatuses.h */

#define GaimSavedStatus     GaimSavedStatus
#define GaimSavedStatusSub  GaimSavedStatusSub

#define gaim_savedstatus_new              gaim_savedstatus_new
#define gaim_savedstatus_set_title        gaim_savedstatus_set_title
#define gaim_savedstatus_set_type         gaim_savedstatus_set_type
#define gaim_savedstatus_set_message      gaim_savedstatus_set_message
#define gaim_savedstatus_set_substatus    gaim_savedstatus_set_substatus
#define gaim_savedstatus_unset_substatus  gaim_savedstatus_unset_substatus
#define gaim_savedstatus_delete           gaim_savedstatus_delete

#define gaim_savedstatuses_get_all              gaim_savedstatuses_get_all
#define gaim_savedstatuses_get_popular          gaim_savedstatuses_get_popular
#define gaim_savedstatus_get_current            gaim_savedstatus_get_current
#define gaim_savedstatus_get_default            gaim_savedstatus_get_default
#define gaim_savedstatus_get_idleaway           gaim_savedstatus_get_idleaway
#define gaim_savedstatus_is_idleaway            gaim_savedstatus_is_idleaway
#define gaim_savedstatus_set_idleaway           gaim_savedstatus_set_idleaway
#define gaim_savedstatus_get_startup            gaim_savedstatus_get_startup
#define gaim_savedstatus_find                   gaim_savedstatus_find
#define gaim_savedstatus_find_by_creation_time  gaim_savedstatus_find_by_creation_time
#define gaim_savedstatus_find_transient_by_type_and_message \
	gaim_savedstatus_find_transient_by_type_and_message

#define gaim_savedstatus_is_transient           gaim_savedstatus_is_transient
#define gaim_savedstatus_get_title              gaim_savedstatus_get_title
#define gaim_savedstatus_get_type               gaim_savedstatus_get_type
#define gaim_savedstatus_get_message            gaim_savedstatus_get_message
#define gaim_savedstatus_get_creation_time      gaim_savedstatus_get_creation_time
#define gaim_savedstatus_has_substatuses        gaim_savedstatus_has_substatuses
#define gaim_savedstatus_get_substatus          gaim_savedstatus_get_substatus
#define gaim_savedstatus_substatus_get_type     gaim_savedstatus_substatus_get_type
#define gaim_savedstatus_substatus_get_message  gaim_savedstatus_substatus_get_message
#define gaim_savedstatus_activate               gaim_savedstatus_activate
#define gaim_savedstatus_activate_for_account   gaim_savedstatus_activate_for_account

#define gaim_savedstatuses_get_handle  gaim_savedstatuses_get_handle
#define gaim_savedstatuses_init        gaim_savedstatuses_init
#define gaim_savedstatuses_uninit      gaim_savedstatuses_uninit

/* from signals.h */

#define GAIM_CALLBACK  GAIM_CALLBACK

#define GaimCallback           GaimCallback
#define GaimSignalMarshalFunc  GaimSignalMarshalFunc

#define GAIM_SIGNAL_PRIORITY_DEFAULT  GAIM_SIGNAL_PRIORITY_DEFAULT
#define GAIM_SIGNAL_PRIORITY_HIGHEST  GAIM_SIGNAL_PRIORITY_HIGHEST
#define GAIM_SIGNAL_PRIORITY_LOWEST   GAIM_SIGNAL_PRIORITY_LOWEST

#define gaim_signal_register    gaim_signal_register
#define gaim_signal_unregister  gaim_signal_unregister

#define gaim_signals_unregister_by_instance  gaim_signals_unregister_by_instance

#define gaim_signal_get_values              gaim_signal_get_values
#define gaim_signal_connect_priority        gaim_signal_connect_priority
#define gaim_signal_connect                 gaim_signal_connect
#define gaim_signal_connect_priority_vargs  gaim_signal_connect_priority_vargs
#define gaim_signal_connect_vargs           gaim_signal_connect_vargs
#define gaim_signal_disconnect              gaim_signal_disconnect

#define gaim_signals_disconnect_by_handle  gaim_signals_disconnect_by_handle

#define gaim_signal_emit                 gaim_signal_emit
#define gaim_signal_emit_vargs           gaim_signal_emit_vargs
#define gaim_signal_emit_return_1        gaim_signal_emit_vargs
#define gaim_signal_emit_vargs_return_1  gaim_signal_emit_vargs_return_1

#define gaim_signals_init    gaim_signals_init
#define gaim_signals_uninit  gaim_signals_uninit

#define gaim_marshal_VOID \
	gaim_marshal_VOID
#define gaim_marshal_VOID__INT \
	gaim_marshal_VOID__INT
#define gaim_marshal_VOID__INT_INT \
	gaim_marshal_VOID_INT_INT
#define gaim_marshal_VOID__POINTER \
	gaim_marshal_VOID__POINTER
#define gaim_marshal_VOID__POINTER_UINT \
	gaim_marshal_VOID__POINTER_UINT
#define gaim_marshal_VOID__POINTER_INT_INT \
	gaim_marshal_VOID__POINTER_INT_INT
#define gaim_marshal_VOID__POINTER_POINTER \
	gaim_marshal_VOID__POINTER_POINTER
#define gaim_marshal_VOID__POINTER_POINTER_UINT \
	gaim_marshal_VOID__POINTER_POINTER_UINT
#define gaim_marshal_VOID__POINTER_POINTER_UINT_UINT \
	gaim_marshal_VOID__POINTER_POINTER_UINT_UINT
#define gaim_marshal_VOID__POINTER_POINTER_POINTER \
	gaim_marshal_VOID__POINTER_POINTER_POINTER
#define gaim_marshal_VOID__POINTER_POINTER_POINTER_POINTER \
	gaim_marshal_VOID__POINTER_POINTER_POINTER_POINTER
#define gaim_marshal_VOID__POINTER_POINTER_POINTER_POINTER_POINTER \
	gaim_marshal_VOID__POINTER_POINTER_POINTER_POINTER_POINTER
#define gaim_marshal_VOID__POINTER_POINTER_POINTER_UINT \
	gaim_marshal_VOID__POINTER_POINTER_POINTER_UINT
#define gaim_marshal_VOID__POINTER_POINTER_POINTER_POINTER_UINT \
	gaim_marshal_VOID__POINTER_POINTER_POINTER_POINTER_UINT
#define gaim_marshal_VOID__POINTER_POINTER_POINTER_UINT_UINT \
	gaim_marshal_VOID__POINTER_POINTER_POINTER_UINT_UINT

#define gaim_marshal_INT__INT \
	gaim_marshal_INT__INT
#define gaim_marshal_INT__INT_INT \
	gaim_marshal_INT__INT_INT
#define gaim_marshal_INT__POINTER_POINTER_POINTER_POINTER_POINTER \
	gaim_marshal_INT__POINTER_POINTER_POINTER_POINTER_POINTER

#define gaim_marshal_BOOLEAN__POINTER \
	gaim_marshal_BOOLEAN__POINTER
#define gaim_marshal_BOOLEAN__POINTER_POINTER \
	gaim_marshal_BOOLEAN__POINTER_POINTER
#define gaim_marshal_BOOLEAN__POINTER_POINTER_POINTER \
	gaim_marshal_BOOLEAN__POINTER_POINTER_POINTER
#define gaim_marshal_BOOLEAN__POINTER_POINTER_UINT \
	gaim_marshal_BOOLEAN__POINTER_POINTER_UINT
#define gaim_marshal_BOOLEAN__POINTER_POINTER_POINTER_UINT \
	gaim_marshal_BOOLEAN__POINTER_POINTER_POINTER_UINT
#define gaim_marshal_BOOLEAN__POINTER_POINTER_POINTER_POINTER \
	gaim_marshal_BOOLEAN__POINTER_POINTER_POINTER_POINTER
#define gaim_marshal_BOOLEAN__POINTER_POINTER_POINTER_POINTER_POINTER \
	gaim_marshal_BOOLEAN__POINTER_POINTER_POINTER_POINTER_POINTER

#define gaim_marshal_BOOLEAN__INT_POINTER \
	gaim_marshal_BOOLEAN__INT_POINTER

#define gaim_marshal_POINTER__POINTER_INT \
	gaim_marshal_POINTER__POINTER_INT
#define gaim_marshal_POINTER__POINTER_INT64 \
	gaim_marshal_POINTER__POINTER_INT64
#define gaim_marshal_POINTER__POINTER_INT_BOOLEAN \
	gaim_marshal_POINTER__POINTER_INT_BOOLEAN
#define gaim_marshal_POINTER__POINTER_INT64_BOOLEAN \
	gaim_marshal_POINTER__POINTER_INT64_BOOLEAN
#define gaim_marshal_POINTER__POINTER_POINTER \
	gaim_marshal_POINTER__POINTER_POINTER

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

#define gaim_sound_play_file   gaim_sound_play_file
#define gaim_sound_play_event  gaim_sound_play_event
#define gaim_sound_set_ui_ops  gaim_sound_set_ui_ops
#define gaim_sound_get_ui_ops  gaim_sound_get_ui_ops
#define gaim_sound_init        gaim_sound_init
#define gaim_sound_uninit      gaim_sound_uninit

#define gaim_sounds_get_handle  gaim_sounds_get_handle

/* from sslconn.h */

#define GAIM_SSL_DEFAULT_PORT  GAIM_SSL_DEFAULT_PORT

#define GAIM_SSL_HANDSHAKE_FAILED  GAIM_SSL_HANDSHAKE_FAILED
#define GAIM_SSL_CONNECT_FAILED    GAIM_SSL_CONNECT_FAILED
#define GaimSslErrorType  GaimSslErrorType

#define GaimSslConnection  GaimSslConnection

#define GaimSslInputFunction  GaimSslInputFunction
#define GaimSslErrorFunction  GaimSslErrorFunction

#define GaimSslOps  GaimSslOps

#define gaim_ssl_is_supported  gaim_ssl_is_supported
#define gaim_ssl_connect       gaim_ssl_connect
#define gaim_ssl_connect_fd    gaim_ssl_connect_fd
#define gaim_ssl_input_add     gaim_ssl_input_add
#define gaim_ssl_close         gaim_ssl_close
#define gaim_ssl_read          gaim_ssl_read
#define gaim_ssl_write         gaim_ssl_write

#define gaim_ssl_set_ops  gaim_ssl_set_ops
#define gaim_ssl_get_ops  gaim_ssl_get_ops
#define gaim_ssl_init     gaim_ssl_init
#define gaim_ssl_uninit   gaim_ssl_uninit

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

#define gaim_primitive_get_id_from_type    gaim_primitive_get_id_from_type
#define gaim_primitive_get_name_from_type  gaim_primitive_get_name_from_type
#define gaim_primitive_get_type_from_id    gaim_primitive_get_type_from_id

#define gaim_status_type_new_full          gaim_status_type_new_full
#define gaim_status_type_new               gaim_status_type_new
#define gaim_status_type_new_with_attrs    gaim_status_type_new_with_attrs
#define gaim_status_type_destroy           gaim_status_type_destroy
#define gaim_status_type_set_primary_attr  gaim_status_type_set_primary_attr
#define gaim_status_type_add_attr          gaim_status_type_add_attr
#define gaim_status_type_add_attrs         gaim_status_type_add_attrs
#define gaim_status_type_add_attrs_vargs   gaim_status_type_add_attrs_vargs
#define gaim_status_type_get_primitive     gaim_status_type_get_primitive
#define gaim_status_type_get_id            gaim_status_type_get_id
#define gaim_status_type_get_name          gaim_status_type_get_name
#define gaim_status_type_is_saveable       gaim_status_type_is_saveable
#define gaim_status_type_is_user_settable  gaim_status_type_is_user_settable
#define gaim_status_type_is_independent    gaim_status_type_is_independent
#define gaim_status_type_is_exclusive      gaim_status_type_is_exclusive
#define gaim_status_type_is_available      gaim_status_type_is_available
#define gaim_status_type_get_primary_attr  gaim_status_type_get_primary_attr
#define gaim_status_type_get_attr          gaim_status_type_get_attr
#define gaim_status_type_get_attrs         gaim_status_type_get_attrs
#define gaim_status_type_find_with_id      gaim_status_type_find_with_id

#define gaim_status_attr_new        gaim_status_attr_new
#define gaim_status_attr_destroy    gaim_status_attr_destroy
#define gaim_status_attr_get_id     gaim_status_attr_get_id
#define gaim_status_attr_get_name   gaim_status_attr_get_name
#define gaim_status_attr_get_value  gaim_status_attr_get_value

#define gaim_status_new                         gaim_status_new
#define gaim_status_destroy                     gaim_status_destroy
#define gaim_status_set_active                  gaim_status_set_active
#define gaim_status_set_active_with_attrs       gaim_status_set_active_with_attrs
#define gaim_status_set_active_with_attrs_list  gaim_status_set_active_with_attrs_list
#define gaim_status_set_attr_boolean            gaim_status_set_attr_boolean
#define gaim_status_set_attr_int                gaim_status_set_attr_int
#define gaim_status_set_attr_string             gaim_status_set_attr_string
#define gaim_status_get_type                    gaim_status_get_type
#define gaim_status_get_presence                gaim_status_get_presence
#define gaim_status_get_id                      gaim_status_get_id
#define gaim_status_get_name                    gaim_status_get_name
#define gaim_status_is_independent              gaim_status_is_independent
#define gaim_status_is_exclusive                gaim_status_is_exclusive
#define gaim_status_is_available                gaim_status_is_available
#define gaim_status_is_active                   gaim_status_is_active
#define gaim_status_is_online                   gaim_status_is_online
#define gaim_status_get_attr_value              gaim_status_get_attr_value
#define gaim_status_get_attr_boolean            gaim_status_get_attr_boolean
#define gaim_status_get_attr_int                gaim_status_get_attr_int
#define gaim_status_get_attr_string             gaim_status_get_attr_string
#define gaim_status_compare                     gaim_status_compare

#define gaim_presence_new                gaim_presence_new
#define gaim_presence_new_for_account    gaim_presence_new_for_account
#define gaim_presence_new_for_conv       gaim_presence_new_for_conv
#define gaim_presence_new_for_buddy      gaim_presence_new_for_buddy
#define gaim_presence_destroy            gaim_presence_destroy
#define gaim_presence_remove_buddy       gaim_presence_remove_buddy
#define gaim_presence_add_status         gaim_presence_add_status
#define gaim_presence_add_list           gaim_presence_add_list
#define gaim_presence_set_status_active  gaim_presence_set_status_active
#define gaim_presence_switch_status      gaim_presence_switch_status
#define gaim_presence_set_idle           gaim_presence_set_idle
#define gaim_presence_set_login_time     gaim_presence_set_login_time
#define gaim_presence_get_context        gaim_presence_get_context
#define gaim_presence_get_account        gaim_presence_get_account
#define gaim_presence_get_conversation   gaim_presence_get_conversation
#define gaim_presence_get_chat_user      gaim_presence_get_chat_user
#define gaim_presence_get_buddies        gaim_presence_get_buddies
#define gaim_presence_get_statuses       gaim_presence_get_statuses
#define gaim_presence_get_status         gaim_presence_get_status
#define gaim_presence_get_active_status  gaim_presence_get_active_status
#define gaim_presence_is_available       gaim_presence_is_available
#define gaim_presence_is_online          gaim_presence_is_online
#define gaim_presence_is_status_active   gaim_presence_is_status_active
#define gaim_presence_is_status_primitive_active \
	gaim_presence_is_status_primitive_active
#define gaim_presence_is_idle            gaim_presence_is_idle
#define gaim_presence_get_idle_time      gaim_presence_get_idle_time
#define gaim_presence_get_login_time     gaim_presence_get_login_time
#define gaim_presence_compare            gaim_presence_compare

#define gaim_status_get_handle  gaim_status_get_handle
#define gaim_status_init        gaim_status_init
#define gaim_status_uninit      gaim_status_uninit

/* from stringref.h */

#define GaimStringref  GaimStringref

#define gaim_stringref_new        gaim_stringref_new
#define gaim_stringref_new_noref  gaim_stringref_new_noref
#define gaim_stringref_printf     gaim_stringref_printf
#define gaim_stringref_ref        gaim_stringref_ref
#define gaim_stringref_unref      gaim_stringref_unref
#define gaim_stringref_value      gaim_stringref_value
#define gaim_stringref_cmp        gaim_stringref_cmp
#define gaim_stringref_len        gaim_stringref_len

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

#define gaim_stun_discover  gaim_stun_discover
#define gaim_stun_init      gaim_stun_init

/* from upnp.h */

/* suggested rename: GaimUPnpMappingHandle */
#define UPnPMappingAddRemove  GaimUPnPMappingAddRemove

#define GaimUPnPCallback  GaimUPnPCallback

#define gaim_upnp_discover             gaim_upnp_discover
#define gaim_upnp_get_public_ip        gaim_upnp_get_public_ip
#define gaim_upnp_cancel_port_mapping  gaim_upnp_cancel_port_mapping
#define gaim_upnp_set_port_mapping     gaim_upnp_set_port_mapping

#define gaim_upnp_remove_port_mapping  gaim_upnp_remove_port_mapping

/* from util.h */

#define GaimUtilFetchUrlData  GaimUtilFetchUrlData
#define GaimMenuAction        GaimMenuAction

#define GaimInfoFieldFormatCallback  GaimIntoFieldFormatCallback

#define GaimKeyValuePair  GaimKeyValuePair

#define gaim_menu_action_new   gaim_menu_action_new
#define gaim_menu_action_free  gaim_menu_action_free

#define gaim_base16_encode   gaim_base16_encode
#define gaim_base16_decode   gaim_base16_decode
#define gaim_base64_encode   gaim_base64_encode
#define gaim_base64_decode   gaim_base64_decode
#define gaim_quotedp_decode  gaim_quotedp_decode

#define gaim_mime_decode_field  gaim_mime_deco_field

#define gaim_utf8_strftime      gaim_utf8_strftime
#define gaim_date_format_short  gaim_date_format_short
#define gaim_date_format_long   gaim_date_format_long
#define gaim_date_format_full   gaim_date_format_full
#define gaim_time_format        gaim_time_format
#define gaim_time_build         gaim_time_build

#define GAIM_NO_TZ_OFF  GAIM_NO_TZ_OFF

#define gaim_str_to_time  gaim_str_to_time

#define gaim_markup_find_tag            gaim_markup_find_tag
#define gaim_markup_extract_info_field  gaim_markup_extract_info_field
#define gaim_markup_html_to_xhtml       gaim_markup_html_to_xhtml
#define gaim_markup_strip_html          gaim_markup_strip_html
#define gaim_markup_linkify             gaim_markup_linkify
#define gaim_markup_slice               gaim_markup_slice
#define gaim_markup_get_tag_name        gaim_markup_get_tag_name
#define gaim_unescape_html              gaim_unescape_html

#define gaim_home_dir  gaim_home_dir
#define gaim_user_dir  gaim_user_dir

#define gaim_util_set_user_dir  gaim_util_set_user_dir

#define gaim_build_dir  gaim_build_dir

#define gaim_util_write_data_to_file  gaim_util_write_data_to_file

#define gaim_util_read_xml_from_file  gaim_util_read_xml_from_file

#define gaim_mkstemp  gaim_mkstemp

#define gaim_program_is_valid  gaim_program_is_valid

#define gaim_running_gnome  gaim_running_gnome
#define gaim_running_kde    gaim_running_kde
#define gaim_running_osx    gaim_running_osx

#define gaim_fd_get_ip  gaim_fd_get_ip

#define gaim_normalize         gaim_normalize
#define gaim_normalize_nocase  gaim_normalize_nocase

#define gaim_strdup_withhtml  gaim_strdup_withhtml

#define gaim_str_has_prefix  gaim_str_has_prefix
#define gaim_str_has_suffix  gaim_str_has_suffix
#define gaim_str_add_cr      gaim_str_add_cr
#define gaim_str_strip_char  gaim_str_strip_char

#define gaim_util_chrreplace  gaim_util_chrreplace

#define gaim_strreplace  gaim_strreplace

#define gaim_utf8_ncr_encode  gaim_utf8_ncr_encode
#define gaim_utf8_ncr_decode  gaim_utf8_ncr_decode

#define gaim_strcasereplace  gaim_strcasereplace
#define gaim_strcasestr      gaim_strcasestr

#define gaim_str_size_to_units      gaim_str_size_to_units
#define gaim_str_seconds_to_string  gaim_str_seconds_to_string
#define gaim_str_binary_to_ascii    gaim_str_binary_to_ascii


#define gaim_got_protocol_handler_uri  gaim_got_protocol_handler_uri

#define gaim_url_parse  gaim_url_parse

#define GaimUtilFetchUrlCallback  GaimUtilFetchUrlCallback
#define gaim_util_fetch_url          gaim_util_fetch_url
#define gaim_util_fetch_url_request  gaim_util_fetch_url_request
#define gaim_util_fetch_url_cancel   gaim_util_fetch_url_cancel

#define gaim_url_decode  gaim_url_decode
#define gaim_url_encode  gaim_url_encode

#define gaim_email_is_valid  gaim_email_is_valid

#define gaim_uri_list_extract_uris       gaim_uri_list_extract_uris
#define gaim_uri_list_extract_filenames  gaim_uri_list_extract_filenames

#define gaim_utf8_try_convert  gaim_utf8_try_convert
#define gaim_utf8_salvage      gaim_utf8_salvage
#define gaim_utf8_strcasecmp   gaim_utf8_strcasecmp
#define gaim_utf8_has_word     gaim_utf8_has_word

#define gaim_print_utf8_to_console  gaim_print_utf8_to_console

#define gaim_message_meify  gaim_message_meify

#define gaim_text_strip_mnemonic  gaim_text_strip_mnemonic

#define gaim_unescape_filename  gaim_unescape_filename
#define gaim_escape_filename    gaim_escape_filename

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

#define gaim_value_new                gaim_value_new
#define gaim_value_new_outgoing       gaim_value_new_outgoing
#define gaim_value_destroy            gaim_value_destroy
#define gaim_value_dup                gaim_value_dup
#define gaim_value_get_type           gaim_value_get_type
#define gaim_value_get_subtype        gaim_value_get_subtype
#define gaim_value_get_specific_type  gaim_value_get_specific_type
#define gaim_value_is_outgoing        gaim_value_is_outgoing
#define gaim_value_set_char           gaim_value_set_char
#define gaim_value_set_uchar          gaim_value_set_uchar
#define gaim_value_set_boolean        gaim_value_set_boolean
#define gaim_value_set_short          gaim_value_set_short
#define gaim_value_set_ushort         gaim_value_set_ushort
#define gaim_value_set_int            gaim_value_set_int
#define gaim_value_set_uint           gaim_value_set_uint
#define gaim_value_set_long           gaim_value_set_long
#define gaim_value_set_ulong          gaim_value_set_ulong
#define gaim_value_set_int64          gaim_value_set_int64
#define gaim_value_set_uint64         gaim_value_set_uint64
#define gaim_value_set_string         gaim_value_set_string
#define gaim_value_set_object         gaim_value_set_object
#define gaim_value_set_pointer        gaim_value_set_pointer
#define gaim_value_set_enum           gaim_value_set_enum
#define gaim_value_set_boxed          gaim_value_set_boxed
#define gaim_value_get_char           gaim_value_get_char
#define gaim_value_get_uchar          gaim_value_get_uchar
#define gaim_value_get_boolean        gaim_value_get_boolean
#define gaim_value_get_short          gaim_value_get_short
#define gaim_value_get_ushort         gaim_value_get_ushort
#define gaim_value_get_int            gaim_value_get_int
#define gaim_value_get_uint           gaim_value_get_uint
#define gaim_value_get_long           gaim_value_get_long
#define gaim_value_get_ulong          gaim_value_get_ulong
#define gaim_value_get_int64          gaim_value_get_int64
#define gaim_value_get_uint64         gaim_value_get_uint64
#define gaim_value_get_string         gaim_value_get_string
#define gaim_value_get_object         gaim_value_get_object
#define gaim_value_get_pointer        gaim_value_get_pointer
#define gaim_value_get_enum           gaim_value_get_enum
#define gaim_value_get_boxed          gaim_value_get_boxed

/* from version.h */

#define GAIM_MAJOR_VERSION  GAIM_MAJOR_VERSION
#define GAIM_MINOR_VERSION  GAIM_MINOR_VERSION
#define GAIM_MICRO_VERSION  GAIM_MICRO_VERSION

#define GAIM_VERSION_CHECK  GAIM_VERSION_CHECK

/* from whiteboard.h */

#define GaimWhiteboardPrplOps  GaimWhiteboardPrplOps
#define GaimWhiteboard         GaimWhiteboard
#define GaimWhiteboardUiOps    GaimWhiteboardUiOps

#define gaim_whiteboard_set_ui_ops    gaim_whiteboard_set_ui_ops
#define gaim_whiteboard_set_prpl_ops  gaim_whiteboard_set_prpl_ops

#define gaim_whiteboard_create             gaim_whiteboard_create
#define gaim_whiteboard_destroy            gaim_whiteboard_destroy
#define gaim_whiteboard_start              gaim_whiteboard_start
#define gaim_whiteboard_get_session        gaim_whiteboard_get_session
#define gaim_whiteboard_draw_list_destroy  gaim_whiteboard_draw_list_destroy
#define gaim_whiteboard_get_dimensions     gaim_whiteboard_get_dimensions
#define gaim_whiteboard_set_dimensions     gaim_whiteboard_set_dimensions
#define gaim_whiteboard_draw_point         gaim_whiteboard_draw_point
#define gaim_whiteboard_send_draw_list     gaim_whiteboard_send_draw_list
#define gaim_whiteboard_draw_line          gaim_whiteboard_draw_line
#define gaim_whiteboard_clear              gaim_whiteboard_clear
#define gaim_whiteboard_send_clear         gaim_whiteboard_send_clear
#define gaim_whiteboard_send_brush         gaim_whiteboard_send_brush
#define gaim_whiteboard_get_brush          gaim_whiteboard_get_brush
#define gaim_whiteboard_set_brush          gaim_whiteboard_set_brush

/* for static plugins */
#define gaim_init_ssl_plugin			gaim_init_ssl_plugin
#define gaim_init_ssl_openssl_plugin	gaim_init_ssl_openssl_plugin
#define gaim_init_ssl_gnutls_plugin		gaim_init_ssl_gnutls_plugin
#define gaim_init_gg_plugin				gaim_init_gg_plugin
#define gaim_init_jabber_plugin			gaim_init_jabber_plugin
#define gaim_init_sametime_plugin		gaim_init_sametime_plugin
#define gaim_init_msn_plugin			gaim_init_msn_plugin
#define gaim_init_novell_plugin			gaim_init_novell_plugin
#define gaim_init_qq_plugin				gaim_init_qq_plugin
#define gaim_init_simple_plugin			gaim_init_simple_plugin
#define gaim_init_yahoo_plugin			gaim_init_yahoo_plugin
#define gaim_init_zephyr_plugin			gaim_init_zephyr_plugin
#define gaim_init_aim_plugin			gaim_init_aim_plugin
#define gaim_init_icq_plugin			gaim_init_icq_plugin

#endif /* _GAIM_COMPAT_H_ */
