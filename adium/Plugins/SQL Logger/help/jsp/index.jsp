<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.sql.*' %>
<%@ page import = 'javax.naming.*' %>
<%@ page import = 'java.util.ArrayList' %>
<%@ page import = 'java.util.StringTokenizer' %>
<%@ page import = 'java.util.regex.Pattern' %>
<%@ page import = 'java.util.regex.Matcher' %>

<!DOCTYPE HTML PUBLIC "-//W3C/DTD HTML 4.01 Transitional//EN">
<!--$URL: http://svn.visualdistortion.org/repos/projects/adium/jsp/index.jsp $-->
<!--$Rev: 683 $ $Date: 2004/04/23 04:26:27 $ -->

<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();

String dateStart, dateFinish, from_sn, to_sn, contains_sn, hl;
boolean showDisplay = true, showForm = false, showConcurrentUsers = false, simpleViewStyle = false;
Date today = new Date(System.currentTimeMillis());
int chat_id = 0;

String formURL = new String("saveForm.jsp?action=saveChat.jsp");

dateFinish = request.getParameter("finish");
dateStart = request.getParameter("start");
from_sn = request.getParameter("from");
to_sn = request.getParameter("to");
contains_sn = request.getParameter("contains");
String screennameDisplay = request.getParameter("screen_or_display");
String viewStyle = request.getParameter("viewstyle");

String title = new String("");
String notes = new String("");

try {
    chat_id = Integer.parseInt(request.getParameter("chat_id"));
} catch (NumberFormatException e) {
    chat_id = 0;
}

showForm = Boolean.valueOf(request.getParameter("form")).booleanValue();

showConcurrentUsers =
    Boolean.valueOf(request.getParameter("users")).booleanValue();

hl = request.getParameter("hl");
ArrayList hlWords = new ArrayList();

if (dateFinish != null && (dateFinish.equals("") || dateFinish.equals("null"))) {
    dateFinish = null;
} else if (dateFinish != null) {
    formURL += "&dateFinish=" + dateFinish;
}


if (dateStart != null && (dateStart.equals("") || dateStart.startsWith("null"))) {
    dateStart = null;
} else if (dateStart != null) {
    formURL += "&dateStart=" + dateStart;
} else if (dateStart == null ) {
    formURL += "&dateStart=" + today.toString();
}

if (from_sn != null && from_sn.equals("")) {
    from_sn = null;
} else if(from_sn != null) {
    formURL += "&sender=" + from_sn;
}

if (to_sn != null && to_sn.equals("")) {
    to_sn = null;
} else if(to_sn != null ) {
    formURL += "&recipient=" + to_sn;
}

if (contains_sn != null && contains_sn.equals("")) {
    contains_sn = null;
} else if(contains_sn != null) {
    formURL += "&single_sn=" + contains_sn;
}

if (screennameDisplay == null || screennameDisplay.equals("display")) {
    showDisplay = true;
} else {
    showDisplay = false;
}

if (viewStyle != null && viewStyle.equals("simple")) {
    simpleViewStyle = true;
} else {
    simpleViewStyle = false;
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

String hlColor[] = {"#ff6","#a0ffff", "#9f9", "#f99", "#f69"};

%>

<html>
    <head>
        <title>
            Adium Log Viewer
        </title>
        <style type="text/css">
            :link, :visited {text-decoration: none}
        </style>
    </head>
    <body bgcolor="#ffffff">
<%
PreparedStatement pstmt = null;
ResultSet rset = null;

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
    }

    if (!showForm) { 
%>
        <table border="0"><tr><td>
        <form action="index.jsp" method="GET">
            <fieldset>
                <legend>View by Date</legend>
                <label for="from">Sent SN: </label>
                <input type="text" name="from" <% if(from_sn != null)
                out.print("value=\"" + from_sn + "\""); %> id="from" />
                <label for="to">Received SN: </label>
                <input type="text" name="to" <% if (to_sn != null)
                out.print("value=\"" + to_sn + "\""); %> id="to" />
                <br />
                <label for="contains">Single SN:</label>
                <input type="text" name="contains" <% if (contains_sn != null)
                out.print("value=\"" + contains_sn + "\""); %> id = "contains"
                /><br />
                <label for="start_date">Date Range: </label>
                <input type="text" name="start" <% if (dateStart != null)
                out.print("value=\"" + dateStart + "\""); else
                out.print("value=\"" + today.toString() + " 00:00:00\"");%>
                id="start_date" />
                <label for="finish_date">&nbsp;--&nbsp;</label>
                <input type="text" name="finish" <% if (dateFinish != null)
                out.print("value=\"" + dateFinish + "\""); %> id="finish_date" />
                &nbsp;(YYYY-MM-DD hh:mm:ss)<br />
            </fieldset>
            <fieldset>
                <legend>Format Options</legend>
                <table>
                    <tr>
                        <td>
                            <input type="checkbox" name="users" id="user"
                            value="true" <% if (showConcurrentUsers)
                            out.print(" checked=\"true\""); %>/>
                                <label for="user">Do Not Show Multiple Users</label><br />
                            <input type="checkbox" name="form" id="form" value="true" />
                                <label for="form">Do Not Show Form</label>
                        </td>
                        <td>
                            <input type="radio" name="screen_or_display" value
                            = "screenname" id = "sn" <% if (!showDisplay)
                            out.print("checked=\"true\""); %> />
                                <label for="sn">Show Screename</label><br />
                            <input type="radio" name="screen_or_display"
                            value="display" id="disp" <% if (showDisplay)
                            out.print("checked=\"true\""); %> />
                                <label for="disp">Show Alias/Display Name</label>
                        </td>
                        <td>
                            <input type="radio" name="viewstyle" value="simple"
                              id="simple" <% if (simpleViewStyle) out.print("checked=\"true\""); %> />
                            <label for="simple">Simple View</label>
                            <br />
                            <input type="radio" name="viewstyle"
                              value="complex" id="complex" <% if (!simpleViewStyle) out.print("checked=\"true\""); %> />
                            <label for="complex">Complex View</label>
                        </td>
                    </tr>
                </table>
            </fieldset>
            <input type="reset">
            <input type="submit">
        </form>
        </td>
        <td>
            <form action="index.jsp" method="post">
                <select name="chat_id">
                    <option value="0" selected="yes">Please Choose</option>
<%
pstmt = conn.prepareStatement("select chat_id, title from adium.saved_chats");

rset = pstmt.executeQuery();

while(rset.next()) {
    out.println("<option value=\"" + rset.getString("chat_id") + "\">" +
        rset.getString("title") + "</option>");
}
%>
                </select>
                <input type="submit">
            </form>
            <a href="#"
                onClick="window.open('<%= formURL %>', 'Save Search', 'width=275,height=225')">
                Save Chat
            </a>
        </td>
        </tr>
        </table>
        <%
        if (hl != null) {
            out.print("<table border=\"1\"><tr><td>");
            out.print("Search Words:<br />");
            for (int i = 0; i < hlWords.size(); i++) {
                out.print("<b style=\"color:black;" +
                    "background-color:" + hlColor[i % hlColor.length] +
                    "\">" + hlWords.get(i).toString() + "</b> ");
            }
            out.print("</td></tr></table>");
        }
        %>
        <h2><%= title %></h2>
        <p><%= notes %></p><br />
        <a href="search.jsp">[Search Logs]</a>&nbsp;&nbsp;
        <a href="statistics.jsp">[Statistics]</a><br /><br />
        <%
    }
    
    String commandArray[] = new String[10];
    int aryCount = 0;
    boolean unconstrained = false;

    String queryText = "select scramble(sender_sn) as sender_sn, "+
    " scramble(recipient_sn) as recipient_sn, " + 
    " message, message_date, message_id, title, notes";
    if(showDisplay) {
       queryText += ", scramble(sender_display) as sender_display, "+
           " scramble(recipient_display) as recipient_display "
        + " from adium.message_v ";
    } else {
        queryText += " from adium.simple_message_v ";
    }

    queryText += " natural left join adium.message_notes notes ";
    
    String concurrentWhereClause = " where ";

    if (dateStart == null) {
        queryText += "where message_date > 'now'::date ";
        concurrentWhereClause += " message_date > 'now'::date ";
    } else {
        queryText += "where message_date > ?::timestamp ";
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
    
    if(!showConcurrentUsers) {
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

        rset = pstmt.executeQuery();
        out.print("<div align=\"center\">");
        out.println("<b>Users:</b><br />");
        while(rset.next()) {
            if (rset.getRow() % 5 == 0) {
                out.print("<br />");
            }
            out.print("<a href=\"index.jsp?start=" + dateStart + 
            "&finish=" + dateFinish + "&contains=" + 
            rset.getString("username") + "\">"+
            rset.getString("username") + "</a>&nbsp;|&nbsp;");
        }
        out.print("<a href=\"index.jsp?start=" + dateStart +
            "&finish=" + dateFinish + "\"><i>All</i></a>");
        out.println("</div><br />");
    }
    pstmt = conn.prepareStatement(queryText);
    
    //out.print(queryText + "<br />");
    
    for(int i = 0; i < aryCount; i++) {
      //  out.print(commandArray[i] + "<br />");
        pstmt.setString(i + 1, commandArray[i]);
    }

    rset = pstmt.executeQuery();

    /*
     * Used to print query plans.
    out.println("<pre>");
    while(rset.next()) {
        out.println(rset.getString(1));
    }
    out.println("</pre>");
    */

    if (!rset.isBeforeFirst()) {
        out.print("<div align=\"center\"><i>No records found.</i></div>");
    } else {
        out.print("<table border=\"0\">");
    }

    ArrayList userArray = new java.util.ArrayList();
    String colorArray[] =
    {"red","blue","green","purple","black","orange", "teal"};
    String sent_color = new String();
    String received_color = new String();
    String user = new String();

    int cntr = 1;
    Date currentDate = null;
    while (rset.next()) {
        if(!rset.getDate("message_date").equals(currentDate)) {
            currentDate = rset.getDate("message_date");
            out.print("<tr>");
            out.print("<td></td>");
            out.print("<td align=\"center\" bgcolor=\"teal\"" +
            " background=\"images/transp-change.png\" width=\"150\">");
            out.print("<font color=\"white\">" + currentDate.toString());
            out.print("</font></td><td></td>");
            out.print("</tr>");
        }

        sent_color = null;
        received_color = null;
        String message = rset.getString("message");

        for(int i = 0; i < userArray.size(); i++) {
            if (userArray.get(i).equals(rset.getString("sender_sn"))) {
                sent_color = colorArray[i % colorArray.length];
            }
        }

        if (sent_color == null) {
            sent_color = colorArray[userArray.size() % colorArray.length];
            userArray.add(rset.getString("sender_sn"));
        }

        for(int i = 0; i < userArray.size(); i++) {
            if (userArray.get(i).equals(rset.getString("recipient_sn"))) {
                received_color = colorArray[i % colorArray.length];
            }
        }

        if (received_color == null) {
            received_color = colorArray[userArray.size() % colorArray.length];
            userArray.add(rset.getString("recipient_sn"));
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

        out.print("<tr>\n");
        String cellColor = "#ffffff";
        if(cntr++ % 2 == 0) {
            cellColor = "#dddddd";
        }

        out.print("<td valign=\"top\" align=\"left\" bgcolor=\"" +
        cellColor + "\" id=\"" + rset.getInt("message_id") + "\">");

        if(simpleViewStyle) {
            out.print(rset.getTime("message_date") + " ");
        }

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
        
        out.print("<font color=\"" + sent_color + "\">");
        if(showDisplay) {
            out.print(rset.getString("sender_display"));
        } else {
            out.print(rset.getString("sender_sn"));
        }
        out.print("</font>:</a></font>\n");

        if(to_sn == null || from_sn == null) {
            out.print("<font color=\"" +
            received_color + "\">");
            if(showDisplay) {
                out.print(rset.getString("recipient_display"));
            } else {
                out.print(rset.getString("recipient_sn"));
            }
            out.print("</font>");
        }
        if(!simpleViewStyle) {
            out.print("</td>");
            out.print("<td valign=\"top\" align=\"right\" bgcolor=\"" + 
                cellColor + "\" width=\"150\">");
            out.print(rset.getTime("message_date"));
            out.print("</td>\n");
            if(rset.getString("notes") != null) {
                out.println("<td rowspan=\"2\" width=\"150\" bgcolor=\"#ffff99\">" + 
                    "<font size=\"2\"><b>" + rset.getString("title") + 
                    "</b><br />" + rset.getString("notes") + "</font></td>");
            } else {
                out.println("<td rowspan=\"2\"><a href=\"#\" " +
                    "onClick=\"window.open('saveForm.jsp?action=saveNote.jsp&message_id=" +
                    rset.getString("message_id") + "', 'Add Note', "+
                    "'width=275,height=225')\">");
                out.println("Add Note");
                out.println("</a></td>");
            }
            out.print("</tr><tr>");
            out.print("<td colspan=\"2\" bgcolor=\"" + cellColor + "\">");
        }
        out.print(" " + message + "</td>\n");

        out.print("</tr>\n");
    }
%>
</table>
<%
}catch(SQLException e) {
    out.print(e.getMessage());
} finally {
    pstmt.close();
    conn.close();
}
%>
</body>
</html>
