/*
 * This file is intended to upgrade your database from the state in the
 * previous commit to the current schema.  It only needs to be run once.
 *
 * Jeffrey Melloy <jmelloy@visualdistortion.org>
 *
 */

alter schema adium rename to im;

create or replace function scramble(text) returns text as '
declare
    do_scramble     text := ''false'';
    entry_text      alias for $1;
    alternate_text  text;
    final_text      text;
    entry_length    int;
begin

    select value
    into   do_scramble
    from   im.preferences
    where  rule = ''scramble'';

    entry_length = length(entry_text);

    if (do_scramble <> ''true'') then
        return entry_text;
    else
        alternate_text := trim(''1345689'' from substring(entry_text,
        entry_length / 2, entry_length));
        if mod(entry_length, 3) = 0 then
            final_text := initcap(alternate_text || bit_length(entry_text));
        else
            final_text := initcap(alternate_text);
        end if;
        return final_text;
    end if;

end;
' language plpgsql;

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

create trigger msgidxupdate before update or insert on im.messages
for each row execute procedure tsearch(message_idx, message);

alter table im.users alter user_id set default nextval('im.users_user_id_seq');
alter table im.messages alter message_id set default nextval('im.messages_message_id_seq');
alter table im.meta_container alter meta_id set default nextval('im.meta_container_meta_id_seq');
alter table im.information_keys alter colum key_id set default nextval('im.information_keys_key_id_seq');
alter table im.information_keys alter column key_id set default nextval('im.information_keys_key_id_seq');
alter table im.saved_searches alter column search_id set default nextval('im.saved_searches_search_id_seq');
alter table im.saved_chats alter column chat_id set default nextval('im.saved_chats_chat_id_seq');

\echo ''
\echo ' *** '
\echo 'Please enter the following command in a psql window:'
\echo 'alter user USERNAME set search_path = im, public'
