/*
 * This file is intended to upgrade your database from the state in the
 * previous commit to the current schema.  It only needs to be run once.
 *
 * Jeffrey Melloy <jmelloy@visualdistortion.org>
 *
 */

drop view im.simple_message_v;

create or replace view im.simple_message_v as
select  m.message_date,
        s.username as sender_sn,
        r.username as recipient_sn,
        s.service as sender_service,
        r.service as recipient_service,
        m.sender_id,
        m.recipient_id,
        message,
        message_id
from    im.messages m,
        im.users s,
        im.users r
where   m.sender_id = s.user_id
 and    m.recipient_id = r.user_id;

