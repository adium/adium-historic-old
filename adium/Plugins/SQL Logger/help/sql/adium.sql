create schema adium;

create table adium.users (
user_id serial primary key,
username varchar(50) not null,
service varchar(30) default 'AIM',
unique(username,service)
);

create table adium.messages (
message_id serial primary key,
message_date timestamp default now(),
message varchar(8096),
sender_id int references adium.users(user_id) not null,
recipient_id int references adium.users(user_id) not null
);

create index adium_sender_recipient on adium.messages(sender_id, recipient_id);
create index adium_msg_date_sender_recipient on
   adium.messages (message_date, sender_id, recipient_id);
create index adium_recipient on adium.messages(recipient_id);

create view adium.message_v as
select message_id,
       message_date,
       message,
       s.username as sender_sn,
       s.service as sender_service,
       r.username as recipient_sn,
       r.service as recipient_service
from adium.messages m,
     adium.users s,
     adium.users r
where m.sender_id = s.user_id
      and m.recipient_id = r.user_id;

create or replace rule insert_message_v as
on insert to adium.message_v
do instead  (
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
        and service = coalesce(new.sender_service, 'AIM'));

    insert into adium.messages
        (message,sender_id,recipient_id, message_date)
    values (new.message,
    (select user_id from users where username = new.sender_sn),
    (select user_id from users where username = new.recipient_sn),
    coalesce(new.message_date, now() )
    )
);
