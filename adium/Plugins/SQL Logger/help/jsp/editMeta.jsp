<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.naming.*' %>
<%@ page import = 'javax.sql.*' %>

<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();

int meta_id;

try {
    meta_id = Integer.parseInt(request.getParameter("meta_id"));
} catch (NumberFormatException e) {
    meta_id = 0;
}

PreparedStatement pstmt = null;
ResultSet rset = null;

try {
    pstmt = conn.prepareStatement("select name, coalesce(url, '') as url, coalesce(email, '') as email, coalesce(location, '') as location, coalesce(notes, '') as notes from adium.meta_container where meta_id = ?");
    
    pstmt.setInt(1, meta_id);
    
    rset = pstmt.executeQuery();
    
    rset.next();
%>
<html>
    <head><title>Edit Meta-Contact <%= rset.getString("name") %></title></head>
    <body>
        <form action="updateMeta.jsp" method="get">
            <label for="name"><b>Name</b></label><br />
            <input type="text" name="name" size="30" 
                value="<%= rset.getString("name")%>"/><br /><br />

            <label for="url"><b>URL</b></label><br />
            <input type="text" name="url" size="30"
                value="<%= rset.getString("url")%>"><br /><br />

            <label for="email"><b>Email</b></label><br />
            <input type="text" name="email" size="30"
                value="<%= rset.getString("email")%>"><br /><br />

            <label for="location"><b>Location</b></label><br />
            <input type="text" name="location" size="30"
                value="<%= rset.getString("location")%>"><br /><br />

            <label for="notes"><b>Notes</b></label><br />
            <textarea rows="6" cols="30" name="notes"><%= rset.getString("notes")%></textarea><br />
            <br />
            <input type="checkbox" name="delete" id="delete" />
            <label for="delete">Delete</label><br />
            <input type="hidden" name="meta_id" value="<%= meta_id %>">
            <div align="right">
                <input type="reset" /><input type="submit" />
            </div>
        </form>
    </body>
</html>
<%
} catch (SQLException e) {
    out.println(e.getMessage());
} finally {
    conn.close();
}
%>