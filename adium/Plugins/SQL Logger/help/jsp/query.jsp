<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.naming.*' %>
<%@ page import = 'javax.sql.*' %>
<%@ page import = 'java.net.URLEncoder' %>

<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();

String query = request.getParameter("query");
String safeQuery = query;
int query_id;

if(query != null && query.equals("")) {
    query = null;
}

if(query == null || safeQuery == null) {
    safeQuery = "";
}

PreparedStatement pstmt = null;
ResultSet rset = null;
ResultSetMetaData rsmd = null;

String formURL = new String("action=saveQuery.jsp&query=" +
    query);

try {
    query_id = Integer.parseInt(request.getParameter("query_id"));
} catch (NumberFormatException e) {
    query_id = 0;
}

String notes = new String();
String title = new String();;

try {

    if(query_id != 0) {
        pstmt = conn.prepareStatement("select title, notes, query_text from im.saved_queries where query_id = ?");
        pstmt.setInt(1, query_id);

        rset = pstmt.executeQuery();

        while(rset.next()) {
            title = rset.getString("title");
            notes = rset.getString("notes");
            query = rset.getString("query_text");
            safeQuery = query;
        }
    }
%>
<html>
    <head><title>Query</title>
    <link rel="stylesheet" type="text/css" href="styles/layout.css" />
    <link rel="stylesheet" type="text/css" href="styles/default.css" />
    </head>
    <body>
        <div id="container">
            <div id="header">
            </div>
            <div id="banner">
                <div id="bannerTitle">
                    <img class="adiumIcon" src="images/adiumy/green.png" width="128" height="128" border="0" alt="Adium X Icon" />
                    <div class="text">
                        <h1>Query</h1>
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
                        <li><a href="meta.jsp">Meta-Contacts</a></li>
                        <li><span id="current">Query</span></li>
                    </ul>
                </div>

                <div id="sidebar-a">
                    <h1>Saved Queries</h1>
                    <div class="boxThinTop"></div>
                    <div class="boxThinContent">
<%
    pstmt = conn.prepareStatement("select query_id, title, notes from im.saved_queries order by title");

    rset = pstmt.executeQuery();

    while(rset.next()) {
        out.println("<p><a href=\"query.jsp?query_id=" +
            rset.getString("query_id") + "\" title=\"" +
            rset.getString("notes") + "\">" + rset.getString("title") +
            "</a></p>");
    }
    out.println("<p></p>");

    out.println("<p><a href=\"#\" onClick=\"window.open('saveForm.jsp?action=saveQuery.jsp&query=" + URLEncoder.encode(safeQuery, "UTF-8") +
        "', 'Save Query', 'width=275,height=225')\">Save Query</a></p>");
%>
                    </div>
                    <div class="boxThinBottom"></div>
                </div>

                <div id="content">
                    <h1>Query</h1>

                    <div class="boxWideTop"></div>
                    <div class="boxWideContent">

                    <form action="query.jsp" method="post">
                        <table>
                            <tr>
                                <td rowspan="2" align="right">
                                    <textarea name="query"
                                        cols="50" rows="20"><%= safeQuery %></textarea>
                                    <br />
                                    <input type="reset">
                                    <input type="submit" />
                                </td>
                                <td>
                                    <h3><%= title %></h3>
                                </td>
                            </tr>
                            <tr>
                                <td>
                                    <p><%= notes %></p>
                                </td>
                            </tr>
                        </table>
                    </form>

                    </div>
                    <div class="boxWideBottom"></div>

                    <h1>Results</h1>
                    <div class="boxExtraWideTop"></div>
                    <div class="boxExtraWideContent">
<%
    if(query != null) {
        pstmt = conn.prepareStatement(query);
        rset = pstmt.executeQuery();
        rsmd = rset.getMetaData();

        out.print("<table>");

        String prevFirst = new String();

        while(rset.next()) {
            if((rset.getRow() - 1) % 25 == 0) {
                out.println("<tr>");
                out.println("<td><b>#</b></td>");
                for(int i = 1; i <= rsmd.getColumnCount(); i++) {
                    out.print("<td><b>" +
                        rsmd.getColumnName(i) + "</b></td>");
                }
                out.println("</tr>");
            }

            out.println("<tr>");
            out.println("<td>" + rset.getRow() + "</td>");

            for(int i = 1; i <= rsmd.getColumnCount(); i++) {
                if(i == 1 && rset.getString(1).equals(prevFirst)) {
                    out.println("<td></td>");
                } else {
                    if(rsmd.getColumnName(i).equals("message_id")) {
                        out.println("<td><a href=\"index.jsp?message_id=" +
                            rset.getString(i) + "\">" + rset.getString(i) +
                            "</a></td>");
                    } else {
                        out.println("<td>" + rset.getString(i) + "</td>");
                    }
                }
                if(i == 1) {
                    prevFirst = rset.getString(1);
                }
            }
            out.println("</tr>");
        }

        out.println("</table>");
    }

} catch (SQLException e) {
    out.println("<span style=\"color:red\">" + e.getMessage() + "</span>");
} finally {
    conn.close();
}
%>
                    </div>
                    <div class="boxExtraWideBottom"></div>
                </div>

                <div id="bottom">
                    <div class="cleanHackBoth"> </div>
                </div>
            </div>
            <div id="footer">&nbsp;</div>
        </div>
    </body>
</html>
