/*
 * This file is intended to upgrade your database from the state in the
 * previous commit to the current schema.  It only needs to be run once.
 *
 * Jeffrey Melloy <jmelloy@visualdistortion.org>
 *
 */

alter table adium.saved_chats add column meta_id int
    references adium.meta_container (meta_id);

create index user_stats_sender on adium.user_statistics (sender_id);
create index user_stats_recipient on adium.user_statistics (recipient_id);
create index meta_contact_user on adium.meta_contact (user_id);
create index meta_contact_meta on adium.meta_contact (meta_id);
