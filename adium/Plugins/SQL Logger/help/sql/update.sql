/*
 * This file is intended to upgrade your database from the state in the
 * previous commit to the current schema.  It only needs to be run once.
 *
 * Jeffrey Melloy <jmelloy@visualdistortion.org>
 *
 */

alter table adium.saved_searches add column date_start timestamp;
alter table adium.saved_searches add column date_finish timestamp;