/*
 * This file is intended to upgrade your database from the state in the
 * previous commit to the current schema.  It only needs to be run once.
 *
 * Jeffrey Melloy <jmelloy@visualdistortion.org>
 *
 */

create table adium.information_keys (
key_id          serial primary key,
key_name        text not null
);

create table adium.contact_information (
meta_id         int references adium.meta_container (meta_id),
user_id         int references adium.users (user_id),
key_id          int references adium.information_keys (key_id),
value           text,
    constraint meta_or_user_not_null 
        check (meta_id is not null or user_id is not null)
);

insert into adium.information_keys (key_name) values ('URL');
insert into adium.information_keys (key_name) values ('Email');
insert into adium.information_keys (key_name) values ('Location');
insert into adium.information_keys (key_name) values ('Notes');

insert into contact_information (meta_id, key_id, value) (select meta_id, 1,
url from meta_container where url is not null);

insert into contact_information (meta_id, key_id, value) (select meta_id, 2,
email from meta_container where email is not null);

insert into contact_information (meta_id, key_id, value) (select meta_id, 3,
location from meta_container where location is not null);

insert into contact_information (meta_id, key_id, value) (select meta_id, 4,
notes from meta_container where notes is not null);

create or replace view adium.user_contact_info as 
(select user_id, username, key_id, key_name, value 
from adium.users natural join 
     adium.contact_information natural join
     adium.information_keys);

create or replace view adium.meta_contact_info as 
(select meta_id, name, key_id, key_name, value 
from adium.meta_container natural join 
     adium.contact_information natural join
     adium.information_keys);

alter table adium.meta_container drop column notes;
alter table adium.meta_container drop column url;
alter table adium.meta_container drop column location;
alter table adium.meta_container drop column email;
