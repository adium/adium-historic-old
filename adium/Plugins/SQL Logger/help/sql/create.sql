create schema im;

create table im.users (
user_id     serial primary key,
username    varchar(50) not null,
service     varchar(30) not null default 'AIM',
login       boolean default false,
unique(username,service)
);

create table im.messages (
message_id serial primary key,
message_date timestamp default now(),
message varchar(8096),
sender_id int references im.users(user_id) not null,
recipient_id int references im.users(user_id) not null
);

create table im.user_display_name (
user_id         int references im.users(user_id) not null,
display_name    varchar(300),
effdate         timestamp default now()
);

create table im.user_statistics (
sender_id       int references im.users(user_id) not null,
recipient_id    int references im.users(user_id) not null,
num_messages    int default 1,
last_message    timestamp default now(),
primary key (sender_id, recipient_id)
);

create index im_sender_recipient on im.messages(sender_id, recipient_id);
create index im_msg_date_sender_recipient on
   im.messages (message_date, sender_id, recipient_id);
create index im_recipient on im.messages(recipient_id);
create index im_display_user on im.user_display_name(user_id);
create index im_message_date on im.messages(message_date);

create or replace view im.message_v as
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
from   im.messages m,
       im.users s natural join im.user_display_name s_disp,
       im.users r natural join im.user_display_name r_disp
where  m.sender_id = s.user_id
  and  m.recipient_id = r.user_id
  and  s_disp.effdate <= message_date
  and  not exists (
       select 'x'
       from   im.user_display_name udn
       where  udn.effdate > s_disp.effdate
       and    udn.user_id = s.user_id
       and    udn.effdate <= message_date
       )
  and  r_disp.effdate <= message_date
  and  not exists (
       select 'x'
       from   im.user_display_name udn
       where  udn.effdate > r_disp.effdate
       and    udn.user_id = r.user_id
       and    udn.effdate <= message_date
       );

create or replace view im.simple_message_v as
select  m.message_date,
        s.username as sender_sn,
        r.username as recipient_sn,
        m.sender_id,
        m.recipient_id,
        message,
        message_id
from    im.messages m,
        im.users s,
        im.users r
where   m.sender_id = s.user_id
 and    m.recipient_id = r.user_id;

create or replace rule insert_message_v as
on insert to im.message_v
do instead  (

    -- Usernames

    insert into im.users (username,service)
    select new.sender_sn, coalesce(new.sender_service, 'AIM')
    where not exists (
        select 'x'
        from im.users
        where username = new.sender_sn
        and service = coalesce(new.sender_service, 'AIM'));

    insert into im.users (username, service)
    select new.recipient_sn, coalesce(new.recipient_service, 'AIM')
    where not exists (
        select 'x'
        from im.users
        where username = new.recipient_sn
        and service = coalesce(new.recipient_service, 'AIM'));

    -- Display Names
    insert into im.user_display_name
    (user_id, display_name)
    select user_id,
        case when new.sender_display is null
        or new.sender_display = ''
        then new.sender_sn
        else new.sender_display end
    from   im.users
    where  username = new.sender_sn
     and   service = coalesce(new.sender_service, 'AIM')
    and not exists (
        select 'x'
        from   im.user_display_name udn
        where  user_id =
               (select user_id from im.users
                where  username = new.sender_sn
                 and   service = coalesce(new.sender_service, 'AIM'))
            and   display_name = case when new.sender_display is null
             or new.sender_display = '' then new.sender_sn
              else new.sender_display end
            and not exists (
                select 'x'
                from im.user_display_name
                where effdate > udn.effdate
                and user_id = udn.user_id));

    insert into im.user_display_name
    (user_id, display_name)
    select user_id,
        case when new.recipient_display is null
        or new.recipient_display = ''
        then new.recipient_sn
        else new.recipient_display end
    from im.users
    where username = new.recipient_sn
     and  service = coalesce(new.sender_service, 'AIM')
    and not exists (
        select 'x'
        from   im.user_display_name udn
        where  user_id =
               (select user_id from im.users
               where username = new.recipient_sn
                and  service = coalesce(new.sender_service, 'AIM'))
        and    display_name = new.recipient_display
        and not exists (
            select 'x'
            from   im.user_display_name
            where  effdate > udn.effdate
             and   user_id = udn.user_id));

    -- The mesage
    insert into im.messages
        (message,sender_id,recipient_id, message_date)
    values (new.message,
    (select user_id from im.users where username = new.sender_sn and
    service= coalesce(new.sender_service, 'AIM')),
    (select user_id from im.users where username = new.recipient_sn and
    service=coalesce(new.recipient_service, 'AIM')),
    coalesce(new.message_date, now() )
    );

    -- Updating statistics
    update im.user_statistics
    set num_messages = num_messages + 1,
    last_message = CURRENT_TIMESTAMP
    where sender_id = (select user_id from im.users where username =
    new.sender_sn and service = coalesce(new.sender_service, 'AIM'))
    and recipient_id = (select user_id from im.users where username =
    new.recipient_sn and service = coalesce(new.recipient_service, 'AIM'));

    -- Inserting statistics if none exist
    insert into im.user_statistics
    (sender_id, recipient_id, num_messages)
    select
    (select user_id from im.users
    where username = new.sender_sn and service = new.sender_service),
    (select user_id from im.users
    where username = new.recipient_sn and service = new.recipient_service),
    1
    where not exists
        (select 'x' from im.user_statistics
        where sender_id = (select user_id from im.users where username =
        new.sender_sn and service = new.sender_service)
        and recipient_id =
        (select user_id from im.users where username =
        new.recipient_sn and service = new.recipient_service))
);

create table im.meta_container (
meta_id         serial primary key,
name            text not null,
url             text,
email           text,
location        text,
notes           text
);

create table im.meta_contact (
meta_id         int references im.meta_container (meta_id) not null,
user_id         int references im.users (user_id) not null,
preferred       boolean default false
);

create table im.saved_searches (
search_id       serial primary key,
title           text,
notes           text,
sender          text,
recipient       text,
searchString    text,
orderBy         text,
date_start      timestamp,
date_finish     timestamp,
date_added      timestamp default now()
);

create table im.saved_chats (
chat_id         serial primary key,
title           text,
notes           text,
sent_sn         text,
received_sn     text,
single_sn       text,
meta_id         int references im.meta_container(meta_id),
date_start      timestamp,
date_finish     timestamp,
date_added      timestamp default now()
);

create table im.message_notes (
message_id      int references im.messages(message_id),
title           text not null,
notes           text not null,
date_added      timestamp default now()
);

create table im.preferences (
rule            text,
value           varchar(30)
);

insert into im.preferences values ('scramble', 'false');

create table im.information_keys (
key_id          serial primary key,
key_name        text not null,
delete          boolean default false
);

insert into im.information_keys (key_name) values ('Location');
insert into im.information_keys (key_name) values ('URL');
insert into im.information_keys (key_name) values ('Email');
insert into im.information_keys (key_name) values ('Notes');

create table im.contact_information (
meta_id         int references im.meta_container (meta_id),
user_id         int references im.users (user_id),
key_id          int references im.information_keys (key_id),
value           text,
    constraint meta_or_user_not_null
        check (meta_id is not null or user_id is not null)
);

create or replace view im.user_contact_info as
(select user_id, username, key_id, key_name, value
from im.users natural join
     im.contact_information natural join
     im.information_keys where delete = false);

create or replace view im.meta_contact_info as
(select meta_id, name, key_id, key_name, value
from im.meta_container natural join
     im.contact_information natural join
     im.information_keys where delete = false);
