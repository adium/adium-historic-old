<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.sql.*' %>
<%@ page import = 'javax.naming.*' %>
<%@ page import = 'java.util.ArrayList' %>
<%@ page import = 'java.util.StringTokenizer' %>
<%@ page import = 'java.util.regex.Pattern' %>
<%@ page import = 'java.util.regex.Matcher' %>

<!DOCTYPE HTML PUBLIC "-//W3C/DTD HTML 4.01 Transitional//EN">
<!--$URL: http://svn.visualdistortion.org/repos/projects/adium/jsp/index.jsp $-->
<!--$Rev: 586 $ $Date: 2004/02/10 00:25:18 $ -->

<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();
String afterDate, beforeDate, from_sn, to_sn, contains_sn, hl;
boolean showDisplay = true, showForm = false, showConcurrentUsers = false, simpleViewStyle = false;

Date today = new Date(System.currentTimeMillis());

beforeDate = request.getParameter("before");
afterDate = request.getParameter("after");
from_sn = request.getParameter("from");
to_sn = request.getParameter("to");
contains_sn = request.getParameter("contains");
String screennameDisplay = request.getParameter("screen_or_display");
String viewStyle = request.getParameter("viewstyle");

showForm = Boolean.valueOf(request.getParameter("form")).booleanValue();

showConcurrentUsers =
    Boolean.valueOf(request.getParameter("users")).booleanValue();

hl = request.getParameter("hl");
ArrayList hlWords = new ArrayList();

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

    String queryText = "select scramble(sender_sn) as sender_sn, "+
    " scramble(recipient_sn) as recipient_sn, " + 
    " message, message_date, message_id";
    if(showDisplay) {
       queryText += ", scramble(sender_display) as sender_display, "+
           " scramble(recipient_display) as recipient_display "
        + " from adium.message_v ";
    } else {
        queryText += " from adium.simple_message_v ";
    }

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
        queryText += " and (((sender_sn = ? " + 
        " and recipient_sn = ?) or " +
        "(sender_sn = ? and recipient_sn = ?)) or " +
        "((scramble(sender_sn) = ? and scramble(recipient_sn) = ?) or " +
        "(scramble(recipient_sn) = ? and scramble(sender_sn) = ?)))";
        commandArray[aryCount++] = new String(to_sn);
        commandArray[aryCount++] = new String(from_sn);
        commandArray[aryCount++] = new String(from_sn);
        commandArray[aryCount++] = new String(to_sn);
        commandArray[aryCount++] = new String(to_sn);
        commandArray[aryCount++] = new String(from_sn);
        commandArray[aryCount++] = new String(to_sn);
        commandArray[aryCount++] = new String(from_sn);
    
    } else if (from_sn != null && to_sn == null) {
        queryText += " and (sender_sn = ? or scramble(sender_sn) = ?)";
        
        commandArray[aryCount++] = new String(from_sn);
        commandArray[aryCount++] = new String(from_sn);

    } else if (from_sn == null && to_sn != null) {
        queryText += " and (recipient_sn = ? or scramble(recipient_sn) =?)";
        
        commandArray[aryCount++] = new String(to_sn);
        commandArray[aryCount++] = new String(to_sn);
    }

    if (contains_sn != null) {
        queryText += " and (recipient_sn = ? or sender_sn = ? or scramble(recipient_sn) = ? or scramble(sender_sn) = ?) ";
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
            out.print("<a href=\"index.jsp?after=" + afterDate + 
            "&before=" + beforeDate + "&contains=" + 
            rset.getString("username") + "\">"+
            rset.getString("username") + "</a>&nbsp;|&nbsp;");
        }
        out.print("<a href=\"index.jsp?after=" + afterDate +
            "&before=" + beforeDate + "\"><i>All</i></a>");
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
            out.print("</font></td>");
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
                if(sb.toString().lastIndexOf('>') > 
                  sb.toString().lastIndexOf('<')) {
                    sb.append(m.group(1) + 
                    "<b style=\"color:black;background-color:" +
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
        "&after=" + afterDate +
        "&before=" + beforeDate + "#" + rset.getInt("message_id") + "\" ");
        
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
