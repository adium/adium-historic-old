<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.sql.*' %>
<%@ page import = 'javax.naming.*' %>
<%@ page import = 'java.util.ArrayList' %>
<%@ page import = 'java.util.StringTokenizer' %>
<%@ page import = 'java.util.regex.Pattern' %>
<%@ page import = 'java.util.regex.Matcher' %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<!--$URL: http://svn.visualdistortion.org/repos/projects/adium/jsp/index.jsp $-->
<!--$Rev: 765 $ $Date: 2004/05/21 03:47:18 $ -->

<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();

String dateStart, dateFinish, from_sn, to_sn, contains_sn, hl;
boolean showDisplay = true;
boolean showMeta = false;

Date today = new Date(System.currentTimeMillis());
int chat_id = 0;

String formURL = new String("saveForm.jsp?action=saveChat.jsp");

dateFinish = request.getParameter("finish");
dateStart = request.getParameter("start");
from_sn = request.getParameter("from");
to_sn = request.getParameter("to");
contains_sn = request.getParameter("contains");
String screenDisplayMeta = request.getParameter("screen_or_display");
hl = request.getParameter("hl");
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

if(screenDisplayMeta != null && screenDisplayMeta.equals("screen")) {
    showDisplay = false;
} else if (screenDisplayMeta != null && screenDisplayMeta.equals("meta")) {
    showMeta = true;
    showDisplay = false;
}

String hlColor[] = {"#ff6","#a0ffff", "#9f9", "#f99", "#f69"};

PreparedStatement pstmt = null;
ResultSet rset = null;
ResultSet noteSet = null;

String queryText = new String();

try {

    if(chat_id != 0) {
        pstmt = conn.prepareStatement("select title, notes, sent_sn, received_sn, single_sn, date_start, date_finish from adium.saved_chats where chat_id = ?");

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
        }
    } else {
        title = "SQL Logger";
    }
%>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>Adium SQL Logger</title>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1" />
<link rel="stylesheet" type="text/css" href="styles/layout.css" />
<link rel="stylesheet" type="text/css" href="styles/default.css" />
<link rel="stylesheet" type="text/css" href="styles/message.css" />
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
                    <li><a href="statistics.jsp">Statistics</a></li>
                    <li><a href="users.jsp">Users</a></li>
                    <li><a href="meta.jsp">Meta-Contacts</a></li>
                </ul>
            </div>
            <div id="sidebar-a">
    <%
    if (hl != null) {
        out.print("<h1>Search Words</h1>");
        out.println("<div class=\"boxThinTop\"></div>");
        out.println("<div class=\"boxThinContent\">");
        for (int i = 0; i < hlWords.size(); i++) {
            out.print("<p><b style=\"color:black;" +
                "background-color:" + hlColor[i % hlColor.length] +
                "\">" + hlWords.get(i).toString() + "</b></p>\n");
        }
        out.println("</div>");
        out.println("<div class=\"boxThinBottom\"></div>");
    }
    String commandArray[] = new String[20];
    int aryCount = 0;
    boolean unconstrained = false;

    queryText = "select scramble(sender_sn) as sender_sn, "+
    " scramble(recipient_sn) as recipient_sn, " + 
    " message, message_date, message_id, " +
    " to_char(message_date, 'fmDay, fmMonth DD, YYYY') as fancy_date, " +
    " exists (select 'x' from adium.message_notes " +
    " where message_id = view.message_id) as notes";
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

    String concurrentWhereClause = " where ";

    if (dateStart == null) {
        queryText += "where message_date > 'now'::date ";
        concurrentWhereClause += " message_date > 'now'::date ";
    } else {
        queryText += "where  message_date > ?::timestamp ";
        concurrentWhereClause += " message_date > ?::timestamp ";
        commandArray[aryCount++] = new String(dateStart);
        if(dateFinish == null) {
            unconstrained = true;
        }
    }

    if (dateFinish != null) {
        queryText += " and message_date < ?::timestamp";
        concurrentWhereClause += "and message_date < ?::timestamp ";
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

    queryText += " order by message_date, message_id";
    
    if(unconstrained) {
        queryText += " limit 250";
        out.print("<div align=\"center\"><i>Limited to 250 " +
        "messages.</i><br><br></div>");
    }
    
    String query = "select scramble(username) as username " +
    "from adium.users natural join "+
    "(select distinct sender_id as user_id from adium.messages "+
    concurrentWhereClause + " union " +
    "select distinct recipient_id as user_id from adium.messages " +
    concurrentWhereClause + ") messages";

    pstmt = conn.prepareStatement(query);

    if(dateStart != null && dateFinish != null) {
        pstmt.setString(1, dateStart);
        pstmt.setString(2, dateFinish);
        pstmt.setString(3, dateStart);
        pstmt.setString(4, dateFinish);
    } else if(dateStart == null && dateFinish != null) {
        pstmt.setString(1, dateFinish);
        pstmt.setString(2, dateFinish);
    } else if(unconstrained) {
        pstmt.setString(1, dateStart);
        pstmt.setString(2, dateStart);
    }

    out.println("<h1>Users</h1>");
    out.println("<div class=\"boxThinTop\"></div>");
    out.println("<div class=\"boxThinContent\">");

    try {

        rset = pstmt.executeQuery();

        while(rset.next()) {
            out.print("<p><a href=\"index.jsp?start=" + dateStart + 
            "&finish=" + dateFinish + "&contains=" + 
            rset.getString("username") + "\">"+
            rset.getString("username") + "</a></p>\n");
        }

        out.print("<a href=\"index.jsp?start=" + dateStart +
            "&finish=" + dateFinish + "\"><i>All</i></a>");
    } catch (SQLException e) {
        out.print("<span style=\"color: red\">" + e.getMessage() + "</span>");
    }

    out.println("</div>");
    out.println("<div class=\"boxThinBottom\"></div>");
    
    out.println("<h1>Saved Chats</h1>");
    out.println("<div class=\"boxThinTop\"></div>");
    out.println("<div class=\"boxThinContent\">");
    
    pstmt = conn.prepareStatement("select chat_id, title from adium.saved_chats");
    
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
    out.println("</div>");
    out.println("<div class=\"boxThinBottom\"></div>");
    
    
%>
            </div>
            <div id="content">
            <h1>View Messages by Date</h1>
            
            <div class="boxWideTop"></div>
            <div class="boxWideContent">
            <form action="index.jsp" method="get">
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
                    <td align="right"><label for="start_date">Date Range: </label></td>
                <td><input type="text" name="start" <% if (dateStart != null)
                out.print("value=\"" + dateStart + "\""); else
                out.print("value=\"" + today.toString() + " 00:00:00\"");%>
                id="start_date" />
                <label for="finish_date">&nbsp;--&nbsp;</label>
                <input type="text" name="finish" <% if (dateFinish != null)
                out.print("value=\"" + dateFinish + "\""); %> id="finish_date" />
                    </td>
                </tr>
                </table>
                <p style="text-indent: 80px"><i>(YYYY-MM-DD hh:mm:ss)</i></p><br />

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
                    <label for="meta">Show Meta Contact</label>

                <div align="right">
                    <input type="reset" /><input type="submit" />
                </div>
                </form>
            </div>
            <div class="boxWideBottom"></div>

            <h1>Messages</h1>
                <div class="boxWideTop"></div>
                <div class="boxWideContent">
<%

    pstmt = conn.prepareStatement(queryText);

    //out.print(queryText + "<br />");

    for(int i = 0; i < aryCount; i++) {
      //  out.print(commandArray[i] + "<br />");
        pstmt.setString(i + 1, commandArray[i]);
    }

    rset = pstmt.executeQuery();

    if (!rset.isBeforeFirst()) {
        out.print("<div align=\"center\"><i>No records found.</i></div>");
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

            out.println("<div class=\"weblogDateHeader\">");
            out.println(rset.getString("fancy_date"));
            out.println("</div>");
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

            out.print("<div class=\"message_container\">");

            out.println("<div class=\"sender\">");
            out.print("<a href=\"index.jsp?from=" +
            rset.getString("sender_sn") + 
            "&to=" + rset.getString("recipient_sn") + 
            "&start=" + dateStart +
            "&finish=" + dateFinish + "#" + rset.getInt("message_id") + "\" ");

            if(!showDisplay) {
                out.print("title=\"" + rset.getString("sender_sn"));
            } else {
                out.print("title=\"" + rset.getString("sender_display"));
            }
            out.print("\">");

            out.print("<span style=\"color: " + sent_color + "\">");
            if(showDisplay) {
                out.print(rset.getString("sender_display"));
            } else if (showMeta) {
                out.print(rset.getString("sender_meta"));
            } else {
                out.print(rset.getString("sender_sn"));
            }
            out.print("</span></a>\n");

            if(to_sn == null || from_sn == null) {
                out.print("&rarr; <span style=\"color: " +
                received_color + "\">");
                if(showDisplay) {
                    out.print(rset.getString("recipient_display"));
                } else if (showMeta) {
                    out.print(rset.getString("recipient_meta"));
                } else {
                    out.print(rset.getString("recipient_sn"));
                }
                out.print("</span>");
            }
            out.println("</div>");
        } else {
            out.println("<div class=\"msg_container_next\">");
        }

        prevSender = rset.getString("sender_sn");
        prevRecipient = rset.getString("recipient_sn");

        out.println("<div class=\"time_initial\">");
        if(rset.getBoolean("notes")) {
            pstmt = conn.prepareStatement("select title, notes " +
            " from adium.message_notes where message_id = ? " +
            " order by date_added ");
            
            pstmt.setInt(1, rset.getInt("message_id"));
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
            rset.getString("message_id") + "', 'Add Note', "+
            "'width=275,height=225')\">");

        out.print("<img src=\"images/note_add.png\" alt=\"Add Note\"></a>");
        
        out.print(rset.getTime("message_date"));
        out.println("</div>");
        
        out.println("<div class=\"message\"><p>");
        out.println(message);
        out.println("</p></div>");
        
        out.println("</div>");
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
