<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.sql.*' %>
<%@ page import = 'javax.naming.*' %>
<%@ page import = 'java.util.regex.Pattern' %>
<%@ page import = 'java.util.regex.Matcher' %>
<%@ page import = 'org.slamb.axamol.library.*' %>
<%@ page import = 'java.io.File' %>
<%@ page import = 'java.util.Map' %>
<%@ page import = 'java.util.HashMap' %>
<%@ page import = 'sqllogger.*' %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<!--$URL: http://svn.visualdistortion.org/repos/projects/sqllogger/jsp/urls.jsp $-->
<!--$Rev: 922 $ $Date$ -->

<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();

File queryFile = new File(session.getServletContext().getRealPath("queries/standard.xml"));

LibraryConnection lc = new LibraryConnection(queryFile, conn);
Map params = new HashMap();

String dateStart, dateFinish;

dateFinish = Util.checkNull(request.getParameter("finish"));
dateStart = Util.checkNull(request.getParameter("start"));

params.put("startDate", dateStart);
params.put("endDate", dateFinish);

%>

<html>
    <head><title>Recent URLs</title></head>
    <link rel="stylesheet" type="text/css" href="styles/default.css" />
    <body style="background: #fff">

    <div align="right">
        <form action="urls.jsp" method="get">
            <input type="text" name="start" value="<%= Util.safeString(dateStart) %>" > -- <input type="text" name="finish" value="<%= Util.safeString(dateFinish) %>">
            <br/><input type="submit">
        </form>
    </div>
    <br />
<%

ResultSet rset = null;

try {

    rset = lc.executeQuery("message_urls", params);

    while(rset.next()) {
        StringBuffer sb = new StringBuffer();
        String messageContent = rset.getString("message");

        Pattern p = Pattern.compile("(?i).*?(<a href.*?)(>.*?</a>).*?");
        Matcher m = p.matcher(messageContent);

        while(m.find()) {
            sb.append(m.group(1) + " target=\"_blank\"" + m.group(2) + "<br />");
        }

        messageContent = messageContent.replaceAll("<a href.*?</a>", " ");

        p = Pattern.compile("(?i).*?(http:\\/\\/.*)\\s*?.*?");
        m = p.matcher(messageContent);

        while(m.find()) {
            sb.append("<a href=\"" + m.group(1) + " target=\"_blank\"\">" +
                m.group(1) +
                "</a><br />");
        }

        out.print("<span style=\"float:right\">" +
            rset.getDate("message_date") +
            "&nbsp;" + rset.getTime("message_date") +
            "</span>\n");

        out.println(rset.getString("sender_sn") +
            ":&#8203;" + rset.getString("recipient_sn"));
        out.println("<p style=\"padding-left: 30px; margin-top:5px\">" +
            sb.toString() + "</p>");
    }
//} catch (SQLException e) {
//    out.println(e.getMessage());
} finally {
    lc.close();
    conn.close();
}
%>

    </body>
</html>
