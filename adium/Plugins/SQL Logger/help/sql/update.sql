/*
 * This file is intended to upgrade your database from the state in the
 * previous commit to the current schema.  It only needs to be run once.
 *
 * Jeffrey Melloy <jmelloy@visualdistortion.org>
 *
 */

create table im.saved_queries (
query_id        serial primary key,
title           text,
notes           text,
query_text      text,
date_added      timestamp default now()
);

INSERT INTO saved_queries (title, notes, query_text)
VALUES ('Word Frequency', 'Shows the frequency of a selected word.', 'select s.username as sender,
          r.username as recipient,
          count(*)
from   messages,
          users s,
          users r,
          to_tsquery(''porn'') as q
where idxfti @@ q
   and  s.user_id = sender_id
   and  r.user_id = recipient_id
group by s.username, r.username
having count(*) > 1
order by count(*) desc');

INSERT INTO saved_queries (title, notes, query_text) VALUES ('Proximity Search', 'Search for two words within x minutes of each other.', 'select message_id,
          s.username as sender,
          r.username as recipient,
          message_date,
          message
from   messages a,
          users s,
          users r,
          to_tsquery(''porn'') as q
where s.user_id = sender_id
   and  r.user_id = recipient_id
   and  idxfti @@ q
   and  exists (
           select ''x''
           from   messages b,
                     to_tsquery(''raccoon'') as q2
           where sender_id in (a.sender_id, a.recipient_id)
             and   recipient_id in (a.sender_id, a.recipient_id)
             and   b.idxfti @@ q2
             and   b.message_date > 
                         a.message_date - ''5 minutes''::interval
             and   b.message_date <
                         a.message_date + ''5 minutes''::interval)');

INSERT INTO saved_queries (title, notes, query_text) VALUES ('Contact Info', 'Retrieve the contact info for a person.', 'select username,
          key_name,
          value
from   users natural join contact_information 
          natural join information_keys
where username = ''fetchgreebledonx''');
