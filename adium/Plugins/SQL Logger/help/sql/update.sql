/*
 * This file is intended to upgrade your database from the state in the
 * previous commit to the current schema.  It only needs to be run once.
 *
 * Jeffrey Melloy <jmelloy@visualdistortion.org>
 *
 */

alter table adium.meta_contact add preferred boolean;
alter table adium.meta_contact alter column preferred set default = false;
update adium.meta_contact set preferred = false;
