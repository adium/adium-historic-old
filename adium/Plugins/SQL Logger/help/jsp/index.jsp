<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.sql.*' %>
<%@ page import = 'javax.naming.*' %>
<%@ page import = 'java.util.ArrayList' %>

<!DOCTYPE HTML PUBLIC "-//W3C/DTD HTML 4.01 Transitional//EN">
<!--$URL: http://svn.visualdistortion.org/repos/projects/adium/jsp/index.jsp $-->
<!--$Rev: 348 $ $Date: 2003/07/19 00:03:29 $ -->

<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();
String afterDate, beforeDate, from_sn, to_sn;

Date today = new Date(System.currentTimeMillis());

beforeDate = request.getParameter("before");
afterDate = request.getParameter("after");
from_sn = request.getParameter("from");
to_sn = request.getParameter("to");

if (beforeDate != null && (beforeDate.equals("") || beforeDate.equals("null"))) {
    beforeDate = null;
}
if (afterDate != null && (afterDate.equals("") || afterDate.equals("null"))) {
    afterDate = null;
}
if (from_sn != null && from_sn.equals("")) {
    from_sn = null;
}
if (to_sn != null && to_sn.equals("")) {
    to_sn = null;
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
                <label for="after_date">Date Range: </label>
                <input type="text" name="after" <% if (afterDate != null)
                out.print("value=\"" + afterDate + "\""); else
                out.print("value=\"" + today.toString() + " 00:00:00\"");%>
                id="after_date" />
                <label for="before_date">&nbsp;--&nbsp;</label>
                <input type="text" name="before" <% if (beforeDate != null)
                out.print("value=\"" + beforeDate + "\""); %> id="before_date" />
                &nbsp;(YYYY-MM-DD hh:mm:ss)<br />
                <input type="reset" />
                <input type="submit" />
            
            </fieldset>
        </form>
        <a href="search.jsp">[Search Logs]</a>&nbsp;&nbsp;
        <a href="statistics.jsp">[Statistics]</a><br /><br />
<%
PreparedStatement pstmt = null;
ResultSet rset = null;

try {
    String commandArray[] = new String[10];
    int aryCount = 0;
    boolean unconstrained = false;
    String queryText = "select sender_sn, recipient_sn, message, " +
    " message_date, message_id from adium.message_v ";
    
    if (afterDate == null) {
        queryText += "where message_date > 'now'::date ";
        unconstrained = true;
    } else {
        queryText += "where message_date > ?";
        commandArray[aryCount++] = new String(afterDate);
    }
    
    if (beforeDate != null) {
        queryText += " and message_date < ?";
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

    queryText += " order by message_date, message_id";
    
    if((afterDate != null && beforeDate == null) ||
        (beforeDate != null && afterDate == null) && !unconstrained) {
        queryText += " limit 250";
        out.print("<div align=\"center\"><i>Limited to 250 " +
        "messages.</i><br><br></div>");
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
            out.print("<td align=\"center\" bgcolor=\"teal\">");
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
        
        message = message.replaceAll("\n", "<br>"); 
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
        out.print("<font color=\"" + sent_color + "\">" + 
        rset.getString("sender_sn") + "</font>:" + 
        "</a></font></td>\n");


        out.print("<td bgcolor=\"" + cellColor + "\">" + message + "</td>\n");

        out.print("<td valign=\"top\" bgcolor=\"" + cellColor + "\">");
        out.print(rset.getTime("message_date"));

        if(to_sn == null || from_sn == null) {
            out.print("<font color=\"" +
            received_color + "\">&nbsp;(" +
            rset.getString("recipient_sn") +
            ")</font>");
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
