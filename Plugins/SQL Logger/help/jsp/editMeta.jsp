<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.naming.*' %>
<%@ page import = 'javax.sql.*' %>

<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();

int meta_id;

try {
    meta_id = Integer.parseInt(request.getParameter("meta_id"));
} catch (NumberFormatException e) {
    meta_id = 0;
}

PreparedStatement pstmt = null;
ResultSet rset = null;
String name = new String();

try {
    pstmt = conn.prepareStatement("select name, key_id, key_name, coalesce(value, '') as value from im.meta_container natural join im.information_keys natural left join im.contact_information where meta_id = ? and delete = false order by key_name");

    pstmt.setInt(1, meta_id);

    rset = pstmt.executeQuery();
    if(rset.isBeforeFirst()) {
        rset.next();
        name = rset.getString("name");
        rset.beforeFirst();
    }

%>
<html>
    <head><title>Edit Meta-Contact <%= name %></title></head>
    <link rel="stylesheet" type="text/css" href="styles/default.css" />
    <link rel="stylesheet" type="text/css" href="styles/users.css" />
    <body style="background :#fff">
        <form action="updateMeta.jsp" method="get">
            <table border="0" cellpadding="0" cellspacing="5">
            <tr>
            <td align="right" class="header">
            <label for="name">Name</label>
            </td>
            <td>
            <input type="text" name="name" size="20"
                value="<%= name %>"/>
            </td>
            </tr>
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
            <input type="checkbox" name="delete" id="delete" />
            <label for="delete">Delete</label><br />
            <input type="hidden" name="meta_id" value="<%= meta_id %>">
            <div align="right">
                <input type="reset" /><input type="submit" />
            </div>
        </form>
        <p><a href="manageFields.jsp?return=editMeta.jsp?meta_id=<%= meta_id%>">Manage ...</a></p>
    </body>
</html>
<%
} catch (SQLException e) {
    out.println("<br />" + e.getMessage());
} finally {
    conn.close();
}
%>
