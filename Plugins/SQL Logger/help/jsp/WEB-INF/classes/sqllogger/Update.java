/*
 * $URL$
 * $Id$
 *
 * Jeffrey Melloy
 */

package sqllogger;

import java.sql.*;
import org.slamb.axamol.library.SqlUtils;
/**
 * Updates the database DML to match the current schema.
 * Needs to be run as a user who can do various table manipulations.
 *
 * @author      Jeffrey Melloy &lt;jmelloy@visualdistortion.org&gt;
 * @version     $Rev$ $Date$
 **/
public class Update {
    static int version;
    static int maxVersion = 1;

    public static boolean versionCheck(Connection conn) {
        PreparedStatement pstmt = null;
        ResultSet rset = null;

        try {
            pstmt = conn.prepareStatement("select last_value from im.db_version_seq");
            rset = pstmt.executeQuery();
            rset.next();
            version = rset.getInt(1);
        } catch (SQLException e) {
            version = -1;
        } finally {
            SqlUtils.close(pstmt);
            SqlUtils.close(rset);
        }

        if(version > maxVersion) return false;
        else return true;
    }

    public static void updateDB(Connection conn) throws SQLException {
        PreparedStatement pstmt = null;
        ResultSet rset = null;
        ResultSet rs = null;

        if(version < 0) {
            try {
                pstmt = conn.prepareStatement("create sequence im.db_version_seq");
                pstmt.execute();
                pstmt = conn.prepareStatement("select nextval('im.db_version_seq')");
                pstmt.execute();
                version++;
            } finally {
                SqlUtils.close(pstmt);
                SqlUtils.close(rset);
            }
        }

        if(version == 1) {
            try {
                pstmt = conn.prepareStatement("create table im.saved_items ( " +
                       " item_id         serial primary key, "+
                       " title           text not null, " +
                       " notes           text, " +
                       " item_type       text, " +
                       " date_added      timestamp default now()" +
                    ")");

                pstmt.execute();

                pstmt = conn.prepareStatement("create table im.saved_fields ( " +
                        " item_id         int references im.saved_items(item_id) not null, " +
                        " field_name      text, " +
                        " value           text " +
                        ")");

                pstmt.execute();

                pstmt = conn.prepareStatement("select * from im.saved_queries");

                rset = pstmt.executeQuery();

                while(rset.next()) {
                    pstmt = conn.prepareStatement("insert into im.saved_items (title, notes, item_type) " +
                            " values (?, ?, 'query') ");

                    pstmt.setString(1, rset.getString("title"));
                    pstmt.setString(2, rset.getString("notes"));

                    pstmt.executeUpdate();

                    pstmt = conn.prepareStatement("select currval('saved_items_item_id_seq')");

                    rs = pstmt.executeQuery();

                    rs.next();

                    pstmt = conn.prepareStatement("insert into im.saved_fields (item_id, field_name, value) " +
                            " values (?, ?, ?) ");

                    pstmt.setInt(1, rs.getInt(1));
                    pstmt.setString(2, "query_text");
                    pstmt.setString(3, rset.getString("query_text"));
                }

                pstmt = conn.prepareStatement("select * from im.saved_chats");

                rset = pstmt.executeQuery();

                while(rset.next()) {
                    pstmt = conn.prepareStatement("insert into im.saved_items (title, notes, item_type) " +
                            " values (?, ?, 'chat') ");

                    pstmt.setString(1, rset.getString("title"));
                    pstmt.setString(2, rset.getString("notes"));

                    pstmt.executeUpdate();

                    pstmt = conn.prepareStatement("select currval('saved_items_item_id_seq')");

                    rs = pstmt.executeQuery();

                    rs.next();

                    pstmt = conn.prepareStatement("insert into im.saved_fields (item_id, field_name, value) " +
                            " values (?, ?, ?) ");

                    if(rset.getString("sent_sn") != null) {
                        pstmt.setInt(1, rs.getInt(1));
                        pstmt.setString(2, "sender");
                        pstmt.setString(3, rset.getString("sent_sn"));
                    }

                    if(rset.getString("received_sn") != null) {
                        pstmt.setInt(1, rs.getInt(1));
                        pstmt.setString(2, "recipient");
                        pstmt.setString(3, rset.getString("received_sn"));
                    }

                    if(rset.getString("single_sn") != null) {
                        pstmt.setInt(1, rs.getInt(1));
                        pstmt.setString(2, "contains");
                        pstmt.setString(3, rset.getString("single_sn"));
                    }

                    if(rset.getString("meta_id") != null) {
                        pstmt.setInt(1, rs.getInt(1));
                        pstmt.setString(2, "meta_id");
                        pstmt.setString(3, rset.getString("meta_id"));
                    }

                    if(rset.getString("date_start") != null) {
                        pstmt.setInt(1, rs.getInt(1));
                        pstmt.setString(2, "dateStart");
                        pstmt.setString(3, rset.getString("date_start"));
                    }

                    if(rset.getString("date_finish") != null) {
                        pstmt.setInt(1, rs.getInt(1));
                        pstmt.setString(2, "dateFinish");
                        pstmt.setString(3, rset.getString("date_finish"));
                    }
                }

                pstmt = conn.prepareStatement("select * from im.saved_searches");

                rset = pstmt.executeQuery();

                while(rset.next()) {
                    pstmt = conn.prepareStatement("insert into im.saved_items (title, notes, item_type) " +
                            " values (?, ?, 'search') ");

                    pstmt.setString(1, rset.getString("title"));
                    pstmt.setString(2, rset.getString("notes"));

                    pstmt.executeUpdate();

                    pstmt = conn.prepareStatement("select currval('saved_items_item_id_seq')");

                    rs = pstmt.executeQuery();

                    rs.next();

                    pstmt = conn.prepareStatement("insert into im.saved_fields (item_id, field_name, value) " +
                            " values (?, ?, ?) ");

                    ResultSetMetaData rsmd = rset.getMetaData();

                    for(int i = 1; i <= rsmd.getColumnCount(); i++) {
                        if(rset.getString(i) != null
                                && !rsmd.getColumnName(i).equals("search_id")
                                && !rsmd.getColumnName(i).equals("date_added")) {

                            String column = rsmd.getColumnName(i);

                            column = column.replaceAll("_s", "S");
                            column = column.replaceAll("_f", "F");
                            column = column.replaceAll("string$", "");

                            pstmt.setInt(1, rs.getInt(1));
                            pstmt.setString(2, column);
                            pstmt.setString(3, rset.getString(i));
                        }
                    }
                }

                pstmt = conn.prepareStatement("drop table im.saved_chats");
                pstmt.execute();

                pstmt = conn.prepareStatement("drop table im.saved_queries");
                pstmt.execute();

                pstmt = conn.prepareStatement("drop table im.saved_searches");
                pstmt.execute();

                pstmt = conn.prepareStatement("select nextval('im.db_version_seq')");
                pstmt.execute();
                version++;

            } finally {
                SqlUtils.close(pstmt);
                SqlUtils.close(rset);
                SqlUtils.close(rs);
            }
        }
    }
}

