<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.naming.*' %>
<%@ page import = 'javax.sql.*' %>
<%@ page import = 'org.slamb.axamol.library.*' %>
<%@ page import = 'java.io.File' %>
<%@ page import = 'java.util.Map' %>
<%@ page import = 'java.util.HashMap' %>

<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();

File queryFile = new File(session.getServletContext().getRealPath("queries/update.xml"));

LibraryConnection lc = new LibraryConnection(queryFile, conn);
Map params = new HashMap();

try {
    params.put("message_id", new Integer(request.getParameter("message_id")));
    params.put("title", request.getParameter("title"));
    params.put("notes", request.getParameter("notes"));
    lc.executeUpdate("insert_message_note", params);

%>
<html>
<body onLoad="window.opener.parent.location.reload(); window.close()"></body>
</html>
<%
} catch (SQLException e) {
    out.println("<br />" + e.getMessage());
} finally {
    conn.close();
}
%>
