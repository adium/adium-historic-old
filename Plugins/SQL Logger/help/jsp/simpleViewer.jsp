<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.sql.*' %>
<%@ page import = 'javax.naming.*' %>
<%@ page import = 'java.util.ArrayList' %>
<%@ page import = 'java.io.File' %>
<%@ page import = 'org.slamb.axamol.library.*' %>
<%@ page import = 'java.util.Map' %>
<%@ page import = 'java.util.HashMap' %>
<%@ page import = 'sqllogger.*' %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<!--$URL: http://svn.visualdistortion.org/repos/projects/sqllogger/jsp/simpleViewer.jsp $-->
<!--$Rev: 922 $ $Date$ -->

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

dateFinish = Util.checkNull(request.getParameter("finish"));
dateStart = Util.checkNull(request.getParameter("start"));
from_sn = Util.checkNull(request.getParameter("from"));
to_sn = Util.checkNull(request.getParameter("to"));
contains_sn = Util.checkNull(request.getParameter("contains"));
String screenDisplayMeta = Util.checkNull(request.getParameter("screen_or_display"));
String service = Util.checkNull(request.getParameter("service"));

String title = new String("");
String notes = new String("");

chat_id = Util.checkInt(request.getParameter("chat_id"));

if(screenDisplayMeta != null && screenDisplayMeta.equals("screen")) {
    showDisplay = false;
} else if (screenDisplayMeta != null && screenDisplayMeta.equals("meta")) {
    showMeta = true;
    showDisplay = false;
}

meta_id = Util.checkInt(request.getParameter("meta_id"));
if(meta_id != 0) {
    showMeta = true;
    showDisplay = false;
}

ResultSet rset = null;
ResultSet noteSet = null;

File queryFile = new File(session.getServletContext().getRealPath("queries/standard.xml"));
LibraryConnection lc = new LibraryConnection(queryFile, conn);
Map paramMap = new HashMap();
try {

    if(chat_id != 0) {

        paramMap.put("chat_id", new Integer(chat_id));
        rset = lc.executeQuery("saved_chat", paramMap);

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
    boolean unconstrained = false;

    if(dateStart != null && dateFinish == null) unconstrained = true;

    if(unconstrained) {
        out.print("<div align=\"center\"><i>Limited to 250 " +
        "messages.</i><br><br></div>\n");
    }

    paramMap.put("startDate", dateStart);
    paramMap.put("endDate", dateFinish);
    paramMap.put("sendSN", from_sn);
    paramMap.put("recSN", to_sn);
    paramMap.put("containsSN", contains_sn);
    paramMap.put("service", service);
    paramMap.put("meta_id", new Integer(meta_id));

    if(unconstrained) paramMap.put("limit", new Integer(250));
    else paramMap.put("limit", new Integer(1000000000));

    if(showDisplay)
        rset = lc.executeQuery("message_span_display", paramMap);
    else
        rset = lc.executeQuery("message_span_meta", paramMap);

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

        out.println("<p" +
                (rset.getRow() % 2 == 0 ? " class=\"even\"" : " class=\"odd\"") +
                 ">(" + rset.getTime("message_date") + ")&nbsp;");

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

            paramMap.put("message_id", new Integer(rset.getInt("message_id")));
            noteSet = lc.executeQuery("message_notes", paramMap);

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
} finally {
    lc.close();
    conn.close();
}
%>
</body>
</html>
