<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.sql.*' %>
<%@ page import = 'java.util.ArrayList' %>
<%@ page import = 'javax.naming.*' %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<!--$URL: http://svn.visualdistortion.org/repos/projects/adium/jsp/statistics.jsp $-->
<!--$Rev: 723 $ $Date: 2004/05/07 17:32:36 $ -->

<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();
int sender, meta_id;
String sender_sn = new String();
String senderDisplay = new String();
String title = new String("Statistics");
String notes = new String();

int total_messages = 0;
boolean loginUsers = false;
try {
    sender = Integer.parseInt(request.getParameter("sender"));
} catch (NumberFormatException e) {
    sender = 0;
}

try {
    meta_id = Integer.parseInt(request.getParameter("meta_id"));
} catch (NumberFormatException e) {
    meta_id = 0;
}

loginUsers = Boolean.valueOf(request.getParameter("login")).booleanValue();

PreparedStatement pstmt = null;
Statement stmt = null;
ResultSet rset = null;
ResultSet totals = null;
ResultSet year = null;
ResultSetMetaData rsmd = null;
try {

    stmt = conn.createStatement();

    if(sender != 0) {
        pstmt = conn.prepareStatement("select scramble(username) as username, "+
        "scramble(display_name) as display_name from " +
        " adium.users natural join adium.user_display_name udn " +
        " where user_id = ?"+
        " and not exists " +
        " (select 'x' from adium.user_display_name " +
        " where effdate > udn.effdate and user_id = users.user_id)");
        pstmt.setInt(1, sender);
        rset = pstmt.executeQuery();
        rset.next();
        
        title = rset.getString("display_name") + " (" + 
            rset.getString("username") + ")";

        sender_sn = rset.getString("username");
        senderDisplay = rset.getString("display_name");
    }

    if(meta_id != 0) {
        pstmt = conn.prepareStatement("select name, service, username,display_name from adium.meta_container natural join adium.meta_contact natural join adium.users natural join adium.user_display_name udn where meta_id = ? and not exists (select 'x' from adium.user_display_name where user_id = udn.user_id and effdate > udn.effdate)");

        pstmt.setInt(1, meta_id);

        rset = pstmt.executeQuery();

        
        while(rset.next()) {
            title = rset.getString("name");
            sender_sn = rset.getString("name");
            notes += rset.getString("display_name") + " (" + 
                rset.getString("service") + "." + 
                rset.getString("username") + ")<br />";
        }
    }
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
                    <p><%= notes %></p>
                </div>
            </div>
        </div>
        <div id="central">
            <div id="navcontainer">
                <ul id="navlist">
                    <li><a href="index.jsp">Viewer</a></li>
                    <li><a href="search.jsp">Search</a></li>
                    <li><span id="current">Statistics</span></li>
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
            " from messages, meta_contact where sender_id = user_id "+
            " and meta_id = ? order by full_date"); 

            pstmt.setInt(1, meta_id);
        }

        rset = pstmt.executeQuery();

        while(rset.next()) {
            out.print("<p><a href=\"details.jsp?" +
            "&meta_id=" + meta_id +
            "&sender_id=" + sender +
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
    pstmt = conn.prepareStatement("select meta_id, name from adium.meta_container order by name");

    rset = pstmt.executeQuery();

    while(rset.next()) {
        out.println("<p><a href=\"statistics.jsp?meta_id=" + rset.getInt("meta_id") + "\">" + rset.getString("name") + "</a></p>");
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
        " where login = " + loginUsers +
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
            "\" title=\"" + rset.getString("username") + "\">" +
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
    
    pstmt.setInt(1, sender);
    pstmt.setInt(2, sender);

    if(meta_id != 0) {
 
        pstmt = conn.prepareStatement("select " +
            " count(*) as total_sent, "+
            " min(length(message)) as min_sent_length, " +
            " max(length(message)) as max_sent_length, " +
            " trunc(avg(length(message)),2) as avg_sent_length " +
            " from adium.messages, adium.meta_contact " +
            " where sender_id = user_id " + 
            " and meta_id = ? " +
            " union all " +
            " select " +
            " count(*) as total_sent, " +
            " min(length(message)) as min_sent_length, " +
            " max(length(message)) as max_sent_length, " +
            " trunc(avg(length(message)),2) as avg_sent_length " +
            " from adium.messages, adium.meta_contact " +
            " where recipient_id =  user_id " +
            " and meta_id = ? ");
        
        pstmt.setInt(1, meta_id);
        pstmt.setInt(2, meta_id);

    }

    totals = pstmt.executeQuery();
        
    /*
    out.println("<pre>");
    while(totals.next()) {
        out.println(totals.getString(1));
    }
    
    out.println("</pre>");
    */
        
    if(totals.next()) {

        out.print("Total Messages Sent: " + 
            totals.getString("total_sent") + "<br>");
        total_messages += totals.getInt("total_sent");
        
        out.print("Minimum sent length: " + totals.getString("min_sent_length") +
        "<br>");
        out.print("Average Sent Length: " + 
            totals.getString("avg_sent_length") +
            "<br>");

        out.print("Maximum Sent Length: " + 
            totals.getString("max_sent_length") +
            "<br /><br />");
        
        totals.next();
            
        out.print("Total Messages Received: " + 
        totals.getString("total_sent") + "<br />");
        total_messages += totals.getInt("total_sent");
        
        out.println("Mimimum Received Length: " + totals.getString("min_sent_length") + "<br />");
        out.println("Average Received Length: " + totals.getString("avg_sent_length") + "<br />");
        out.println("Maximum Received Length: " + totals.getString("max_sent_length") + "<br />");
 
        out.println("<br />Total Messages Sent/Received: " + total_messages + "<br /><br/>");
    
    }
%>
                </div>
                <div class="boxWideBottom"></div>

                <h1>Messages Sent/Received by Year</h1>
                <div class="boxWideTop"></div>
                <div class="boxWideContent">
<%

    pstmt = conn.prepareStatement("select date_part('year', message_date) " +
    " as year, " +
    "count(*) as count from adium.messages where sender_id = ? or recipient_id = ? " +
    " group by date_part('year', message_date) " +
    " order by date_part('year', message_date)");
    
    pstmt.setInt(1, sender);
    pstmt.setInt(2, sender);

    if(meta_id != 0) {
        pstmt = conn.prepareStatement("select date_part('year', message_date) " +
        " as year, " +
        " count(*) as count from adium.messages, adium.meta_contact " + 
        " where (sender_id = user_id or recipient_id = user_id) " +
        " and meta_id = ? " +
        " group by date_part('year', message_date) " +
        " order by date_part('year', message_date)");
        
        pstmt.setInt(1, meta_id);
    }

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
%>
                </div>
                <div class="boxWideBottom"></div>
            
                <h1>Messages Sent/Received by Month</h1>
                <div class="boxWideTop"></div>
                <div class="boxWideContent">
<%
    pstmt = conn.prepareStatement("select date_part('month', message_date) " +
    "as month, count(*) as count from messages where sender_id = ? or " +
    "recipient_id = ? group by date_part('month', message_date)");

    pstmt.setInt(1, sender);
    pstmt.setInt(2, sender);

    if(meta_id != 0) {
        pstmt = conn.prepareStatement("select date_part('month', message_date) " +
        " as month, count(*) as count from adium.messages, adium.meta_contact " +
        " where (sender_id = user_id or " +
        " recipient_id = user_id) and meta_id = ? " +
        " group by date_part('month', message_date)");

        pstmt.setInt(1, meta_id);
    }

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
    
    out.print("<br />\n<table height=\"250\" width=\"350\"" +
    " cellspacing=\"0\"><tr>");

    for(int i = 1; i < 13; i++) {
        double height = monthArray[i] / maxDistance * 225;
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
%>
                </div>
                <div class="boxWideBottom"></div>

                <h1>Messages Sent/Received by Hour</h1>
                <div class="boxWideTop"></div>
                <div class="boxWideContent">
<%
    pstmt = conn.prepareStatement("select date_part('hour', message_date), sender_id = ? as sent, count(*) from messages where sender_id = ? or recipient_id = ? group by date_part('hour', message_date), sender_id = ?");

    for(int i = 1; i <= 4; i++) {
        pstmt.setInt(1, sender);
    }

    rset = pstmt.executeQuery();


%>
                </div>
                <div class="boxWideBottom"></div>
                
                <h1>Most Popular Messages</h1>
                <div class="boxWideTop"></div>
                <div class="boxWideContent">
<%
    pstmt = conn.prepareStatement("select message, count(*) " +
        " from adium.messages where sender_id = ? group by message " +
        " order by count(*) desc limit 20 ");

    pstmt.setInt(1, sender);

    if(meta_id != 0) {
        pstmt = conn.prepareStatement("select message, count(*) " +
            " from adium.messages, adium.meta_contact " +
            " where sender_id = user_id and meta_id = ? " +
            " group by message " +
            " order by count(*) desc limit 20 ");

        pstmt.setInt(1, meta_id);
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
        " group by sender_sn, recipient_sn, message "+
        " order by count(*) desc limit 20");
    
    pstmt.setInt(1, sender);
    pstmt.setInt(2, sender);

    if(meta_id != 0) {
         pstmt = conn.prepareStatement("select scramble(sender_sn) as sender_sn "+
            ", scramble(recipient_sn) as recipient_sn, " +
            " message, count(*) " +
            " from simple_message_v smv, adium.meta_contact "+
            " where not exists "+
                " (select 'x' from messages "+
                " where sender_id in (smv.sender_id, smv.recipient_id) "+
                " and recipient_id in (smv.sender_id, smv.recipient_id) "+
                " and message_date < smv.message_date " +
                " and message_date > smv.message_date - '10 minutes'::interval) "+
            " and (sender_id = user_id or recipient_id = user_id) "+
            " and meta_id = ? " +
            " group by sender_sn, recipient_sn, message "+
            " order by count(*) desc limit 20");

        pstmt.setInt(1, meta_id);
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
            </div>
            <div id="bottom">
                <div class="cleanHackBoth"> </div>
            </div>
        </div>
        <div id="footer">&nbsp;</div>
    </div>
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
