<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.naming.*' %>
<%@ page import = 'javax.sql.*' %>

<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();

String name = request.getParameter("name");

PreparedStatement pstmt = null;
ResultSet rset = null;

PreparedStatement updateStmt = null;

int meta_id;

try {

    if(name != null && !name.equals("")) {

        conn.setAutoCommit(false);

        pstmt = conn.prepareStatement("insert into adium.meta_container (name) values (?)");

        pstmt.setString(1, name);

        pstmt.executeUpdate();

        pstmt = conn.prepareStatement("select currval('meta_container_meta_id_seq')");
        rset = pstmt.executeQuery();

        rset.next();

        meta_id = rset.getInt("currval");
        
        pstmt = conn.prepareStatement("select key_id from information_keys");

        rset = pstmt.executeQuery();

        while(rset.next()) {
            String requestText = request.getParameter(rset.getString("key_id"));

            if(requestText != null && !requestText.equals("")) {
                updateStmt = conn.prepareStatement("insert into adium.contact_information (meta_id, key_id, value) values (?, ?, ?)");

                updateStmt.setInt(1, meta_id);
                updateStmt.setInt(2, rset.getInt("key_id"));
                updateStmt.setString(3, requestText);

                updateStmt.executeUpdate();
            }
        }
    }
} catch (SQLException e) {
    out.println("<br />" + e.getMessage());
    conn.rollback();
} finally {
    conn.commit();
    conn.close();
}
%>
<html>
<body onLoad="window.opener.parent.location.reload(); window.close()"></body>
</html>
