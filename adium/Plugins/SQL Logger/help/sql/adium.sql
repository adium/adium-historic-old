create schema adium;

create table adium.users (
user_id serial primary key,
username varchar(50) not null,
service varchar(30) not null default 'AIM',
num_sent int default 0,
num_received int default 0,
unique(username,service)
);

create table adium.messages (
message_id serial primary key,
message_date timestamp default now(),
message varchar(8096),
sender_id int references adium.users(user_id) not null,
recipient_id int references adium.users(user_id) not null
);

create table adium.user_display_name (
user_id         int references adium.users(user_id) not null,
display_name    varchar(300),
effdate         timestamp default now()
);

create index adium_sender_recipient on adium.messages(sender_id, recipient_id);
create index adium_msg_date_sender_recipient on
   adium.messages (message_date, sender_id, recipient_id);
create index adium_recipient on adium.messages(recipient_id);
create index adium_display_user on adium.user_display_name(user_id);
create index adium_display_date on adium.user_display_name(effdate);

create or replace view adium.message_v as
select message_id,
       message_date,
       message,
       s.username as sender_sn,
       s.service as sender_service,
       s_disp.display_name as sender_display,
       r.username as recipient_sn,
       r.service as recipient_service,
       r_disp.display_name as recipient_display
from   adium.messages m,
       adium.users s natural join adium.user_display_name s_disp,
       adium.users r natural join adium.user_display_name r_disp
where  m.sender_id = s.user_id
  and  m.recipient_id = r.user_id
  and  s_disp.effdate < message_date
  and  not exists (
       select 'x'
       from adium.user_display_name udn
       where udn.effdate > s_disp.effdate
       and   udn.user_id = s.user_id)
  and  r_disp.effdate < message_date
  and  not exists (
       select 'x'
       from   adium.user_display_name udn
       where  udn.effdate > r_disp.effdate
       and    udn.user_id = r.user_id);

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
        and service = coalesce(new.recipient_service, 'AIM'));

    insert into adium.user_display_name
    (user_id, display_name)
    select user_id, new.sender_display
    from users 
    where username = new.sender_sn
    and new.sender_display is not null
    and new.sender_display <> ''
    and not exists (
        select 'x'
        from   user_display_name
        where  user_id = 
               (select user_id from users where username = new.sender_sn)
        and    display_name = new.sender_display);

    insert into adium.user_display_name
    (user_id, display_name)
    select user_id, new.recipient_display
    from users
    where username = new.recipient_sn
    and new.recipient_display is not null
    and new.recipient_display <> ''
    and not exists (
        select 'x'
        from   user_display_name
        where  user_id = 
               (select user_id from users where username = new.recipient_sn)
        and    display_name = new.recipient_display);

    insert into adium.messages
        (message,sender_id,recipient_id, message_date)
    values (new.message,
    (select user_id from users where username = new.sender_sn and
    service=new.sender_service),
    (select user_id from users where username = new.recipient_sn and
    service=new.recipient_service),
    coalesce(new.message_date, now() )
    );

    update adium.users
    set num_sent = num_sent + 1
    where user_id = (select user_id from users where username= new.sender_sn
      and service = new.sender_service);

    update adium.users
    set num_received = num_received + 1
    where user_id = (select user_id from users where username =
    new.recipient_sn
     and service = new.recipient_service);
);
