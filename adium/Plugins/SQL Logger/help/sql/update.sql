/*
 * This file is intended to upgrade your database from the state in the
 * previous commit to the current schema.  It only needs to be run once.
 *
 * Jeffrey Melloy <jmelloy@visualdistortion.org>
 *
 */

alter table adium.users add column login boolean;
alter table adium.users alter column login set default false;
update adium.users set login = false;
