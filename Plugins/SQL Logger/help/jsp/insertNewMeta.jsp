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

String name = Util.checkNull(request.getParameter("name"));

ResultSet rset = null;

int meta_id;

File queryFile = new File(session.getServletContext().getRealPath("queries/update.xml"));

LibraryConnection lc = new LibraryConnection(queryFile, conn);
Map params = new HashMap();

try {

    if(name != null && !name.equals("")) {

        params.put("name", name);

        lc.executeUpdate("add_meta", params);

        params.put("sequence", "meta_container_meta_id_seq");

        rset = lc.executeQuery("currval", params);

        rset.next();

        meta_id = rset.getInt("currval");

        params.put("meta_id", new Integer(meta_id));

        rset = lc.executeQuery("info_keys", params);

        while(rset.next()) {
            String requestText = request.getParameter(rset.getString("key_id"));

            if(requestText != null && !requestText.equals("")) {

                params.put("key_id", new Integer(rset.getInt("key_id")));
                params.put("value", requestText);

                lc.executeUpdate("insert_meta_key_info", params);
            }
        }
    }
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
