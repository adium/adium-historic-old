<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.sql.*' %>
<%@ page import = 'javax.naming.*' %>
<%@ page import = 'java.util.regex.*' %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<!--$URL: http://svn.visualdistortion.org/repos/projects/adium/jsp/details.jsp $-->
<!--$Rev: 751 $ $Date: 2004/05/12 05:25:53 $ -->

<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();

int sender, meta_id;
try {
    sender = Integer.parseInt(request.getParameter("sender_id"));
} catch (NumberFormatException e) {
    sender = 0;
}

try {
    meta_id = Integer.parseInt(request.getParameter("meta_id"));
} catch (NumberFormatException e) {
    meta_id = 0;
}

String date = request.getParameter("date");
if (date != null && date.equals("")) {
    date = null;
}

String endMonth = new String();

boolean loginUsers =
    Boolean.valueOf(request.getParameter("login")).booleanValue();

String sender_sn = new String();
String title = new String();

int lastDayOfMonth = 0;
String month = new String();

PreparedStatement pstmt = null;
Statement stmt = null;
ResultSet rset = null;
ResultSetMetaData rsmd = null;

try {
    
    stmt = conn.createStatement();
    
    pstmt = conn.prepareStatement("select scramble(username) as username, "+
    "scramble(display_name) as display_name, " +
    " date_part(\'day\', ?::timestamp + \'1 month\'::interval -"+ 
    " \'1 day\'::interval) as last_day, "+
    " ?::timestamp + \'1 month\'::interval as end_month, " +
    " to_char(?::timestamp, \'Mon, YYYY\') as month " +
    " from " +
    " adium.users natural join adium.user_display_name udn " +
    " where user_id = ?"+
    " and not exists " +
    " (select 'x' from adium.user_display_name " +
    " where effdate > udn.effdate and user_id = users.user_id)");
    
    pstmt.setString(1, date);
    pstmt.setString(2, date);
    pstmt.setString(3, date);
    pstmt.setInt(4, sender);

    if(meta_id != 0) {
        pstmt = conn.prepareStatement("select name as username, "+
        " name as display_name, " +
        " date_part(\'day\', ?::timestamp + \'1 month\'::interval -"+ 
        " \'1 day\'::interval) as last_day, "+
        " ?::timestamp + \'1 month\'::interval as end_month, " +
        " to_char(?::timestamp, \'Mon, YYYY\') as month " +
        " from " +
        " adium.meta_container " +
        " where meta_id = ? ");
        
        pstmt.setString(1, date);
        pstmt.setString(2, date);
        pstmt.setString(3, date);
        pstmt.setInt(4, meta_id);
    }

    rset = pstmt.executeQuery();
    rset.next();
    
    title = rset.getString("display_name");
    
    month = rset.getString("month");
    
    lastDayOfMonth = rset.getInt("last_day");
    
    endMonth = rset.getString("end_month");
    
    sender_sn = rset.getString("username");
%>

<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>Adium SQL Logger Statistics</title>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1" />
<link rel="stylesheet" type="text/css" href="styles/layout.css" />
<link rel="stylesheet" type="text/css" href="styles/default.css" />
<link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />
<script language="javascript" type="text/javascript">
 function OpenLink(c){
   window.open(c, 'link', 'width=480,height=480,scrollbars=yes,status=yes,toolbar=no');
 }
</script>
</head>
<body>
	<div id="container">
	   <div id="header">
	   </div>
	   <div id="banner">
            <div id="bannerTitle">
                <img class="adiumIcon" src="images/adiumy/blue.png" width="128" height="128" border="0" alt="Adium X Icon" />
                <div class="text">
                    <h1><%= title %></h1>
                    <p><%= month %></p>
                </div>
            </div>
        </div>
        <div id="central">
            <div id="navcontainer">
                <ul id="navlist">
                    <li><a href="index.jsp">Viewer</a></li>
                    <li><a href="search.jsp">Search</a></li>
                    <li><a href="statistics.jsp">Statistics</a></li>
                    <li><a href="users.jsp">Users</a></li>
                </ul>
            </div>
            <div id="sidebar-a">
<%
    if(sender != 0 || meta_id != 0) {
%>
                <h1>Detailed Statistics for <%= sender_sn %></h1>
                <div class="boxThinTop"></div>
                <div class="boxThinContent">
<%
        if(sender != 0) {
            pstmt = conn.prepareStatement("select distinct " +
            " to_char(date_trunc('month', message_date), 'Mon, YYYY') " +
            " as date, date_trunc('month', message_date) as full_date " +
            " from messages where sender_id = ? order by full_date"); 

            pstmt.setInt(1, sender);
        }

        if(meta_id != 0) {
            pstmt = conn.prepareStatement("select distinct " +
            " to_char(date_trunc('month', message_date), 'Mon, YYYY') " +
            " as date, date_trunc('month', message_date) as full_date " +
            " from messages, meta_contact "+ 
            " where sender_id = user_id and meta_id = ? order by full_date"); 

            pstmt.setInt(1, meta_id);
        }


        rset = pstmt.executeQuery();
        
        while(rset.next()) {
            out.print("<p><a href=\"details.jsp?sender=" +
            sender_sn + 
            "&sender_id=" + sender +
            "&meta_id=" + meta_id +
            "&date=" + rset.getString("full_date") + "\">");
            out.print(rset.getString("date") + "</a></p>");
        }

%>
                </div>
                <div class="boxThinBottom"></div>
<%
    }
%>

                <h1>Meta Contacts</h1>
                <div class="boxThinTop"></div>
                <div class="boxThinContent">

<%
    pstmt = conn.prepareStatement("select name, meta_id from adium.meta_container order by name");

    rset = pstmt.executeQuery();

    while(rset.next()) {
        out.println("<p><a href=\"statistics.jsp?meta_id=" + 
            rset.getInt("meta_id") + "\">" + rset.getString("name") +
            "</a></p>");
    }
%>
                </div>
                <div class="boxThinBottom"></div>

                <h1>Users</h1>
                <div class="boxThinTop"></div>
                <div class="boxThinContent">
<%
    rset = stmt.executeQuery("select user_id, " +
        " scramble(display_name) as display_name, " +
        " scramble(username) " +
        " as username from adium.users " +
        " natural join adium.user_display_name udn" +
        " where case when true = " + loginUsers +
        " then login = true" + 
        " else 1 = 1 end " +
        " and not exists (select 'x' from adium.user_display_name where " +
        " user_id = users.user_id and effdate > udn.effdate) " +
        " order by scramble(display_name), username");

    if(!loginUsers) {
        out.print("<p><i><a href=\"statistics.jsp?sender=" + 
            sender + "&login=true\">Login Users</a></i></p>");
    } else {
        out.print("<p><i><a href=\"statistics.jsp?sender=" +
            sender + "&login=false\">" + 
            "All Users</a></i></p>");
    }    
    out.println("<p></p>");
    
    while (rset.next())  {
        if (rset.getInt("user_id") != sender) {
            out.println("<p><a href=\"statistics.jsp?sender=" + 
            rset.getString("user_id") + "&login=" + 
            Boolean.toString(loginUsers) +
            "\" + title=\"" + rset.getString("username") + "\">" + 
            rset.getString("display_name") +
            "</a></p>");
        }
        else {
            out.println("<p>" + rset.getString("username") + "</p>");
        }
    }

%>
                </div>
                <div class="boxThinBottom"></div>
            </div>
            <div id="content">
                <h1>Total Messages Sent/Received</h1>
                <div class="boxWideTop"></div>
                <div class="boxWideContent">
<%
    pstmt = conn.prepareStatement("select " +
    " coalesce(count(*),0) as total_sent," +
    " coalesce(min(length(message)),0) as min_length, " +
    " coalesce(max(length(message)),0) as max_length, " +
    " coalesce(trunc(avg(length(message)),2),0) as avg_length, " +
    " \'S\' as identifier " +
    " from adium.messages " +
    " where sender_id = ? and message_date >= ?::timestamp " +
    " and message_date < ?::timestamp group by sender_id " + 
    " union all " +
    " select " + 
    " coalesce(count(*),0) as total_sent, " + 
    " coalesce(min(length(message)),0) as min_length, " +
    " coalesce(max(length(message)),0) as max_length, " +
    " coalesce(trunc(avg(length(message)), 2),0) as avg_length, " +
    " \'R\' as identifier " +
    " from adium.messages " +
    " where recipient_id = ? " +
    " and message_date >= ?::timestamp " +
    " and message_date < ?::timestamp " +
    " group by recipient_id ");
    
    pstmt.setInt(1, sender);
    pstmt.setString(2, date);
    pstmt.setString(3, endMonth);
    pstmt.setInt(4, sender);
    pstmt.setString(5, date);
    pstmt.setString(6, endMonth);
    
    if(meta_id != 0) {
        pstmt = conn.prepareStatement("select " +
        " coalesce(count(*),0) as total_sent," +
        " coalesce(min(length(message)),0) as min_length, " +
        " coalesce(max(length(message)),0) as max_length, " +
        " coalesce(trunc(avg(length(message)),2),0) as avg_length, " +
        " \'S\' as identifier " +
        " from adium.messages, adium.meta_contact " +
        " where sender_id = user_id and " +
        " meta_id = ? " +
        " and message_date >= ?::timestamp " +
        " and message_date < ?::timestamp " + 
        " union all " +
        " select " + 
        " coalesce(count(*),0) as total_sent, " + 
        " coalesce(min(length(message)),0) as min_length, " +
        " coalesce(max(length(message)),0) as max_length, " +
        " coalesce(trunc(avg(length(message)), 2),0) as avg_length, " +
        " \'R\' as identifier " +
        " from adium.messages, adium.meta_contact " +
        " where recipient_id = user_id " +
        " and meta_id = ? " +
        " and message_date >= ?::timestamp " +
        " and message_date < ?::timestamp");
        
        pstmt.setInt(1, meta_id);
        pstmt.setString(2, date);
        pstmt.setString(3, endMonth);
        pstmt.setInt(4, meta_id);
        pstmt.setString(5, date);
        pstmt.setString(6, endMonth);
    }
    
    rset = pstmt.executeQuery();

    if(rset != null && rset.next()) {
        int total = 0;
        if(rset.getString("identifier").equals("S")) { %>
            Total Sent: <%= rset.getString("total_sent") %><br />
            <% total += rset.getInt("total_sent"); %>
            Minimum Sent Length: <%= rset.getString("min_length") %><br />
            Maximum Sent Length: <%= rset.getString("max_length") %><br />
            Average Sent Length: <%= rset.getString("avg_length") %><br />
    <%  } else { %>
            Total Sent: 0<br />
            Minimum Sent Length: 0<br />
            Maximum Sent Length: 0<br />
            Average Sent Length: 0<br />
    <%  } %>
        <br />
    <%  rset.next(); 
        if(rset.getString("identifier").equals("R")) { 
    %>
            Total Received: <%= rset.getString("total_sent") %><br />
            <% total += rset.getInt("total_sent"); %>
            Minimum Received Length: <%= rset.getString("min_length") %><br />
            Maximum Received Length: <%= rset.getString("max_length") %><br />
            Average Received Length: <%= rset.getString("avg_length") %><br />
            <br />
    <%  } else { %>
        Total Received: 0 <br />
        Minimum Received Length: 0<br />
        Maximum Received Length: 0<br />
        Average Received Length: 0<br />
        <br />
        <% } %>
        
        Total Sent/Received: <%= total %><br />
        <br />
    <%  } %>
    
                </div>
                <div class="boxWideBottom"></div>
                
                <h1>Total Messages by Day</h1>
                <div class="boxWideTop"></div>
                <div class="boxWideContent">
                
<%
    pstmt = conn.prepareStatement("select " +
    " date_part(\'day\', message_date) as day," +
    " count(*) as count " +
    " from messages " +
    " where message_date >= ?::date " +
    " and message_date < ?::date " +
    " and (sender_id = ? or recipient_id = ?) " +
    " group by date_part(\'day\', message_date)");

    pstmt.setString(1, date);
    pstmt.setString(2, endMonth);
    pstmt.setInt(3, sender);
    pstmt.setInt(4, sender);

    if(meta_id != 0) {
        pstmt = conn.prepareStatement("select " +
            " date_part(\'day\', message_date) as day," +
            " count(*) as count " +
            " from messages, meta_contact " +
            " where message_date >= ?::date " +
            " and message_date < ?::date " +
            " and (sender_id = user_id or recipient_id = user_id) " +
            " and meta_id = ? " +
            " group by date_part(\'day\', message_date)");

        pstmt.setString(1, date);
        pstmt.setString(2, endMonth);
        pstmt.setInt(3, meta_id);
    }

    
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

    out.print("<table cellspacing=\"0\" cellpadding=\"0\"><tr>");
    
    for (int i = 1; i <= lastDayOfMonth; i++) {
        double height = (double)dailyAry[i] / maxCount * 300;
        if (height < 1 && height != 0) {
            height = 1;
        }
        out.print("<td height=\"300\" valign=\"bottom\"" +
        " background=\"images/gridline.gif\" rowspan=\"4\">");
        out.print("<img src=\"images/bar2.gif\" width=\"11\" height=\"" +
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
%>

                </div>
                <div class="boxWideBottom"></div>
                
                <h1>Most Popular Messages</h1>
                <div class="boxWideTop"></div>
                <div class="boxWideContent">
                
<%
    pstmt = conn.prepareStatement("select message, count(*) " +
        " from messages where sender_id = ? " +
        " and message_date >= ?::timestamp " +
        " and message_date < ?::timestamp " +
        " group by message " +
        " having count(*) > 1 " +
        " order by count(*) desc limit 20 ");

    pstmt.setInt(1, sender);
    pstmt.setString(2, date);
    pstmt.setString(3, endMonth);

    if(meta_id != 0) {
        pstmt = conn.prepareStatement("select message, count(*) " +
            " from messages, meta_contact " +
            " where sender_id = user_id and meta_id = ? " +
            " and message_date >= ?::timestamp " +
            " and message_date < ?::timestamp " +
            " group by message " +
            " having count(*) > 1 " +
            " order by count(*) desc limit 20 ");

        pstmt.setInt(1, meta_id);
        pstmt.setString(2, date);
        pstmt.setString(3, endMonth);
    }

    rset = pstmt.executeQuery();

    out.println("<table>");
    
    out.println("<tr><td>#</td>"+
        "<td>Message</td><td >"+
        "Cnt</td></tr>");

    while(rset.next()) {
        out.println("<tr><td>" + rset.getRow() + "</td>");
        out.println("<td>" + 
            rset.getString("message") + "</td>");
        out.println("<td>" + 
                rset.getString("count") + "</td></tr>");
    }
    out.println("</table>");

%>
                </div>
                <div class="boxWideBottom"></div>
                
                <h1>Most Popular Conversation Starters</h1>
                <div class="boxWideTop"></div>
                <div class="boxWideContent">
<%
    pstmt = conn.prepareStatement("select scramble(sender_sn) as sender_sn"+
        ", scramble(recipient_sn) as recipient_sn, "+
        " message, count(*) "+
        " from simple_message_v smv "+
        " where not exists "+
            " (select 'x' from messages "+
            " where sender_id in (smv.sender_id, smv.recipient_id) "+
            " and recipient_id in (smv.sender_id, smv.recipient_id) "+
            " and message_date < smv.message_date "+
            " and message_date > smv.message_date - '10 minutes'::interval) "+
        " and (sender_id = ? or recipient_id = ?) "+
        " and message_date >= ?::timestamp " +
        " and message_date < ?::timestamp " +
        " group by sender_sn, recipient_sn, message "+
        " order by count(*) desc limit 20");
    
    pstmt.setInt(1, sender);
    pstmt.setInt(2, sender);
    pstmt.setString(3, date);
    pstmt.setString(4, endMonth);

    if(meta_id != 0) {
        pstmt = conn.prepareStatement("select scramble(sender_sn) as sender_sn"+
            ", scramble(recipient_sn) as recipient_sn, "+
            " message, count(*) "+
            " from simple_message_v smv, meta_contact "+
            " where not exists "+
                " (select 'x' from messages "+
                " where sender_id in (smv.sender_id, smv.recipient_id) "+
                " and recipient_id in (smv.sender_id, smv.recipient_id) "+
                " and message_date < smv.message_date "+
                " and message_date > smv.message_date - '10 minutes'::interval) "+
            " and (sender_id = user_id or recipient_id = user_id) "+
            " and meta_id = ? " +
            " and message_date >= ?::timestamp " +
            " and message_date < ?::timestamp " +
            " group by sender_sn, recipient_sn, message "+
            " order by count(*) desc limit 20");
    
        pstmt.setInt(1, meta_id);
        pstmt.setString(2, date);
        pstmt.setString(3, endMonth);
    }

    rset = pstmt.executeQuery();
%>
                <table>
                    <tr>
                        <td>#</td>
                        <td>Sender</td>
                        <td>Recipient</td>
                        <td>Message</td>
                        <td>Count</td>
                    </tr>
<%
        while(rset.next()) {
            out.println("<tr>");
            out.println("<td>" + 
                rset.getRow() + "</td>");
            out.println("<td>" + rset.getString("sender_sn") + "</td>");
            out.println("<td>" + rset.getString("recipient_sn") + "</td>");
            out.println("<td>" + rset.getString("message") + "</td>");
            out.println("<td>" + rset.getString("count") + "</td>");
            out.println("</tr>");
        }
        out.print("</table>");

%>
                </div>
                <div class="boxWideBottom"></div>
                
                <h1>Messages by Hour of Day</h1>
                <div class="boxWideTop"></div>
                <div class="boxWideContent">
<%
    pstmt = conn.prepareStatement("select " +
        " date_part(\'day\', message_date) as day, " +
        " date_part(\'hour\', message_date) as hour, " +
        " count(*) as count" +
        " from messages " + 
        " where (sender_id = ? or recipient_id = ?) " +
        " and message_date >= ?::timestamp " +
        " and message_date < ?::timestamp " +
        " group by date_part(\'day\', message_date), " +
        " date_part(\'hour\', message_date)");

    pstmt.setInt(1, sender);
    pstmt.setInt(2, sender);
    pstmt.setString(3, date);
    pstmt.setString(4, endMonth);

    if(meta_id != 0) {
        pstmt = conn.prepareStatement("select " +
            " date_part(\'day\', message_date) as day, " +
            " date_part(\'hour\', message_date) as hour, " +
            " count(*) as count" +
            " from messages, meta_contact " + 
            " where (sender_id = user_id or recipient_id = user_id) " +
            " and meta_id = ? " +
            " and message_date >= ?::timestamp " +
            " and message_date < ?::timestamp " +
            " group by date_part(\'day\', message_date), " +
            " date_part(\'hour\', message_date)");

        pstmt.setInt(1, meta_id);
        pstmt.setString(2, date);
        pstmt.setString(3, endMonth);
    }

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

    out.println("<table border=\"0\">");
    out.println("<tr><td></td>");
    for(int i = 0; i < 24; i++) {
        out.println("<td>" + i + "</td>");
    }
    out.println("<td>"+
    "Total</td></tr>");

    for(int i = 1; i <= lastDayOfMonth; i++) {
        out.print("<tr><td>" + i + "</td>");
        for(int j = 0; j < 24; j++) {
            String start = new String(date);
            String finish = new String(date);

            start = start.replaceFirst("01 ", i + " ");
            start = start.replaceFirst("00:", j + ":");
            if(j != 23) {
                finish = finish.replaceFirst("01 ", i + " ");
                finish = finish.replaceFirst("00:", j + 1  + ":");
            } else if (j == 23 && i != lastDayOfMonth) {
                finish = finish.replaceFirst("01 ", (i + 1) + " ");
            } else if (j == 23 && i == lastDayOfMonth) {
                Pattern p = Pattern.compile("(\\d*-)(\\d*)(-01.*)");
                Matcher m = p.matcher(finish);
                StringBuffer sb = new StringBuffer();
                while(m.find()) {
                    sb.append(m.group(1) +
                        (Integer.parseInt(m.group(2)) + 1) +
                        m.group(3));
                }
                finish = sb.toString();
            } 

            out.print("<td align=\"center\" class=\"shade\"");

            double shade = (255 - ((double) dailyHourly[i][j] / maxHourly) * 255);
            if (dailyHourly[i][j] != 0) {
                 out.print(" bgcolor=\"#" + Integer.toHexString((int)shade) +
                 Integer.toHexString((int)shade) +
                 Integer.toHexString((int)shade) + "\" ");
                out.print("><a href=\"index.jsp?start=" + start +
                "&finish=" + finish + "\">" + dailyHourly[i][j] + 
                "</a>");
            } else {
                out.print(">&nbsp;&nbsp;&nbsp;&nbsp;");
            }
            
            out.print("</td>");
        }
        out.print("<td ");
        out.print(" align=\"right\"><b>" + dailyAry[i] + "</b></td>");
        out.print("</tr>");
    }
    out.print("</table>");
%>
                </div>
                <div "class="boxWideBottom"></div>
                
                <h1>Message Statistics</h1>
                <div class="boxWideTop"></div>
                <div class="boxWideContent">
<%
    pstmt = conn.prepareStatement("select scramble(username) as username, "+
    " recipient_id as \"Recipient\", "+ 
    " count(*) as \"Sent\", (select count(*)"+
    " from messages where"+
    " recipient_id = a.sender_id and sender_id = a.recipient_id " +
    " and message_date >= ?::timestamp and message_date < ?::timestamp) as " +
    " \"Recieved\", " +
    " trunc(avg(length(message)), 2) as "+
    " \"Avg Sent Length\", (select coalesce(trunc(avg(length(message)),2),0)"+
    " from "+
    " messages where a.sender_id = recipient_id and sender_id = " +
    " a.recipient_id and message_date >= ?::timestamp" +
    " and message_date < ?::timestamp " +
    " ) as \"Avg Recd Length\","+
    " min(length(message)) as \"Min Sent\", max(length(message))"+
    " as \"Max Sent\","+
    " (select coalesce(min(length(message)),0) from messages where a.sender_id = "+
    " recipient_id and sender_id = a.recipient_id " +
    " and message_date >= ?::timestamp and message_date < ?::timestamp "+
    " ) as \"Min Received\","+
    " (select "+
    " coalesce(max(length(message)),0) from "+
    " messages where a.sender_id = recipient_id and a.recipient_id " +
    " = sender_id and message_date >= ?::timestamp " +
    " and message_date < ?::timestamp)"+
    " as \"Max Received\" from messages a, users "+
    " where sender_id = ? and message_date >= ?::timestamp " +
    " and message_date < ?::timestamp " +
    " and users.user_id = a.recipient_id " +
    " group by sender_id, recipient_id, username");

    pstmt.setString(1, date);
    pstmt.setString(2, endMonth);
    pstmt.setString(3, date);
    pstmt.setString(4, endMonth);
    pstmt.setString(5, date);
    pstmt.setString(6, endMonth);
    pstmt.setString(7, date);
    pstmt.setString(8, endMonth);
    pstmt.setInt(9, sender);
    pstmt.setString(10, date);
    pstmt.setString(11, endMonth);

    if(meta_id != 0) {
        pstmt = conn.prepareStatement("select scramble(username) as username, "+
            " recipient_id as \"Recipient\", "+ 
            " count(*) as \"Sent\", (select count(*)"+
            " from messages where"+
            " recipient_id = a.sender_id and sender_id = a.recipient_id " +
            " and message_date >= ?::timestamp " +
            " and message_date < ?::timestamp) as " +
            " \"Recieved\", " +
            " trunc(avg(length(message)), 2) as "+
            " \"Avg Sent Length\", " + 
            " (select coalesce(trunc(avg(length(message)),2),0)"+
            " from "+
            " messages " +
            " where a.sender_id = recipient_id and sender_id = " +
            " a.recipient_id and message_date >= ?::timestamp" +
            " and message_date < ?::timestamp " +
            " ) as \"Avg Recd Length\","+
            " min(length(message)) as \"Min Sent\", max(length(message))"+
            " as \"Max Sent\","+
            " (select coalesce(min(length(message)),0) from messages where a.sender_id = "+
            " recipient_id and sender_id = a.recipient_id " +
            " and message_date >= ?::timestamp and message_date < ?::timestamp "+
            " ) as \"Min Received\","+
            " (select "+
            " coalesce(max(length(message)),0) from "+
            " messages where a.sender_id = recipient_id and a.recipient_id " +
            " = sender_id and message_date >= ?::timestamp " +
            " and message_date < ?::timestamp)"+
            " as \"Max Received\" from messages a, users, meta_contact "+
            " where sender_id = meta_contact.user_id "+
            " and meta_id = ? " +
            " and message_date >= ?::timestamp " +
            " and message_date < ?::timestamp " +
            " and users.user_id = a.recipient_id " +
            " group by sender_id, recipient_id, username");

        pstmt.setString(1, date);
        pstmt.setString(2, endMonth);
        pstmt.setString(3, date);
        pstmt.setString(4, endMonth);
        pstmt.setString(5, date);
        pstmt.setString(6, endMonth);
        pstmt.setString(7, date);
        pstmt.setString(8, endMonth);
        pstmt.setInt(9, meta_id);
        pstmt.setString(10, date);
        pstmt.setString(11, endMonth);
    }
    
    rset = pstmt.executeQuery();

    rsmd = rset.getMetaData();

    out.print("<table>");
    
    int cntr = 0;
    while(rset.next()) {
        if (cntr % 25 == 0) {
            out.print("<td>#</td>");
            for(int j = 2; j <= rsmd.getColumnCount(); j++) {
                out.print("<td>"+
                rsmd.getColumnName(j) + "</td>");
            }
        }

        out.print("<tr>");
        out.println("<td>" + rset.getRow() + "</td>");
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

<%
} catch (SQLException e) {
    out.print("<span style=\"color: red\">" + e.getMessage() + "</span>");
    while(e.getNextException() != null) {
        out.println(e.getMessage());
    }
} finally {
    if (stmt != null) {
        stmt.close();
    }
    conn.close();
}
%>
</body>
</html>
