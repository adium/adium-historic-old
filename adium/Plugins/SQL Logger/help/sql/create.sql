create schema im;

 -- Stores each user who sends or receives a message.
create table im.users (
user_id     serial primary key,
username    varchar(50) not null,
service     varchar(30) not null default 'AIM',
login       boolean default false,
unique(username,service)
);

 -- Stores each message sent and received
create table im.messages (
message_id serial primary key,
message_date timestamp default now(),
message varchar(8096),
sender_id int references im.users(user_id) not null,
recipient_id int references im.users(user_id) not null
);

 -- Stores aliases/display names for users, with history.
 -- This is able to view messages with the display name they were using at the
 -- time it was sent.
create table im.user_display_name (
user_id         int references im.users(user_id) not null,
display_name    varchar(300),
effdate         timestamp default now()
);

 -- Stores a total count of messages for speed purposes.
create table im.user_statistics (
sender_id       int references im.users(user_id) not null,
recipient_id    int references im.users(user_id) not null,
num_messages    int default 1,
last_message    timestamp default now(),
primary key (sender_id, recipient_id)
);

 -- Createe a few commonly used indexes
create index im_sender_recipient on im.messages(sender_id, recipient_id);
create index im_msg_date_sender_recipient on
   im.messages (message_date, sender_id, recipient_id);
create index im_recipient on im.messages(recipient_id);
create index im_display_user on im.user_display_name(user_id);
create index im_message_date on im.messages(message_date);

 -- message_v contains the message, sender and recipient screennames, and
 -- sender/recipient display names
 -- the subselect to get display names makes it slower than simple_message_v
 -- uses a not exists subselect for the display names to get the first display
 -- name with an effective date less than the message
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

 -- simple_message_v: does not contain display names for speed
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

/*
 * function which does an insert.
 * 1) insert a new user if one does not exist with that name/service already
 * 2) insert a new display name if it is different and not null, with the
 *      effdate
 * 3) insert a message
 * 4) update user_statistics with a new count
 */

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

 -- Contains names of the meta contacts.
create table im.meta_container (
meta_id         serial primary key,
name            text not null
);

 -- contains users who belong to a meta-contact, with a boolean to determine
 -- which is their primary meta-contact (if one users belongs to more than one)
create table im.meta_contact (
meta_id         int references im.meta_container (meta_id) not null,
user_id         int references im.users (user_id) not null,
preferred       boolean default false
);

 -- saved_searches and saved_chats are used by the JSPs to label
 -- conversations.  Simply save the parameters, so they behave like a
 -- smart folder.  If data is added that fits the criteria, it will show up.

 -- used to save the search results
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

 -- used to save the chat settings
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

 -- used to save queries
create table im.saved_queries (
query_id       serial primary key,
title          text,
notes          text,
query_text     text,
date_added     timestamp default now()
);

 -- saves a note and links it to a message id
create table im.message_notes (
message_id      int references im.messages(message_id),
title           text not null,
notes           text not null,
date_added      timestamp default now()
);


 -- the master table for the extensible metadata system.
 -- saved names of categories (URL, location, etc)
create table im.information_keys (
key_id          serial primary key,
key_name        text not null,
delete          boolean default false
);

 -- insert a couple to start with so joins don't get messed up when the
 -- database is clean
insert into im.information_keys (key_name) values ('Location');
insert into im.information_keys (key_name) values ('URL');
insert into im.information_keys (key_name) values ('Email');
insert into im.information_keys (key_name) values ('Notes');

 -- stores information, linked to either a meta contact or a user.
create table im.contact_information (
meta_id         int references im.meta_container (meta_id),
user_id         int references im.users (user_id),
key_id          int references im.information_keys (key_id),
value           text,
    constraint meta_or_user_not_null
        check (meta_id is not null or user_id is not null)
);

 -- View to see users with metadata added
create or replace view im.user_contact_info as
(select user_id, username, key_id, key_name, value
from im.users natural join
     im.contact_information natural join
     im.information_keys where delete = false);

 -- View to see meta contacts with metadata
create or replace view im.meta_contact_info as
(select meta_id, name, key_id, key_name, value
from im.meta_container natural join
     im.contact_information natural join
     im.information_keys where delete = false);

-- Insert the default queries into the saved queries
INSERT INTO saved_queries (title, notes, query_text)
VALUES ('Word Frequency', 'Shows the frequency of a selected word.', 'select s.username as sender,
          r.username as recipient,
          count(*)
from   messages,
          users s,
          users r,
          to_tsquery(''porn'') as q
where idxfti @@ q
   and  s.user_id = sender_id
   and  r.user_id = recipient_id
group by s.username, r.username
having count(*) > 1
order by count(*) desc');

INSERT INTO saved_queries (title, notes, query_text) VALUES ('Proximity Search', 'Search for two words within x minutes of each other.', 'select message_id,
          s.username as sender,
          r.username as recipient,
          message_date,
          message
from   messages a,
          users s,
          users r,
          to_tsquery(''porn'') as q
where s.user_id = sender_id
   and  r.user_id = recipient_id
   and  idxfti @@ q
   and  exists (
           select ''x''
           from   messages b,
                     to_tsquery(''raccoon'') as q2
           where sender_id in (a.sender_id, a.recipient_id)
             and   recipient_id in (a.sender_id, a.recipient_id)
             and   b.idxfti @@ q2
             and   b.message_date > 
                         a.message_date - ''5 minutes''::interval
             and   b.message_date <
                         a.message_date + ''5 minutes''::interval)');

INSERT INTO saved_queries (title, notes, query_text) VALUES ('Contact Info', 'Retrieve the contact info for a person.', 'select username,
          key_name,
          value
from   users natural join contact_information 
          natural join information_keys
where username = ''fetchgreebledonx''');
