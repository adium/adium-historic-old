<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.naming.*' %>
<%@ page import = 'javax.sql.*' %>

<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();

PreparedStatement pstmt = null;
ResultSet rset = null;

try {
    pstmt = conn.prepareStatement("select key_id, key_name from adium.information_keys where delete = false order by key_name");

    rset = pstmt.executeQuery();
%>
<html>
    <head><title>Add Meta-Contact</title></head>
    <link rel="stylesheet" type="text/css" href="styles/default.css" />
    <link rel="stylesheet" type="text/css" href="styles/users.css" />
    <body style="background: #ffffff">
        <form action="insertNewMeta.jsp" method="get">
            <table border="0" cellpadding="0" cellspacing="5">
            <tr>
            <td align="right" class="header">
            <label for="name">Name</label>
            </td>
            <td>
            <input type="text" name="name" size="20" />
            </td>
            </tr>
<%
    while(rset.next()) {
        out.println("<tr><td align=\"right\">");
        out.println("<label for=\"" + rset.getString("key_name") + "\">" +
            rset.getString("key_name") + "</label>");

        out.println("</td><td>");

        out.println("<input type=\"text\" name=\"" +
            rset.getString("key_id") + "\" size=\"20\">");

        out.println("</td></tr>");
    }

%>
            </table>
            <div align="right">
                <input type="reset" /><input type="submit" />
            </div>
        </form>
        <p><a href="manageFields.jsp?return=addMeta.jsp">Manage Fields ... </a></p>
    </body>
</html>
<%
} catch (SQLException e) {
    out.println("<br />" + e.getMessage());
} finally {
    conn.close();
}
%>
