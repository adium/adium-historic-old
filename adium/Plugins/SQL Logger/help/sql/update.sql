/*
 * This file is intended to upgrade your database from the state in the
 * previous commit to the current schema.  It only needs to be run once.
 *
 * Jeffrey Melloy <jmelloy@visualdistortion.org>
 *
 */

drop view adium.simple_message_v;
drop view adium.message_v;

create or replace view adium.message_v as
select message_id,
       message_date,
       message,
       s.username as sender_sn,
       s.service as sender_service,
       m.sender_id,
       m.recipient_id,
       s_disp.display_name as sender_display,
       r.username as recipient_sn,
       r.service as recipient_service,
       r_disp.display_name as recipient_display
from   adium.messages m,
       adium.users s natural join adium.user_display_name s_disp,
       adium.users r natural join adium.user_display_name r_disp
where  m.sender_id = s.user_id
  and  m.recipient_id = r.user_id
  and  s_disp.effdate <= message_date
  and  not exists (
       select 'x'
       from   adium.user_display_name udn
       where  udn.effdate > s_disp.effdate
       and    udn.user_id = s.user_id
       and    udn.effdate <= message_date
       )
  and  r_disp.effdate <= message_date
  and  not exists (
       select 'x'
       from   adium.user_display_name udn
       where  udn.effdate > r_disp.effdate
       and    udn.user_id = r.user_id
       and    udn.effdate <= message_date
       );

create or replace view adium.simple_message_v as
select  m.message_date,
        s.username as sender_sn,
        r.username as recipient_sn,
        m.sender_id,
        m.recipient_id,
        message,
        message_id
from    adium.messages m,
        adium.users s,
        adium.users r
where   m.sender_id = s.user_id
 and    m.recipient_id = r.user_id;

create or replace rule insert_message_v as
on insert to adium.message_v
do instead  (
    
    -- Usernames
    
    insert into adium.users (username,service)
    select new.sender_sn, coalesce(new.sender_service, 'AIM')
    where not exists (
        select 'x'
        from adium.users
        where username = new.sender_sn
        and service = coalesce(new.sender_service, 'AIM'));

    insert into adium.users (username, service)
    select new.recipient_sn, coalesce(new.recipient_service, 'AIM')
    where not exists (
        select 'x'
        from adium.users
        where username = new.recipient_sn
        and service = coalesce(new.recipient_service, 'AIM'));

    -- Display Names
    insert into adium.user_display_name
    (user_id, display_name)
    select user_id, new.sender_display
    from adium.users 
    where username = new.sender_sn
    and new.sender_display is not null
    and not exists (
        select 'x'
        from   adium.user_display_name udn
        where  user_id = 
               (select user_id from adium.users where username = new.sender_sn)
            and   display_name = new.sender_display
            and not exists (
                select 'x'
                from adium.user_display_name
                where effdate > udn.effdate
                and user_id = udn.user_id));

    insert into adium.user_display_name
    (user_id, display_name)
    select user_id, new.recipient_display
    from adium.users
    where username = new.recipient_sn
    and new.recipient_display is not null
    and not exists (
        select 'x'
        from   adium.user_display_name udn
        where  user_id = 
               (select user_id from adium.users where username = new.recipient_sn)
        and    display_name = new.recipient_display
        and not exists (
            select 'x'
            from   adium.user_display_name
            where  effdate > udn.effdate
             and   user_id = udn.user_id));

    -- The mesage
    insert into adium.messages
        (message,sender_id,recipient_id, message_date)
    values (new.message,
    (select user_id from adium.users where username = new.sender_sn and
    service=new.sender_service),
    (select user_id from adium.users where username = new.recipient_sn and
    service=new.recipient_service),
    coalesce(new.message_date, now() )
    );

    -- Updating statistics
    update adium.user_statistics
    set num_messages = num_messages + 1,
    last_message = CURRENT_TIMESTAMP
    where sender_id = (select user_id from adium.users where username =
    new.sender_sn and service = new.sender_service) 
    and recipient_id = (select user_id from adium.users where username =
    new.recipient_sn and service = new.recipient_service);

    -- Inserting statistics if none exist
    insert into adium.user_statistics
    (sender_id, recipient_id, num_messages)
    select
    (select user_id from adium.users 
    where username = new.sender_sn and service = new.sender_service),
    (select user_id from adium.users
    where username = new.recipient_sn and service = new.recipient_service),
    1
    where not exists 
        (select 'x' from adium.user_statistics
        where sender_id = (select user_id from adium.users where username =
        new.sender_sn and service = new.sender_service) 
        and recipient_id = 
        (select user_id from adium.users where username = 
        new.recipient_sn and service = new.recipient_service))
);

create table adium.saved_searches (
search_id       serial primary key,
title           text,
notes           text,
sender          text,
recipient       text,
searchString    text,
orderBy         text,
date_added      timestamp default now()
);
*/

create table adium.saved_chats (
chat_id     serial primary key,
title           text,
notes           text,
sent_sn         text,
received_sn     text,
single_sn       text,
date_start      timestamp,
date_finish     timestamp,
date_added      timestamp default now()
);

create table adium.meta_container (
meta_id         serial primary key,
name            text not null,
url             text,
email           text,
location        text,
notes           text
);

create table adium.meta_contact (
meta_id int references adium.meta_container (meta_id) not null,
user_id int references adium.users (user_id) not null
);

create table adium.message_notes (
message_id      int references adium.messages(message_id),
title           text not null,
notes           text not null,
date_added      timestamp default now()
);
