<%@ page import = 'java.sql.*' %>
<%@ page import = 'org.slamb.axamol.library.*' %>
<%@ page import = 'java.util.Map' %>
<%@ page import = 'java.util.HashMap' %>

<%
LibraryConnection lc = (LibraryConnection) request.getAttribute("lc-update");
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
}
%>
