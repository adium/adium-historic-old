<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.naming.*' %>
<%@ page import = 'javax.sql.*' %>
<%@ page import = 'java.util.Map' %>
<%@ page import = 'java.util.HashMap' %>
<%@ page import = 'java.io.File' %>
<%@ page import = 'org.slamb.axamol.library.*' %>
<%@ page import = 'sqllogger.*' %>

<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();

ResultSet rset = null;

String title = new String();
String service = new String();
String username = new String();
int meta_id;

File queryFile = new File(session.getServletContext().getRealPath("queries/standard.xml"));

LibraryConnection lc = new LibraryConnection(queryFile, conn);
Map params = new HashMap();

meta_id = Util.checkInt(request.getParameter("meta_id"));

service = Util.checkNull(request.getParameter("service"));

username = Util.checkNull(request.getParameter("username"));

try {

    params.put("meta_id", new Integer(meta_id));
    rset = lc.executeQuery("meta_contained_users", params);


    if(rset.next()) {
        title = rset.getString("name");
    }

%>

<html>
<head><title>Add Contact: <%= title %></title>
<body>
<form action="insertMeta.jsp" method="get">

<%

    rset = lc.executeQuery("distinct_services", params);
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

    <input type="text" name="username" value="<%= Util.safeString(username) %>" /><br />

    <select name="user_id">
        <option value="0" selected="selected">Choose One</option>
<%

    params.put("username", username);
    params.put("service", service);
    rset = lc.executeQuery("all_users_except_meta", params);

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
