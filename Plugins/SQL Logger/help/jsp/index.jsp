<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.sql.*' %>
<%@ page import = 'javax.naming.*' %>
<%@ page import = 'java.util.ArrayList' %>
<%@ page import = 'java.util.Vector' %>
<%@ page import = 'java.util.StringTokenizer' %>
<%@ page import = 'java.util.regex.Pattern' %>
<%@ page import = 'java.util.regex.Matcher' %>
<%@ page import = 'java.net.URLEncoder' %>
<%@ page import = 'sqllogger.*' %>
<%@ page import = 'java.util.Enumeration' %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<!--$URL: http://svn.visualdistortion.org/repos/projects/sqllogger/jsp/index.jsp $-->
<!--$Rev: 909 $ $Date$ -->

<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();

String dateStart, dateFinish, from_sn, to_sn, contains_sn, hl, service;
boolean showDisplay = true;
boolean showMeta = false;

Date today = new Date(System.currentTimeMillis());
int chat_id = 0;
int meta_id = 0;
int message_id = 0;
int bTime = 15;
int aTime = 45;

String formURL = new String("saveForm.jsp?action=saveChat.jsp");

dateFinish = request.getParameter("finish");
dateStart = request.getParameter("start");
from_sn = request.getParameter("from");
to_sn = request.getParameter("to");
contains_sn = request.getParameter("contains");
String screenDisplayMeta = request.getParameter("screen_or_display");
hl = request.getParameter("hl");
service = request.getParameter("service");
ArrayList hlWords = new ArrayList();

String title = new String("");
String notes = new String("");

try {
    chat_id = Integer.parseInt(request.getParameter("chat_id"));
} catch (NumberFormatException e) {
    chat_id = 0;
}

if (dateFinish != null && (dateFinish.equals("") || dateFinish.equals("null"))) {
    dateFinish = null;
} else if (dateFinish != null) {
    formURL += "&amp;dateFinish=" + dateFinish;
}


if (dateStart != null && (dateStart.equals("") || dateStart.startsWith("null"))) {
    dateStart = null;
} else if (dateStart != null) {
    formURL += "&amp;dateStart=" + dateStart;
} else if (dateStart == null ) {
    formURL += "&amp;dateStart=" + today.toString();
}

if (from_sn != null && from_sn.equals("")) {
    from_sn = null;
} else if(from_sn != null) {
    formURL += "&amp;sender=" + from_sn;
}

if (to_sn != null && to_sn.equals("")) {
    to_sn = null;
} else if(to_sn != null ) {
    formURL += "&amp;recipient=" + to_sn;
}

if (contains_sn != null && contains_sn.equals("")) {
    contains_sn = null;
} else if(contains_sn != null) {
    formURL += "&amp;single_sn=" + contains_sn;
}

if (hl != null && hl.equals("")) {
    hl = null;
} else if (hl != null) {
    hl = hl.trim();
    StringTokenizer st = new StringTokenizer(hl, " ");
    while (st.hasMoreTokens()) {
        hlWords.add(st.nextToken());
    }
}

if(service != null && service.equals("0")) {
    service = null;
} else if (service != null) {
    formURL += "&amp;service=" + service;
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
        formURL += "&amp;meta_id=" + meta_id;
    }
} catch (NumberFormatException e) {
    meta_id = 0;
}

try {
    message_id = Integer.parseInt(request.getParameter("message_id"));
} catch (NumberFormatException e) {
    message_id = 0;
}

try {
    bTime = Integer.parseInt(request.getParameter("time"));
    aTime = Integer.parseInt(request.getParameter("time"));
} catch (NumberFormatException e) {
    bTime = 10;
    aTime = 45;
}

String hlColor[] = {"#ff6","#a0ffff", "#9f9", "#f99", "#f69"};

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
        title = "SQL Logger";
    }

    if(message_id != 0) {
        pstmt = conn.prepareStatement("select message_date + '" + aTime + " minutes'::interval as finish, message_date - '" + bTime + " minutes'::interval as start from messages where message_id = ?");

        pstmt.setInt(1, message_id);

        rset = pstmt.executeQuery();

        if(rset.next()) {
            dateStart = rset.getString("start");
            dateFinish = rset.getString("finish");
        }
    }

%>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>SQL Logger: Message Viewer</title>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1" />
<link rel="stylesheet" type="text/css" href="styles/layout.css" />
<link rel="stylesheet" type="text/css" href="styles/default.css" />
<link rel="stylesheet" type="text/css" href="styles/message.css" />
<script lanaguage = "JavaScript">
    window.name='viewer';
</script>
<script language="JavaScript" src="calendar.js"></script>
</head>
<body>
    <div id="container">
        <div id="header">
        </div>
        <div id="banner">
            <div id="bannerTitle">
                <img class="adiumIcon" src="images/adiumy/green.png" width="128" height="128" border="0" alt="Adium X Icon" />
                <div class="text">
                    <h1><%= title %></h1>
                    <p><%= notes %></p>
                </div>
            </div>
        </div>
        <div id="central">
            <div id="navcontainer">
                <ul id="navlist">
                    <li><span id="current">Viewer</span></li>
                    <li><a href="search.jsp">Search</a></li>
                    <li><a href="users.jsp">Users</a></li>
                    <li><a href="meta.jsp">Meta-Contacts</a></li>
                    <li><a href="chats.jsp">Chats</a></li>
                    <li><a href="statistics.jsp">Statistics</a></li>
                    <li><a href="query.jsp">Query</a></li>
                </ul>
            </div>
            <div id="sidebar-a">
    <%
    if (hl != null) {
        out.print("<h1>Search Words</h1>");
        out.println("<div class=\"boxThinTop\"></div>\n");
        out.println("<div class=\"boxThinContent\">");
        for (int i = 0; i < hlWords.size(); i++) {
            out.print("<p><b style=\"color:black;" +
                "background-color:" + hlColor[i % hlColor.length] +
                "\">" + hlWords.get(i).toString() + "</b></p>\n");
        }
        out.println("</div>\n");
        out.println("<div class=\"boxThinBottom\"></div>\n");
    }


    out.println("<h1>Users</h1>");
    out.println("<div class=\"boxThinTop\"></div>\n");
    out.println("<div class=\"boxThinContent\">");

    try {

        Vector userVec = User.getUsersForInterval(conn, dateStart, dateFinish);
        Enumeration e = userVec.elements();

        while(e.hasMoreElements()) {
            User u = (User) e.nextElement();
            out.print("<p>" +
                "<a href=\"index.jsp?start=" + dateStart +
                "&finish=" + dateFinish + "&service=" +
                u.getValue("service") + "\">" +
                "<img src=\"images/services/" +
                u.getValue("service").toLowerCase() +
                ".png\" width=\"12\" height=\"12\" /></a> " +
                "<a href=\"index.jsp?start=" + dateStart +
                "&finish=" + dateFinish + "&contains=" +
                u.getValue("username") + "\">"+
                u.getValue("username") + "</a></p>\n");
        }

        out.print("<a href=\"index.jsp?start=" + dateStart +
            "&finish=" + dateFinish + "\"><i>All</i></a>");
    } catch (UserException e) {
        out.print("<span style=\"color: red\">" + e.getMessage() + "</span>");
    }

    out.println("</div>\n");
    out.println("<div class=\"boxThinBottom\"></div>\n");

    out.println("<h1>Saved Chats</h1>");
    out.println("<div class=\"boxThinTop\"></div>\n");
    out.println("<div class=\"boxThinContent\">");

    pstmt = conn.prepareStatement("select chat_id, title from im.saved_chats");

    rset = pstmt.executeQuery();

    while(rset.next()) {
        out.println("<p><a href=\"index.jsp?chat_id=" + rset.getInt("chat_id") +
            "\">" + rset.getString("title") + "</a></p>");
    }
    out.println("<p></p>");
    %>
        <p><a href="#"
                onClick="window.open('<%= formURL %>', 'Save Chat', 'width=275,height=225')">
                Save Chat ...
            </a></p>
    <%
    out.println("</div>\n");
    out.println("<div class=\"boxThinBottom\"></div>\n");

%>

<%
    out.println("<h1>Links</h1>");
    out.println("<div class=\"boxThinTop\"></div>\n");
    out.println("<div class=\"boxThinContent\">");
%>

                <p><a href="#"
                onClick="window.open('urls.jsp?start=<% if(dateStart != null) out.print(dateStart); else out.print(today); %>&finish=<%= dateFinish %>', 'Save Chat', 'width=640,height=480')">Recent Links</a></p>
<%
    String safeTo = to_sn;
    if(safeTo == null) {
        safeTo = "";
    }

    String safeFrom = from_sn;
    if(safeFrom == null) {
        safeFrom = "";
    }

    String safeCont = contains_sn;
    if(safeCont == null) {
        safeCont = "";
    }
%>
                <p><a href="#"
                onClick="window.open('simpleViewer.jsp?start=<% if(dateStart != null) out.print(dateStart); else out.print(today); %>&finish=<%= dateFinish %>&from=<%= URLEncoder.encode(safeFrom, "UTF-8")  %>&to=<%= URLEncoder.encode(safeTo, "UTF-8")  %>&contains=<%= URLEncoder.encode(safeCont, "UTF-8") %>&screen_or_display=<%= screenDisplayMeta %>&meta_id=<%=meta_id%>&chat_id=<%=chat_id%>', 'Save Chat', 'width=640,height=480')">Simple Message View</a></p>
<%
    out.println("</div>\n");
    out.println("<div class=\"boxThinBottom\"></div>\n");
%>
            </div>
            <div id="content">

            <h1>View Messages by Date</h1>

            <div class="boxWideTop"></div>
            <div class="boxWideContent">
            <form action="index.jsp" method="get" name="control">
                <table border="0" cellpadding="3" cellspacing="0">
                <tr>
                    <td align="right">
                        <label for="from">Sent SN: </label></td>
                    <td>
                        <input type="text" name="from" <% if(from_sn != null)
                        out.print("value=\"" + from_sn + "\""); %> id="from" />
                    </td>
                </tr>
                <tr>
                <tr>
                    <td align="right"><label for="to"">Received SN: </label></td>
                    <td><input type="text" name="to" <% if (to_sn != null)
                        out.print("value=\"" + to_sn + "\""); %> id="to" />
                    </td>
                </tr>
                <tr>
                    <td align="right">
                        <label for="contains">Single SN:</label>
                    </td>
                    <td>
                        <input type="text" name="contains" <% if (contains_sn != null)
                        out.print("value=\"" + contains_sn + "\""); %>
                        id = "contains" />
                    </td>
                </tr>
                <tr>
                    <td align="right">
                        <label for="service">Service:</label>
                    </td>
                    <td>
                        <select name="service" id="service">
                            <option value="0">Choose One</option>
<%
    pstmt = conn.prepareStatement("select distinct service from users");
    rset = pstmt.executeQuery();
    while(rset.next()) {
        out.print("<option value=\"" + rset.getString("service") + "\"" );
        if(rset.getString("service").equals(service)) {
            out.print(" selected=\"selected\"");
        }
        out.print(">" + rset.getString("service") + "</option>\n");
    }
%>
                        </select>
                    </td>
                </tr>
                <tr>
                    <td align="right">
                        <label for="meta">Meta Contact:</label>
                    </td>
                    <td>
                        <select name="meta_id">
                            <option value=\"0\">Choose One</option>
<%
    pstmt = conn.prepareStatement("select meta_id, name from im.meta_container order by name");

    rset = pstmt.executeQuery();

    while(rset.next()) {
        out.print("<option value=\"" + rset.getInt("meta_id") + "\"");
        if(rset.getInt("meta_id") == meta_id) {
            out.print(" selected=\"selected\"");
        }
        out.print(" >" + rset.getString("name") + "</option>\n");
    }
%>
                        </select>
                    </td>
                </tr>
                <tr>
                    <td align="right"><label for="start_date">Date Range: </label></td>
                <td><input type="text" name="start" <% if (dateStart != null)
                out.print("value=\"" + dateStart + "\""); else
                out.print("value=\"" + today.toString() + " 00:00:00\"");%>
                id="start_date" />
                <a href="javascript:show_calendar('control.start');"
                    onmouseover="window.status='Date Picker';return true;"
                    onmouseout="window.status='';return true;">
                <img src="images/calicon.jpg" border=0></a>

                <label for="finish_date">&nbsp;--&nbsp;</label>
                <input type="text" name="finish" <% if (dateFinish != null)
                out.print("value=\"" + dateFinish + "\""); %> id="finish_date" />
                <a href="javascript:show_calendar('control.finish');"
                    onmouseover="window.status='Date Picker';return true;"
                    onmouseout="window.status='';return true;">
                    <img src="images/calicon.jpg" border=0></a>
                    </td>
                </tr>
                <tr>
                    <td>
                    </td>
                    <td valign="top">
                        <p><i>(YYYY-MM-DD hh:mm:ss)</i></p>
                    </td>
                </tr>
                </table>

                <input type="radio" name="screen_or_display" value
                = "screen" id = "sn" <% if (!showDisplay && !showMeta)
                out.print("checked=\"true\""); %> />
                    <label for="sn">Show Screename</label><br />
                <input type="radio" name="screen_or_display"
                value="display" id="disp" <% if (showDisplay)
                out.print("checked=\"true\""); %> />
                <label for="disp">Show Alias/Display Name</label>
               <br />
                <input type="radio" name="screen_or_display" value="meta" id="meta" <% if (showMeta) out.print("checked=\"true\""); %> />
                    <label for="meta">Show Meta Contact</label><br /><br />

                <span style="float: right">
                    <input type="reset" /><input type="submit" />
                </span>
                </form>
            </div>
            <div class="boxWideBottom"></div>

            <h1>Messages</h1>
                <div class="boxWideTop"></div>
                <div class="boxWideContent">
<%
    Vector messageVec = new Vector();
    try {
        messageVec = Message.getMessagesForInterval(conn,
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

    String currentDate = new String();
    Timestamp currentTime = new Timestamp(0);

    int greyCount = 1;

    Enumeration e = messageVec.elements();

    while (e.hasMoreElements()) {
        Message m = (Message) e.nextElement();

        if(!m.getValue("message_date").equals(currentDate)) {
            currentDate = m.getValue("message_date");
            prevSender = "";
            prevRecipient = "";

            out.println("<div class=\"weblogDateHeader\">");
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

        for (int i = 0; i < hlWords.size(); i++) {

            Pattern p = Pattern.compile("(?i)(.*?)(" +
            hlWords.get(i).toString() + ")(.*?)");
            Matcher match = p.matcher(message);
            StringBuffer sb = new StringBuffer();
            int oldIndex = 0;
            while(match.find()) {
                sb.append(message.substring(oldIndex,match.start()));
                if(sb.toString().lastIndexOf('<') <=
                  sb.toString().lastIndexOf('>')) {
                    sb.append(match.group(1) +
                    "<b style=\"color:black;background-color:" +
                    hlColor[i % hlColor.length] + "\">");
                    sb.append(match.group(2) + "</b>" + match.group(3));
                } else {
                    sb.append(match.group(1) + match.group(2) +
                            match.group(3));
                }
                oldIndex = match.end();
            }
            sb.append(message.substring(oldIndex, message.length()));

            message = sb.toString();
        }

        if(!m.getValue("sender_sn").equals(prevSender) ||
            !m.getValue("recipient_sn").equals(prevRecipient)) {

            greyCount = 1;

            out.print("<div class=\"message_container\" id=\""
                + m.getValue("message_id") + "\">");

            out.println("<div class=\"sender\">");
            out.print("<a href=\"index.jsp?from=" +
            m.getValue("sender_sn") +
            "&to=" + m.getValue("recipient_sn") +
            "&start=" + dateStart +
            "&finish=" + dateFinish + "#" + m.getValue("message_id") + "\" ");

            out.print("title=\"" + m.getValue("sender_sn") + "\">");

            out.print("<span style=\"color: " + sent_color + "\">");
            if(showDisplay) {
                out.print(m.getValue("sender_display").replaceAll("<", "&lt;").replaceAll(">", "&gt;"));
            } else if (showMeta) {
                out.print(m.getValue("sender_meta").replaceAll("<", "&lt;").replaceAll(">", "&gt;"));
            } else {
                out.print(m.getValue("sender_sn").replaceAll("<", "&lt;").replaceAll(">", "&gt;"));
            }
            out.print("</span></a>\n");

            if(to_sn == null || from_sn == null) {
                out.println("&rarr;");

                out.println("<a href=\"index.jsp?from=" +
                m.getValue("sender_sn") +
                    "&to=" + m.getValue("recipient_sn") +
                    "&start=" + dateStart +
                    "&finish=" + dateFinish +
                    "#" + m.getValue("message_id") +
                    "\" title=\"" + m.getValue("recipient_sn") + "\">");

                out.print("<span style=\"color: " +
                received_color + "\">");
                if(showDisplay) {
                    out.print(m.getValue("recipient_display").replaceAll("<", "&lt;").replaceAll(">", "&gt;"));
                } else if (showMeta) {
                    out.print(m.getValue("recipient_meta").replaceAll("<", "&lt;").replaceAll(">", "&gt;"));
                } else {
                    out.print(m.getValue("recipient_sn").replaceAll("<", "&lt;").replaceAll(">", "&gt;"));
                }
                out.print("</span></a>");
            }
            out.println("</div>\n\n");
        } else {
            out.println("<div class=\"msg_container_next\">\n");
        }

        prevSender = m.getValue("sender_sn");
        prevRecipient = m.getValue("recipient_sn");

        out.println("<div class=\"time_initial\">");
        if(m.getValue("notes").equals("t")) {
            pstmt = conn.prepareStatement("select title, notes " +
            " from im.message_notes where message_id = ? " +
            " order by date_added ");

            pstmt.setInt(1, Integer.parseInt(m.getValue("message_id")));
            noteSet = pstmt.executeQuery();

            out.print("<a class=\"info\" href=\"#\">");
            out.print("<img src=\"images/note.png\"><span>");

            while(noteSet.next()) {
                out.print("<p><b>" + noteSet.getString("title") + "</b><br />" +
                    noteSet.getString("notes") + "</p>");
            }
            out.print("</span></a>");

        }
        out.println("<a href=\"#\" title=\"Add Note ...\" " +
            "onClick=\"window.open('saveForm.jsp?action=saveNote.jsp&message_id=" +
            m.getValue("message_id") + "', 'Add Note', "+
            "'width=275,height=225')\">");

        out.print("<img src=\"images/note_add.png\" alt=\"Add Note\"></a>");

        out.print(m.getValue("message_time"));
        out.println("</div>\n");

        out.println("<div class=\"message\"><p " +
                (greyCount++ % 2 == 0 ? "class=\"even\"" :
                 "class=\"odd\"") + ">");
        out.println(message);
        out.println("</p></div>\n");

        out.println("</div>\n");
    }

}catch(SQLException e) {
    out.print("<br /><span style=\"color: red\">" + e.getMessage() + "</span>");
    out.print("<br /><br />" + queryText);
} finally {
    pstmt.close();
    conn.close();
}
%>
                </div>
                <div class="boxWideBottom"></div>
            </div>
            <div id="bottom">
                <div class="cleanHackBoth"> </div>
            </div>
        </div>
        <div id="footer">&nbsp;</div>
    </div>
</body>
</html>
