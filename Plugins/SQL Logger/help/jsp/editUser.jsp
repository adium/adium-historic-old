<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.naming.*' %>
<%@ page import = 'javax.sql.*' %>
<%@ page import = 'java.io.File' %>
<%@ page import = 'org.slamb.axamol.library.*' %>
<%@ page import = 'java.util.Map' %>
<%@ page import = 'java.util.HashMap' %>
<%@ page import = 'sqllogger.*' %>

<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();

int user_id = Util.checkInt(request.getParameter("user_id"));

ResultSet rset = null;
String username = new String();

File queryFile = new File(session.getServletContext().getRealPath("queries/standard.xml"));

LibraryConnection lc = new LibraryConnection(queryFile, conn);
Map params = new HashMap();

try {

    params.put("user_id", new Integer(user_id));

    rset = lc.executeQuery("user_info_all_keys", params);

    if(rset.isBeforeFirst()) {
        rset.next();
        username = rset.getString("username");
        rset.beforeFirst();
    }
%>
<html>
    <head><title>Edit User <%= username  %></title></head>
    <link rel="stylesheet" type="text/css" href="styles/default.css" />
    <link rel="stylesheet" type="text/css" href="styles/users.css" />
    <body style="background :#fff">
        <form action="updateUser.jsp" method="get">
            <table border="0" cellpadding="0" cellspacing="5">
<%
    if(rset.isBeforeFirst()) {
        while(rset.next()) {
            out.println("<tr><td align=\"right\">");
            out.println("<label for=\"" + rset.getString("key_name") + "\">" +
                rset.getString("key_name") + "</label>");

            out.println("</td><td>");

            out.println("<input type=\"text\" name=\"" +
                rset.getString("key_id") + "\" size=\"20\" value=\"" +
                rset.getString("value") + "\">");

            out.println("</td></tr>");
        }
    }

%>
            </table>
            <input type="hidden" name="user_id" value="<%= user_id %>">
            <div align="right">
                <input type="reset" /><input type="submit" />
            </div>
        </form>
        <p><a href="manageFields.jsp?return=editMeta.jsp?user_id=<%= user_id%>">Manage ...</a></p>
    </body>
</html>
<%
} catch (SQLException e) {
    out.println("<br />" + e.getMessage());
} finally {
    conn.close();
}
%>
