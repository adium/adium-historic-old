<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.naming.*' %>
<%@ page import = 'javax.sql.*' %>

<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();

PreparedStatement pstmt = null;

try {
    pstmt = conn.prepareStatement("insert into im.saved_queries (title, notes, query_text) values (?, ?, ?)");

    pstmt.setString(1, request.getParameter("title"));
    pstmt.setString(2, request.getParameter("notes"));
    pstmt.setString(3, request.getParameter("query"));

    pstmt.executeUpdate();

} catch (SQLException e) {
    out.println("<br />" + e.getMessage());
} finally {
    conn.close();
}
%>
<html>
<body onLoad="window.opener.parent.location.reload(); window.close()"></body>
</html>
