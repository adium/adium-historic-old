<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.naming.*' %>
<%@ page import = 'javax.sql.*' %>

<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();

String name = request.getParameter("name");
String deleteMe = request.getParameter("delete");

int user_id = 0;

try {
    user_id = Integer.parseInt(request.getParameter("user_id"));
} catch (NumberFormatException e) {
    user_id = 0;
}

PreparedStatement pstmt = null;
ResultSet rset = null;

PreparedStatement updateStmt = null;

try {

    if(user_id != 0) {

        pstmt = conn.prepareStatement("select key_id from information_keys");

        rset = pstmt.executeQuery();

        while(rset.next()) {
            String requestText = request.getParameter(rset.getString("key_id"));
            int returnVal;

            if(requestText != null && !requestText.equals("")) {
                updateStmt = conn.prepareStatement("update adium.contact_information set value = ? where key_id = ? and user_id = ?");

                updateStmt.setString(1, requestText);
                updateStmt.setInt(2, rset.getInt("key_id"));
                updateStmt.setInt(3, user_id);

                returnVal = updateStmt.executeUpdate();

                if(returnVal == 0) {
                    updateStmt = conn.prepareStatement("insert into adium.contact_information (user_id, key_id, value) values (?, ?, ?)");

                    updateStmt.setInt(1, user_id);
                    updateStmt.setInt(2, rset.getInt("key_id"));
                    updateStmt.setString(3, requestText);

                    updateStmt.executeUpdate();
                }
            } else if (requestText == null || requestText.equals("")) {

                updateStmt = conn.prepareStatement("delete from adium.contact_information where user_id = ? and key_id = ?");

                updateStmt.setInt(1, user_id);
                updateStmt.setInt(2, rset.getInt("key_id"));

                updateStmt.executeUpdate();
            }
        }
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
