package sqllogger;

/**
 * @author jmelloy
 */

import java.sql.*;
import java.util.HashMap;
import java.util.Vector;

public class User {

    HashMap map;

    public User() {
        map = new HashMap();
    }

    public static Vector getUsersForInterval(Connection conn,
            String dateStart, String dateFinish) throws UserException {

        Vector resultVec = new Vector();

        String concurrentWhereClause = " where ";

        if (dateStart == null) {
            concurrentWhereClause += " message_date > 'now'::date ";
        } else {
            concurrentWhereClause += " message_date > ?::timestamp ";
        }

        if(dateFinish != null) {
            concurrentWhereClause += "and message_date < ?::timestamp ";
        }

        String query = "select user_id, service as service, username as username " +
        "from im.users natural join "+
        "(select sender_id as user_id from im.messages "+
        concurrentWhereClause + " union " +
        "select recipient_id as user_id from im.messages " +
        concurrentWhereClause + ") messages order by username";

        try {

            PreparedStatement pstmt = conn.prepareStatement(query);

            if(dateStart != null && dateFinish != null) {
                pstmt.setString(1, dateStart);
                pstmt.setString(2, dateFinish);
                pstmt.setString(3, dateStart);
                pstmt.setString(4, dateFinish);
            } else if(dateStart == null && dateFinish != null) {
                pstmt.setString(1, dateFinish);
                pstmt.setString(2, dateFinish);
            } else if(dateStart != null && dateFinish == null) {
                pstmt.setString(1, dateStart);
                pstmt.setString(2, dateStart);
            }

            ResultSet rset = pstmt.executeQuery();
            ResultSetMetaData rsmd = rset.getMetaData();

            while(rset.next()) {
                User u = new User();
                for(int i = 1; i <= rsmd.getColumnCount(); i++) {
                    u.addPair(rsmd.getColumnName(i), rset.getString(i));
                }
                resultVec.add(u);
            }
        } catch (SQLException e) {
            throw new UserException ("Could not get user list <br>" + e.getMessage());
        }

        return resultVec;
    }

    public static Vector getUsersWithDisplayNames(Connection conn, boolean login)
            throws UserException {

        Vector resultVec = new Vector();

        String query = "select user_id, " +
        " display_name as display_name, " +
        " username " +
        " as username, lower(service) as service from im.users " +
        " natural join im.user_display_name udn" +
        " where case when true = " + login +
        " then login = true " +
        " else 1 = 1 " +
        " end " +
        " and not exists (select 'x' from im.user_display_name where " +
        " user_id = users.user_id and effdate > udn.effdate) " +
        " order by display_name, username";

        try {

            PreparedStatement pstmt = conn.prepareStatement(query);

            ResultSet rset = pstmt.executeQuery();
            ResultSetMetaData rsmd = rset.getMetaData();

            while(rset.next()) {
                User u = new User();
                for(int i = 1; i <= rsmd.getColumnCount(); i++) {
                    u.addPair(rsmd.getColumnName(i), rset.getString(i));
                }
                resultVec.add(u);
            }
        } catch (SQLException e) {
            throw new UserException ("Could not get user list <br>" + e.getMessage());
        }

        return resultVec;
    }

    public static Vector getUsersStartingWith(Connection conn, String start)
            throws UserException {

        String query = new String();
        Vector resultVec = new Vector();

        if(start.equals("0")) {
            query = " select user_id, username, service, display_name " +
                    " from im.users natural join im.user_display_name " +
                    " where not exists (" +
                    "    select 'x' " +
                    "    from im.user_display_name udn" +
                    "    where udn.user_id = users.user_id " +
                    "    and udn.effdate > user_display_name.effdate) " +
                    "  and lower(substr(username, 1, 1)) < 'a' " +
                    " order by username ";
        } else {
            query = " select user_id, username, service, display_name " +
                    " from im.users natural join im.user_display_name " +
                    " where not exists (" +
                    "    select 'x' " +
                    "    from im.user_display_name udn" +
                    "    where udn.user_id = users.user_id " +
                    "    and udn.effdate > user_display_name.effdate) " +
                    "  and lower(substr(username, 1, 1)) = ? " +
                    " order by username ";
        }

        try {

            PreparedStatement pstmt = conn.prepareStatement(query);

            if(!start.equals("0")) {
                pstmt.setString(1, start);
            }

            ResultSet rset = pstmt.executeQuery();
            ResultSetMetaData rsmd = rset.getMetaData();

            while(rset.next()) {
                User u = new User();

                for(int i = 1; i <= rsmd.getColumnCount(); i++) {
                    u.addPair(rsmd.getColumnName(i), rset.getString(i));
                }

                resultVec.add(u);
            }

        } catch (SQLException e) {
            throw new UserException("Error getting users: <br />" +
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
