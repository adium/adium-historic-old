alter table users drop column num_sent int;
alter table users drop column num_received int;

create table adium.user_statistics (
sender_id       int references adium.users(user_id) not null,
recipient_id    int references adium.users(user_id) not null,
num_messages    int default 1,
last_message    timestamp default now(),
primary key (sender_id, recipient_id)
);

insert into adium.user_statistics
select sender_id, recipient_id, count(*), max(message_date)
from messages
group by sender_id, recipient_id;

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

    update adium.user_statistics
    set num_messages = num_messages + 1,
    last_message = CURRENT_TIMESTAMP
    where sender_id = (select user_id from users where username =
    new.sender_sn and service = new.sender_service) 
    and recipient_id = (select user_id from users where username =
    new.recipient_sn and service = new.recipient_service);

    insert into adium.user_statistics
    (sender_id, recipient_id)
    select
    (select user_id from users 
    where username = new.sender_sn and service = new.sender_service),
    (select user_id from users
    where username = new.recipient_sn and service = new.recipient_service)
    where not exists 
        (select 'x' from user_statistics
        where sender_id = (select user_id from users where username =
        new.sender_sn and service = new.sender_service) 
        and recipient_id = 
        (select user_id from users where username = 
        new.recipient_sn and service = new.recipient_service))
);
