<%@ page import = 'java.sql.*' %>
<%@ page import = 'org.slamb.axamol.library.*' %>
<%@ page import = 'java.util.Map' %>
<%@ page import = 'java.util.HashMap' %>

<%

LibraryConnection lc = (LibraryConnection) request.getAttribute("lc-update");
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
}
%>
