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

String returnVar  = request.getParameter("return");

ResultSet rset = null;

File queryFile = new File(session.getServletContext().getRealPath("queries/update.xml"));

LibraryConnection lc = new LibraryConnection(queryFile, conn);
Map params = new HashMap();

try {

    rset = lc.executeQuery("info_keys", params);

    while(rset.next()) {
        String requestText = request.getParameter(rset.getString("key_id"));

        if(requestText != null && requestText.equals("on")) {
            params.put("key_id", new Integer(rset.getString("key_id")));
            lc.executeUpdate("delete_key", params);
        }
    }


    for(int i = 1; i <= 3; i++) {
        String req = request.getParameter("new" + i);

        if(req != null && !req.equals("")) {
            params.put("name", req);

            lc.executeUpdate("insert_key", params);
        }
    }
    response.sendRedirect(returnVar);

} catch (SQLException e) {
    out.println("<br />" + e.getMessage());
} finally {
    lc.close();
    conn.close();
}
%>
<html>
</html>
