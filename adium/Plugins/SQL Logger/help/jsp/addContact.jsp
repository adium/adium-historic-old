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
String service = new String();
String username = new String();
int meta_id;

try {
    meta_id = Integer.parseInt(request.getParameter("meta_id"));
} catch (NumberFormatException e) {
    meta_id = 0;
}

service = request.getParameter("service");
if(service != null && service.equals("")) {
    service = null;
}

username = request.getParameter("username");
if(username != null && username.equals("")) {
    username = null;
}

try {
    pstmt = conn.prepareStatement("select name from adium.meta_container where meta_id = ?");

    pstmt.setInt(1, meta_id);

    rset = pstmt.executeQuery();

    if(rset.next()) {
        title = rset.getString("name");
    }

%>

<html>
<head><title>Add Contact: <%= title %></title>
<body>
<form action="insertMeta.jsp" method="get">

<%
    pstmt = conn.prepareStatement("select distinct service from adium.users order by service");

    rset = pstmt.executeQuery();
%>
    <select name="service">
        <option value="" selected="selected">Choose One</option>
<%
    while(rset.next()) {
        out.print("<option value=\"" + rset.getString("service") + "\"");
        if(service != null && service.equals(rset.getString("service"))) {
            out.print(" selected=\"selected\" " );
        }
        out.print(">" +
            rset.getString("service") + "</option>\n");
    }
%>
    </select>

    <input type="text" name="username" <% if (username != null) out.print("value=\"" + username + "\""); %> /><br />

    <select name="user_id">
        <option value="0" selected="selected">Choose One</option>
<%
    out.println(username);
    out.println(service);

    if(username == null && service == null) {
        pstmt = conn.prepareStatement("select user_id, display_name || ' (' || service || '.' || username || ')' as full_display from adium.users natural join adium.user_display_name udn where not exists (select 'x' from adium.user_display_name where user_id = udn.user_id and effdate > udn.effdate) and not exists (select 'x' from adium.meta_contact where meta_id = ? and user_id = users.user_id) order by display_name, username");

        pstmt.setInt(1, meta_id);

    } else if (username != null && service != null) {
        pstmt = conn.prepareStatement("select user_id, display_name || ' (' || service || '.' || username || ')' as full_display from adium.users natural join adium.user_display_name udn where not exists (select 'x' from adium.user_display_name where user_id = udn.user_id and effdate > udn.effdate) and not exists (select 'x' from adium.meta_contact where meta_id = ? and user_id = users.user_id) and service = ? and username ilike ? order by display_name, username");

        pstmt.setInt(1, meta_id);
        pstmt.setString(2, service);
        pstmt.setString(3, username);

    } else if (username != null && service == null) {
        pstmt = conn.prepareStatement("select user_id, display_name || ' (' || service || '.' || username || ')' as full_display from adium.users natural join adium.user_display_name udn where not exists (select 'x' from adium.user_display_name where user_id = udn.user_id and effdate > udn.effdate) and not exists (select 'x' from adium.meta_contact where meta_id = ? and user_id = users.user_id) and username ilike ? order by display_name, username");

        pstmt.setInt(1, meta_id);
        pstmt.setString(2, username);
    } else if (service != null && username == null) {
        pstmt = conn.prepareStatement("select user_id, display_name || ' (' || service || '.' || username || ')' as full_display from adium.users natural join adium.user_display_name udn where not exists (select 'x' from adium.user_display_name where user_id = udn.user_id and effdate > udn.effdate) and not exists (select 'x' from adium.meta_contact where meta_id = ? and user_id = users.user_id) and service = ? order by display_name, username");

        pstmt.setInt(1, meta_id);
        pstmt.setString(2, service);
    }

    rset = pstmt.executeQuery();

    while(rset.next()) {
        out.println("<option value=\"" + rset.getString("user_id") +
            "\">" + rset.getString("full_display") + "</option>");
    }
%>
    </select>
    <br />
    <input type="checkbox" name="all" id="all"><label for="all">Add All</label>
    <br />
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
