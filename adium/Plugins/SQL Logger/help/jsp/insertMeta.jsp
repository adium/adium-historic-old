<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.naming.*' %>
<%@ page import = 'javax.sql.*' %>

<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();

int meta_id, user_id;

try {
    meta_id = Integer.parseInt(request.getParameter("meta_id"));
} catch (NumberFormatException e) {
    meta_id = 0;
}

try {
    user_id = Integer.parseInt(request.getParameter("user_id"));
} catch (NumberFormatException e) {
    user_id = 0;
}

PreparedStatement pstmt = null;

try {
    if(meta_id != 0 && user_id != 0) {
        
        pstmt = conn.prepareStatement("insert into adium.meta_contact (meta_id, user_id) values (?, ?)");

        pstmt.setInt(1, meta_id);
        pstmt.setInt(2, user_id);

        pstmt.executeUpdate();
    }
} catch (SQLException e) {
    out.println("<br />" + e.getMessage());
} finally {
    conn.close();
}
%>
<html>
<body onLoad="window.opener.parent.location.reload(); window.close()"></body>
</html>
