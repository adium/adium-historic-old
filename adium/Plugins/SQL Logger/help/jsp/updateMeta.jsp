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
String deleteMe = request.getParameter("delete");

int meta_id = 0;

try {
    meta_id = Integer.parseInt(request.getParameter("meta_id"));
} catch (NumberFormatException e) {
    meta_id = 0;
}

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
    
    if(deleteMe != null && deleteMe.equals("on")) {
        
        pstmt = conn.prepareStatement("delete from adium.meta_contact where meta_id = ?");
        
        pstmt.setInt(1, meta_id);
        
        pstmt.executeUpdate();
        
        pstmt = conn.prepareStatement("delete from adium.meta_container where meta_id = ?");
        pstmt.setInt(1, meta_id);
        
        pstmt.executeUpdate();
        
    } else if(name != null && !name.equals("") && meta_id != 0) {
        pstmt = conn.prepareStatement("update adium.meta_container set name = ?, url = ?, email = ?, location = ?, notes = ? where meta_id = ?");

        pstmt.setString(1, name);
        pstmt.setString(2, url);
        pstmt.setString(3, email);
        pstmt.setString(4, location);
        pstmt.setString(5, notes);
        pstmt.setInt(6, meta_id);
        
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
