<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.sql.*' %>
<%@ page import = 'javax.naming.*' %>

<!DOCTYPE HTML PUBLIC "-//W3C/DTD HTML 4.01 Transitional//EN">
<!--$URL: http://svn.visualdistortion.org/repos/projects/adium/jsp/details.jsp $-->
<!--$Rev: 356 $ $Date: 2003/08/05 04:25:49 $ -->
<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();

String sender = request.getParameter("sender");
if (sender != null && sender.equals("")) {
    sender = null;
}
int sender_id;
try {
	sender_id = Integer.parseInt(request.getParameter("sender_id"));
} catch (NumberFormatException e) {
	sender_id = 0;
}

String date = request.getParameter("date");
if (date != null && date.equals("")) {
    date = null;
}
%>
<html>
    <head>
        <title>Detailed Adium Statistics</title>
    </head>
    <body>
<%
PreparedStatement pstmt = null;
ResultSet rset = null;
ResultSetMetaData rsmd = null;

int lastDayOfMonth = 0;
try {
    
    pstmt = conn.prepareStatement("select " +
    " to_char(?::timestamp, \'Mon, YYYY\') as month, " +
    " count(*) as total_sent," +
    " min(length(message)) as min_length, " +
    " max(length(message)) as max_length, " +
    " trunc(avg(length(message)),2) as avg_length, " +
    " null as last_day " +
    " from adium.messages " +
    " where sender_id = ? and date_trunc(\'month\', " +
    " message_date) = ?::timestamp group by sender_id " + 
    " union all " +
    " select " + 
    " null as month, " +
    " count(*) as total_sent, " + 
    " min(length(message)) as min_length, " +
    " max(length(message)) as max_length, " +
    " trunc(avg(length(message)), 2) as avg_length, " +
    " date_part(\'day\', ?::timestamp + \'1 month\'::interval -"+ 
    " \'1 day\'::interval) as last_day"+
    " from adium.messages " +
    " where recipient_id = ? " +
    " and date_trunc(\'month\', message_date) = ? " +
    " group by recipient_id ");
    
    pstmt.setString(1, date);
    pstmt.setInt(2, sender_id);
    pstmt.setString(3, date);
    pstmt.setString(4, date);
    pstmt.setInt(5, sender_id);
    pstmt.setString(6, date);
    rset = pstmt.executeQuery();
    
    out.print("<div align=\"center\"><h3>");
    out.print(sender + "<br />");
    
    if(rset != null && rset.next()) {
        int total = 0;
        out.print(rset.getString("month"));
        out.print("</h3></div>");
    %>
        Total Sent: <%= rset.getString("total_sent") %><br />
        <% total += rset.getInt("total_sent"); %>
        Minimum Sent Length: <%= rset.getString("min_length") %><br />
        Maximum Sent Length: <%= rset.getString("max_length") %><br />
        Average Sent Length: <%= rset.getString("avg_length") %><br />
        <br />
        <% rset.next(); %>
        Total Received: <%= rset.getString("total_sent") %><br />
        <% total += rset.getInt("total_sent"); %>
        Minimum Received Length: <%= rset.getString("min_length") %><br
        />
        Maximum Received Length: <%= rset.getString("max_length") %><br
        />
        Average Received Length: <%= rset.getString("avg_length") %><br
        />
        <br />
        Total Sent/Received: <%= total %><br />
        <br />
    <%
    lastDayOfMonth = rset.getInt("last_day");
    }
    
    pstmt = conn.prepareStatement("select " +
    " date_part(\'day\', message_date) as day," +
    " count(*) as count " +
    " from messages " +
    " where date_trunc(\'month\', message_date) = ?::date " +
    " and (sender_id = ? or recipient_id = ?) " +
    " group by date_part(\'day\', message_date)");

    pstmt.setString(1, date);
    pstmt.setInt(2, sender_id);
    pstmt.setInt(3, sender_id);

    rset = pstmt.executeQuery();
    
    int[] dailyAry = new int[lastDayOfMonth + 1];
    int maxCount = 0;
    
    for(int i = 0; i <= lastDayOfMonth; i++) {
        dailyAry[i] = 0;
    }
    
    while(rset.next()) {
        dailyAry[rset.getInt("day")] = rset.getInt("count");
        
        if (rset.getInt("count") > maxCount) {
            maxCount = rset.getInt("count");
        }
    }
    maxCount *= 1.1;

    out.print("<table cellspacing=\"0\"><tr><td colspan=\"" + lastDayOfMonth + 
    "\" align=\"center\" bgcolor=\"navy\">");
    out.println("<b><font color=\"white\">");
    out.println("Number of Messages by Date</font></b>");
    out.println("</td></tr><tr>");
    
    for (int i = 1; i <= lastDayOfMonth; i++) {
        double height = (double)dailyAry[i] / maxCount * 300;
        if (height < 1 && height != 0) {
            height = 1;
        }
        out.print("<td height=\"300\" valign=\"bottom\"" +
        " background=\"images/gridline.gif\" rowspan=\"4\">");
        out.print("<img src=\"images/bar2.gif\" width=\"15\" height=\"" +
        (int)height  + "\"></td>");
    }
    
    out.print("<td valign=\"top\" height=\"70\">" + maxCount + "</td></tr>");
    out.print("<tr><td valign=\"top\" height=\"73\">" + 
        (int) (maxCount * .75) + "</td></tr>");
    out.print("<tr><td valign=\"top\" height=\"75\">" + 
        (int) (maxCount * .5) + "</td></tr>");
    out.print("<tr><td valign=\"top\">" + (int) (maxCount * .25) + 
        "</td></tr>");
    
    out.print("<tr>");
    for(int i = 1; i <= lastDayOfMonth; i++) {
        out.print("<td valign=\"top\" align=\"center\">" + 
        i + "&nbsp;</td>");
    }
    out.print("</tr>");
    
    out.print("</table>");

    pstmt = conn.prepareStatement("select " +
    " date_part(\'day\', message_date) as day, " +
    " date_part(\'hour\', message_date) as hour, " +
    " count(*) as count" +
    " from messages " + 
    " where (sender_id = ? or recipient_id = ?) " +
    " and date_trunc(\'month\', message_date) = ?::timestamp " +
    " group by date_part(\'day\', message_date), " +
    " date_part(\'hour\', message_date)");

    pstmt.setInt(1, sender_id);
    pstmt.setInt(2, sender_id);
    pstmt.setString(3, date);

    rset = pstmt.executeQuery();
    
    int[][] dailyHourly= new int[lastDayOfMonth + 1][24];
    int maxHourly = 0;
    for(int i = 0; i <= lastDayOfMonth; i++) {
        for(int j = 0; j < 24; j++) {
            dailyHourly[i][j] = 0;
        }
    }

    while(rset.next()) {
        dailyHourly[rset.getInt("day")][rset.getInt("hour")] = 
        rset.getInt("count");
        if (rset.getInt("count") > maxHourly) {
            maxHourly = rset.getInt("count");
        }
    }

    out.println("<br /><table border=\"0\">");
    out.println("<tr><td colspan=\"26\" align=\"center\" bgcolor=\"navy\">");
    out.println("<b><font color=\"white\">");
    out.println("Instant Messages by Hour of Day</font></b>");
    out.println("</td></tr>");
    out.println("<tr><td bgcolor=\"teal\"></td>");
    for(int i = 0; i < 24; i++) {
        out.println("<td bgcolor=\"teal\" align=\"center\">" + 
        " <font color=\"white\">" + i + 
        "</font></td>");
    }
    out.println("<td bgcolor=\"teal\"><font color=\"white\"> "+
    "<b>Total</b></font></td></tr>");

    for(int i = 1; i <= lastDayOfMonth; i++) {
        out.println("<tr><td align=\"right\"");
        out.println(" bgcolor=\"#99CCFF\">" + i + "</td>");
        for(int j = 0; j < 24; j++) {
            String after = new String(date);
            String before = new String(date);

            after = after.replaceFirst("01 ", i + " ");
            after = after.replaceFirst("00:", j + ":");

            before = before.replaceFirst("01 ", i + " ");
            before = before.replaceFirst("00:", j + 1 + ":");

            out.print("<td align=\"center\"");
            
            if(i % 2 == 0) {
                out.print(" bgcolor=\"#cccccc\" ");
            }
            
            // double shade = ((double) dailyHourly[i][j] / maxHourly) * 255;
            if (dailyHourly[i][j] != 0) {
                // out.print(" bgcolor=\"#" + Integer.toHexString((int)shade) +
                // Integer.toHexString((int)shade) +
                // Integer.toHexString((int)shade) + "\" ");
                out.print("><a href=\"index.jsp?after=" + after +
                "&before=" + before + "\">" + dailyHourly[i][j] + 
                "</a>");
            } else
                out.print(">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;");

            out.print("</td>");
        }
        out.print("<td ");
        if(i % 2 == 0) out.print(" bgcolor=\"#cccccc\"");
        out.print(" align=\"right\"><b>" + dailyAry[i] + "</b></td>");
        out.print("</tr>");
    }
    out.print("</table><br />");

    pstmt = conn.prepareStatement("select username, recipient_id as \"Recipient\", "+ 
    " count(*) as \"Sent\", (select count(*)"+
    " from messages where"+
    " recipient_id = a.sender_id and sender_id = a.recipient_id " +
    " and date_trunc('month', message_date) = ?::timestamp) as " +
    " \"Recieved\", " +
    " trunc(avg(length(message)), 2) as "+
    " \"Avg Sent Length\", (select coalesce(trunc(avg(length(message)),2),0)"+
    " from "+
    " messages where a.sender_id = recipient_id and sender_id = " +
    " a.recipient_id and date_trunc('month', message_date) = ?::timestamp" +
    " ) as \"Avg Recd Length\","+
    " min(length(message)) as \"Min Sent\", max(length(message))"+
    " as \"Max Sent\","+
    " (select coalesce(min(length(message)),0) from messages where a.sender_id = "+
    " recipient_id and sender_id = a.recipient_id " +
    " and date_trunc('month', message_date) = ?::timestamp) as \"Min Received\","+
    " (select "+
    " coalesce(max(length(message)),0) from "+
    " messages where a.sender_id = recipient_id and a.recipient_id " +
    " = sender_id and date_trunc('month', message_date) = ?::timestamp)"+
    " as \"Max Received\" from messages a, users "+
    " where sender_id = ? and date_trunc('month', message_date) = ?::timestamp " +
    " and users.user_id = a.recipient_id " +
    " group by sender_id, recipient_id, username");

    pstmt.setString(1, date);
    pstmt.setString(2, date);
    pstmt.setString(3, date);
    pstmt.setString(4, date);
    pstmt.setInt(5, sender_id);
    pstmt.setString(6, date);

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
            rset.getString("Recipient") + "\">" + rset.getString("username") +
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

} catch (SQLException e) {
    out.print(e.getMessage());
} finally {
    if (pstmt != null) {
        pstmt.close();
    }
    conn.close();
}
%>
</body>
</html>
