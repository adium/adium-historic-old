<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.sql.*' %>
<%@ page import = 'javax.naming.*' %>
<%@ page import = 'java.util.ArrayList' %>

<!DOCTYPE HTML PUBLIC "-//W3C/DTD HTML 4.01 Transitional//EN">
<!--$URL: http://svn.visualdistortion.org/repos/projects/adium/jsp/index.jsp $-->
<!--$Rev: 413 $ $Date: 2003/09/03 05:16:13 $ -->

<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();
String afterDate, beforeDate, from_sn, to_sn, contains_sn;
boolean showDisplay = true, showForm = false, showConcurrentUsers = false;

Date today = new Date(System.currentTimeMillis());

beforeDate = request.getParameter("before");
afterDate = request.getParameter("after");
from_sn = request.getParameter("from");
to_sn = request.getParameter("to");
contains_sn = request.getParameter("contains");
String screennameDisplay = request.getParameter("screen_or_display");

showForm = Boolean.valueOf(request.getParameter("form")).booleanValue();

showConcurrentUsers =
    Boolean.valueOf(request.getParameter("users")).booleanValue();

if (beforeDate != null && (beforeDate.equals("") || beforeDate.equals("null"))) {
    beforeDate = null;
}
if (afterDate != null && (afterDate.equals("") || afterDate.startsWith("null"))) {
    afterDate = null;
}
if (from_sn != null && from_sn.equals("")) {
    from_sn = null;
}
if (to_sn != null && to_sn.equals("")) {
    to_sn = null;
}
if (contains_sn != null && contains_sn.equals("")) {
    contains_sn = null;
}

if (screennameDisplay == null || screennameDisplay.equals("display")) {
    showDisplay = true;
} else {
    showDisplay = false;
}
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
<% if (!showForm) { 
%>
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
                <label for="after_date">Date Range: </label>
                <input type="text" name="after" <% if (afterDate != null)
                out.print("value=\"" + afterDate + "\""); else
                out.print("value=\"" + today.toString() + " 00:00:00\"");%>
                id="after_date" />
                <label for="before_date">&nbsp;--&nbsp;</label>
                <input type="text" name="before" <% if (beforeDate != null)
                out.print("value=\"" + beforeDate + "\""); %> id="before_date" />
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
                    </tr>
                </table>
            </fieldset>
            <input type="reset">
            <input type="submit">
        </form>
        <a href="search.jsp">[Search Logs]</a>&nbsp;&nbsp;
        <a href="statistics.jsp">[Statistics]</a><br /><br />
<%
    }
PreparedStatement pstmt = null;
ResultSet rset = null;

try {
    String commandArray[] = new String[10];
    int aryCount = 0;
    boolean unconstrained = false;
    
    String queryText = "select sender_sn, recipient_sn, sender_display, " + 
    " recipient_display, message, " +
    " message_date, message_id from adium.message_v ";
    
    String concurrentWhereClause = " where ";
    
    if (afterDate == null) {
        queryText += "where message_date > 'now'::date ";
        concurrentWhereClause += " message_date > 'now'::date ";
    } else {
        queryText += "where message_date > ?::timestamp ";
        concurrentWhereClause += " message_date > ?::timestamp ";
        commandArray[aryCount++] = new String(afterDate);
        if(beforeDate == null) {
            unconstrained = true;
        }
    }
    
    if (beforeDate != null) {
        queryText += " and message_date < ?::timestamp";
        concurrentWhereClause += "and message_date < ?::timestamp ";
        commandArray[aryCount++] = new String(beforeDate);
    }

    if (from_sn != null && to_sn != null) {
        queryText += " and ((sender_sn = ? " + 
        " and recipient_sn = ?) or " +
        "(sender_sn = ? and recipient_sn = ?))";
        commandArray[aryCount++] = new String(to_sn);
        commandArray[aryCount++] = new String(from_sn);
        commandArray[aryCount++] = new String(from_sn);
        commandArray[aryCount++] = new String(to_sn);
    } else if (from_sn != null && to_sn == null) {
        queryText += " and sender_sn = ? ";
        commandArray[aryCount++] = new String(from_sn);
    } else if (from_sn == null && to_sn != null) {
        queryText += " and recipient_sn = ? ";
        commandArray[aryCount++] = new String(to_sn);
    }

    if (contains_sn != null) {
        queryText += " and (recipient_sn = ? or sender_sn = ?) ";
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
        String query = "select username from adium.users natural join "+
        "(select distinct sender_id as user_id from adium.messages "+
        concurrentWhereClause + " union " +
        "select distinct recipient_id as user_id from adium.messages " +
        concurrentWhereClause + ") messages";

        pstmt = conn.prepareStatement(query);
        
        if(afterDate != null && beforeDate != null) {
            pstmt.setString(1, afterDate);
            pstmt.setString(2, beforeDate);
            pstmt.setString(3, afterDate);
            pstmt.setString(4, beforeDate);
        } else if(afterDate == null && beforeDate != null) {
            pstmt.setString(1, beforeDate);
            pstmt.setString(2, beforeDate);
        } else if(unconstrained) {
            pstmt.setString(1, afterDate);
            pstmt.setString(2, afterDate);
        }

        rset = pstmt.executeQuery();
        out.print("<div align=\"center\">");
        out.println("<b>Users:</b><br />");
        while(rset.next()) {
            if (rset.getRow() % 5 == 0) {
                out.print("<br />");
            }
            else if (rset.getRow() != 1) {
                out.print(" | ");
            }
            out.print("<a href=\"index.jsp?&after=" + afterDate + 
            "&before=" + beforeDate + "&contains=" + 
            rset.getString("username") + "\">"+
            rset.getString("username") + "</a>");
        }
        out.println("</div><br />");
    }
    pstmt = conn.prepareStatement(queryText);
    for(int i = 0; i < aryCount; i++) {
        pstmt.setString(i + 1, commandArray[i]);
    }
    rset = pstmt.executeQuery();
    
    if (!rset.isBeforeFirst()) {
        out.print("<div align=\"center\"><i>No records found.</i></div>");
    } else {
        out.print("<table border=\"0\"");
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
            out.print("<td align=\"center\" bgcolor=\"teal\"" +
            " background=\"images/transp-change.png\">");
            out.print("<font color=\"white\">" + currentDate.toString());
            out.print("</font></td><td></td><td></td>");
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
        
        out.print("<tr>\n");
        String cellColor = "#ffffff";
        if(cntr++ % 2 == 0) {
            cellColor = "#dddddd";
        }
        
        out.print("<td valign=\"top\" align=\"right\" bgcolor=\"" +
        cellColor + "\" id=\"" + rset.getInt("message_id") + "\">");
 
        out.print("<a href=\"index.jsp?from=" +
        rset.getString("sender_sn") + 
        "&to=" + rset.getString("recipient_sn") + 
        "&after=" + afterDate +
        "&before=" + beforeDate + "#" + rset.getInt("message_id") + "\">");
        out.print("<font color=\"" + sent_color + "\">");
        if(showDisplay) {
            out.print(rset.getString("sender_display"));
        } else {
            out.print(rset.getString("sender_sn"));
        }
        out.print("</font>:</a></font></td>\n");


        out.print("<td bgcolor=\"" + cellColor + "\">" + message + "</td>\n");

        out.print("<td valign=\"top\" bgcolor=\"" + cellColor + "\">");
        out.print(rset.getTime("message_date"));

        if(to_sn == null || from_sn == null) {
            out.print("<font color=\"" +
            received_color + "\">&nbsp;(");
            if(showDisplay) {
                out.print(rset.getString("recipient_display"));
            } else {
                out.println(rset.getString("recipient_sn"));
            }
            out.print(")</font>");
        }
        out.print("</td>\n");
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
