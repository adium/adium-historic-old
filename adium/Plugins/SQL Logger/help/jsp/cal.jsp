<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.sql.*' %>
<%@ page import = 'javax.naming.*' %>
<%@ page import = 'java.util.regex.Pattern' %>
<%@ page import = 'java.util.regex.Matcher' %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<!--$URL: http://svn.visualdistortion.org/repos/projects/adium/jsp/index.jsp $-->
<!--$Rev: 778 $ $Date: 2004/06/13 18:32:28 $ -->

<html>
    <head><title>Calendar</title>
    <link rel="stylesheet" type="text/css" href="styles/default.css" />
    </head>
    <body style="background: #fff">

<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();

String date = request.getParameter("date");
if (date == null || date.equals("")) {
    date = new String("'now'");
}

PreparedStatement pstmt = null;
ResultSet rset = null;

try {
    int firstDay;
    int daysOfMonth;
    String monthName;
    String prevMonth;
    String nextMonth;

    pstmt = conn.prepareStatement("select " +
        " extract('dow' from date_trunc('month', ?::timestamp)) as first_day, " +
        " extract('day' from date_trunc('month', ?::timestamp + '1 month'::interval) - " +
            " '1 day'::interval) as months_days, " +
        " to_char(?::timestamp, 'fmMonth, YYYY') as month_name, " +
        " ?::timestamp - '1 month'::interval as prev, " +
        " ?::timestamp + '1 month'::interval as next");

    for(int i = 1; i <= 5; i++) {
        pstmt.setString(i, date);
    }

    rset = pstmt.executeQuery();

    rset.next();

    firstDay = rset.getInt("first_day");
    daysOfMonth = rset.getInt("months_days");
    monthName = rset.getString("month_name");
    prevMonth = rset.getString("prev");
    nextMonth = rset.getString("next");


    pstmt = conn.prepareStatement("select distinct " +
        " extract('day' from message_date) as day, " +
        " date_trunc('day', message_date) as start_date, " +
        " date_trunc('day', message_date + '1 day'::interval) as end_date " +
        " from messages " +
        " where message_date >= date_trunc('month', ?::timestamp) "+
        " and message_date < date_trunc('month', ?::timestamp + '1 month'::interval)");

    pstmt.setString(1, date);
    pstmt.setString(2, date);

    rset = pstmt.executeQuery();

    if(rset != null && !rset.isBeforeFirst()) {
        rset = null;
    } else {
        rset.next();
    }

    out.println("<table>");
    out.println("<tr><td><a href=\"cal.jsp?date=" + prevMonth + "\">" +
        "&laquo;</a></td>");
    out.println("<td colspan=\"5\" align=\"center\"><b>" +
        monthName + "</b></td>");
    out.println("<td><a href=\"cal.jsp?date=" + nextMonth + "\">" +
        "&raquo;</a></td></tr>");
    out.println("<tr><td>S</td><td>M</td>" +
        "<td>T</td><td>W</td><td>T</td><td>F</td><td>S</td></tr><tr>");

    int position = 0;
    while(position++ < firstDay) {
        out.println("<td>&nbsp;</td>");
    }

    for(int i = 1; i <= daysOfMonth; i++) {
        if(rset == null || rset.getInt("day") != i) {
            out.println("<td>" + i + "</td>");
        } else if (rset != null) {
            out.println("<td align=\"center\"><a href=\"index.jsp?start=" +
                rset.getString("start_date") + "&finish=" +
                rset.getString("end_date") + "\" onClick=\"window.close()\""+
                " target=\"viewer\">" +
                i + "</a></td>");
            rset.next();
        }

        if(position++ % 7 == 0) {
            out.println("</tr><tr>");
        }
    }

    while(position++ % 7 != 0) {
        out.println("<td>&nbsp;</td>");
    }
    out.println("</tr>");
    out.println("</table>");

    out.println("<div align=\"right\"><a href=\"cal.jsp\">Today</a></div>");
} catch (SQLException e) {
    out.println(e.getMessage());
} finally {
    conn.close();
}
%>
    </body>
</html>
