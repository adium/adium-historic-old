<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.naming.*' %>
<%@ page import = 'javax.sql.*' %>

<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();

int user_id;

try {
    user_id = Integer.parseInt(request.getParameter("user_id"));
} catch (NumberFormatException e) {
    user_id = 0;
}

PreparedStatement pstmt = null;
ResultSet rset = null;

try {
    pstmt = conn.prepareStatement("select username, key_id, key_name, coalesce(value, '') as value from adium.users natural left join adium.information_keys natural left join adium.contact_information where user_id = ? and delete = false order by key_name");

    pstmt.setInt(1, user_id);

    rset = pstmt.executeQuery();
    rset.next();
%>
<html>
    <head><title>Edit User <%= rset.getString("username") %></title></head>
    <link rel="stylesheet" type="text/css" href="styles/default.css" />
    <link rel="stylesheet" type="text/css" href="styles/users.css" />
    <body style="background :#fff">
        <form action="updateUser.jsp" method="get">
            <table border="0" cellpadding="0" cellspacing="5">
<%
    rset.beforeFirst();

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
