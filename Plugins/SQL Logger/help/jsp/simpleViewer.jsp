<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.sql.*' %>
<%@ page import = 'javax.naming.*' %>
<%@ page import = 'java.util.ArrayList' %>
<%@ page import = 'java.util.Vector' %>
<%@ page import = 'java.util.Enumeration' %>
<%@ page import = 'sqllogger.*' %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<!--$URL: http://svn.visualdistortion.org/repos/projects/sqllogger/jsp/simpleViewer.jsp $-->
<!--$Rev: 909 $ $Date$ -->

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
String service = request.getParameter("service");

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
        pstmt = conn.prepareStatement("select title, notes, sent_sn, received_sn, single_sn, date_start, date_finish, meta_id from im.saved_chats where chat_id = ?");

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
        title = "Message Viewer";
    }
%>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>SQL Logger: <%= title %></title>
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

.even {
    background: #dddddd;
}

.odd {
    background: #ffffff;
}

</style>
</head>
<body>
<%
    Vector messageVec = new Vector();
    try {
        messageVec  = Message.getMessagesForInterval(conn,
            dateStart, dateFinish,
            from_sn, to_sn, contains_sn, service,
            meta_id, showDisplay, showMeta);
    } catch (MessageException e) {
        out.println(e.getMessage());
    }

    if (messageVec.size() == 0) {
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
    String currentDate = new String();
    Timestamp currentTime = new Timestamp(0);

    Enumeration e = messageVec.elements();
    int count = 0;
    while (e.hasMoreElements()) {
        count++;
        Message m = (Message) e.nextElement();

        if(!m.getValue("message_date").equals(currentDate)) {
            currentDate = m.getValue("message_date");
            prevSender = "";
            prevRecipient = "";

            out.println("<div class=\"dateHeader\">");
            out.println(m.getValue("fancy_date"));
            out.println("</div>\n");
        } else if (Timestamp.valueOf(m.getValue("message_timestamp")).getTime() -
            currentTime.getTime() > 60*10*1000) {
            out.println("<hr width=\"75%\">");
        }

        currentTime = Timestamp.valueOf(m.getValue("message_timestamp"));

        sent_color = null;
        received_color = null;
        String message = m.getValue("message");

        for(int i = 0; i < userArray.size(); i++) {
            if (!showMeta &&
                    userArray.get(i).equals(m.getValue("sender_sn"))) {
                sent_color = colorArray[i % colorArray.length];
            } else if (showMeta &&
                    userArray.get(i).equals(m.getValue("sender_meta"))) {
                sent_color = colorArray[i % colorArray.length];
            }
        }

        if (sent_color == null) {
            sent_color = colorArray[userArray.size() % colorArray.length];
            if(!showMeta) {
                userArray.add(m.getValue("sender_sn"));
            } else {
                userArray.add(m.getValue("sender_meta"));
            }
        }

        for(int i = 0; i < userArray.size(); i++) {
            if (!showMeta &&
                    userArray.get(i).equals(m.getValue("recipient_sn"))) {
                received_color = colorArray[i % colorArray.length];
            } else if (showMeta &&
                    userArray.get(i).equals(m.getValue("recipient_meta"))) {
                received_color = colorArray[i % colorArray.length];
            }
        }

        if (received_color == null) {
            received_color = colorArray[userArray.size() % colorArray.length];
            if(!showMeta) {
                userArray.add(m.getValue("recipient_sn"));
            } else {
                userArray.add(m.getValue("recipient_meta"));
            }
        }

        message = message.replaceAll("\r|\n", "<br />");
        message = message.replaceAll("   ", " &nbsp; ");

        out.println("<p id=\"" + m.getValue("message_id") + "\"" +
                (count % 2 == 0 ? " class=\"even\"" : " class=\"odd\"") +
                 ">(" + m.getValue("message_date") + ")&nbsp;");

        out.print("<a href=\"simpleViewer.jsp?from=" +
            m.getValue("sender_sn") +
            "&to=" + m.getValue("recipient_sn") +
            "&start=" + dateStart +
            "&finish=" + dateFinish + "#" + m.getValue("message_id") + "\" ");

        out.print("title=\"" + m.getValue("sender_sn") + "\">");

        out.print("<span style=\"color: " + sent_color + "\">");
        if(showDisplay) {
            out.print(m.getValue("sender_display"));
        } else if (showMeta) {
            out.print(m.getValue("sender_meta"));
        } else {
            out.print(m.getValue("sender_sn"));
        }

        if(to_sn == null || from_sn == null) {
        out.println("</span></a>\n");
            out.println("&rarr;");

            out.println("<a href=\"#\" title=\"" +
                m.getValue("recipient_sn") + "\">");

            out.print("<span style=\"color: " +
            received_color + "\">");
            if(showDisplay) {
                out.print(m.getValue("recipient_display"));
            } else if (showMeta) {
                out.print(m.getValue("recipient_meta"));
            } else {
                out.print(m.getValue("recipient_sn"));
            }
        }

        out.println("</span></a>:&nbsp;" + message);

        if(m.getValue("notes").equals("t")) {
            pstmt = conn.prepareStatement("select title, notes " +
            " from im.message_notes where message_id = ? " +
            " order by date_added ");

            pstmt.setInt(1, Integer.parseInt(m.getValue("message_id")));
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
    conn.close();
}
%>
</body>
</html>
