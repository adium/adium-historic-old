<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.sql.*' %>
<%@ page import = 'javax.naming.*' %>
<%@ page import = 'java.util.regex.Pattern' %>
<%@ page import = 'java.util.regex.Matcher' %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<!--$URL: http://svn.visualdistortion.org/repos/projects/adium/jsp/index.jsp $-->
<!--$Rev: 778 $ $Date: 2004/05/27 16:09:04 $ -->

<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();


String dateStart, dateFinish;

dateFinish = request.getParameter("finish");
dateStart = request.getParameter("start");
String niceStart = dateStart;
String niceFinish = dateFinish;

if (dateFinish != null && (dateFinish.equals("") || dateFinish.equals("null"))) {
    dateFinish = null;
    niceFinish = "";
} 

if (dateStart != null && (dateStart.equals("") || dateStart.startsWith("null"))) {
    dateStart = null;
    niceStart = "";
}

%>

<html>
    <head><title>Recent URLs</title></head>
    <link rel="stylesheet" type="text/css" href="styles/default.css" />
    <body style="background: #fff">
    
    <div align="right">
        <form action="urls.jsp" method="get">
            <input type="text" name="start" value="<%= niceStart %>" > -- <input type="text" name="finish" value="<%= niceFinish %>">
            <br/><input type="submit">
        </form>
    </div>
    <br />
<%

PreparedStatement pstmt = null;
ResultSet rset = null;

try {

    String cmdArray[] = new String[2];
    int cmdCntr = 0;
    
    String queryString = new String("select sender_sn, recipient_sn, message, message_date from simple_message_v where message ~* '(.*http:\\/\\/.*)|(.*<a href.*?</a>.*)'");
    
    if(dateStart != null) {
        queryString += " and message_date >= ? ";
        cmdArray[cmdCntr++] = dateStart;
    }
    
    if(dateFinish != null) {
        queryString += " and message_date <= ? ";
        cmdArray[cmdCntr++] = dateFinish;
    }

    queryString += " order by message_date desc ";

    pstmt = conn.prepareStatement(queryString);

    for(int i = 0; i < cmdCntr; i++) {
        pstmt.setString(i + 1, cmdArray[i]);
    }

    rset = pstmt.executeQuery();
    
    while(rset.next()) {
        StringBuffer sb = new StringBuffer();
        String messageContent = rset.getString("message");

        Pattern p = Pattern.compile("(?i).*?(<a href.*?</a>).*?");
        Matcher m = p.matcher(messageContent);
        
        while(m.find()) {
            sb.append(m.group(1) + "<br />");
        }
        
        messageContent = messageContent.replaceAll("<a href.*?</a>", " ");
        
        p = Pattern.compile("(?i).*?(http:\\/\\/.*)\\s*?.*?");
        m = p.matcher(messageContent);
        
        while(m.find()) {
            sb.append("<a href=\"" + m.group(1) + "\">" + m.group(1) + 
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
} catch (SQLException e) {
    out.println(e.getMessage());
} finally {
    pstmt.close();
    conn.close();
}
%>

    </body>
</html>