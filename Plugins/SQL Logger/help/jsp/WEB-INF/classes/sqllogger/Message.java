/**
 * @author jmelloy
 *
 */

package sqllogger;

import java.sql.*;
import java.util.Vector;
import java.util.HashMap;

public class Message {
    HashMap map;
    public Message() {
        map = new HashMap();
    }
    
    public static Vector getMessagesForInterval(Connection conn, 
            String dateStart, String dateFinish, String from_sn, 
            String to_sn, String contains_sn, String service,
            int meta_id, boolean showDisplay, boolean showMeta) throws MessageException {
        
        String commandArray[] = new String[20];
        String queryText;
        int aryCount = 0;
        boolean unconstrained = false;
        
        Vector resultVec = new Vector();

        queryText = "select sender_sn as sender_sn, "+
        " recipient_sn as recipient_sn, " +
        " message, message_date as message_timestamp, message_id, " +
        " message_date::time(0) as message_time, message_date::date as message_date, " +
        " to_char(message_date, 'fmDay, fmMonth DD, YYYY') as fancy_date, " +
        " message_notes.message_id is not null as notes";
        if(showDisplay) {
           queryText += ", sender_display as sender_display, "+
               " recipient_display as recipient_display " +
               " from im.message_v as view ";
        } else if (showMeta) {
            queryText += ", coalesce(send.name, sender_sn) as sender_meta, " +
                " coalesce(rec.name, recipient_sn) as recipient_meta " +
                " from im.simple_message_v as view left join " +
                " im.meta_contact as r " +
                " on (recipient_id = r.user_id and r.preferred = true) " +
                " left join im.meta_container rec on (r.meta_id = rec.meta_id)" +
                " left join im.meta_contact as s " +
                " on (sender_id = s.user_id and s.preferred = true) " +
                " left join im.meta_container send on (s.meta_id = send.meta_id)";
        } else {
            queryText += " from im.simple_message_v as view ";
        }

        queryText += " natural left join im.message_notes ";

        if (dateStart == null) {
            queryText += "where message_date > 'now'::date ";
        } else {
            queryText += "where message_date > ?::timestamp ";
            commandArray[aryCount++] = new String(dateStart);
            if(dateFinish == null) {
                unconstrained = true;
            }
        }

        if (dateFinish != null) {
            queryText += " and message_date < ?::timestamp";
            commandArray[aryCount++] = new String(dateFinish);
        }

        if (from_sn != null && to_sn != null) {
            if(showDisplay) {
                queryText += " and (((sender_display like ? " +
                    " or sender_sn like ?) " +
                    " and (recipient_display like ? or recipient_sn like ?)) or " +
                    " ((sender_display like ? or sender_sn like ?) " +
                    " and (recipient_display like ? or recipient_sn like ? )))";

                commandArray[aryCount++] = new String(to_sn);
                commandArray[aryCount++] = new String(to_sn);

                commandArray[aryCount++] = new String(from_sn);
                commandArray[aryCount++] = new String(from_sn);

                commandArray[aryCount++] = new String(from_sn);
                commandArray[aryCount++] = new String(from_sn);

                commandArray[aryCount++] = new String(to_sn);
                commandArray[aryCount++] = new String(to_sn);
            } else {
                queryText += " and ((sender_sn like ? " +
                " and recipient_sn like ?) or " +
                "(sender_sn like ? and recipient_sn like ?)) ";
                commandArray[aryCount++] = new String(to_sn);
                commandArray[aryCount++] = new String(from_sn);
                commandArray[aryCount++] = new String(from_sn);
                commandArray[aryCount++] = new String(to_sn);
            }
        } else if (from_sn != null && to_sn == null) {
            if(showDisplay) {
                queryText += " and (sender_sn like ? or sender_display like ?) ";
                commandArray[aryCount++] = new String(from_sn);
                commandArray[aryCount++] = new String(from_sn);
            } else {
                queryText += " and sender_sn like ? ";

                commandArray[aryCount++] = new String(from_sn);
            }

        } else if (from_sn == null && to_sn != null) {
            if(showDisplay) {
                queryText += " and (recipient_sn like ? or recipient_display like ?)";
                commandArray[aryCount++] = new String(to_sn);
                commandArray[aryCount++] = new String(to_sn);
            } else {
                queryText += " and recipient_sn like ? ";

                commandArray[aryCount++] = new String(to_sn);
            }
        }

        if (contains_sn != null) {
            if(showDisplay) {
                queryText += " and (recipient_sn like ? or sender_sn like ? " +
                    " or recipient_display like ? or sender_display like ?) ";


                commandArray[aryCount++] = new String(contains_sn);
                commandArray[aryCount++] = new String(contains_sn);
                commandArray[aryCount++] = new String(contains_sn);
                commandArray[aryCount++] = new String(contains_sn);
            } else {
                queryText += " and (recipient_sn like ? or sender_sn like ?) ";
                commandArray[aryCount++] = new String(contains_sn);
                commandArray[aryCount++] = new String(contains_sn);
            }
        }


        if (service != null) {
            queryText += " and (sender_service = ? or recipient_service = ?)";
            commandArray[aryCount++] = new String(service);
            commandArray[aryCount++] = new String(service);
        }

        if (meta_id != 0) {
            queryText += " and (send.meta_id = ? or rec.meta_id = ?)";
        }

        // Only pick the lowest note_id so only one shows up for multiples

        queryText += " and not exists (select 'x' from im.message_notes b where b.message_id = message_notes.message_id and b.date_added > message_notes.date_added)";

        queryText += " order by message_date, message_id";
        
        if(unconstrained) {
            queryText += " limit 250";
        }
        
        try {
        
            PreparedStatement pstmt = conn.prepareStatement(queryText);
            
            for(int i = 0; i < aryCount; i++) {
                pstmt.setString(i + 1, commandArray[i]);
            }
    
            if(meta_id != 0) {
                pstmt.setInt(aryCount + 1, meta_id);
                pstmt.setInt(aryCount + 2, meta_id);
            }
                
            ResultSet rset = pstmt.executeQuery();
            ResultSetMetaData rsmd = rset.getMetaData();
            
            while(rset.next()) {
                Message m = new Message();
                for(int i = 1; i <= rsmd.getColumnCount(); i++) {
                    m.addPair(rsmd.getColumnName(i), rset.getString(i));
                }
                resultVec.add(m);
            }
        } catch (SQLException e) {
            throw new MessageException("Error getting messages.  <br />" +
                    e.getMessage());
        }
        
        return resultVec;
    }
    
    public void addPair( String key, String value ) {
        map.put( key, value ) ;
    }

    public String getValue( String key ) {
        return ( String ) map.get( key ) ;
    }
    
}
