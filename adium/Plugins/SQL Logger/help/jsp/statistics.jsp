<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.sql.*' %>
<%@ page import = 'java.util.ArrayList' %>
<%@ page import = 'javax.naming.*' %>

<!DOCTYPE HTML PUBLIC "-//W3C/DTD HTML 4.01 Transitional//EN">
<!--$URL: http://svn.visualdistortion.org/repos/projects/adium/jsp/statistics.jsp $-->
<!--$Rev: 354 $ $Date: 2003/08/05 04:25:49 $ -->
<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();
int sender;
String sender_sn;
int total_messages = 0;

try {
    sender = Integer.parseInt(request.getParameter("sender"));
} catch (NumberFormatException e) {
    sender = 0;
}
%>
<html>
    <head>
        <title>Adium Statistics</title>
    </head>
    <body>
    <% 
    if (sender == 0) {
        out.print("<div align=\"center\">");
        out.print("<h3>Please choose a user:</h3>");
        out.print("</div>");
    }
    %>
    <table width="100%">
        <tr>
<%
PreparedStatement pstmt = null;
Statement stmt = null;
ResultSet rset = null;
ResultSet totals = null;
ResultSet year = null;
ResultSetMetaData rsmd = null;
try {

    stmt = conn.createStatement();

    if(sender != 0) {
    	pstmt = conn.prepareStatement("select username from adium.users where user_id = ?");
    	pstmt.setInt(1, sender);
    	rset = pstmt.executeQuery();
    	rset.next();
    	sender_sn = new String(rset.getString("username"));
    	
        out.print("<td valign=\"top\">");
        pstmt = conn.prepareStatement(" select " +
        " count(*) as total_sent, "+
        " min(length(message)) as min_sent_length, " +
        " max(length(message)) as max_sent_length, " +
        " trunc(avg(length(message)),2) as avg_sent_length " +
        " from adium.messages " +
        " where sender_id = ? " + 
        " group by sender_id " +
        " union all " +
        " select " +
        " count(*) as total_sent, " +
        " min(length(message)) as min_sent_length, " +
        " max(length(message)) as max_sent_length, " +
        " trunc(avg(length(message)),2) as avg_sent_length " +
        " from adium.messages " +
        " where recipient_id =  ? " +
        " group by recipient_id ");
        
        for(int i = 1; i <= 2; i++) {
            pstmt.setInt( i , sender);
        }

        totals = pstmt.executeQuery();
        /*
        out.println("<pre>");
        while(totals.next()) {
            out.println(totals.getString(1));
        }
        
        out.println("</pre>");
        */
        totals.next();

        out.print("<div align=\"center\"><h3>" + sender_sn + 
        "</h3></div>");
        
        out.print("Total messages sent: " + totals.getString("total_sent") + "<br>");
        total_messages += totals.getInt("total_sent");
        
        out.print("Minimum sent length: " + totals.getString("min_sent_length") +
        "<br>");
        out.print("Average message length: " + totals.getString("avg_sent_length") +
        "<br>");
        out.print("Maximum message length: " + totals.getString("max_sent_length") +
        "<br /><br />");
        
        totals.next();
        
        out.print("Total messages received: " + totals.getString("total_sent") + "<br />");
        total_messages += totals.getInt("total_sent");
        
        out.println("Mimimum Received Length: " + totals.getString("min_sent_length") + "<br />");
        out.println("Average Received Length: " + totals.getString("avg_sent_length") + "<br />");
        out.println("Maximum Received Length: " + totals.getString("max_sent_length") + "<br />");
 
        out.println("<br />Total Messages Sent/Received: " + total_messages + "<br /><br/>");
        
        out.print("<table width=\"700\"><tr><td>");
        
        pstmt = conn.prepareStatement("select date_part('year', message_date) " +
        " as year, " +
        "count(*) as count from adium.messages where sender_id = ? or recipient_id = ? " +
        " group by date_part('year', message_date) ");
        
        pstmt.setInt(1, sender);
        pstmt.setInt(2, sender);

        year = pstmt.executeQuery();

        ArrayList yearAry = new java.util.ArrayList();
        ArrayList countAry = new java.util.ArrayList();

        int max = 0;
        double maxDistance;

        while (year.next()) {
            yearAry.add(year.getString("year"));
            countAry.add(year.getString("count"));

            if (year.getInt("count") > max) {
                max = year.getInt("count");
            }
        }

        maxDistance = max * 1.25;
        
        out.print("<table width=\"350\" border=\"0\">");
        out.print("<tr><td colspan=\"3\" align=\"center\" bgcolor=\"teal\">"+
        "<font color=\"white\">Messages sent/received by year</font></td>");
        for(int i = 0; i < yearAry.size(); i++) {
            double distance = (Integer.parseInt(countAry.get(i).toString()) / maxDistance) * 225;
            if (distance < 1) distance = 1;
            out.print("<tr>");
            out.print("<td width=\"50\" align=\"right\">");
            out.print(yearAry.get(i));
            out.print("</td><td align=\"left\" width=\"225\">");
            out.print("<img src=\"images/bar.gif\" height = \"15\" width=\"" +
            (int)distance + "\">");
            out.print("</td>\n");
            out.print("<td width=\"75\">(" + countAry.get(i) + ")</td>");
        }
        out.print("</table>");

        pstmt = conn.prepareStatement("select date_part('month', message_date) " +
        "as month, count(*) as count from messages where sender_id = ? or " +
        "recipient_id = ? group by date_part('month', message_date)");

        pstmt.setInt(1, sender);
        pstmt.setInt(2, sender);

        year = pstmt.executeQuery();

        int monthArray[] = new int[13];

        for(int i = 0; i < 13; i++) {
            monthArray[i] = 0;
        }
        
        max = 0;
        while(year.next()) {
            monthArray[year.getInt("month")] = year.getInt("count");
            if(year.getInt("count") > max) max = year.getInt("count");
        }

        maxDistance = max * 1.25;
        
        out.print("<br />\n<table height=\"323\" width=\"350\"" +
        " cellspacing=\"0\"><tr>");
        out.print("<td colspan=\"14\" align=\"center\" bgcolor=\"teal\"><font "+
        " color=\"white\">Messages sent/received by month</font></td><tr>");

        for(int i = 1; i < 13; i++) {
            double height = monthArray[i] / maxDistance * 300;
            if (height < 1 && height != 0) height = 1;
            out.print("<td valign=\"bottom\" rowspan=\"13\"" +
            " background=\"images/gridline2.gif\">"+
            "<img src=\"images/bar2.gif\" width = \"15\" height=\"" +
            (int)height + "\"></td>");
        }
        
        out.print("</tr>");
        String months[] = {"", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", 
            "Aug", "Sep", "Oct", "Nov", "Dec"};
        for(int i = 1; i < 13; i++) {
            out.print("<tr><td align=\"right\">" + months[i] + ":</td><td "+
            " align=\"left\"> " + monthArray[i] + "</td></tr>");
        }
        
        out.print("<tr>");
        for(int i = 1; i < 13; i++) {
            out.print("<td>" + i + "</td>");
        }
        out.print("</tr></table>");
        
        out.print("</td><td valign=\"top\" align=\"left\">");
        out.print("View detailed statistics on the following months:<br>");
        pstmt = conn.prepareStatement("select distinct " +
        " to_char(date_trunc('month', message_date), 'Mon, YYYY') " +
        " as date, date_trunc('month', message_date) as full_date " +
        " from messages where sender_id = ? order by full_date"); 
        
        pstmt.setInt(1, sender);
        
        rset = pstmt.executeQuery();
        
        int count = 1;
        while(rset.next()) {
            out.print("<a href=\"details.jsp?sender=" +
            sender_sn + 
            "&sender_id=" + sender +
            "&date=" + rset.getString("full_date") + "\">");
            out.print(rset.getString("date") + "</a><br>");
            if(count % 23 == 0) out.print("</td><td valign=\"top\"" +
                " align=\"left\">");
            count++;
        }

        out.print("</td></tr></table>");
        
        pstmt = conn.prepareStatement("select username, recipient_id as \"Recipient\", "+ 
        " count(*) as \"Sent\", (select count(*)"+
        " from messages where"+
        " recipient_id = a.sender_id and sender_id = a.recipient_id) as " +
        " \"Recieved\", " +
        " trunc(avg(length(message)), 2) as "+
        " \"Avg Sent Length\", (select coalesce(trunc(avg(length(message)),2),0)"+
        " from "+
        " messages where a.sender_id = recipient_id and sender_id = " +
        " a.recipient_id) as \"Avg Recd Length\","+
        " min(length(message)) as \"Min Sent\", max(length(message))"+
        " as \"Max Sent\","+
        " (select coalesce(min(length(message)),0) from messages where "+
        " a.sender_id = "+
        " recipient_id and sender_id = a.recipient_id) as \"Min Received\","+
        " (select "+
        " coalesce(max(length(message)),0) from "+
        " messages where a.sender_id = recipient_id and a.recipient_id = "+
        " sender_id)"+
        " as \"Max Received\" from messages a, users "+
        " where a.sender_id = ? " +
        " and users.user_id = a.recipient_id " +
        " group by sender_id, recipient_id, username");

        pstmt.setInt(1, sender);

        rset = pstmt.executeQuery();

        rsmd = rset.getMetaData();

        out.print("<table>");
        
        int cntr = 0;
        while(rset.next()) {
            if (cntr % 25 == 0) {
                for(int j = 2; j <= rsmd.getColumnCount(); j++) {
                    out.print("<td bgcolor=\"teal\"><font color=\"white\">"+
                    rsmd.getColumnName(j) + "</font></td>");
                }
            }

            out.print("<tr>");
            if (cntr % 2 == 0) {
                out.print("<td><a href=\"statistics.jsp?sender=" + 
                rset.getString("Recipient") + "\">" +
                rset.getString("username") +
                "</a></td>");
            } else {
                out.print("<td bgcolor=\"#cccccc\"><a href=\"statistics.jsp"+
                "?sender=" + rset.getString("Recipient") + "\">" + 
                rset.getString("username") + "</a></td>");
            }
            
            for(int i = 3; i <= rsmd.getColumnCount(); i++) {
                if (cntr % 2 == 0) 
                    out.print("<td>" + rset.getString(i) + "</td>");
                else
                    out.print("<td bgcolor=\"#cccccc\">" + rset.getString(i) +
                    "</td>");
            }
            cntr++;
            out.print("</tr>");
        }

        out.print("</table>");
        out.print("</td>");
    }
%>
    <td width="150" align="right" valign="top">
    <% if (sender != 0) out.print("<h4>Users:</h4>"); %>
    <font size="2">
<%
    rset = stmt.executeQuery("select user_id, username from adium.users" +
    " order by username");

    int peopleCnt = 1;
    
    while (rset.next())  {
        if (rset.getInt("user_id") != sender) {
            out.print("<a href=\"statistics.jsp?sender=" + 
            rset.getString("user_id") + "\">" + rset.getString("username") +
            "</a>");
        }
        else {
            out.print(rset.getString("username"));
        }
        out.print("<br>");
        
        if (sender == 0 && peopleCnt++ % 30 == 0) {
            out.print("</font></td><td width=\"150\" valign=\"top\"" +
            "align=\"right\"><font size=\"2\">");
        }
    }
%>
</td></tr>
</table>
<%
} catch (SQLException e) {
    out.print(e.getMessage());
} finally {
    if (stmt != null) {
        stmt.close();
    }
    conn.close();
}
%>
</body>
</html>
