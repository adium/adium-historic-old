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
    pstmt = conn.prepareStatement("select key_id, key_name from adium.information_keys where delete = false order by key_name ");

    rset = pstmt.executeQuery();
    rset.next();
%>
<html>
    <head><title>Manage Fields</title></head>
    <link rel="stylesheet" type="text/css" href="styles/default.css" />
    <body style="background :#fff">
        <form action="updateFields.jsp" method="get">
            <table border="0" cellpadding="0" cellspacing="5">
            <tr>
            <td align="right">
            <label for="name">Delete?</label>
            </td>
            <td>
                Field Name
            </td>
            </tr>
<%
    rset.beforeFirst();
    while(rset.next()) {
        out.println("<tr><td align=\"right\">");

        out.println("<input type=\"checkbox\" name=\"" +
            rset.getInt("key_id") + "\" id=\"" +
            rset.getString("key_name") + "\"/>");
        out.println("</td><td>");

        out.println("<label for=\"" + rset.getString("key_name") +
            "\">" + rset.getString("key_name") + "</label>");

        out.println("</td></tr>");
    }

    for(int i = 1; i <= 3; i ++) {
        out.println("<tr><td></td><td>");
        out.println("<input type=\"text\" name=\"new" + i + "\" />");
        out.println("</td></tr>");
    }
%>

            </table>
                <input type="hidden" name="return" value="<%= request.getParameter("return") %>">
                <input type="reset" /><input type="submit" />
            </div>
        </form>
    </body>
</html>
<%
} catch (SQLException e) {
    out.println("<br />" + e.getMessage());
} finally {
    conn.close();
}
%>
