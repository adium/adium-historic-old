<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.sql.*' %>
<%@ page import = 'java.util.ArrayList' %>
<%@ page import = 'javax.naming.*' %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<!--$URL: http://svn.visualdistortion.org/repos/projects/adium/jsp/statistics.jsp $-->
<!--$Rev: 697 $ $Date: 2004/05/04 21:29:54 $ -->

<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();

PreparedStatement pstmt = null;
Statement stmt = null;
PreparedStatement metaStmt = null;
ResultSet rset = null;
ResultSet metaSet = null;
try {
    stmt = conn.createStatement();
%>

<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>Adium SQL Logger Users</title>
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
                <h1>Meta-Contacts/Grouping</h1>
                <div class="boxWideTop"></div>
                <div class="boxWideContent">
<%
    pstmt = conn.prepareStatement("select meta_id, name, url, " +
    " email, location, notes " +
    " from adium.meta_container order by name");;
    
    rset = pstmt.executeQuery();
    
    while(rset.next()) {

        String editURL = "editMeta.jsp?meta_id=" + rset.getInt("meta_id");
%>
<span class="edit"<a href="#" 
    onClick="window.open('<%= editURL %>', 'Edit Meta Contact', 'width=275,height=450')">Edit ...</a></span>
<%

        out.print("<h2>" + rset.getString("name") + "</h2>");
        out.println("<div class=\"meta\">");
        out.print("<div class=\"personal_info\">");
        out.println("<table>");

        if(rset.getString("url") != null) {
            out.println("<tr><td class=\"left\">URL</td>" +
                "<td><a href=\"" + rset.getString("url") + 
                "\">" + rset.getString("url") + "</a></td></tr>");
        }
             
        if(rset.getString("email") != null) {
            out.println("<tr><td class=\"left\">Email</td><td>");
            out.println("<a href=\"mailto:" + rset.getString("email") + 
                "\">" + rset.getString("email") + "</a></td></tr>");
        }
            
        if(rset.getString("location") != null) {
            out.println("<tr><td class=\"left\">Location</td><td>" + 
                rset.getString("location") + "</td></tr>");
        }
        
        if(rset.getString("notes") != null) {
            out.println("<tr><td class=\"left\">Notes</td><td>" + 
                rset.getString("notes") + "</td></tr>");
        }
        out.println("</table>");
        out.println("</div>");

        metaStmt = conn.prepareStatement("select user_id, service, username, display_name from adium.users natural join adium.meta_contact natural join adium.user_display_name udn where meta_id = ? and not exists (select 'x' from adium.user_display_name where effdate > udn.effdate and user_id = users.user_id)");
        
        metaStmt.setInt(1, rset.getInt("meta_id"));
        
        metaSet = metaStmt.executeQuery();
        
        while(metaSet.next()) {
            out.println("<p>" + metaSet.getString("display_name")  + 
                " (" + metaSet.getString("service") + "." + 
                metaSet.getString("username") + ")");
            out.println("<span class=\"remove\">" +
            "<a href=\"removeMetaContact.jsp?meta_id=" + 
                rset.getString("meta_id") + "&amp;user_id=" +
                metaSet.getString("user_id") + "\">Remove</a></span></p>");
        }
        
        String formURL = new String("addContact.jsp?meta_id=" + 
            rset.getString("meta_id"));
%>
<p><a href="#" 
    onClick="window.open('<%= formURL %>', 'Add Contact', 'width=450,height=100')">
                Add Contact ...
            </a></p>
<%
        out.println("</div>");

    }
    
%>
    <h2>
<a href="#" 
    onClick="window.open('addMeta.jsp', 'Add Meta Contact', 'width=275,height=425')">Add Meta Contact ...</a></h2>

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
