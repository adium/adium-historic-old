<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.naming.*' %>
<%@ page import = 'javax.sql.*' %>

<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();

String name = request.getParameter("name");
String url = request.getParameter("url");
String email = request.getParameter("email");
String location = request.getParameter("location");
String notes = request.getParameter("notes");

if(url != null && url.equals("")) {
    url = null;
}

if(email != null && email.equals("")) {
    email = null;
}

if(location != null && location.equals("")) {
    location = null;
}

if (notes != null && notes.equals("")) {
    notes = null;
}

PreparedStatement pstmt = null;

try {
    if(name != null && !name.equals("")) {
        pstmt = conn.prepareStatement("insert into adium.meta_container (name, url, email, location, notes) values (?, ?, ?, ?, ?)");

        pstmt.setString(1, name);
        pstmt.setString(2, url);
        pstmt.setString(3, email);
        pstmt.setString(4, location);
        pstmt.setString(5, notes);

        pstmt.executeUpdate();
    }
} catch (SQLException e) {
    out.println(e.getMessage());
} finally {
    conn.close();
}
%>
<html>
<body onLoad="window.opener.parent.location.reload(); window.close()"></body>
</html>
