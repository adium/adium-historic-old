<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.naming.*' %>
<%@ page import = 'javax.sql.*' %>
<%@ page import = 'java.net.URLEncoder' %>
<%@ page import = 'java.io.File' %>
<%@ page import = 'org.slamb.axamol.library.*' %>
<%@ page import = 'java.util.Map' %>
<%@ page import = 'java.util.HashMap' %>
<%@ page import = 'sqllogger.*' %>

<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();

String query = Util.checkNull(request.getParameter("query"));
int query_id;

PreparedStatement pstmt = null;
ResultSet rset = null;
ResultSetMetaData rsmd = null;

String formURL = new String("action=saveQuery.jsp&query=" +
    query);

query_id = Util.checkInt(request.getParameter("query_id"));

String notes = new String();
String title = new String();

File queryFile = new File(session.getServletContext().getRealPath("queries/standard.xml"));

LibraryConnection lc = new LibraryConnection(queryFile, conn);
Map params = new HashMap();

try {

    if(query_id != 0) {

        params.put("query_id", new Integer(query_id));
        rset = lc.executeQuery("saved_query", params);

        while(rset.next()) {
            title = rset.getString("title");
            notes = rset.getString("notes");
            query = rset.getString("query_text");
        }
    }
%>
<html>
    <head><title>SQL Logger: Query</title>
    <link rel="stylesheet" type="text/css" href="styles/layout.css" />
    <link rel="stylesheet" type="text/css" href="styles/default.css" />
    </head>
    <body>
        <div id="container">
            <div id="header">
            </div>
            <div id="banner">
                <div id="bannerTitle">
                    <img class="adiumIcon" src="images/headlines/query.png" width="128" height="128" border="0" alt="Query Icon" />
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
                        <li><a href="users.jsp">Users</a></li>
                        <li><a href="meta.jsp">Meta-Contacts</a></li>
                        <li><a href="chats.jsp">Chats</a></li>
                        <li><a href="statistics.jsp">Statistics</a></li>
                        <li><span id="current">Query</span></li>
                    </ul>
                </div>

                <div id="sidebar-a">
                    <h1>Saved Queries</h1>
                    <div class="boxThinTop"></div>
                    <div class="boxThinContent">
<%

    rset = lc.executeQuery("saved_queries_list", params);

    while(rset.next()) {
        out.println("<p><a href=\"query.jsp?query_id=" +
            rset.getString("query_id") + "\" title=\"" +
            rset.getString("notes") + "\">" + rset.getString("title") +
            "</a></p>");
    }
    out.println("<p></p>");

%>
                    </div>
                    <div class="boxThinBottom"></div>
                </div>

                <div id="content">
                    <h1>Query</h1>

                    <div class="boxWideTop"></div>
                    <div class="boxWideContent">

                    <form action="query.jsp" method="post">
                        <h3><%= title %></h3>
                        <p><%= notes %></p>
                        <textarea name="query"
                            cols="68" rows="20"><%= Util.safeString(query) %></textarea>
                        <br />
                        <span style="float: right">
<%
if(query != null)
    out.println("<p><a href=\"#\" onClick=\"window.open('saveForm.jsp?action=saveQuery.jsp&query=" + URLEncoder.encode(Util.safeString(query), "UTF-8") +
        "', 'Save Query', 'width=275,height=225')\">Save Query</a></p>");
%>
                        </span>
                        <input type="reset">
                        <input type="submit" />
                    </form>

                    </div>
                    <div class="boxWideBottom"></div>

                    <h1>Results</h1>
                    <div class="boxExtraWideTop"></div>
                    <div class="boxExtraWideContent">
<%
    if(query != null) {
        pstmt = conn.prepareStatement(query);

        long beginTime = System.currentTimeMillis();
        rset = pstmt.executeQuery();
        long queryTime = System.currentTimeMillis() - beginTime;

        rsmd = rset.getMetaData();

        out.println("<div align=\"right\">Query Time: " + queryTime + " ms</div>");

        out.print("<table>");

        String prevFirst = new String();

        int numTotal[] = new int[rsmd.getColumnCount()];
        boolean isNumber[] = new boolean[rsmd.getColumnCount()];

        for (int i = 0; i < numTotal.length; i++) {
            numTotal[i] = 0;
            isNumber[i] = true;
        }

        if(rsmd.getColumnName(1).equals("QUERY PLAN")
                && rsmd.getColumnCount() == 1) {
            out.println("<pre>");
            while(rset.next()) {
                out.println(rset.getString(1));
            }
            out.println("</pre>");
        }

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
                if(i == 1 && rset.getString(1) != null &&
                    rset.getString(1).equals(prevFirst)) {
                    out.println("<td></td>");
                } else {
                    if(rsmd.getColumnName(i).equals("message_id")) {
                        out.println("<td><a href=\"index.jsp?message_id=" +
                            rset.getString(i) + "#" + rset.getString(i) +
                            "\">" + rset.getString(i) +
                            "</a></td>");
                        isNumber[i - 1] = false;
                    } else {
                        out.println("<td>" + rset.getString(i) + "</td>");
                    }
                }
                if(i == 1) {
                    prevFirst = rset.getString(1);
                }

                if(isNumber[i - 1]) {
                    try {
                        numTotal[i - 1] += Integer.parseInt(rset.getString(i));
                    } catch (NumberFormatException e) {
                        isNumber[i - 1] = false;
                    }
                }
            }
            out.println("</tr>");
        }
        out.println("<tr><td><b>Tot:</b></td>");

        for(int i = 1; i <= rsmd.getColumnCount(); i++) {
            if(isNumber[i - 1]) {
                out.println("<td><b>" + numTotal[i - 1] + "</b></td>");
            } else {
                out.println("<td></td>");
            }
        }

        out.println("</tr>");

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
