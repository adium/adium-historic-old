<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.sql.*' %>
<%@ page import = 'javax.naming.*' %>
<%@ page import = 'java.util.ArrayList' %>
<%@ page import = 'java.util.StringTokenizer' %>
<%@ page import = 'java.util.regex.Pattern' %>
<%@ page import = 'java.util.regex.Matcher' %>
<%@ page import = 'java.net.URLEncoder' %>
<%@ page import = 'org.slamb.axamol.library.*' %>
<%@ page import = 'java.io.File' %>
<%@ page import = 'java.util.Map' %>
<%@ page import = 'java.util.HashMap' %>
<%@ page import = 'sqllogger.*' %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<!--$URL: http://svn.visualdistortion.org/repos/projects/sqllogger/jsp/index.jsp $-->
<!--$Rev: 922 $ $Date$ -->

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

dateFinish = Util.checkNull(request.getParameter("finish"));
dateStart = Util.checkNull(request.getParameter("start"));
from_sn = Util.checkNull(request.getParameter("from"), false);
to_sn = Util.checkNull(request.getParameter("to"), false);
contains_sn = Util.checkNull(request.getParameter("contains"), false);
String screenDisplayMeta = Util.checkNull(request.getParameter("screen_or_display"));
hl = Util.checkNull(request.getParameter("hl"));
service = Util.checkNull(request.getParameter("service"));
meta_id = Util.checkInt(request.getParameter("meta_id"));
bTime = Util.checkInt(request.getParameter("time"), 10);
aTime = Util.checkInt(request.getParameter("time"), 45);

ArrayList hlWords = new ArrayList();

String title = new String("");
String notes = new String("");

chat_id = Util.checkInt(request.getParameter("chat_id"));

formURL += "&amp;dateFinish=" + Util.safeString(dateFinish);
formURL += "&amp;dateStart=" + Util.safeString(dateStart, today.toString());
formURL += "&amp;sender=" + Util.safeString(from_sn);
formURL += "&amp;recipient=" + Util.safeString(to_sn);
formURL += "&amp;single_sn=" + Util.safeString(contains_sn);
formURL += "&amp;service=" + service;
formURL += "&amp;meta_id=" + meta_id;

if (hl != null) {
    hl = hl.trim();
    StringTokenizer st = new StringTokenizer(hl, " ");
    while (st.hasMoreTokens()) {
        hlWords.add(st.nextToken());
    }
}

if(screenDisplayMeta != null && screenDisplayMeta.equals("screen")) {
    showDisplay = false;
} else if (screenDisplayMeta != null && screenDisplayMeta.equals("meta")) {
    showMeta = true;
    showDisplay = false;
}

if(meta_id != 0) {
    showMeta = true;
    showDisplay = false;
}

String hlColor[] = {"#ff6","#a0ffff", "#9f9", "#f99", "#f69"};

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
        title = "SQL Logger";
    }

    if(message_id != 0) {
        paramMap.put("afterTime", new Integer(aTime));
        paramMap.put("beforeTime", new Integer(bTime));
        paramMap.put("message_id", new Integer(message_id));

        rset = lc.executeQuery("message_times", paramMap);

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
                <img class="adiumIcon" src="images/headlines/index.png" width="128" height="128" border="0" alt="SQL Logger: Viewer" />
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
    boolean unconstrained = false;

    if(dateStart != null && dateFinish == null) unconstrained = true;

    if(unconstrained) {
        out.print("<div align=\"center\"><i>Limited to 250 " +
        "messages.</i><br><br></div>\n");
    }

    out.println("<h1>Users</h1>");
    out.println("<div class=\"boxThinTop\"></div>\n");
    out.println("<div class=\"boxThinContent\">");

    try {
        paramMap.put("startDate", dateStart);
        paramMap.put("endDate", dateFinish);

        rset = lc.executeQuery("date_range_users", paramMap);

        while(rset.next()) {
            out.print("<p>" +
                "<a href=\"index.jsp?start=" + Util.safeString(dateStart) +
                "&finish=" + Util.safeString(dateFinish) + "&service=" +
                rset.getString("service") + "\">" +
                "<img src=\"images/services/" +
                rset.getString("service").toLowerCase() +
                ".png\" width=\"12\" height=\"12\" /></a> " +
                "<a href=\"index.jsp?start=" + Util.safeString(dateStart) +
                "&finish=" + Util.safeString(dateFinish) + "&contains=" +
                rset.getString("username") + "\">"+
                rset.getString("username") + "</a></p>\n");
        }

        out.print("<a href=\"index.jsp?start=" + Util.safeString(dateStart) +
            "&finish=" + Util.safeString(dateFinish) + "\"><i>All</i></a>");
    } catch (SQLException e) {
        out.print("<span style=\"color: red\">" + e.getMessage() + "</span>");
    }

    out.println("</div>\n");
    out.println("<div class=\"boxThinBottom\"></div>\n");

    out.println("<h1>Saved Chats</h1>");
    out.println("<div class=\"boxThinTop\"></div>\n");
    out.println("<div class=\"boxThinContent\">");

    rset = lc.executeQuery("saved_chats_list", paramMap);

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
                onClick="window.open('urls.jsp?start=<%=Util.safeString(dateStart, today.toString()) %>&finish=<%= Util.safeString(dateFinish) %>', 'Save Chat', 'width=640,height=480')">Recent Links</a></p>

                <p><a href="#"
                onClick="window.open('simpleViewer.jsp?start=<%= Util.safeString(dateStart, today.toString()) %>&finish=<%= Util.safeString(dateFinish) %>&from=<%= URLEncoder.encode(Util.safeString(from_sn), "UTF-8")  %>&to=<%= URLEncoder.encode(Util.safeString(to_sn), "UTF-8")  %>&contains=<%= URLEncoder.encode(Util.safeString(contains_sn), "UTF-8") %>&screen_or_display=<%= screenDisplayMeta %>&meta_id=<%=meta_id%>&chat_id=<%=chat_id%>', 'Save Chat', 'width=640,height=480')">Simple Message View</a></p>
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
                        <input type="text" name="from"
                            value="<%= Util.safeString(from_sn) %>" id="from" />
                    </td>
                </tr>
                <tr>
                <tr>
                    <td align="right"><label for="to">Received SN: </label></td>
                    <td><input type="text" name="to" value="<%= Util.safeString(to_sn) %>" id="to" />
                    </td>
                </tr>
                <tr>
                    <td align="right">
                        <label for="contains">Single SN:</label>
                    </td>
                    <td>
                        <input type="text" name="contains"
                            value="<%= Util.safeString(contains_sn)  %>"
                            id = "contains" />
                    </td>
                </tr>
                <tr>
                    <td align="right">
                        <label for="service">Service:</label>
                    </td>
                    <td>
                        <select name="service" id="service">
                            <option value="null">Choose One</option>
<%

    rset = lc.executeQuery("distinct_services", paramMap);

    while(rset.next()) {
        out.print("<option value=\"" + rset.getString("service") + "\"" );
        out.print(Util.compare(rset.getString("service"),
                    service, " selected=\"selected\""));
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

    rset = lc.executeQuery("meta_contacts", paramMap);

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
                <td><input type="text" name="start" value="<%=
                Util.safeString(dateStart, today.toString() + " 00:00:00\"")
                %>" id="start_date" />
                <a href="javascript:show_calendar('control.start');"
                    onmouseover="window.status='Date Picker';return true;"
                    onmouseout="window.status='';return true;">
                <img src="images/calicon.jpg" border=0></a>

                <label for="finish_date">&nbsp;--&nbsp;</label>
                <input type="text" name="finish"
                        value="<%= Util.safeString(dateFinish) %>"
                        id="finish_date" />
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

    Date currentDate = null;
    Timestamp currentTime = new Timestamp(0);

    int greyCount = 1;

    while (rset.next()) {
        if(!rset.getDate("message_date").equals(currentDate)) {
            currentDate = rset.getDate("message_date");
            prevSender = "";
            prevRecipient = "";

            out.println("<div class=\"weblogDateHeader\">");
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

        for (int i = 0; i < hlWords.size(); i++) {

            Pattern p = Pattern.compile("(?i)(.*?)(" +
            hlWords.get(i).toString() + ")(.*?)");
            Matcher m = p.matcher(message);
            StringBuffer sb = new StringBuffer();
            int oldIndex = 0;
            while(m.find()) {
                sb.append(message.substring(oldIndex,m.start()));
                if(sb.toString().lastIndexOf('<') <=
                  sb.toString().lastIndexOf('>')) {
                    sb.append(m.group(1) + "<b style=\"color:black;background-color:" +
                    hlColor[i % hlColor.length] + "\">");
                    sb.append(m.group(2) + "</b>" + m.group(3));
                } else {
                    sb.append(m.group(1) + m.group(2) + m.group(3));
                }
                oldIndex = m.end();
            }
            sb.append(message.substring(oldIndex, message.length()));

            message = sb.toString();
        }

        if(!rset.getString("sender_sn").equals(prevSender) ||
            !rset.getString("recipient_sn").equals(prevRecipient)) {

            greyCount = 1;

            out.print("<div class=\"message_container\" id=\""
                + rset.getString("message_id") + "\">");

            out.println("<div class=\"sender\">");
            out.print("<a href=\"index.jsp?from=" +
            rset.getString("sender_sn") +
            "&to=" + rset.getString("recipient_sn") +
            "&start=" + Util.safeString(dateStart) +
            "&finish=" + Util.safeString(dateFinish) + "#" +
            rset.getInt("message_id") + "\" ");

            out.print("title=\"" + rset.getString("sender_sn") + "\">");

            out.print("<span style=\"color: " + sent_color + "\">");
            if(showDisplay) {
                out.print(rset.getString("sender_display").replaceAll("<", "&lt;").replaceAll(">", "&gt;"));
            } else if (showMeta) {
                out.print(rset.getString("sender_meta").replaceAll("<", "&lt;").replaceAll(">", "&gt;"));
            } else {
                out.print(rset.getString("sender_sn").replaceAll("<", "&lt;").replaceAll(">", "&gt;"));
            }
            out.print("</span></a>\n");

            if(to_sn == null || from_sn == null) {
                out.println("&rarr;");

                out.println("<a href=\"index.jsp?from=" +
                rset.getString("sender_sn") +
                    "&to=" + rset.getString("recipient_sn") +
                    "&start=" + Util.safeString(dateStart) +
                    "&finish=" + Util.safeString(dateFinish) +
                    "#" + rset.getInt("message_id") +
                    "\" title=\"" + rset.getString("recipient_sn") + "\">");

                out.print("<span style=\"color: " +
                received_color + "\">");
                if(showDisplay) {
                    out.print(rset.getString("recipient_display").replaceAll("<", "&lt;").replaceAll(">", "&gt;"));
                } else if (showMeta) {
                    out.print(rset.getString("recipient_meta").replaceAll("<", "&lt;").replaceAll(">", "&gt;"));
                } else {
                    out.print(rset.getString("recipient_sn").replaceAll("<", "&lt;").replaceAll(">", "&gt;"));
                }
                out.print("</span></a>");
            }
            out.println("</div>\n\n");
        } else {
            out.println("<div class=\"msg_container_next\">\n");
        }

        prevSender = rset.getString("sender_sn");
        prevRecipient = rset.getString("recipient_sn");

        out.println("<div class=\"time_initial\">");
        if(rset.getBoolean("notes")) {

            paramMap.put("message_id",
                new Integer(rset.getInt("message_id")));
            noteSet = lc.executeQuery("message_notes", paramMap);

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
            rset.getString("message_id") + "', 'Add Note', "+
            "'width=275,height=225')\">");

        out.print("<img src=\"images/note_add.png\" alt=\"Add Note\"></a>");

        out.print(rset.getTime("message_date"));
        out.println("</div>\n");

        out.println("<div class=\"message\"><p " +
                (greyCount++ % 2 == 0 ? "class=\"even\"" :
                 "class=\"odd\"") + ">");
        out.println(message);
        out.println("</p></div>\n");

        out.println("</div>\n");
    }
} catch (SQLException e) {
    out.print("<br /><span style=\"color: red\">" + e.getMessage() + "</span>");
} finally {
    lc.close();
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
