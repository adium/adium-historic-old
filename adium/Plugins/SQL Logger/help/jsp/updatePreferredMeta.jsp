<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.naming.*' %>
<%@ page import = 'javax.sql.*' %>

<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();

PreparedStatement pstmt = null;

try {
    pstmt = conn.prepareStatement("update adium.meta_contact set preferred = true where user_id = ? and meta_id = ?");

    pstmt.setInt(1, Integer.parseInt(request.getParameter("user_id")));
    pstmt.setInt(2, Integer.parseInt(request.getParameter("meta_id")));

    pstmt.executeUpdate();

    pstmt = conn.prepareStatement("update adium.meta_contact set preferred = false where user_id = ? and meta_id <> ?");


    pstmt.setInt(1, Integer.parseInt(request.getParameter("user_id")));
    pstmt.setInt(2, Integer.parseInt(request.getParameter("meta_id")));

    pstmt.executeUpdate();

    response.sendRedirect("meta.jsp");
} catch (SQLException e) {
    out.println("<br/>" + e.getMessage());
} catch (NumberFormatException e) {
    out.println(e.getMessage());
}finally {
    conn.close();
}
%>
