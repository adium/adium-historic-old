<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.sql.*' %>
<%@ page import = 'java.util.ArrayList' %>
<%@ page import = 'javax.naming.*' %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<!--$URL: http://svn.visualdistortion.org/repos/projects/adium/jsp/statistics.jsp $-->
<!--$Rev: 697 $ $Date: 2004/05/24 16:39:37 $ -->

<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();

PreparedStatement pstmt = null;
Statement stmt = null;
PreparedStatement metaStmt = null;
ResultSet rset = null;
ResultSet metaSet = null;
PreparedStatement infoStmt = null;
ResultSet infoSet = null;

try {
    stmt = conn.createStatement();
%>

<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>Adium SQL Logger: Users</title>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1" />
<link rel="stylesheet" type="text/css" href="styles/layout.css" />
<link rel="stylesheet" type="text/css" href="styles/default.css" />
<link rel="stylesheet" type="text/css" href="styles/users.css" />
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
                <img class="adiumIcon" src="images/adiumy/yellow.png" width="128" height="128" border="0" alt="Adium X Icon" />
                <div class="text">
                    <h1>Edit Users</h1>
                </div>
            </div>
        </div>
        <div id="central">
            <div id="navcontainer">
                <ul id="navlist">
                    <li><a href="index.jsp">Viewer</a></li>
                    <li><a href="search.jsp">Search</a></li>
                    <li><a href="statistics.jsp">Statistics</a></li>
                    <li><span id="current">Users</span></li>
                    <li><a href="meta.jsp">Meta-Contacts</a></li>
                </ul>
            </div>
            <div id="sidebar-a">
                <h1>Login Users</h1>
                <div class="boxThinTop"></div>
                <div class="boxThinContent">
                    <form action="updateLogin.jsp" method="get">
<%
    rset = stmt.executeQuery("select sender_id as user_id, "+
        " scramble(username) as username, login "+
        "from user_statistics, users where sender_id = user_id "+
        " group by sender_id, username, login "+
        " having count(*) > 1 order by username");

    while (rset.next())  {
        out.println("<p>");
        out.print("<input type=\"checkbox\" name=\"" +
            rset.getString("user_id") + "\" ");

        if(rset.getBoolean("login")) {
            out.print("checked=\"checked\"");
        }

        out.print("/>");
        out.println(rset.getString("username") + "</p>");
    }

%>
                        <input type="submit">
                    </form>
                </div>
                <div class="boxThinBottom"></div>
            </div>
            <div id="content">
                <h1>Users</h1>
                <div class="boxWideTop"></div>
                <div class="boxWideContent">
<%

    pstmt = conn.prepareStatement("select count(*) * 31 + 100 as height from adium.information_keys where delete = false");

    rset = pstmt.executeQuery();

    rset.next();

    int height = rset.getInt("height");

    pstmt = conn.prepareStatement("select user_id, scramble(username) " +
        " as username, scramble(display_name) as display_name " +
        " from adium.users natural join user_display_name udn " +
        " where not exists (select 'x' from user_display_name " +
        " where user_id = udn.user_id  and effdate > udn.effdate) " +
        " order by not exists (select 'x' from meta_contact " +
        " where user_id = users.user_id), not exists (select 'x' from " +
        " user_contact_info where user_id = users.user_id), " +
        " display_name, username");

    rset = pstmt.executeQuery();

    while(rset.next()) {

        String editURL = "editUser.jsp?user_id=" + rset.getInt("user_id");
%>
<span class="edit"<a href="#"
    onClick="window.open('<%= editURL %>', 'Edit User', 'width=275,height=<%= height %>')">Edit Info ...</a></span>
<%

        out.print("<h2>" + rset.getString("display_name") + " (" +
            rset.getString("username") + ")</h2>");
        out.println("<div class=\"meta\">");

        infoStmt = conn.prepareStatement("select key_name, value from adium.user_contact_info where user_id = ? order by key_name");

        infoStmt.setInt(1, rset.getInt("user_id"));

        infoSet = infoStmt.executeQuery();

        out.println("<table>");

        while(infoSet.next()) {
            out.println("<tr><td class=\"left\">" +
                infoSet.getString("key_name") + "</td>" +
                "<td>" + infoSet.getString("value") +
                "</td></tr>");
        }
        out.println("</table>");


%>
        </div>
<%

    }

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
    out.println("<br />You may need to run <code>psql < update.sql</code>");
} finally {
    if (stmt != null) {
        stmt.close();
    }
    conn.close();
}
%>
</body>
</html>
