<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.naming.*' %>
<%@ page import = 'javax.sql.*' %>

<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();

PreparedStatement pstmt = null;
ResultSet rset = null;

String title = new String();

int meta_id;
try {
    meta_id = Integer.parseInt(request.getParameter("meta_id"));
} catch (NumberFormatException e) {
    meta_id = 0;
}

try {
    pstmt = conn.prepareStatement("select name from adium.meta_container where meta_id = ?");

    pstmt.setInt(1, meta_id);

    rset = pstmt.executeQuery();

    if(rset.next()) {
        title = rset.getString("name");
    }

    pstmt = conn.prepareStatement("select user_id, display_name || ' (' || service || '.' || username || ')' as full_display from adium.users natural join adium.user_display_name udn where not exists (select 'x' from adium.user_display_name where user_id = udn.user_id and effdate > udn.effdate) and not exists (select 'x' from adium.meta_contact where meta_id = ? and user_id = users.user_id) order by display_name, username");

    pstmt.setInt(1, meta_id);

    rset = pstmt.executeQuery();
%>

<html>
<head><title><%= title %></title>
<body>
<form action="insertMeta.jsp" method="get">
<select name="user_id">
    <option value="0" selected="selected">Choose One</option>
<%
    while(rset.next()) {
        out.println("<option value=\"" + rset.getString("user_id") +
            "\">" + rset.getString("full_display") + "</option>");
    }
%>
</select>
<br /><br />
<input type="hidden" value="<%= meta_id %>" name="meta_id" />
<div align="right">
    <input type="submit" />
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
