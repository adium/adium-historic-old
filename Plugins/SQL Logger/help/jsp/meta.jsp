<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.sql.*' %>
<%@ page import = 'java.util.ArrayList' %>
<%@ page import = 'javax.naming.*' %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<!--$URL: http://svn.visualdistortion.org/repos/projects/adium/jsp/statistics.jsp $-->
<!--$Rev: 697 $ $Date$ -->

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
<title>SQL Logger: Meta-Contacts</title>
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
                    <h1>Edit Meta-Contacts</h1>
                </div>
            </div>
        </div>
        <div id="central">
            <div id="navcontainer">
                <ul id="navlist">
                    <li><a href="index.jsp">Viewer</a></li>
                    <li><a href="search.jsp">Search</a></li>
                    <li><a href="users.jsp">Users</a></li>
                    <li><span id="current">Meta-Contacts</span></li>
                    <li><a href="chats.jsp">Chats</a></li>
                    <li><a href="statistics.jsp">Statistics</a></li>
                    <li><a href="query.jsp">Query</a></li>
                </ul>
            </div>
            <div id="content">
                <h1>Meta-Contacts/Grouping</h1>
                <div class="boxExtraWideTop"></div>
                <div class="boxExtraWideContent">
<%

    pstmt = conn.prepareStatement("select count(*) * 31 + 105 as height from im.information_keys where delete = false");

    rset = pstmt.executeQuery();

    rset.next();

    int height = rset.getInt("height");

    pstmt = conn.prepareStatement("select (max(length(username || display_name)) + 5) * 5 as width from im.users natural join im.user_display_name where not exists (select 'x' from im.user_display_name where user_id = users.user_id and effdate < user_display_name.effdate)");

    rset = pstmt.executeQuery();

    rset.next();

    int longDispWidth = rset.getInt(1);

    pstmt = conn.prepareStatement("select meta_id, name, count(meta_contact.meta_id) " +
        " from im.meta_container natural left join im.meta_contact " +
        " group by meta_id, name order by name");

    rset = pstmt.executeQuery();

    while(rset.next()) {

        String editURL = "editMeta.jsp?meta_id=" + rset.getInt("meta_id");
%>
<span class="edit">

    <a href="updateMeta.jsp?meta_id=<%= rset.getInt("meta_id") %>&delete=on&redirect=meta.jsp">Delete</a> |

    <a href="#" onClick="window.open('<%= editURL %>',
    'Edit Meta Contact', 'width=275,height=<%= height %>')">Edit ...</a>
    </span>
<%

        out.print("<h2><a href=\"chats.jsp?meta_id=" +
            rset.getString("meta_id") + "\">" +
            rset.getString("name") + "</a> (" +
            rset.getString("count") + ")</h2>");
        out.println("<div class=\"meta\">");
        out.print("<div class=\"personal_info\">");

        infoStmt = conn.prepareStatement("select key_name, value from im.meta_contact_info where meta_id = ? order by key_name");

        infoStmt.setInt(1, rset.getInt("meta_id"));

        infoSet = infoStmt.executeQuery();

        out.println("<table>");

        while(infoSet.next()) {
            out.println("<tr><td class=\"left\">" +
                infoSet.getString("key_name") + "</td>" +
                "<td>" + infoSet.getString("value") +
                "</td></tr>");
        }
        out.println("</table>");
        out.println("</div>");

        metaStmt = conn.prepareStatement("select user_id, service, username as username, display_name, lower(service) as lower_service, preferred from im.users natural join im.meta_contact natural join im.user_display_name udn where meta_id = ? and not exists (select 'x' from im.user_display_name where effdate > udn.effdate and user_id = users.user_id) order by display_name, username");

        metaStmt.setInt(1, rset.getInt("meta_id"));

        metaSet = metaStmt.executeQuery();

        while(metaSet.next()) {
            out.println("<p><img src=\"images/services/" +
                metaSet.getString("lower_service") + ".png\" width=\"12\" height=\"12\" /> " +
                metaSet.getString("display_name")  + " (" +
                "<a href=\"chats.jsp?sender=" +
                metaSet.getString("user_id") + "\">" +
                metaSet.getString("username") + "</a>)");
            out.println("<span class=\"remove\">");

            if(!metaSet.getBoolean("preferred")) {
                out.println("<a href=\"updatePreferredMeta.jsp?meta_id=" +
                    rset.getString("meta_id") + "&amp;user_id=" +
                    metaSet.getString("user_id") + "\">Set Preferred</a>");
            }

            out.println("<a href=\"removeMetaContact.jsp?meta_id=" +
                rset.getString("meta_id") + "&amp;user_id=" +
                metaSet.getString("user_id") + "\">Remove</a></span></p>");
        }

        String formURL = new String("addContact.jsp?meta_id=" +
            rset.getString("meta_id"));
%>
<p><a href="#"
    onClick="window.open('<%= formURL %>', 'Add Contact', 'width=<%= longDispWidth %>,height=100')">
                Add Contact ...
            </a></p>

            <div style="clear:both">&nbsp;</div>
<%
        out.println("</div>");

    }

%>
    <h2>
<a href="#"
    onClick="window.open('addMeta.jsp', 'Add Meta Contact', 'width=275,height=<%= height %>')">Add Meta Contact ...</a></h2>

                </div>
                <div class="boxExtraWideBottom"></div>
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
