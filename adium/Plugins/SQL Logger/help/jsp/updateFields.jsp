<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.naming.*' %>
<%@ page import = 'javax.sql.*' %>

<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();

String returnVar  = request.getParameter("return");

PreparedStatement pstmt = null;
ResultSet rset = null;

PreparedStatement updateStmt = null;

try {

    pstmt = conn.prepareStatement("select key_id from information_keys where delete = false");

    rset = pstmt.executeQuery();
    
    while(rset.next()) {
        String requestText = request.getParameter(rset.getString("key_id"));
        int returnVal;

        if(requestText != null && requestText.equals("on")) {

            updateStmt = conn.prepareStatement("update adium.information_keys set delete = true where key_id = ? ");

            updateStmt.setInt(1, rset.getInt("key_id"));

            updateStmt.executeUpdate();
        }
    }

    pstmt = conn.prepareStatement("insert into adium.information_keys (key_name) values (?)");
    
    for(int i = 1; i <= 3; i++) {
        String req = request.getParameter("new" + i);

        if(req != null && !req.equals("")) {
            pstmt.setString(1, req);

            pstmt.executeUpdate();
        }
    }
    response.sendRedirect(returnVar);

} catch (SQLException e) {
    out.println("<br />" + e.getMessage());
} finally {
    conn.close();
}
%>
<html>
</html>
