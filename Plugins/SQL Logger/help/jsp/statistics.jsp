<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.sql.*' %>
<%@ page import = 'java.util.ArrayList' %>
<%@ page import = 'javax.naming.*' %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<!--$URL: http://svn.visualdistortion.org/repos/projects/sqllogger/jsp/statistics.jsp $-->
<!--$Rev: 898 $ $Date$ -->

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

int totalStats[][] = new int[2][3];
double sentAve = 0;
double recAve = 0;

int max = 0;
int years = 0;

int monthArray[][] = new int[10][14];

PreparedStatement pstmt = null;
Statement stmt = null;
ResultSet rset = null;
ResultSet totals = null;
ResultSetMetaData rsmd = null;
try {

    stmt = conn.createStatement();

    if(sender != 0) {
        pstmt = conn.prepareStatement("select username as username, "+
            " display_name as display_name, lower(service) as service  from " +
            " im.users natural join im.user_display_name udn " +
            " where user_id = ?"+
            " and not exists " +
            " (select 'x' from im.user_display_name " +
            " where effdate > udn.effdate and user_id = users.user_id)");
        pstmt.setInt(1, sender);
        rset = pstmt.executeQuery();
        rset.next();

        title = "<img src=\"images/services/" + rset.getString("service") +
            ".png\" width=\"28\" height=\"28\"> " +
            rset.getString("display_name") + " (" +
            rset.getString("username") + ")";

        sender_sn = rset.getString("username");
        senderDisplay = rset.getString("display_name");
    }

    if(meta_id != 0) {
        pstmt = conn.prepareStatement("select name, lower(service) as service, username,display_name from im.meta_container natural join im.meta_contact natural join im.users natural join im.user_display_name udn where meta_id = ? and not exists (select 'x' from im.user_display_name where user_id = udn.user_id and effdate > udn.effdate)");

        pstmt.setInt(1, meta_id);

        rset = pstmt.executeQuery();


        while(rset.next()) {
            title = rset.getString("name");
            sender_sn = rset.getString("name");
            notes += "<img src=\"images/services/" +
                rset.getString("service") +
                ".png\" width=\"12\" height=\"12\" /> " +
                rset.getString("display_name") + " (" +
                rset.getString("username") + ")<br />";
        }
    }
%>

<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>Adium SQL Logger: Statistics</title>
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
                    <li><a href="meta.jsp">Meta-Contacts</a></li>
                    <li><a href="query.jsp">Query</a></li>
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
        pstmt = conn.prepareStatement("select date_part('month', message_date) " +
                " as month, date_part('year', message_date) as year, " +
                " count(*) as count, " +
                " to_char(date_trunc('month', message_date), 'Mon, YYYY') " +
                " as date, date_trunc('month', message_date) as full_date, " +
                " sender_id = ? as is_sender " +
                " from messages where sender_id = ? or " +
                " recipient_id = ? group by date_part('month', message_date), " +
                " to_char(date_trunc('month', message_date), 'Mon, YYYY'), " +
                " date_trunc('month', message_date), " +
                " date_part('year', message_date), sender_id = ?  order by full_date");

        pstmt.setInt(1, sender);
        pstmt.setInt(2, sender);
        pstmt.setInt(3, sender);
        pstmt.setInt(4, sender);

        if(meta_id != 0) {
            pstmt = conn.prepareStatement("select date_part('month', message_date) " +
                    " as month, date_part('year', message_date) as year, " +
                    " to_char(date_trunc('month', message_date), 'Mon, YYYY') " +
                    " as date, date_trunc('month', message_date) as full_date, " +
                    " count(*) as count, sender_id = user_id as is_sender " +
                    " from im.messages, im.meta_contact " +
                    " where (sender_id = user_id or " +
                    " recipient_id = user_id) and meta_id = ? " +
                    " group by date_part('month', message_date), " +
                    " to_char(date_trunc('month', message_date), 'Mon, YYYY'), " +
                    " date_trunc('month', message_date), " +
                    " date_part('year', message_date), sender_id = user_id " +
                    " order by full_date");

            pstmt.setInt(1, meta_id);

        }

        totals = pstmt.executeQuery();

        String prev = new String();

        for(int i = 0; i < 2; i++) {
            for( int j = 0; j < 3; j++) {
                totalStats[i][j] = 0;
            }
        }

        for(int i = 0; i < 10; i++) {
            for(int j = 0; j < 14; j++) {
                monthArray[i][j] = 0;
            }
        }


        while(totals.next()) {
            if(!prev.equals(totals.getString("date"))) {
                out.println("<p><a href=\"details.jsp?" +
                        "&meta_id=" + meta_id +
                        "&sender_id=" + sender +
                        "&date=" + totals.getString("full_date") + "\">");
                out.print(totals.getString("date") + "</a></p>");
                prev = totals.getString("date");
            }

            if(totals.getBoolean("is_sender")) {

                totalStats[0][0] += totals.getInt("count");
                totalStats[0][1]++;
                sentAve = (double)totalStats[0][0] /
                    totalStats[0][1];

            } else {

                totalStats[1][0] += totals.getInt("count");
                totalStats[1][1]++;
                recAve = (double) totalStats[1][0] /
                    totalStats[1][1];
            }

            boolean found = false;
            if(totals.getInt("count") > max) max = totals.getInt("count");

            for(int i = 0; i < years && !found; i++) {
                if(monthArray[i][0] == totals.getInt("year")) {
                    found = true;
                    monthArray[i][totals.getInt("month")] = totals.getInt("count");
                    monthArray[i][13] += totals.getInt("count");
                }
            }

            if(!found) {
                monthArray[years][0] = totals.getInt("year");
                monthArray[years][totals.getInt("month")] = totals.getInt("count");
                monthArray[years++][13] += totals.getInt("count");
            }

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
    pstmt = conn.prepareStatement("select meta_id, name from im.meta_container order by name");

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
        " display_name as display_name, " +
        " username " +
        " as username, lower(service) as service from im.users " +
        " natural join im.user_display_name udn" +
        " where case when true = " + loginUsers +
        " then login = true " +
        " else 1 = 1 " +
        " end " +
        " and not exists (select 'x' from im.user_display_name where " +
        " user_id = users.user_id and effdate > udn.effdate) " +
        " order by display_name, username");

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
            out.println("<p>");
            out.println("<img src=\"images/services/" +
                rset.getString("service") + ".png\" width=\"12\" height=\"12\" />");
            out.println("<a href=\"statistics.jsp?sender=" +
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

out.print("Total Messages Sent: " +
        totalStats[0][0] + "<br>");
total_messages += totalStats[0][0];

out.print("Average Sent per Month: " + (int)sentAve + " <br /><br />");

out.print("Total Messages Received: " +
        totalStats[1][0] + "<br />");
total_messages += totalStats[1][0];

out.println("Average Received per Month: " + (int)recAve + "<br />");

out.println("<br />Total Messages Sent/Received: " + total_messages + "<br /><br/>");

%>
                </div>
                <div class="boxWideBottom"></div>


                <h1>Messages Sent/Received by Month and Year</h1>
                <div class="boxWideTop"></div>
                <div class="boxWideContent">
<%

double maxDistance = max * 1.25;

for(int yrCnt = 0; yrCnt < years; yrCnt++) {
    out.print("<br />\n");
    out.println("<b>" + monthArray[yrCnt][0] + "</b> (" +
            monthArray[yrCnt][13] + ")<br />");
    out.println("<table height=\"250\" width=\"350\"" +
            " cellspacing=\"0\"><tr>");

    for(int i = 1; i < 13; i++) {
        double height = monthArray[yrCnt][i] / maxDistance * 225;
        if (height < 1 && height != 0) height = 1;
        out.println("<td valign=\"bottom\" rowspan=\"13\"" +
                " background=\"images/gridline2.gif\">"+
                "<img src=\"images/bar2.gif\" width = \"15\" height=\"" +
                (int)height + "\"></td>");
    }

    out.println("</tr>");

    String months[] = {"", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul",
        "Aug", "Sep", "Oct", "Nov", "Dec"};
    for(int i = 1; i < 13; i++) {
        out.println("<tr><td align=\"right\">" + months[i] + ":</td><td "+
                " align=\"left\"> " + monthArray[yrCnt][i] +
                "</td></tr>");
    }

    out.println("<tr>");
    for(int i = 1; i < 13; i++) {
        out.println("<td align=\"center\">" + i + "</td>");
    }
    out.println("</tr></table>");
}
%>
                </div>
                <div class="boxWideBottom"></div>

                <h1>Most Popular Messages</h1>
                <div class="boxWideTop"></div>
                <div class="boxWideContent">
<%
    pstmt = conn.prepareStatement("select message, count(*) " +
        " from im.messages where sender_id = ? group by message " +
        " order by count(*) desc limit 20 ");

    pstmt.setInt(1, sender);

    if(meta_id != 0) {
        pstmt = conn.prepareStatement("select message, count(*) " +
            " from im.messages, im.meta_contact " +
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
    pstmt = conn.prepareStatement("select sender_sn as sender_sn"+
        ", recipient_sn as recipient_sn, "+
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
         pstmt = conn.prepareStatement("select sender_sn as sender_sn "+
            ", recipient_sn as recipient_sn, " +
            " message, count(*) " +
            " from simple_message_v smv, im.meta_contact "+
            " where not exists "+
                " (select 'x' from messages "+
                " where sender_id in (smv.sender_id, smv.recipient_id) "+
                " and recipient_id in (smv.sender_id, smv.recipient_id) "+
                " and message_date < smv.message_date " +
                " and message_date > smv.message_date - '10 minutes'::interval) "+
            " and (sender_id = user_id or recipient_id = user_id) " +
            " and meta_id = ? " +
            " group by sender_sn, recipient_sn, message " +
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

                <h1>Most Popular Users</h1>
                <div class="boxWideTop"></div>
                <div class="boxWideContent">
<%
    pstmt = conn.prepareStatement("select username, sum(num_messages), (select message from messages where sender_id = user_id order by random() limit 1) as message from users, user_statistics where user_id = sender_id and (sender_id = ? or recipient_id = ?) group by username, user_id order by sum desc, username limit 20");

    pstmt.setInt(1, sender);
    pstmt.setInt(2, sender);

    if(meta_id != 0) {
        pstmt = conn.prepareStatement("select (select username from users where user_id = user_statistics.sender_id) as username, sum(num_messages), (select message from messages where sender_id = user_statistics.sender_id order by random() limit 1) as message from users natural join meta_contact, user_statistics where (user_id = sender_id or user_id = recipient_id) and meta_id = ? group by username, user_id, sender_id order by sum desc, username limit 20");

        pstmt.setInt(1, meta_id);
    }


    rset = pstmt.executeQuery();

    out.println("<table>");
    out.println("<tr><td>#</td><td>Username</td><td>Total</td><td>Random Quote</td></tr>");

    while(rset.next()) {
        out.println("<tr>");
        out.println("<td>" + rset.getRow() + "</td>");
        out.println("<td>" + rset.getString("username") + "</td>");
        out.println("<td>" + rset.getString("sum") + "</td>");
        out.println("<td>" + rset.getString("message") + "</td>");
        out.println("</tr>");
    }

    out.println("</table>");
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
    out.print("<br />" + e.getMessage());
} finally {
    if (stmt != null) {
        stmt.close();
    }
    conn.close();
}
%>
</body>
</html>
