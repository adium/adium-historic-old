<%@ page import = 'java.sql.*' %>
<%@ page import = 'org.slamb.axamol.library.*' %>
<%@ page import = 'java.util.Map' %>
<%@ page import = 'java.util.HashMap' %>
<%@ page import = 'sqllogger.*' %>

<%

LibraryConnection lc = (LibraryConnection) request.getAttribute("lc-update");
Map params = new HashMap();

String name = request.getParameter("name");
String deleteMe = request.getParameter("delete");

int user_id = Util.checkInt(request.getParameter("user_id"));

params.put("user_id", new Integer(user_id));

ResultSet rset = null;

try {

    if(user_id != 0) {

        rset = lc.executeQuery("info_keys", params);

        while(rset.next()) {
            String requestText = request.getParameter(rset.getString("key_id"));
            int returnVal;

            params.put("value", requestText);
            params.put("key_id", new Integer(rset.getInt("key_id")));

            if(requestText != null && !requestText.equals("")) {

                returnVal = lc.executeUpdate("update_user_info", params);

                if(returnVal == 0) {
                    lc.executeUpdate("insert_user_info", params);
                }
            } else if (requestText == null || requestText.equals("")) {

                lc.executeUpdate("delete_user_info", params);

            }
        }
    }
} catch (SQLException e) {
    out.println("<br />" + e.getMessage());
}
%>
<html>
<body onLoad="window.opener.parent.location.reload(); window.close()"></body>
</html>
