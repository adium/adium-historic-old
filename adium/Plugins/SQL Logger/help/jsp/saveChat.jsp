<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.naming.*' %>
<%@ page import = 'javax.sql.*' %>

<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();

PreparedStatement pstmt = null;
int meta_id = 0;

try {
    pstmt = conn.prepareStatement("insert into adium.saved_chats (title, notes, sent_sn, received_sn, single_sn, date_start, date_finish, meta_id) values (?, ?, ?, ?, ?, ?, ?, ?)");

    pstmt.setString(1, request.getParameter("title"));
    pstmt.setString(2, request.getParameter("notes"));
    pstmt.setString(3, request.getParameter("sender"));
    pstmt.setString(4, request.getParameter("recipient"));
    pstmt.setString(5, request.getParameter("single_sn"));
    pstmt.setString(6, request.getParameter("dateStart"));
    pstmt.setString(7, request.getParameter("dateFinish"));

    try {
        meta_id = Integer.parseInt(request.getParameter("meta_id"));
    } catch (NumberFormatException e) {
        meta_id = 0;
    }

    pstmt.setInt(8, meta_id);

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
