/*
 * This file is intended to upgrade your database from the state in the
 * previous commit to the current schema.  It only needs to be run once.
 *
 * Jeffrey Melloy <jmelloy@visualdistortion.org>
 *
 */

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
    select user_id,
        case when new.sender_display is null
        or new.sender_display = ''
        then new.sender_sn
        else new.sender_display end
    from   adium.users
    where  username = new.sender_sn
     and   service = coalesce(new.sender_service, 'AIM')
    and not exists (
        select 'x'
        from   adium.user_display_name udn
        where  user_id =
               (select user_id from adium.users
                where  username = new.sender_sn
                 and   service = coalesce(new.sender_service, 'AIM'))
            and   display_name = case when new.sender_display is null
             or new.sender_display = '' then new.sender_sn
              else new.sender_display end
            and not exists (
                select 'x'
                from adium.user_display_name
                where effdate > udn.effdate
                and user_id = udn.user_id));

    insert into adium.user_display_name
    (user_id, display_name)
    select user_id,
        case when new.recipient_display is null
        or new.recipient_display = ''
        then new.recipient_sn
        else new.recipient_display end
    from adium.users
    where username = new.recipient_sn
     and  service = coalesce(new.sender_service, 'AIM')
    and not exists (
        select 'x'
        from   adium.user_display_name udn
        where  user_id =
               (select user_id from adium.users
               where username = new.recipient_sn
                and  service = coalesce(new.sender_service, 'AIM'))
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
    service= coalesce(new.sender_service, 'AIM')),
    (select user_id from adium.users where username = new.recipient_sn and
    service=coalesce(new.recipient_service, 'AIM')),
    coalesce(new.message_date, now() )
    );

    -- Updating statistics
    update adium.user_statistics
    set num_messages = num_messages + 1,
    last_message = CURRENT_TIMESTAMP
    where sender_id = (select user_id from adium.users where username =
    new.sender_sn and service = coalesce(new.sender_service, 'AIM'))
    and recipient_id = (select user_id from adium.users where username =
    new.recipient_sn and service = coalesce(new.recipient_service, 'AIM'));

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

