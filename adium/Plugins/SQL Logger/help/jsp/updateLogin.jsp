<%@ page import='java.sql.*' %>
<%@ page import='javax.sql.*' %>
<%@ page import='javax.naming.*' %>
<%@ page import='java.util.Properties' %>

<!--$URL: http://svn.visualdistortion.org/repos/projects/crash/post-comments.jsp $-->
<!--$Rev: 504 $ $Date: 2004/05/22 20:08:07 $-->
<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();

String queryString = request.getQueryString();

queryString = queryString.replaceAll("=on", "");
queryString = queryString.replaceAll("&", ",");

out.println(queryString);

PreparedStatement pstmt = null;
PreparedStatement stmt = null;
ResultSet rset = null;

int rowsAffected = 0;

try {
    pstmt = conn.prepareStatement("select user_id from adium.users where login=true and user_id not in (" + queryString + ")");

    rset = pstmt.executeQuery();

    while(rset.next()) {
        stmt = conn.prepareStatement("update users set login = false where user_id = ?");
        stmt.setInt(1, rset.getInt("user_id"));

        stmt.executeUpdate();

        rowsAffected++;
    }

    pstmt = conn.prepareStatement("select user_id from adium.users where (login=false or login is null) and user_id in (" + queryString + ")");

    rset = pstmt.executeQuery();

    while(rset.next()) {
        stmt = conn.prepareStatement("update users set login = true where user_id = ?");
        stmt.setInt(1, rset.getInt("user_id"));

        stmt.executeUpdate();

        rowsAffected++;
    }
    out.println("<br /> " + rowsAffected);

    response.sendRedirect("meta.jsp");
} catch(SQLException e) {
    out.println("<br />Error!\n");
    out.print(e.getMessage());
}

finally {
conn.close();
}

%>
</body>
</html>
