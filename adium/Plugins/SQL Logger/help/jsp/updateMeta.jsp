<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.naming.*' %>
<%@ page import = 'javax.sql.*' %>

<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();

String name = request.getParameter("name");
String deleteMe = request.getParameter("delete");

int meta_id = 0;

try {
    meta_id = Integer.parseInt(request.getParameter("meta_id"));
} catch (NumberFormatException e) {
    meta_id = 0;
}

PreparedStatement pstmt = null;
ResultSet rset = null;

PreparedStatement updateStmt = null;

try {

    if(deleteMe != null && deleteMe.equals("on")) {

        pstmt = conn.prepareStatement("delete from adium.meta_contact where meta_id = ?");

        pstmt.setInt(1, meta_id);

        pstmt.executeUpdate();


        pstmt = conn.prepareStatement("delete from adium.contact_information where meta_id = ?");

        pstmt.setInt(1, meta_id);

        pstmt.executeUpdate();


        pstmt = conn.prepareStatement("delete from adium.meta_container where meta_id = ?");
        pstmt.setInt(1, meta_id);

        pstmt.executeUpdate();

    } else if(name != null && !name.equals("") && meta_id != 0) {

        pstmt = conn.prepareStatement("update adium.meta_container set name = ? where meta_id = ?");

        pstmt.setString(1, name);
        pstmt.setInt(2, meta_id);

        pstmt.executeUpdate();

        pstmt = conn.prepareStatement("select key_id from information_keys");

        rset = pstmt.executeQuery();

        while(rset.next()) {
            String requestText = request.getParameter(rset.getString("key_id"));
            int returnVal;

            if(requestText != null && !requestText.equals("")) {
                updateStmt = conn.prepareStatement("update adium.contact_information set value = ? where key_id = ? and meta_id = ?");

                updateStmt.setString(1, requestText);
                updateStmt.setInt(2, rset.getInt("key_id"));
                updateStmt.setInt(3, meta_id);

                returnVal = updateStmt.executeUpdate();

                if(returnVal == 0) {
                    updateStmt = conn.prepareStatement("insert into adium.contact_information (meta_id, key_id, value) values (?, ?, ?)");

                    updateStmt.setInt(1, meta_id);
                    updateStmt.setInt(2, rset.getInt("key_id"));
                    updateStmt.setString(3, requestText);

                    updateStmt.executeUpdate();
                }
            } else if (requestText == null || requestText.equals("")) {

                updateStmt = conn.prepareStatement("delete from adium.contact_information where meta_id = ? and key_id = ?");

                updateStmt.setInt(1, meta_id);
                updateStmt.setInt(2, rset.getInt("key_id"));

                updateStmt.executeUpdate();
            }
        }
    }
} catch (SQLException e) {
    out.println("<br/>" + e.getMessage());
} finally {
    conn.close();
}
%>
<html>
<body onLoad="window.opener.parent.location.reload(); window.close()"></body>
</html>
