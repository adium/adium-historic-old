-- Jeffrey Melloy <jmelloy@visualdistortion.org>

-- $URL: http://svn.visualdistortion.org/repos/projects/adium/sql/tsearch.sql $
-- $Rev: 310 $ $Date: 2003/08/05 04:25:49 $

-- This script adds full-text index searching (fast).
-- It needs to be run after the "tsearch" module is installed.
-- If the tsearch module is not installed correctly, it will fail with
-- "type txtidx does not exist"

-- Although it can be run either before or after data is in table,
-- running it before a large data entry (parser.pl) will cause data to
-- be entered much more slowly.

-- For large tables, this script may take a few minutes, especially the 
-- "create index" stage.

alter table adium.messages add message_idx txtidx;
update adium.messages set message_idx=txt2txtidx(message);
create index message_idx on adium.messages using gist(message_idx);
create trigger msgidxupdate before update or insert on adium.messages
for each row execute procedure tsearch(message_idx, message);
