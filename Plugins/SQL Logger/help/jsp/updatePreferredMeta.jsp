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

    params.put("user_id", new Integer(request.getParameter("user_id")));
    params.put("meta_id", new Integer(request.getParameter("meta_id")));

    lc.executeUpdate("preferred_true", params);

    lc.executeUpdate("preferred_false", params);

    response.sendRedirect("meta.jsp");
} catch (SQLException e) {
    out.println("<br/>" + e.getMessage());
} catch (NumberFormatException e) {
    out.println(e.getMessage());
} finally {
    lc.close();
    conn.close();
}
%>
