<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.naming.*' %>
<%@ page import = 'javax.sql.*' %>

<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();

PreparedStatement pstmt = null;

try {
    pstmt = conn.prepareStatement("insert into adium.message_notes (message_id, title, notes) values (?, ?, ?)");

    pstmt.setInt(1, Integer.parseInt(request.getParameter("message_id")));
    pstmt.setString(2, request.getParameter("title"));
    pstmt.setString(3, request.getParameter("notes"));
    pstmt.executeUpdate();

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
