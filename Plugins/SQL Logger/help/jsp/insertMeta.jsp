<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.naming.*' %>
<%@ page import = 'javax.sql.*' %>
<%@ page import = 'org.slamb.axamol.library.*' %>
<%@ page import = 'java.io.File' %>
<%@ page import = 'java.util.Map' %>
<%@ page import = 'java.util.HashMap' %>
<%@ page import = 'sqllogger.*' %>

<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();

File queryFile = new File(session.getServletContext().getRealPath("queries/update.xml"));

LibraryConnection lc = new LibraryConnection(queryFile, conn);
Map params = new HashMap();

int meta_id, user_id;
String service, username, addAll;
boolean all = false;
boolean error = false;

service = Util.checkNull(request.getParameter("service"));
username = Util.checkNull(request.getParameter("username"));
addAll = request.getParameter("all");

meta_id = Util.checkInt(request.getParameter("meta_id"));
user_id = Util.checkInt(request.getParameter("user_id"));

params.put("meta_id", new Integer(meta_id));
params.put("user_id", new Integer(user_id));
params.put("service", service);
params.put("username", username);

if(addAll != null && addAll.equals("on")) {
    all = true;
}

ResultSet rs = null;

try {
    if((service != null || username != null) && !all) {
        rs = lc.executeQuery("count_service_user", params);

        rs.next();

        if(rs.getInt(1) > 1) {
            response.sendRedirect("addContact.jsp?meta_id=" +
                meta_id + "&service=" + Util.safeString(service) +
                "&username=" + Util.safeString(username));
        } else if (rs.getInt(1) == 1) {
            if(user_id != 0) {
                error = true;
                out.println("<span style=\"color: red\">Error.  Please de-select a user from the pulldown or remove the typed field.</span>");
            }
            rs = lc.executeQuery("get_user_id", params);

            rs.next();

            user_id = rs.getInt("user_id");
            params.put("user_id", new Integer(user_id));
        }
    } else if ((service != null || username != null) && meta_id != 0 && all) {

        lc.executeUpdate("add_all_users_to_meta", params);
    }

    if(meta_id != 0 && user_id != 0) {
        lc.executeUpdate("add_user_to_meta", params);
    }
    if(!error) {
%>
<html>
    <body onLoad="window.opener.parent.location.reload(); window.close()">
    </body>
</html>
<%
    }
} catch (SQLException e) {
    out.println("<br />" + e.getMessage());
} finally {
    conn.close();
}
%>
