<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.sql.*' %>
<%@ page import = 'javax.naming.*' %>
<%@ page import = 'java.util.ArrayList' %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<!--$URL: http://svn.visualdistortion.org/repos/projects/adium/jsp/simpleViewer.jsp $-->
<!--$Rev: 795 $ $Date: 2004/06/01 00:51:09 $ -->

<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();

String dateStart, dateFinish, from_sn, to_sn, contains_sn;
boolean showDisplay = true;
boolean showMeta = false;

Date today = new Date(System.currentTimeMillis());
int chat_id = 0;
int meta_id = 0;

dateFinish = request.getParameter("finish");
dateStart = request.getParameter("start");
from_sn = request.getParameter("from");
to_sn = request.getParameter("to");
contains_sn = request.getParameter("contains");
String screenDisplayMeta = request.getParameter("screen_or_display");

String title = new String("");
String notes = new String("");

try {
    chat_id = Integer.parseInt(request.getParameter("chat_id"));
} catch (NumberFormatException e) {
    chat_id = 0;
}

if (dateFinish != null && (dateFinish.equals("") || dateFinish.startsWith("null"))) {
    dateFinish = null;
} else if (dateFinish != null) {

}


if (dateStart != null && (dateStart.equals("") || dateStart.startsWith("null"))) {
    dateStart = null;
} else if (dateStart != null) {

} else if (dateStart == null ) {

}

if (from_sn != null && (from_sn.equals("") || from_sn.startsWith("null"))) {
    from_sn = null;
} else if(from_sn != null) {

}

if (to_sn != null && (to_sn.equals("") || to_sn.startsWith("null"))) {
    to_sn = null;
} else if(to_sn != null ) {

}

if (contains_sn != null && (contains_sn.equals("") || contains_sn.startsWith("null"))) {
    contains_sn = null;
} else if(contains_sn != null) {

}

if(screenDisplayMeta != null && screenDisplayMeta.equals("screen")) {
    showDisplay = false;
} else if (screenDisplayMeta != null && screenDisplayMeta.equals("meta")) {
    showMeta = true;
    showDisplay = false;
}

try {
    meta_id = Integer.parseInt(request.getParameter("meta_id"));
    if(meta_id != 0) {
        showMeta = true;
        showDisplay = false;
    }
} catch (NumberFormatException e) {
    meta_id = 0;
}

PreparedStatement pstmt = null;
ResultSet rset = null;
ResultSet noteSet = null;

String queryText = new String();

try {

    if(chat_id != 0) {
        pstmt = conn.prepareStatement("select title, notes, sent_sn, received_sn, single_sn, date_start, date_finish, meta_id from adium.saved_chats where chat_id = ?");

        pstmt.setInt(1, chat_id);

        rset = pstmt.executeQuery();

        if(rset != null && rset.next()) {
            from_sn = rset.getString("sent_sn");
            to_sn = rset.getString("received_sn");
            contains_sn = rset.getString("single_sn");
            dateFinish = rset.getString("date_finish");
            dateStart = rset.getString("date_start");
            title = rset.getString("title");
            notes = rset.getString("notes");
            meta_id = rset.getInt("meta_id");
            if(meta_id != 0) {
                showMeta = true;
                showDisplay = false;
            }
        }
    } else {
        title = "SQL Logger";
    }
%>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>Adium: <%= title %></title>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1" />
<style>
body {
    font-family: "Lucida Grande", "Lucida Sans Unicode", verdana, lucida, sans-serif;
    font-size: 11px;
}

a, a:link, a:visited {
    color: #006600;
    text-decoration: none;
}

a:hover {
    color: #ff9934;
    text-decoration: underline;
}

.dateHeader {
    border: 1px solid #CCCCCC;
    font-weight: bold;
    color: #333;
    margin-bottom: 5px;
    padding: 2px;
}

</style>
</head>
<body>
<%
    String commandArray[] = new String[20];
    int aryCount = 0;
    boolean unconstrained = false;

    queryText = "select scramble(sender_sn) as sender_sn, "+
    " scramble(recipient_sn) as recipient_sn, " +
    " message, message_date, message_id, " +
    " to_char(message_date, 'fmDay, fmMonth DD, YYYY') as fancy_date, " +
    " message_notes.message_id is not null as notes";
    if(showDisplay) {
       queryText += ", scramble(sender_display) as sender_display, "+
           " scramble(recipient_display) as recipient_display " +
           " from adium.message_v as view ";
    } else if (showMeta) {
        queryText += ", coalesce(send.name, scramble(sender_sn)) as sender_meta, " +
            " coalesce(rec.name, scramble(recipient_sn)) as recipient_meta " +
            " from adium.simple_message_v as view left join " +
            " adium.meta_contact as r " +
            " on (recipient_id = r.user_id and r.preferred = true) " +
            " left join adium.meta_container rec on (r.meta_id = rec.meta_id)" +
            " left join adium.meta_contact as s " +
            " on (sender_id = s.user_id and s.preferred = true) " +
            " left join adium.meta_container send on (s.meta_id = send.meta_id)";
    } else {
        queryText += " from adium.simple_message_v as view ";
    }

    queryText += " natural left join adium.message_notes ";

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
        queryText += " and (((sender_sn like ? " +
        " and recipient_sn like ?) or " +
        "(sender_sn like ? and recipient_sn like ?)) or " +
        "((scramble(sender_sn) like ? and scramble(recipient_sn) like ?) or " +
        "(scramble(recipient_sn) like ? and scramble(sender_sn) like ?)))";
        commandArray[aryCount++] = new String(to_sn);
        commandArray[aryCount++] = new String(from_sn);
        commandArray[aryCount++] = new String(from_sn);
        commandArray[aryCount++] = new String(to_sn);
        commandArray[aryCount++] = new String(to_sn);
        commandArray[aryCount++] = new String(from_sn);
        commandArray[aryCount++] = new String(to_sn);
        commandArray[aryCount++] = new String(from_sn);

    } else if (from_sn != null && to_sn == null) {
        queryText += " and (sender_sn like ? or scramble(sender_sn) like ?)";

        commandArray[aryCount++] = new String(from_sn);
        commandArray[aryCount++] = new String(from_sn);

    } else if (from_sn == null && to_sn != null) {
        queryText += " and (recipient_sn like ? or scramble(recipient_sn) like ?)";

        commandArray[aryCount++] = new String(to_sn);
        commandArray[aryCount++] = new String(to_sn);
    }

    if (contains_sn != null) {
        queryText += " and (recipient_sn like ? or sender_sn like ? or scramble(recipient_sn) like ? or scramble(sender_sn) like ?) ";
        commandArray[aryCount++] = new String(contains_sn);
        commandArray[aryCount++] = new String(contains_sn);
        commandArray[aryCount++] = new String(contains_sn);
        commandArray[aryCount++] = new String(contains_sn);
    }

    if (meta_id != 0) {
        queryText += " and (send.meta_id = ? or rec.meta_id = ?)";
    }

    queryText += " order by message_date, message_id";

    pstmt = conn.prepareStatement(queryText);

    for(int i = 0; i < aryCount; i++) {
        pstmt.setString(i + 1, commandArray[i]);
    }

    if(meta_id != 0) {
        pstmt.setInt(aryCount + 1, meta_id);
        pstmt.setInt(aryCount + 2, meta_id);
    }

    rset = pstmt.executeQuery();

    if (!rset.isBeforeFirst()) {
        out.print("<div align=\"center\"><i>No records found.</i></div>\n");
    }

    ArrayList userArray = new java.util.ArrayList();
    String colorArray[] =
    {"red","blue","green","purple","black","orange", "teal"};
    String sent_color = new String();
    String received_color = new String();
    String user = new String();
    String prevSender, prevRecipient;
    prevSender = new String();
    prevRecipient = new String();

    int cntr = 1;
    Date currentDate = null;
    Timestamp currentTime = new Timestamp(0);
    while (rset.next()) {
        if(!rset.getDate("message_date").equals(currentDate)) {
            currentDate = rset.getDate("message_date");
            prevSender = "";
            prevRecipient = "";

            out.println("<div class=\"dateHeader\">");
            out.println(rset.getString("fancy_date"));
            out.println("</div>\n");
        } else if (rset.getTimestamp("message_date").getTime() -
            currentTime.getTime() > 60*10*1000) {
            out.println("<hr width=\"75%\">");
        }

        currentTime = rset.getTimestamp("message_date");

        sent_color = null;
        received_color = null;
        String message = rset.getString("message");

        for(int i = 0; i < userArray.size(); i++) {
            if (!showMeta &&
                    userArray.get(i).equals(rset.getString("sender_sn"))) {
                sent_color = colorArray[i % colorArray.length];
            } else if (showMeta &&
                    userArray.get(i).equals(rset.getString("sender_meta"))) {
                sent_color = colorArray[i % colorArray.length];
            }
        }

        if (sent_color == null) {
            sent_color = colorArray[userArray.size() % colorArray.length];
            if(!showMeta) {
                userArray.add(rset.getString("sender_sn"));
            } else {
                userArray.add(rset.getString("sender_meta"));
            }
        }

        for(int i = 0; i < userArray.size(); i++) {
            if (!showMeta &&
                    userArray.get(i).equals(rset.getString("recipient_sn"))) {
                received_color = colorArray[i % colorArray.length];
            } else if (showMeta &&
                    userArray.get(i).equals(rset.getString("recipient_meta"))) {
                received_color = colorArray[i % colorArray.length];
            }
        }

        if (received_color == null) {
            received_color = colorArray[userArray.size() % colorArray.length];
            if(!showMeta) {
                userArray.add(rset.getString("recipient_sn"));
            } else {
                userArray.add(rset.getString("recipient_meta"));
            }
        }

        message = message.replaceAll("\r|\n", "<br />");
        message = message.replaceAll("   ", " &nbsp; ");

        out.println("(" + rset.getTime("message_date") + ")&nbsp;");

        out.print("<a href=\"#\"");

        out.print("title=\"" + rset.getString("sender_sn") + "\">");

        out.print("<span style=\"color: " + sent_color + "\">");
        if(showDisplay) {
            out.print(rset.getString("sender_display"));
        } else if (showMeta) {
            out.print(rset.getString("sender_meta"));
        } else {
            out.print(rset.getString("sender_sn"));
        }

        if(to_sn == null || from_sn == null) {
        out.println("</span></a>\n");
            out.println("&rarr;");

            out.println("<a href=\"#\" title=\"" +
                rset.getString("recipient_sn") + "\">");

            out.print("<span style=\"color: " +
            received_color + "\">");
            if(showDisplay) {
                out.print(rset.getString("recipient_display"));
            } else if (showMeta) {
                out.print(rset.getString("recipient_meta"));
            } else {
                out.print(rset.getString("recipient_sn"));
            }
        }

        out.println("</span></a>:&nbsp;" + message);

        if(rset.getBoolean("notes")) {
            pstmt = conn.prepareStatement("select title, notes " +
            " from adium.message_notes where message_id = ? " +
            " order by date_added ");

            pstmt.setInt(1, rset.getInt("message_id"));
            noteSet = pstmt.executeQuery();

            out.print("<span style=\"color:black; background-color: yellow\">");

            while(noteSet.next()) {
                out.print("(<b>" + noteSet.getString("title") + "</b> " +
                    noteSet.getString("notes") + ") ");
            }
            out.print("</span>");

        }

        out.println("</p>\n");

    }

}catch(SQLException e) {
    out.print("<br /><span style=\"color: red\">" + e.getMessage() + "</span>");
    out.print("<br /><br />" + queryText);
} finally {
    pstmt.close();
    conn.close();
}
%>
</body>
</html>
