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

String name = request.getParameter("name");
String deleteMe = request.getParameter("delete");

int meta_id = Util.checkInt(request.getParameter("meta_id"));

params.put("meta_id", new Integer(meta_id));
params.put("name", name);

ResultSet rset = null;

try {

    if(deleteMe != null && deleteMe.equals("on")) {
        params.put("key_id", new Integer(0));
        params.put("user_id", new Integer(0));

        lc.executeUpdate("delete_user_from_meta", params);

        lc.executeUpdate("delete_meta_info", params);

        lc.executeUpdate("delete_meta_contact", params);

    } else if(name != null && !name.equals("") && meta_id != 0) {

        lc.executeUpdate("change_meta_name", params);

        rset = lc.executeQuery("info_keys", params);

        while(rset.next()) {
            String requestText = request.getParameter(rset.getString("key_id"));
            int returnVal;

            params.put("value", requestText);
            params.put("key_id", new Integer(rset.getInt("key_id")));

            if(requestText != null && !requestText.equals("")) {

                returnVal = lc.executeUpdate("update_meta_info", params);

                if(returnVal == 0) {
                    lc.executeUpdate("insert_meta_key_info", params);
                }
            } else if (requestText == null || requestText.equals("")) {

                lc.executeUpdate("delete_meta_info", params);
            }
        }
    }

    if(request.getParameter("redirect") != null) {
        response.sendRedirect(request.getParameter("redirect"));
    }
} finally {
    conn.close();
}
%>
<html>
<body onLoad="window.opener.parent.location.reload(); window.close()"></body>
</html>
